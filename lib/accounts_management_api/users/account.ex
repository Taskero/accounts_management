defmodule AccountsManagementAPI.Users.Account do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Encryption.Hashing
  alias Ecto.Changeset

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

  @optional ~w(picture start_date confirmed_at)a
  @required ~w(email password_hash email_verified name last_name locale status system_identifier)a

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> hash_password()
    |> unique_constraint([:email, :system_identifier], name: :accounts_email_system_identifier_key)
  end

  defp hash_password(%Changeset{valid?: true, changes: %{password: password}} = changeset),
    do: changeset |> put_change(:password_hash, Hashing.hash(password))

  defp hash_password(changeset), do: changeset
end
