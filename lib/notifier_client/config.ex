defmodule NotifierClient.Config do
  @moduledoc false

  defstruct source_service: "notifier-client",
            rabbitmq_url: "amqp://localhost",
            publisher_connection_name: "NotifierClient Publisher",
            publisher: NotifierClient.Publisher.Tackle,
            json_codec: NotifierClient.JSONCodec.BuiltIn,
            metadata_provider: NotifierClient.MetadataProvider.Default

  @type t :: %__MODULE__{
          source_service: String.t(),
          rabbitmq_url: String.t(),
          publisher_connection_name: String.t(),
          publisher: module(),
          json_codec: module(),
          metadata_provider: module()
        }

  @app :notifier_client_ex

  def get(overrides \\ []) do
    overrides = Enum.into(overrides, %{})

    %__MODULE__{
      source_service: value(:source_service, overrides, "notifier-client"),
      rabbitmq_url:
        value(:rabbitmq_url, overrides, System.get_env("RABBITMQ_URL") || "amqp://localhost"),
      publisher_connection_name:
        value(:publisher_connection_name, overrides, "NotifierClient Publisher"),
      publisher: value(:publisher, overrides, NotifierClient.Publisher.Tackle),
      json_codec: value(:json_codec, overrides, NotifierClient.JSONCodec.BuiltIn),
      metadata_provider:
        value(:metadata_provider, overrides, NotifierClient.MetadataProvider.Default)
    }
  end

  def publish_options(%__MODULE__{} = config, :email) do
    [
      rabbitmq_url: config.rabbitmq_url,
      exchange: "notifier",
      routing_key: "deliver-email",
      publisher_connection_name: config.publisher_connection_name
    ]
  end

  defp value(key, overrides, default) do
    Map.get(overrides, key) ||
      Application.get_env(@app, key) ||
      default
  end
end
