defmodule NotifierClientTest do
  use ExUnit.Case, async: true

  alias NotifierClient.Email
  alias NotifierClient.Publisher.Stub, as: TestPublisher

  defp email do
    Email.new()
    |> Email.idempotency_key("de.123fahrschule:absence:pending-absence-reminder:1")
    |> Email.template("absence/template")
    |> Email.to("teamlead@example.com")
  end

  test "deliver publishes email commands to notifier deliver-email" do
    assert :ok =
             NotifierClient.deliver(email(),
               source_service: "absence",
               publisher: TestPublisher
             )

    assert_received {:notifier_client_published, payload, options}

    event = JSON.decode!(payload)
    assert event["type"] == "de.123fahrschule:notifier:deliver-email"
    assert event["source"] == "de.123fahrschule:absence"

    assert options[:exchange] == "notifier"
    assert options[:routing_key] == "deliver-email"
    assert options[:rabbitmq_url] == "amqp://localhost"
    assert options[:publisher_connection_name] == "NotifierClient Publisher"
  end

  test "send_email publishes the same event and options as deliver" do
    assert :ok =
             NotifierClient.deliver(email(),
               source_service: "absence",
               metadata: [event_id: "same-event-id", time: "2026-06-26T12:00:00Z"],
               publisher: TestPublisher
             )

    assert_received {:notifier_client_published, deliver_payload, deliver_options}

    assert :ok =
             NotifierClient.send_email(email(),
               source_service: "absence",
               metadata: [event_id: "same-event-id", time: "2026-06-26T12:00:00Z"],
               publisher: TestPublisher
             )

    assert_received {:notifier_client_published, send_email_payload, send_email_options}

    assert JSON.decode!(send_email_payload) == JSON.decode!(deliver_payload)
    assert send_email_options == deliver_options
  end

  test "returns publisher errors" do
    TestPublisher.put_result({:error, :unroutable})

    assert {:error, :unroutable} =
             NotifierClient.send_email(email(), publisher: TestPublisher)
  after
    TestPublisher.clear_result()
  end

  test "does not publish invalid commands" do
    assert {:error, _validation_error} =
             NotifierClient.send_email(Email.new(), publisher: TestPublisher)

    refute_received {:notifier_client_published, _payload, _options}
  end

  test "publisher stub can send captured messages to a configured receiver" do
    receiver = self()

    task =
      Task.async(fn ->
        TestPublisher.put_receiver(receiver)
        NotifierClient.send_email(email(), publisher: TestPublisher)
      end)

    assert :ok = Task.await(task)
    assert_received {:notifier_client_published, payload, _options}
    assert JSON.decode!(payload)["type"] == "de.123fahrschule:notifier:deliver-email"
  end
end
