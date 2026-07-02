defmodule NotifierClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :notifier_client_ex,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :logger]
    ]
  end

  defp deps do
    [
      {:tackle, github: "123fahrschule/ex-tackle", branch: "main"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]
end
