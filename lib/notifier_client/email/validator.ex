defmodule NotifierClient.Email.Validator do
  @moduledoc false

  alias NotifierClient.Email
  alias NotifierClient.ValidationError

  @priorities ~w(highest high default low lowest)
  @email_regex ~r/^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/

  def validate(%Email{} = email) do
    %{}
    |> require_string(:idempotency_key, email.idempotency_key)
    |> require_string(:template_slug, email.template_slug)
    |> require_recipients(email.to)
    |> validate_addresses(:to, email.to)
    |> validate_addresses(:cc, email.cc)
    |> validate_addresses(:bcc, email.bcc)
    |> validate_optional_address(:from, email.from)
    |> validate_optional_address(:reply_to, email.reply_to)
    |> validate_priority(email.priority)
    |> validate_placeholders(email.placeholders)
    |> validate_deliver_at(email.deliver_at)
    |> validate_attachments(email.attachments)
    |> to_result()
  end

  defp require_string(errors, field, value) when is_binary(value) do
    if String.trim(value) == "", do: add_error(errors, field, "must be present"), else: errors
  end

  defp require_string(errors, field, _value), do: add_error(errors, field, "must be present")

  defp require_recipients(errors, [_ | _]), do: errors

  defp require_recipients(errors, _),
    do: add_error(errors, :to, "must contain at least one recipient")

  defp validate_addresses(errors, field, values) when is_list(values) do
    if Enum.all?(values, &valid_address?/1) do
      errors
    else
      add_error(errors, field, "contains an invalid email address")
    end
  end

  defp validate_addresses(errors, field, _values), do: add_error(errors, field, "must be a list")

  defp validate_optional_address(errors, _field, nil), do: errors

  defp validate_optional_address(errors, field, value) do
    if valid_address?(value),
      do: errors,
      else: add_error(errors, field, "is not a valid email address")
  end

  defp validate_priority(errors, priority) when priority in @priorities, do: errors
  defp validate_priority(errors, _priority), do: add_error(errors, :priority, "is not supported")

  defp validate_placeholders(errors, placeholders) when is_map(placeholders) do
    if Enum.all?(Map.keys(placeholders), &is_binary/1) do
      errors
    else
      add_error(errors, :placeholders, "must have string keys")
    end
  end

  defp validate_placeholders(errors, _placeholders),
    do: add_error(errors, :placeholders, "must be a map")

  defp validate_deliver_at(errors, nil), do: errors
  defp validate_deliver_at(errors, %DateTime{}), do: errors

  defp validate_deliver_at(errors, _deliver_at),
    do: add_error(errors, :deliver_at, "must be a DateTime")

  defp validate_attachments(errors, attachments) when is_list(attachments) do
    if Enum.all?(attachments, &valid_attachment?/1) do
      errors
    else
      add_error(errors, :attachments, "contains an invalid attachment")
    end
  end

  defp validate_attachments(errors, _attachments),
    do: add_error(errors, :attachments, "must be a list")

  defp valid_attachment?(%{
         "source" => "amazon-s3",
         "url" => url,
         "content_type" => content_type,
         "name" => name
       }) do
    non_empty_string?(url) and non_empty_string?(content_type) and non_empty_string?(name)
  end

  defp valid_attachment?(_attachment), do: false

  defp valid_address?(address) when is_binary(address) do
    address
    |> extract_email()
    |> then(&Regex.match?(@email_regex, &1))
  end

  defp valid_address?(_address), do: false

  defp extract_email(address) do
    case Regex.run(~r/^.+<(.+)>$/, address) do
      [_, email] -> String.trim(email)
      _ -> String.trim(address)
    end
  end

  defp non_empty_string?(value) when is_binary(value), do: String.trim(value) != ""
  defp non_empty_string?(_value), do: false

  defp add_error(errors, field, message) do
    Map.update(errors, field, [message], &[message | &1])
  end

  defp to_result(errors) when map_size(errors) == 0, do: :ok

  defp to_result(errors) do
    {:error, %ValidationError{errors: normalize_errors(errors)}}
  end

  defp normalize_errors(errors) do
    Map.new(errors, fn {field, messages} -> {field, Enum.reverse(messages)} end)
  end
end
