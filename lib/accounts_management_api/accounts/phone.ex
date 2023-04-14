defmodule AccountsManagementAPI.Accounts.Phone do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias AccountsManagementAPI.Repo
  alias AccountsManagementAPI.Accounts.Phone

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "phones" do
    field(:type, :string)
    field(:name, :string)
    field(:number, :string)
    field(:default, :boolean, default: false)
    field(:verified, :boolean, default: false)

    belongs_to(:user, AccountsManagementAPI.Accounts.User)

    timestamps()
  end

  @optional ~w(default verified)a
  @required ~w(user_id type name number)a

  @doc false
  def changeset(phone, attrs) do
    phone
    |> cast(attrs, @required ++ @optional)
    |> validate_inclusion(:type, ~w(personal business))
    |> validate_length(:number, min: 8, max: 20)
    |> validate_required(@required)
    |> unique_constraint([:name, :user_id], name: :phones_name_user_id_index)
  end

  @doc """
  Sets an unique default phone for an user.

  ## Examples

      iex> "e6bc1093-2d73-4d0e-b1fe-b7b538fe60f1" |> Accounts.get_phone |> set_default()
      {:ok, %Phone{}}

      iex> set_default(phone)
      {:error, reason}
  """
  def set_default(%Phone{user_id: user_id, id: id}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(
      :unset_default,
      Phone |> where(user_id: ^user_id),
      [set: [default: false]],
      []
    )
    |> Ecto.Multi.update_all(
      :set_default,
      Phone |> where(id: ^id),
      [set: [default: true]],
      []
    )
    |> Repo.transaction()
  end
end
