defmodule NotifierClient do
  @moduledoc """
  Client for sending commands to the 123Fahrschule Notifier service.
  """

  alias NotifierClient.Config
  alias NotifierClient.Email
  alias NotifierClient.Email.Event

  @doc """
  Delivers a Notifier command.

  Currently only `NotifierClient.Email` commands are supported.
  """
  def deliver(%Email{} = email, opts \\ []) do
    with {:ok, payload, _event} <- Event.to_json(email, opts) do
      config = Config.get(opts)
      publisher = config.publisher

      publisher.publish(payload, Config.publish_options(config, :email))
    end
  end

  @doc """
  Sends an E-Mail command through Notifier.
  """
  def send_email(%Email{} = email, opts \\ []) do
    deliver(email, opts)
  end
end
