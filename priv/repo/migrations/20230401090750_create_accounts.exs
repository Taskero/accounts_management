defmodule AccountsManagementAPI.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :password_hash, :string
      add :email_verified, :boolean, default: false, null: false
      add :name, :string
      add :last_name, :string
      add :picture, :string
      add :locale, :string
      add :status, :string
      add :start_date, :naive_datetime
      add :confirmed_at, :naive_datetime
      add :system_identifier, :string

      timestamps()
    end
  end
end
