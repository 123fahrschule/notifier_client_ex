## Why

Services currently build Notifier email delivery commands by hand before publishing them to RabbitMQ. This leaks transport details into application code and makes it easy for payload shape, metadata, delivery identifiers, or priority handling to drift from the contract expected by Notifier.

## What Changes

- Add first-class E-Mail support to `notifier_client_ex` for creating valid Notifier `deliver-email` commands.
- Provide an E-Mail object that can be built through small composable functions, similar in feel to `Swoosh.Email`, rather than a single generic `Email.build/1` map constructor.
- Support both generic command delivery via `NotifierClient.deliver(command)` and a domain-readable `send_email` API.
- Hide RabbitMQ exchange/routing-key/type/subject construction from callers while still producing the existing Notifier wire format.
- Validate required email fields and supported options before publishing.
- Use Elixir's built-in JSON support by default on supported Elixir versions, with the JSON codec configurable for projects that intentionally use another encoder.
- Allow services to integrate their existing shared metadata/URN helpers through configuration instead of forcing the client to copy those helpers.
- Keep SMS, Telegram, push notification delivery, and delivery-status consumers out of scope for this first step.

## Capabilities

### New Capabilities

- `email-delivery-client`: Provides the public E-Mail command object, validation, event serialization, and delivery APIs needed to request email delivery through Notifier.

### Modified Capabilities

- None.

## Impact

- Affected code: new Mix project/library structure under `notifier_client_ex`, public email modules, publisher behaviour/adapter, tests, and documentation.
- Affected systems: services that want to send email through Notifier can depend on this client instead of manually constructing `deliver-email` RabbitMQ payloads.
- Dependencies: `ex_tackle`/`tackle` for RabbitMQ publishing. JSON serialization should use Elixir's built-in `JSON` module when available, with a configurable codec for compatibility.
- Wire compatibility: generated messages must remain compatible with Notifier's existing `deliver-email` consumer on exchange `notifier`, routing key `deliver-email`.
