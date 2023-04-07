defmodule AccountsManagementAPI.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
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

      add(:account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(
      index(:addresses, [:name, :account_id], unique: true, name: :addresses_name_account_id_index)
    )
  end
end
