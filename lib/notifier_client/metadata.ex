defmodule NotifierClient.Metadata do
  @moduledoc false

  def build(metadata, config, context) do
    config.metadata_provider.build(Enum.into(metadata, %{}), config, context)
  end
end
