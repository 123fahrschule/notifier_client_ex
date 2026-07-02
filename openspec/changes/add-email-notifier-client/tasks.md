## 1. Project Setup

- [x] 1.1 Create the Mix project structure for `notifier_client_ex` without adding application-code scope beyond the E-Mail client.
- [x] 1.2 Add the Tackle-compatible RabbitMQ publishing dependency and avoid a hard Jason dependency for modern Elixir targets.
- [x] 1.3 Define client configuration for source service, RabbitMQ URL, publisher connection name, publisher adapter, JSON codec, and optional metadata/identifier provider.
- [x] 1.4 Add test support for isolated unit tests and a public publisher stub that does not require RabbitMQ.

## 2. E-Mail Command Object

- [x] 2.1 Implement `NotifierClient.Email` as an immutable command struct with `new/0`.
- [x] 2.2 Add composable functions for idempotency key, template slug, recipients, sender, subject, reply-to, cc, and bcc, including `delivery_request_id/2` as an alias for `idempotency_key/2`.
- [x] 2.3 Add composable functions for placeholders, delivery time, priority, and Amazon S3 attachments.
- [x] 2.4 Cover pipeline-style object construction with unit tests, including preservation of earlier values when optional fields are added.

## 3. Validation and Serialization

- [x] 3.1 Implement validation for required idempotency key, template slug, at least one recipient, supported priority, placeholder keys, email option shape, and attachment shape.
- [x] 3.2 Implement self-contained metadata construction plus a configurable metadata/identifier provider boundary for services that want to use existing shared helpers.
- [x] 3.3 Implement serialization from a valid E-Mail command to the Notifier `deliver-email` event envelope and data payload.
- [x] 3.4 Implement JSON encoding through the default built-in JSON codec with support for a configured alternate codec.
- [x] 3.5 Add serialization tests against the Notifier fixture shape, including optional `deliver_at`, default metadata, explicit metadata, configured shared-helper provider behavior, JSON codec selection, and attachments.
- [x] 3.6 Add validation tests proving invalid commands return errors and are not serialized for publishing.

## 4. Delivery APIs and Publisher

- [x] 4.1 Define a publisher behaviour that receives serialized events and publish options.
- [x] 4.2 Implement the Tackle publisher adapter using exchange `notifier` and routing key `deliver-email`.
- [x] 4.3 Implement `NotifierClient.deliver(command)` for E-Mail commands.
- [x] 4.4 Implement the domain-readable `send_email` API with the same behavior as `NotifierClient.deliver(command)`.
- [x] 4.5 Add tests proving both delivery APIs publish identical events/options, return publisher results, and do not publish on validation errors.

## 5. Documentation and Verification

- [x] 5.1 Document configuration, E-Mail pipeline usage, deterministic idempotency keys, the `delivery_request_id/2` alias, priorities, attachments, and both delivery APIs.
- [x] 5.2 Run formatter and the test suite.
- [x] 5.3 Review the generated public API names for consistency with the E-Mail-only scope before marking the change ready for implementation review.
