defmodule AccountsManagementAPI.Users.Account do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :confirmed_at, :naive_datetime
    field :email, :string
    field :email_verified, :boolean, default: false
    field :last_name, :string
    field :locale, :string
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :picture, :string
    field :start_date, :naive_datetime
    field :status, :string
    field :system_identifier, :string

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :email,
      :password_hash,
      :email_verified,
      :name,
      :last_name,
      :picture,
      :locale,
      :status,
      :start_date,
      :confirmed_at,
      :system_identifier
    ])
    |> validate_required([
      :email,
      :password_hash,
      :email_verified,
      :name,
      :last_name,
      :picture,
      :locale,
      :status,
      :start_date,
      :confirmed_at,
      :system_identifier
    ])
  end
end
