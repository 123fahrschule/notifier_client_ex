defmodule NotifierClient.Email.Event do
  @moduledoc false

  alias NotifierClient.Config
  alias NotifierClient.Email
  alias NotifierClient.Email.Validator
  alias NotifierClient.Metadata

  @event_type "de.123fahrschule:notifier:deliver-email"
  @event_subject "de.123fahrschule:notifier:email-delivery-request"

  def type, do: @event_type
  def subject, do: @event_subject

  def to_event(%Email{} = email, opts \\ []) do
    with :ok <- Validator.validate(email) do
      config = Config.get(opts)
      metadata = Map.merge(email.metadata, opts |> Keyword.get(:metadata, []) |> Enum.into(%{}))

      event =
        metadata
        |> Metadata.build(config, %{event_type: @event_type})
        |> Map.merge(%{
          "type" => @event_type,
          "subject" => @event_subject,
          "data" => data(email)
        })

      {:ok, event}
    end
  end

  def to_json(%Email{} = email, opts \\ []) do
    with {:ok, event} <- to_event(email, opts) do
      config = Config.get(opts)
      {:ok, config.json_codec.encode!(event), event}
    end
  end

  defp data(%Email{} = email) do
    %{
      "mail_options" => mail_options(email),
      "email_delivery_request_identifier" => email.idempotency_key,
      "email_identifier" => email.template_slug,
      "placeholders" => email.placeholders,
      "priority" => email.priority
    }
    |> maybe_put("deliver_at", format_datetime(email.deliver_at))
  end

  defp mail_options(%Email{} = email) do
    %{
      "to" => email.to,
      "from" => email.from,
      "subject" => email.subject,
      "reply_to" => email.reply_to,
      "cc" => email.cc,
      "bcc" => email.bcc
    }
    |> maybe_put("attachments", email.attachments, &(&1 != []))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put(map, key, value, predicate) do
    if predicate.(value), do: Map.put(map, key, value), else: map
  end

  defp format_datetime(nil), do: nil
  defp format_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
