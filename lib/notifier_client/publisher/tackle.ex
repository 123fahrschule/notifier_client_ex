defmodule NotifierClient.Publisher.Tackle do
  @moduledoc """
  Publisher adapter that delegates to `Tackle.publish/2`.

  The client passes options such as `:rabbitmq_url`, `:exchange`, `:routing_key`,
  and `:publisher_connection_name`.
  """

  @behaviour NotifierClient.Publisher

  @impl true
  def publish(payload, options) when is_binary(payload) do
    Tackle.publish(payload, options)
  end
end
