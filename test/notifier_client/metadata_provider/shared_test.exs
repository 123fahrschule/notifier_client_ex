defmodule NotifierClient.MetadataProvider.SharedTest do
  use ExUnit.Case, async: true

  alias NotifierClient.Config
  alias NotifierClient.MetadataProvider.Shared

  @context %{event_type: "de.123fahrschule:notifier:deliver-email"}

  test "uses Shared.UUID.generate/0 when no event id is supplied" do
    metadata = Shared.build(%{}, config(), @context)

    assert metadata["id"] == "shared-event-id"
    assert_received {:shared_uuid_generated, "shared-event-id"}
  end

  test "preserves atom-keyed event id without generating shared UUID" do
    metadata = Shared.build(%{event_id: "explicit-event-id"}, config(), @context)

    assert metadata["id"] == "explicit-event-id"
    refute_received {:shared_uuid_generated, _event_id}
  end

  test "preserves string-keyed event id without generating shared UUID" do
    metadata = Shared.build(%{"event_id" => "explicit-event-id"}, config(), @context)

    assert metadata["id"] == "explicit-event-id"
    refute_received {:shared_uuid_generated, _event_id}
  end

  defp config do
    Config.get(source_service: "absence")
  end
end
