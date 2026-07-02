defmodule NotifierClient.MetadataProvider.Shared do
  @moduledoc """
  Optional metadata provider for host applications that expose compatible Shared helpers.

  Currently this provider uses `Shared.UUID.generate/0` when that module and
  function are available, then delegates the rest of the envelope construction
  to `NotifierClient.MetadataProvider.Default`. If `Shared.UUID.generate/0` is
  not available, it falls back to the default UUID generator.
  """

  @behaviour NotifierClient.MetadataProvider

  alias NotifierClient.Identifier
  alias NotifierClient.MetadataProvider.Default

  @impl true
  def build(metadata, config, context) do
    metadata
    |> Map.put_new(:event_id, shared_uuid() || Identifier.uuid())
    |> Default.build(config, context)
  end

  defp shared_uuid do
    if Code.ensure_loaded?(Shared.UUID) and function_exported?(Shared.UUID, :generate, 0) do
      apply(Shared.UUID, :generate, [])
    end
  end
end
