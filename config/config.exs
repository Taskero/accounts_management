# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :accounts_management_api,
  namespace: AccountsManagementAPI,
  ecto_repos: [AccountsManagementAPI.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :accounts_management_api, AccountsManagementAPIWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: AccountsManagementAPIWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AccountsManagementAPI.PubSub,
  live_view: [signing_salt: "yOfz+5QC"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :accounts_management_api, AccountsManagementAPIWeb.Auth.Guardian,
  issuer: "accounts_management_api",
  ttl: {8, :hours},
  verify_issuer: true,
  secret_key: System.get_env("SECRET_KEY_BASE"),
  serializer: AccountsManagementAPIWeb.Auth.GuardianSerializer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
