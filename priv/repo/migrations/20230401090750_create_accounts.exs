defmodule AccountsManagementAPI.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :email_verified, :boolean, default: false, null: false
      add :name, :string, null: false
      add :last_name, :string, null: false
      add :picture, :string
      add :locale, :string, null: false
      add :status, :string, null: false
      add :start_date, :naive_datetime
      add :confirmed_at, :naive_datetime
      add :system_identifier, :string, null: false

      timestamps()
    end

    create unique_index(:accounts, [:email, :system_identifier])
  end
end
