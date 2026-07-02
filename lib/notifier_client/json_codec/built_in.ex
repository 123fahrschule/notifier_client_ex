defmodule NotifierClient.JSONCodec.BuiltIn do
  @moduledoc """
  JSON codec backed by Elixir's built-in `JSON.encode!/1`.
  """

  @behaviour NotifierClient.JSONCodec

  @impl true
  def encode!(term), do: JSON.encode!(term)
end
