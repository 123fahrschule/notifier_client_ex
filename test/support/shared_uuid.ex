defmodule Shared.UUID do
  @moduledoc false

  def generate do
    send(self(), {:shared_uuid_generated, "shared-event-id"})
    "shared-event-id"
  end
end
