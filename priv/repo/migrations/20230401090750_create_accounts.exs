defmodule AccountsManagementAPI.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    # The citext module provides a case-insensitive character string type.
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :password_hash, :string, null: false
      add :email_verified, :boolean, default: false, null: false
      add :name, :string, null: false
      add :last_name, :string, null: false
      add :picture, :string
      add :locale, :string, null: false
      add :status, :string, null: false
      add :start_date, :naive_datetime
      add :confirmed_at, :naive_datetime

      timestamps()
    end

    create unique_index(:accounts, [:email])
  end
end
