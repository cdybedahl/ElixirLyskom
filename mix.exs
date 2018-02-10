defmodule Lyskom.MixProject do
  use Mix.Project

  def project do
    [
      app: :lyskom,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Lyskom.Application, []}
    ]
  end

  defp deps do
    [
      {:codepagex, "~> 0.1.4"},
      {:timex, "~> 3.0"}
    ]
  end
end
