defmodule AccountsManagementAPI.Repo do
  use Ecto.Repo,
    otp_app: :accounts_management_api,
    adapter: Ecto.Adapters.Postgres
end
