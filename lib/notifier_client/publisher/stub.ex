defmodule NotifierClient.Publisher.Stub do
  @moduledoc """
  Test publisher for capturing Notifier publish calls without RabbitMQ.

  Configure this module as the publisher in tests and assert on the captured
  message:

      config :notifier_client_ex,
        publisher: NotifierClient.Publisher.Stub

      assert :ok = NotifierClient.send_email(email)
      assert_receive {:notifier_client_published, payload, options}

  Published messages are sent to the current process by default. If the publish
  call happens in another process, call `put_receiver/1` in that process before
  the code under test publishes.
  """

  @behaviour NotifierClient.Publisher

  @message_tag :notifier_client_published
  @receiver_key :notifier_client_publisher_receiver
  @result_key :notifier_client_publisher_result

  @type result :: :ok | {:error, term()}
  @type published_message :: {:notifier_client_published, binary(), keyword()}

  @doc """
  Returns the message tag used by `publish/2`.
  """
  @spec message_tag() :: :notifier_client_published
  def message_tag, do: @message_tag

  @doc """
  Sends captured publish messages from the current process to `receiver`.

  This is process-local and therefore safe for async tests.
  """
  @spec put_receiver(pid()) :: :ok
  def put_receiver(receiver) when is_pid(receiver) do
    Process.put(@receiver_key, receiver)
    :ok
  end

  @doc """
  Clears a process-local receiver configured through `put_receiver/1`.
  """
  @spec clear_receiver() :: :ok
  def clear_receiver do
    Process.delete(@receiver_key)
    :ok
  end

  @doc """
  Configures the process-local result returned by `publish/2`.

  Use this to exercise publisher error handling:

      NotifierClient.Publisher.Stub.put_result({:error, :unroutable})
  """
  @spec put_result(result()) :: :ok
  def put_result(:ok), do: put_result_value(:ok)
  def put_result({:error, _reason} = result), do: put_result_value(result)

  @doc """
  Clears a process-local result configured through `put_result/1`.
  """
  @spec clear_result() :: :ok
  def clear_result do
    Process.delete(@result_key)
    :ok
  end

  @impl true
  @spec publish(binary(), keyword()) :: result()
  def publish(payload, options) when is_binary(payload) and is_list(options) do
    receiver = Process.get(@receiver_key, self())

    send(receiver, {@message_tag, payload, options})

    Process.get(@result_key, :ok)
  end

  defp put_result_value(result) do
    Process.put(@result_key, result)
    :ok
  end
end
