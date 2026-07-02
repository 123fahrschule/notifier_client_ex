defmodule NotifierClient.CustomJSONCodec do
  @behaviour NotifierClient.JSONCodec

  @impl true
  def encode!(event) do
    send(self(), {:custom_json_codec_encoded, event})
    "custom-json"
  end
end
