defmodule NotifierClient.JSONCodec do
  @moduledoc """
  Behaviour for JSON encoding serialized Notifier events.

  The client first builds a plain Elixir map for the Notifier event. The
  configured JSON codec then turns that map into the binary payload passed to
  the configured `NotifierClient.Publisher`.

  The default implementation is `NotifierClient.JSONCodec.BuiltIn`, which uses
  Elixir's built-in `JSON.encode!/1`. Configure a custom codec when a host
  application intentionally wants to use Jason or another encoder:

      config :notifier_client_ex,
        json_codec: MyApp.NotifierJSONCodec
  """

  @typedoc "A serialized JSON payload ready for publishing."
  @type payload :: binary()

  @doc """
  Encodes a serialized Notifier event map as JSON.

  Implementations should raise on encoding errors, matching the semantics of
  `JSON.encode!/1` and `Jason.encode!/1`.
  """
  @callback encode!(term()) :: payload()
end
