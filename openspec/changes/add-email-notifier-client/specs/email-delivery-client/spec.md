## ADDED Requirements

### Requirement: Composable E-Mail command object

The system SHALL provide a Notifier-specific E-Mail command object that callers can construct through small composable functions instead of a single generic map builder.

#### Scenario: Build a minimal template email command

- **WHEN** a caller creates an E-Mail command, sets an idempotency key, sets a template slug, adds one recipient, and adds placeholders
- **THEN** the command retains those values as structured E-Mail command data without exposing RabbitMQ exchange or routing-key fields

#### Scenario: Use delivery request id alias

- **WHEN** a caller sets the command idempotency value through a `delivery_request_id` alias
- **THEN** the command stores the same idempotency key value used by the preferred `idempotency_key` function

#### Scenario: Add optional email fields incrementally

- **WHEN** a caller adds `from`, `subject`, `reply_to`, `cc`, `bcc`, `deliver_at`, priority, or supported attachments through E-Mail command functions
- **THEN** the command includes those values without replacing previously configured recipients, template data, or placeholders

#### Scenario: Preserve immutable pipeline behavior

- **WHEN** a caller applies an E-Mail command function to an existing command
- **THEN** the system returns an updated E-Mail command and leaves the previous command value reusable

### Requirement: E-Mail command validation

The system SHALL validate E-Mail commands before serialization or publishing.

#### Scenario: Reject missing required delivery fields

- **WHEN** a caller attempts to deliver an E-Mail command without an idempotency key, template slug, or recipient
- **THEN** the system returns a validation error and MUST NOT publish a Notifier command

#### Scenario: Reject unsupported priority

- **WHEN** a caller sets a priority other than `highest`, `high`, `default`, `low`, or `lowest`
- **THEN** the system returns a validation error and MUST NOT rely on Notifier's default-priority fallback

#### Scenario: Reject invalid email option shape

- **WHEN** a caller provides malformed recipient, sender, reply-to, cc, bcc, placeholder, or attachment data
- **THEN** the system returns a validation error that identifies the invalid field and MUST NOT publish a Notifier command

### Requirement: Notifier deliver-email serialization

The system SHALL serialize a valid E-Mail command to Notifier's existing `deliver-email` wire contract.

#### Scenario: Serialize the command envelope

- **WHEN** a valid E-Mail command is serialized for delivery
- **THEN** the event type is `de.123fahrschule:notifier:deliver-email`, the event subject is `de.123fahrschule:notifier:email-delivery-request`, the spec version is `1.0`, and the data content type is `application/json`

#### Scenario: Serialize email data

- **WHEN** a valid E-Mail command is serialized for delivery
- **THEN** the event data contains the command idempotency key as `email_delivery_request_identifier` alongside `email_identifier`, `mail_options`, `placeholders`, and `priority` in the shape accepted by Notifier's email delivery consumer

#### Scenario: Serialize optional delivery time

- **WHEN** a valid E-Mail command includes `deliver_at`
- **THEN** the serialized event contains `deliver_at` as an ISO 8601 datetime string

#### Scenario: Omit optional delivery time

- **WHEN** a valid E-Mail command does not include `deliver_at`
- **THEN** the serialized event remains valid for immediate Notifier delivery

### Requirement: Source metadata construction

The system SHALL construct event metadata from client configuration and per-command metadata, and MUST allow host applications to configure a compatible metadata or identifier provider.

#### Scenario: Use configured source service

- **WHEN** a valid E-Mail command is serialized with source service `absence`
- **THEN** the event source is `de.123fahrschule:absence`

#### Scenario: Use explicit correlation metadata

- **WHEN** a caller provides correlation, causation, actor, or event id metadata for an E-Mail command
- **THEN** the serialized event uses those metadata values in the corresponding top-level event fields

#### Scenario: Generate safe default metadata

- **WHEN** optional event metadata is omitted
- **THEN** the system generates an event id and time, sets JSON content metadata, and uses deterministic defaults that still produce a Notifier-compatible event

#### Scenario: Use configured shared metadata helpers

- **WHEN** a host application configures a metadata or identifier provider backed by its shared helper modules
- **THEN** the system uses that provider for event identifiers or metadata values without requiring callers to manually construct the Notifier event envelope

### Requirement: JSON codec configuration

The system SHALL encode serialized Notifier events with Elixir's built-in JSON support by default on supported Elixir versions and MUST allow the JSON codec to be configured.

#### Scenario: Encode with default JSON codec

- **WHEN** a valid E-Mail command is published without custom JSON codec configuration
- **THEN** the system encodes the Notifier event with the default JSON codec and passes JSON to the publisher adapter

#### Scenario: Encode with configured JSON codec

- **WHEN** a host application configures an alternate JSON codec
- **THEN** the system uses the configured codec to encode the Notifier event before publishing

### Requirement: E-Mail delivery APIs

The system SHALL provide both generic command delivery and a domain-readable E-Mail sending API.

#### Scenario: Deliver email through generic API

- **WHEN** a caller passes a valid E-Mail command to `NotifierClient.deliver(command)`
- **THEN** the system publishes the serialized event to exchange `notifier` with routing key `deliver-email`

#### Scenario: Send email through domain API

- **WHEN** a caller passes a valid E-Mail command to the `send_email` API
- **THEN** the system publishes the same serialized event and routing options as `NotifierClient.deliver(command)`

#### Scenario: Return publisher result

- **WHEN** the configured publisher returns `:ok` or `{:error, reason}`
- **THEN** the delivery API returns the publisher result to the caller

#### Scenario: Use test publisher without RabbitMQ

- **WHEN** tests configure a non-RabbitMQ publisher implementation
- **THEN** the system sends the serialized event and publish options to that publisher implementation without requiring a RabbitMQ connection
