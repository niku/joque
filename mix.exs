defmodule Joque.MixProject do
  use Mix.Project

  def project do
    [
      app: :joque,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      aliases: aliases(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:credo, "~> 0.10.0", only: :dev, runtime: false},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.2.10"},
      {:jason, "~> 1.1.1"}
    ]
  end

  defp description do
    "A transactional job queue built with Elixir and Postgresql"
  end

  defp package do
    [
      maintainers: ["niku"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/niku/joque"
      }
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp dialyzer do
    [plt_add_apps: [:mix]]
  end
end
