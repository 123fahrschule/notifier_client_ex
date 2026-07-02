defmodule NotifierClient.MetadataProvider.Default do
  @moduledoc """
  Default metadata provider used by NotifierClient.

  This provider is self-contained and does not depend on application-specific
  shared modules. It generates a UUID event id when none is supplied, derives the
  source URN from `source_service`, fills actor/time defaults, and creates
  causation and correlation ids when the caller does not provide them.

  Caller metadata may use atom or string keys.
  """

  @behaviour NotifierClient.MetadataProvider

  alias NotifierClient.Identifier

  @impl true
  def build(metadata, config, %{event_type: event_type}) do
    event_id = value(metadata, :event_id) || Identifier.uuid()
    source = value(metadata, :source) || Identifier.source_urn(config.source_service)
    actor = value(metadata, :actor) || value(metadata, :enacted_by) || source
    time = value(metadata, :time) || value(metadata, :occurred_at) || DateTime.utc_now()
    causation_id = value(metadata, :causation_id) || "#{event_type}:#{event_id}"
    correlation_id = value(metadata, :correlation_id) || causation_id

    %{
      "id" => event_id,
      "source" => source,
      "specversion" => "1.0",
      "time" => format_time(time),
      "actor" => actor,
      "datacontenttype" => "application/json",
      "causation_id" => causation_id,
      "correlation_id" => correlation_id
    }
  end

  defp value(metadata, key) do
    Map.get(metadata, key) || Map.get(metadata, Atom.to_string(key))
  end

  defp format_time(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp format_time(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  defp format_time(time) when is_binary(time), do: time
end
