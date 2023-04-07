defmodule AccountsManagementAPI.Repo.Migrations.CreatePhones do
  use Ecto.Migration

  def change do
    create table(:phones, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:type, :string, null: false)
      add(:name, :string, null: false)
      add(:number, :string, null: false)
      add(:default, :boolean, default: false, null: false)
      add(:verified, :boolean, default: false, null: false)

      add(:account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(
      index(:phones, [:name, :account_id], unique: true, name: :phones_name_account_id_index)
    )
  end
end
