## Context

Notifier accepts email delivery requests as CloudEvents-like JSON messages over RabbitMQ on exchange `notifier` with routing key `deliver-email`. Existing services construct those maps directly, including Notifier-specific `type`, `subject`, metadata fields, `mail_options`, template slug, placeholders, delivery timing, and priority.

The new `notifier_client_ex` repository starts as a public Elixir client for those contracts. The first implementation step is intentionally limited to E-Mail delivery. It should make the message construction visible and testable inside the client while keeping RabbitMQ and Notifier wire details out of calling services.

## Goals / Non-Goals

**Goals:**

- Provide a small, composable E-Mail object API that feels familiar to Elixir developers who have used `Swoosh.Email`.
- Produce the current Notifier `deliver-email` wire format without requiring callers to know the exchange, routing key, event type, or subject.
- Support both `NotifierClient.deliver(command)` and a more domain-readable `send_email` API.
- Validate the email command before publish so caller errors are caught locally.
- Keep the transport replaceable in tests through a publisher behaviour.
- Prefer Elixir's built-in JSON support on modern Elixir versions while allowing a configured codec where needed.
- Allow host applications to opt into existing shared metadata/URN helpers through configuration.

**Non-Goals:**

- Reuse `Swoosh.Email` as the persisted public command type.
- Send rendered email bodies directly through Notifier.
- Add SMS, Telegram, push notification, or delivery-status/reply-to consumer support in this change.
- Query Notifier templates or validate placeholder names against Notifier at runtime.
- Replace existing service-specific event-store listeners in one step.

## Decisions

### Use a Notifier-specific E-Mail command object

Implement a `NotifierClient.Email` struct with composable functions such as `new/0`, `to/2`, `from/2`, `cc/2`, `bcc/2`, `reply_to/2`, `subject/2`, `template/2`, `put_placeholder/3`, `put_placeholders/2`, `idempotency_key/2`, `deliver_at/2`, `priority/2`, and `attach_s3/4`. `delivery_request_id/2` may exist as an alias, but `idempotency_key/2` should be the preferred public name because it describes why the value matters.

Rationale: Notifier email delivery is template-driven and does not match Swoosh's rendered body model. A dedicated command object can model Notifier-specific requirements directly while still supporting pipeline-style construction.

Alternative considered: using `Swoosh.Email` directly. Rejected for the first version because Swoosh has fields and semantics that Notifier does not consume, while Notifier requires fields such as `email_identifier`, `email_delivery_request_identifier`, and `placeholders` that are not native to Swoosh.

Example target shape:

```elixir
email =
  NotifierClient.Email.new()
  |> NotifierClient.Email.idempotency_key("de.123fahrschule:absence:pending-absence-reminder:...")
  |> NotifierClient.Email.template("absence/team-leads/daily_reminder_of_absence_pending_requests")
  |> NotifierClient.Email.to("teamlead@example.com")
  |> NotifierClient.Email.from("info@123fahrschule.de")
  |> NotifierClient.Email.put_placeholder("pending_requests_count", 3)
  |> NotifierClient.Email.priority(:high)

NotifierClient.send_email(email)
NotifierClient.deliver(email)
```

### Require an idempotency key before publishing

An idempotency key should be required for delivery and serialized to Notifier as `email_delivery_request_identifier`. Callers may build the value however they choose, but it should be explicit so retries and repeated command execution can be idempotent from Notifier's perspective.

Rationale: If the client silently generated this identifier for every send attempt, caller retries could produce duplicate email delivery requests. Existing services often derive deterministic identifiers from the triggering domain context.

Alternative considered: expose only a `delivery_request_id/2` function. Rejected as the primary API name because it describes Notifier's internal persistence concept more than the caller-facing purpose. It can remain as an alias for readers who know the Notifier wire contract.

Alternative considered: auto-generate an idempotency key when omitted. Rejected for publishing because convenience would undermine idempotency. Tests or examples can still show helper-generated IDs explicitly.

### Keep CloudEvent metadata in the client boundary, with optional Shared integration

The client should construct the CloudEvents-like envelope itself:

