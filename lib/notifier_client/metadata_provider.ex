defmodule NotifierClient.MetadataProvider do
  @moduledoc """
  Behaviour for building the event metadata envelope around Notifier commands.

  A metadata provider receives caller-provided metadata, the resolved
  `NotifierClient.Config`, and serialization context such as the Notifier event
  type. It must return the top-level event metadata fields expected by Notifier.

  The returned map is merged into the serialized event before `data` is added,
  so keys must be strings matching the wire contract, for example:

      %{
        "id" => "event-id",
        "source" => "de.123fahrschule:absence",
        "specversion" => "1.0",
        "time" => "2026-06-26T12:00:00Z",
        "actor" => "de.123fahrschule:absence",
        "datacontenttype" => "application/json",
        "causation_id" => "cause-id",
        "correlation_id" => "correlation-id"
      }

  Configure a custom provider when a host application should use its own event
  id, URN, actor, causation, or correlation conventions:

      config :notifier_client_ex,
        metadata_provider: MyApp.NotifierMetadataProvider

  The default implementation is `NotifierClient.MetadataProvider.Default`.
  """

  @typedoc "Caller metadata from an email command or delivery options."
  @type metadata :: map()

  @typedoc "Resolved client configuration passed to metadata providers."
  @type config :: NotifierClient.Config.t()

  @typedoc "Serialization context. Currently includes the Notifier `:event_type`."
  @type context :: map()

  @typedoc "String-keyed top-level metadata fields merged into the event envelope."
  @type event_metadata :: %{String.t() => term()}

  @doc """
  Builds string-keyed event metadata for the Notifier event envelope.
  """
  @callback build(metadata(), config(), context()) :: event_metadata()
end
