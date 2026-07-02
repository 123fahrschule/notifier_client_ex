defmodule NotifierClient.CustomMetadataProvider do
  @behaviour NotifierClient.MetadataProvider

  @impl true
  def build(_metadata, _config, _context) do
    %{
      "id" => "custom-event-id",
      "source" => "de.123fahrschule:custom-source",
      "specversion" => "1.0",
      "time" => "2026-06-26T12:00:00Z",
      "actor" => "de.123fahrschule:custom-actor",
      "datacontenttype" => "application/json",
      "causation_id" => "custom-causation-id",
      "correlation_id" => "custom-correlation-id"
    }
  end
end
