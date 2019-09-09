defmodule Deribit.MixProject do
  use Mix.Project

  def project do
    [
      app: :deribit,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Deribit.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websockex, "~> 0.4"},
      {:jason, "~> 1.1"},
      {:gen_stage, "~> 0.14"},
      {:flow, "~> 0.14"},
      {:decimal, "~> 1.8"},
      {:timex, "~> 3.6"},
      {:instream, "~> 0.21"}
    ]
  end
end
