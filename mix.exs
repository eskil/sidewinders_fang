defmodule SidewindersFang.Mixfile do
  use Mix.Project

  def project do
    [app: :sidewinders_fang,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cowboy, :plug, :jiffy, :uuid, :mariaex],
     mod: {SidewindersFang, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:exrm, "~> 1.0.0-rc8"},
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:jiffy, "~> 0.14"},
      {:uuid, "~> 1.1" },
      {:mariaex, "~> 0.6.1"}
    ]
  end
end
