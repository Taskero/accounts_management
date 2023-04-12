defmodule AccountsManagementAPI.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      add :name, :string
      add :last_name, :string
      add :picture, :string
      add :locale, :string
      add :status, :string
      add :start_date, :naive_datetime

      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:users_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:addresses, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:type, :string, null: false)
      add(:name, :string, null: false)
      add(:line_1, :string, null: false)
      add(:line_2, :string)
      add(:city, :string, null: false)
      add(:state, :string, null: false)
      add(:country_code, :string, null: false)
      add(:zip_code, :string, null: false)
      add(:default, :boolean, default: false, null: false)

      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(
      index(:addresses, [:name, :user_id], unique: true, name: :addresses_name_user_id_index)
    )

    create table(:phones, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:type, :string, null: false)
      add(:name, :string, null: false)
      add(:number, :string, null: false)
      add(:default, :boolean, default: false, null: false)
      add(:verified, :boolean, default: false, null: false)

      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:phones, [:name, :user_id], unique: true, name: :phones_name_user_id_index))
  end
end
