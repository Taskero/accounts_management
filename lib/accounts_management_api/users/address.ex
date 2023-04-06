defmodule AccountsManagementAPI.Users.Address do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias AccountsManagementAPI.Repo
  alias AccountsManagementAPI.Users.Address

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "addresses" do
    field(:type, :string)
    field(:name, :string)
    field(:line_1, :string)
    field(:line_2, :string)
    field(:city, :string)
    field(:state, :string)
    field(:country_code, :string)
    field(:zip_code, :string)
    field(:default, :boolean, default: false)

    belongs_to(:account, AccountsManagementAPI.Users.Account)

    timestamps()
  end

  @optional ~w(line_2 default)a
  @required ~w( account_id type name line_1 city state country_code zip_code)a

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, @required ++ @optional)
    |> validate_inclusion(:type, ~w(personal business))
    |> validate_inclusion(:country_code, ~w(US BR AR))
    |> validate_required(@required)
    |> unique_constraint([:name, :account_id], name: :addresses_name_account_id_index)
  end

  @doc """
  Sets an unique default address for an account.

  ## Examples

      iex> "e6bc1093-2d73-4d0e-b1fe-b7b538fe60f1" |> Users.get_address |> set_default()
      {:ok, %Address{}}

      iex> set_default(address)
      {:error, reason}
  """
  def set_default(%Address{account_id: account_id, id: id}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(
      :unset_default,
      Address |> where(account_id: ^account_id),
      [set: [default: false]],
      []
    )
    |> Ecto.Multi.update_all(
      :set_default,
      Address |> where(id: ^id),
      [set: [default: true]],
      []
    )
    |> Repo.transaction()
  end
end