- `type`: `de.123fahrschule:notifier:deliver-email`
- `subject`: `de.123fahrschule:notifier:email-delivery-request`
- `source`: `de.123fahrschule:<configured-source-service>`
- `actor`: explicit metadata actor or the configured source
- `specversion`: `1.0`
- `datacontenttype`: `application/json`
- `time`: current time or explicit metadata time
- `correlation_id` and `causation_id`: explicit metadata values, with sensible defaults when omitted

The default implementation should be self-contained and derive URNs from configured source service values. Host applications that already have compatible `Shared.URN`, `Shared.EventStore.Metadata`, or related helpers may configure a metadata/identifier provider so the client delegates ID and metadata conventions to those modules.

Rationale: the library should remain usable outside one umbrella/service codebase, but it should not prevent existing services from reusing their established shared helper conventions. A provider boundary avoids copying helper modules into the client and avoids making `Shared` a hard dependency for every consumer.

Alternative considered: require the existing `Shared.*` modules directly. Rejected because this would make the client less public/reusable and would couple compilation to modules that are currently duplicated across services rather than distributed as a standalone package.

Alternative considered: ignore the existing helpers entirely. Rejected because services already rely on consistent URN and metadata conventions, and a configured integration can reduce migration friction.

### Use built-in JSON by default with a codec boundary

The serializer should use Elixir's built-in `JSON` module by default on supported Elixir versions. The JSON codec should still be configurable through a small behaviour or module option so services can use Jason or another encoder if they intentionally need compatibility with an older stack or existing test helpers.

Rationale: newer Elixir versions include JSON support, so a hard Jason dependency is unnecessary for the expected target stack. A codec boundary keeps the client explicit without locking the package to one encoder.

Alternative considered: depend on Jason unconditionally. Rejected because it is no longer necessary for modern Elixir targets and adds an avoidable dependency.

### Use a publisher behaviour with a Tackle adapter

Define a publisher behaviour for publishing serialized command events. The production adapter should use Tackle's publish API with pooled publisher connections. The client should include a public stub adapter that records the generated event and publish options for tests.

Rationale: The caller-facing API should be independent from RabbitMQ, but the first production transport remains the existing RabbitMQ contract. Tackle already supports lazy pooled publishers, so the client does not need its own publishing GenServer for the first version.

Alternative considered: expose Tackle options in every send call. Rejected because it leaks transport concerns into application code and recreates the problem this client is meant to solve.

### Serialize only supported Notifier email fields

The email command should serialize to `data.mail_options`, `data.email_delivery_request_identifier`, `data.email_identifier`, `data.placeholders`, optional `data.deliver_at`, and `data.priority`.

Supported `mail_options` are `to`, `from`, `subject`, `reply_to`, `cc`, `bcc`, and `attachments`. Attachments are limited to Notifier's current `amazon-s3` attachment source with `url`, `content_type`, and `name`.

Rationale: strict serialization keeps the public client stable and avoids sending unknown fields that Notifier ignores or could later interpret differently.

### Validate locally, but do not validate remote Notifier state

The client should validate local shape constraints: required idempotency key, template slug, at least one recipient, valid email-like recipient fields, supported priority, placeholder keys as strings, and supported attachment source shape.

It should not check whether the template slug exists in Notifier or whether placeholder names match a template definition.

Rationale: local validation catches contract errors before publishing. Remote template validation would require an additional Notifier API or schema distribution mechanism that does not exist in this first step.

## Risks / Trade-offs

- [Template placeholder drift] -> Mitigation: validate placeholder map shape locally and document that template-specific placeholder validation remains Notifier-side or future schema work.
- [Duplicate emails from unstable identifiers] -> Mitigation: require explicit idempotency keys before publishing and document deterministic key guidance.
- [Overfitting to current Notifier payloads] -> Mitigation: centralize serialization in one module and cover the exact wire contract with tests copied from Notifier fixtures.
- [Swoosh API expectation mismatch] -> Mitigation: keep the builder style familiar but name Notifier-specific functions explicitly, especially `template/2`, `idempotency_key/2`, and `put_placeholder/3`.
- [Transport errors hidden by friendly API] -> Mitigation: `send_email` and `deliver` should return publisher results, including `{:error, reason}`, instead of swallowing Tackle failures.
