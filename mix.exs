defmodule AccountsManagementAPI.MixProject do
  use Mix.Project

  def project do
    [
      app: :accounts_management_api,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      releases: [
        accounts_management_api: [
          include_erts: true,
          include_executables_for: [:unix],
          applications: [
            runtime_tools: :permanent
          ],
          env: %{
            MIX_ENV: "prod",
            PORT: "4000"
          }
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AccountsManagementAPI.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},

      ######## Common libraries ########

      # An HTTP client focused on performance.
      {:finch, "~> 0.13"},
      # A library for parsing and rendering Liquid templates.
      {:solid, "~> 0.14"},
      # Authentication
      {:guardian, "~> 2.2"},
      {:guardian_phoenix, "~> 2.0"},
      {:comeonin, "~> 5.3.3"},
      {:argon2_elixir, "~> 3.0"},

      # Mix tasks to simplify use of Dialyzer in Elixir projects.
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      # Security-focused static analysis for the Phoenix framework
      {:sobelow, "~> 0.8", only: :dev},
      # ExDoc is a documentation generation tool for Elixir
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},

      # A static code analysis tool with a focus on code consistency and teaching.
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      # Code coverage
      {:excoveralls, "~> 0.14.6", only: [:dev, :test]},
      # Automatically run tests when files change
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      # MixAudit provides a `mix deps.audit` task to scan a project Mix dependencies for known Elixir security vulnerabilities
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},

      # Factory Bot like
      {:ex_machina, "~> 2.7.0", only: :test},
      # Mocking library
      {:mock, "~> 0.3.0", only: :test},
      # fake http requests
      {:bypass, "~> 2.1", only: :test},
      # Faker is a pure Elixir library for generating fake data.
      {:faker, "~> 0.17", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
