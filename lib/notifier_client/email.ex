defmodule NotifierClient.Email do
  @moduledoc """
  Immutable command object for requesting E-Mail delivery through Notifier.
  """

  defstruct idempotency_key: nil,
            template_slug: nil,
            to: [],
            cc: [],
            bcc: [],
            from: nil,
            reply_to: nil,
            subject: nil,
            placeholders: %{},
            deliver_at: nil,
            priority: "default",
            attachments: [],
            metadata: %{}

  @type t :: %__MODULE__{}

  def new, do: %__MODULE__{}

  def idempotency_key(%__MODULE__{} = email, idempotency_key) do
    %{email | idempotency_key: idempotency_key}
  end

  def delivery_request_id(%__MODULE__{} = email, delivery_request_id) do
    idempotency_key(email, delivery_request_id)
  end

  def template(%__MODULE__{} = email, template_slug) do
    %{email | template_slug: template_slug}
  end

  def to(%__MODULE__{} = email, recipients) do
    %{email | to: email.to ++ normalize_addresses(recipients)}
  end

  def cc(%__MODULE__{} = email, recipients) do
    %{email | cc: email.cc ++ normalize_addresses(recipients)}
  end

  def bcc(%__MODULE__{} = email, recipients) do
    %{email | bcc: email.bcc ++ normalize_addresses(recipients)}
  end

  def from(%__MODULE__{} = email, sender) do
    %{email | from: normalize_address(sender)}
  end

  def reply_to(%__MODULE__{} = email, address) do
    %{email | reply_to: normalize_address(address)}
  end

  def subject(%__MODULE__{} = email, subject) do
    %{email | subject: subject}
  end

  def put_placeholder(%__MODULE__{} = email, key, value) do
    %{email | placeholders: Map.put(email.placeholders, key, value)}
  end

  def put_placeholders(%__MODULE__{} = email, placeholders) when is_map(placeholders) do
    %{email | placeholders: Map.merge(email.placeholders, placeholders)}
  end

  def deliver_at(%__MODULE__{} = email, deliver_at) do
    %{email | deliver_at: deliver_at}
  end

  def priority(%__MODULE__{} = email, priority) when is_atom(priority) do
    %{email | priority: Atom.to_string(priority)}
  end

  def priority(%__MODULE__{} = email, priority) do
    %{email | priority: priority}
  end

  def attach_s3(%__MODULE__{} = email, url, content_type, name) do
    attachment = %{
      "source" => "amazon-s3",
      "url" => url,
      "content_type" => content_type,
      "name" => name
    }

    %{email | attachments: email.attachments ++ [attachment]}
  end

  def metadata(%__MODULE__{} = email, metadata) when is_list(metadata) or is_map(metadata) do
    %{email | metadata: Map.merge(email.metadata, Enum.into(metadata, %{}))}
  end

  def put_metadata(%__MODULE__{} = email, key, value) do
    %{email | metadata: Map.put(email.metadata, key, value)}
  end

  defp normalize_addresses(nil), do: []

  defp normalize_addresses(addresses) when is_list(addresses),
    do: Enum.map(addresses, &normalize_address/1)

  defp normalize_addresses(address), do: [normalize_address(address)]

  defp normalize_address({name, address}) when is_binary(name) and is_binary(address) do
    "#{name} <#{address}>"
  end

  defp normalize_address(address), do: address
end
