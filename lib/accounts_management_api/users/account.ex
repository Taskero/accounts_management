defmodule AccountsManagementAPI.Users.Account do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Encryption.Hashing

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

  @optional ~w(picture password confirmed_at start_date)a
  @required ~w(email password_hash email_verified name last_name locale status system_identifier)a

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, @required ++ @optional)
    |> validate_inclusion(:status, ~w(pending active inactive))
    |> validate_inclusion(:locale, ~w(en es pt))
    |> hash_password()
    |> validate_required(@required)
    |> validate_email_format()
    |> unique_constraint([:email, :system_identifier],
      name: :accounts_email_system_identifier_index
    )
  end

  defp hash_password(%{valid?: true, changes: %{password: password}} = changeset) do
    changeset
    |> validate_length(:password, min: 12, max: 80)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
    |> put_change(:password_hash, Hashing.hash(password))
  end

  defp hash_password(changeset), do: changeset

  defp validate_email_format(%{changes: %{email: email}} = changeset) do
    email_regex = ~r/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

    if Regex.match?(email_regex, email),
      do: changeset,
      else: add_error(changeset, :email, "is not valid")
  end

  defp validate_email_format(changeset), do: changeset
end
