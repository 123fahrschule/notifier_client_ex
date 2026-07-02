defmodule NotifierClient.ValidationError do
  @moduledoc false

  defexception [:errors]

  @impl true
  def message(%__MODULE__{errors: errors}) do
    "invalid NotifierClient command: " <> inspect(errors)
  end
end
