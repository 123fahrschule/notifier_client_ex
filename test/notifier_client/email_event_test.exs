defmodule NotifierClient.EmailEventTest do
  use ExUnit.Case, async: true

  alias NotifierClient.Email
  alias NotifierClient.Email.Event
  alias NotifierClient.ValidationError

  defp valid_email do
    Email.new()
    |> Email.idempotency_key("de.123fahrschule:absence:pending-absence-reminder:1")
    |> Email.template("absence/team-leads/daily_remidner_of_absence_pending_requests")
    |> Email.to("teamlead@example.com")
    |> Email.from("info@123fahrschule.de")
    |> Email.subject("Pending absences")
    |> Email.put_placeholder("pending_requests_count", 3)
  end

  test "serializes a valid email command to the Notifier deliver-email event" do
    deliver_at = ~U[2026-06-26T12:30:00Z]

    email =
      valid_email()
      |> Email.cc("cc@example.com")
      |> Email.bcc("bcc@example.com")
      |> Email.reply_to("reply@example.com")
      |> Email.deliver_at(deliver_at)
      |> Email.priority(:highest)
      |> Email.attach_s3("https://s3.example.com/file.pdf", "application/pdf", "file.pdf")
      |> Email.metadata(
        event_id: "event-id",
        actor: "de.123fahrschule:absence",
        causation_id: "cause",
        correlation_id: "correlation",
        time: "2026-06-26T12:00:00Z"
      )

    assert {:ok, event} = Event.to_event(email, source_service: "absence")

    assert event["id"] == "event-id"
    assert event["source"] == "de.123fahrschule:absence"
    assert event["specversion"] == "1.0"
    assert event["type"] == "de.123fahrschule:notifier:deliver-email"
    assert event["subject"] == "de.123fahrschule:notifier:email-delivery-request"
    assert event["time"] == "2026-06-26T12:00:00Z"
    assert event["actor"] == "de.123fahrschule:absence"
    assert event["datacontenttype"] == "application/json"
    assert event["causation_id"] == "cause"
    assert event["correlation_id"] == "correlation"

    assert event["data"] == %{
             "mail_options" => %{
               "to" => ["teamlead@example.com"],
               "from" => "info@123fahrschule.de",
               "subject" => "Pending absences",
               "reply_to" => "reply@example.com",
               "cc" => ["cc@example.com"],
               "bcc" => ["bcc@example.com"],
               "attachments" => [
                 %{
                   "source" => "amazon-s3",
                   "url" => "https://s3.example.com/file.pdf",
                   "content_type" => "application/pdf",
                   "name" => "file.pdf"
                 }
               ]
             },
             "email_delivery_request_identifier" =>
               "de.123fahrschule:absence:pending-absence-reminder:1",
             "email_identifier" =>
               "absence/team-leads/daily_remidner_of_absence_pending_requests",
             "placeholders" => %{"pending_requests_count" => 3},
             "priority" => "highest",
             "deliver_at" => "2026-06-26T12:30:00Z"
           }
  end

  test "omits deliver_at for immediate delivery" do
    assert {:ok, event} = Event.to_event(valid_email(), source_service: "absence")

    refute Map.has_key?(event["data"], "deliver_at")
  end

  test "generates default metadata" do
    assert {:ok, event} = Event.to_event(valid_email(), source_service: "absence")

    assert event["source"] == "de.123fahrschule:absence"
    assert event["actor"] == "de.123fahrschule:absence"
    assert event["specversion"] == "1.0"
    assert event["datacontenttype"] == "application/json"
    assert is_binary(event["id"])
    assert is_binary(event["time"])
    assert event["causation_id"] == "#{Event.type()}:#{event["id"]}"
    assert event["correlation_id"] == event["causation_id"]
  end

  test "uses explicit metadata passed in delivery options" do
    assert {:ok, event} =
             Event.to_event(valid_email(),
               source_service: "absence",
               metadata: [
                 event_id: "explicit-event-id",
                 correlation_id: "explicit-correlation-id"
               ]
             )

    assert event["id"] == "explicit-event-id"
    assert event["correlation_id"] == "explicit-correlation-id"
  end

  test "uses configured metadata provider" do
    assert {:ok, event} =
             Event.to_event(valid_email(),
               metadata_provider: NotifierClient.CustomMetadataProvider
             )

    assert event["id"] == "custom-event-id"
    assert event["source"] == "de.123fahrschule:custom-source"
    assert event["correlation_id"] == "custom-correlation-id"
  end

  test "encodes with default JSON codec" do
    assert {:ok, json, event} = Event.to_json(valid_email(), source_service: "absence")

    assert JSON.decode!(json) == event
  end

  test "encodes with configured JSON codec" do
    assert {:ok, "custom-json", event} =
             Event.to_json(valid_email(), json_codec: NotifierClient.CustomJSONCodec)

    assert_received {:custom_json_codec_encoded, ^event}
  end

  test "returns validation errors for invalid commands" do
    email =
      Email.new()
      |> Email.idempotency_key("")
      |> Email.template("")
      |> Email.to("not-an-email")
      |> Email.priority(:urgent)
      |> Email.put_placeholder(:not_a_string_key, "value")
      |> Email.deliver_at(~D[2026-06-26])
      |> Email.attach_s3("", "application/pdf", "file.pdf")

    assert {:error, %ValidationError{errors: errors}} = Event.to_event(email)

    assert errors.idempotency_key == ["must be present"]
    assert errors.template_slug == ["must be present"]
    assert errors.to == ["contains an invalid email address"]
    assert errors.priority == ["is not supported"]
    assert errors.placeholders == ["must have string keys"]
    assert errors.deliver_at == ["must be a DateTime"]
    assert errors.attachments == ["contains an invalid attachment"]
  end

  test "requires at least one recipient" do
    email =
      Email.new()
      |> Email.idempotency_key("key")
      |> Email.template("template")

    assert {:error, %ValidationError{errors: errors}} = Event.to_event(email)

    assert errors.to == ["must contain at least one recipient"]
  end
end
