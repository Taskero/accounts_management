defmodule AccountsManagementAPI.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias AccountsManagementAPI.Repo

  alias AccountsManagementAPI.Users.Account

  @doc """
  `system_identifier` Is required to any query

      ## Examples

      iex>  [system_identifier: :my_app] |> AccountsManagementAPI.Users.list_accounts()
      [%AccountsManagementAPI.Users.Account{}]

  """
  def list_accounts(system_identifier: nil), do: []
  def list_accounts([{:system_identifier, nil} | _]), do: []

  def list_accounts(system_identifier: system) do
    Account
    |> filter_query(system_identifier: system)
    |> Repo.all()
  end

  def list_accounts([{:system_identifier, system} | filters]) do
    query =
      Account
      |> filter_query(system_identifier: system)

    filters
    |> Enum.reduce(query, fn filter, query ->
      query |> filter_query([filter])
    end)
    |> Repo.all()
  end

  defp filter_query(query, system_identifier: system) do
    query |> where([a], a.system_identifier == ^system)
  end

  defp filter_query(query, id: id) do
    query |> where([a], a.id == ^id)
  end

  @doc """
  Gets a single account.

  ## Examples

      iex> get_account("ebfbb184-06f6-4819-812a-3e242bdb42d3", "my_app")
      {:ok, %Account{}}

      iex> get_account("9b65193c-2293-4809-9d34-06a12ba3ddcf", "my_app")
      {:error, :not_found}

  """
  def get_account(id, system) do
    case [system_identifier: system, id: id]
         |> list_accounts()
         |> List.first() do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    attrs = Map.put(attrs, "status", "pending")

    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

  iex> update_account(account, %{field: new_value})
  {:ok, %Account{}}

  iex> update_account(account, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end
end
