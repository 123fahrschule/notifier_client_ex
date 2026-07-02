defmodule NotifierClient.EmailTest do
  use ExUnit.Case, async: true

  alias NotifierClient.Email

  test "builds an email command through composable functions" do
    original = Email.new()

    email =
      original
      |> Email.idempotency_key("de.123fahrschule:absence:email:1")
      |> Email.template("absence/template")
      |> Email.to("teamlead@example.com")
      |> Email.to({"Max Mustermann", "max@example.com"})
      |> Email.from("info@123fahrschule.de")
      |> Email.subject("Pending absences")
      |> Email.put_placeholder("pending_requests_count", 3)

    assert original.to == []
    assert email.idempotency_key == "de.123fahrschule:absence:email:1"
    assert email.template_slug == "absence/template"
    assert email.to == ["teamlead@example.com", "Max Mustermann <max@example.com>"]
    assert email.from == "info@123fahrschule.de"
    assert email.subject == "Pending absences"
    assert email.placeholders == %{"pending_requests_count" => 3}
  end

  test "delivery_request_id is an alias for idempotency_key" do
    email = Email.new() |> Email.delivery_request_id("same-key")

    assert email.idempotency_key == "same-key"
  end

  test "adds optional fields without replacing previous values" do
    deliver_at = ~U[2026-06-26T12:30:00Z]

    email =
      Email.new()
      |> Email.to("first@example.com")
      |> Email.to("second@example.com")
      |> Email.cc(["cc1@example.com", "cc2@example.com"])
      |> Email.bcc("bcc@example.com")
      |> Email.reply_to("reply@example.com")
      |> Email.put_placeholders(%{"first_name" => "Ada"})
      |> Email.put_placeholder("count", 1)
      |> Email.deliver_at(deliver_at)
      |> Email.priority(:high)
      |> Email.attach_s3("https://s3.example.com/file.pdf", "application/pdf", "file.pdf")

    assert email.to == ["first@example.com", "second@example.com"]
    assert email.cc == ["cc1@example.com", "cc2@example.com"]
    assert email.bcc == ["bcc@example.com"]
    assert email.reply_to == "reply@example.com"
    assert email.placeholders == %{"first_name" => "Ada", "count" => 1}
    assert email.deliver_at == deliver_at
    assert email.priority == "high"

    assert email.attachments == [
             %{
               "source" => "amazon-s3",
               "url" => "https://s3.example.com/file.pdf",
               "content_type" => "application/pdf",
               "name" => "file.pdf"
             }
           ]
  end
end
