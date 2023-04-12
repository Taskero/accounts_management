defmodule AccountsManagementAPI.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query

  alias AccountsManagementAPI.Repo
  alias AccountsManagementAPI.Users.{Account, Address, Phone}

  ########### Accounts ###########

  @doc """

      ## Examples

      iex>  AccountsManagementAPI.Users.list_accounts()
      [%AccountsManagementAPI.Users.Account{}]

  """
  def list_accounts() do
    from(a in Account,
      left_join: adr in assoc(a, :addresses),
      left_join: p in assoc(a, :phones),
      preload: [:addresses, :phones]
    )
    |> Repo.all()
  end

  def list_accounts(opts) do
    query =
      from(a in Account,
        left_join: adr in assoc(a, :addresses),
        left_join: p in assoc(a, :phones),
        preload: [:addresses, :phones]
      )

    opts
    |> Enum.reduce(query, fn filter, query ->
      query |> filter_query([filter])
    end)
    |> Repo.all()
  end

  defp filter_query(query, id: id) do
    query |> where([a], a.id == ^id)
  end

  defp filter_query(query, email: email) do
    query |> where([a], a.email == ^email)
  end

  defp filter_query(query, _), do: query

  @doc """
  Gets a single account.

  ## Examples

      iex> get_account("ebfbb184-06f6-4819-812a-3e242bdb42d3")
      {:ok, %Account{}}

      iex> get_account("9b65193c-2293-4809-9d34-06a12ba3ddcf")
      {:error, :not_found}

  """
  def get_account(id) do
    case Account |> Repo.get(id) |> Repo.preload([:addresses, :phones]) do
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

  ########### Addresses ###########

  @doc """
  Gets a single address, including the parent account.

  ## Examples

      iex> get_address("51391cdc-a7e8-467e-8ef5-ae62aef52fc0")
      {:ok, %Address{}}

      iex> get_address("910afada-d4b1-4b03-994d-4d80af4f4c64")
      {:error, :not_found}

  """
  def get_address(id) do
    case Address |> Repo.get(id) |> Repo.preload(:account) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  @doc """
  Creates a address.

  ## Examples

      iex> create_address(%{field: value})
      {:ok, %Account{}}

      iex> create_address(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_address(%{"account_id" => account_id} = attrs) do
    attrs =
      if from(a in Address, where: a.account_id == ^account_id) |> Repo.exists?(),
        do: attrs,
        else: Map.put(attrs, "default", true)

    %Address{}
    |> Address.changeset(attrs)
    |> Repo.insert()
  end

  def create_address(_),
    do:
      {:error,
       %Address{}
       |> Ecto.Changeset.change(%{})
       |> Ecto.Changeset.add_error(:account_id, "is required")}

  @doc """
  Updates a address.

  ## Examples

  iex> update_address(address, %{field: new_value})
  {:ok, %Address{}}

  iex> update_address(address, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_address(%Address{default: true} = address, attrs) do
    with {:ok, _} <- Address.set_default(address) do
      address
      |> Address.changeset(attrs)
      |> Repo.update()
    end
  end

  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a address.

  ## Examples

      iex> delete_address(address)
      {:ok, %Address{}}

      iex> delete_address(address)
      {:error, %Ecto.Changeset{}}

  """
  def delete_address(%Address{account_id: account_id} = address) do
    ids =
      from(a in Address,
        where: a.account_id == ^account_id,
        select: a.id
      )
      |> Repo.all()

    do_address_delete(address, ids)
  end

  defp do_address_delete(_, ids) when ids |> length <= 1,
    do:
      {:error,
       %Address{}
       |> Ecto.Changeset.change(%{})
       |> Ecto.Changeset.add_error(:default, "At least one default address is required")}

  defp do_address_delete(address, ids) do
    with id <- ids |> Enum.find(fn id -> id != address.id end),
         {:ok, _} <- Address.set_default(%Address{id: id, account_id: address.account_id}) do
      Repo.delete(address)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking address changes.

  ## Examples

      iex> change_address(address)
      %Ecto.Changeset{data: %Address{}}

  """
  def change_address(%Address{} = address, attrs \\ %{}) do
    Address.changeset(address, attrs)
  end

  ########### Phones ###########

  @doc """
  Gets a single phone, including the parent account.

  ## Examples

      iex> get_phone("51391cdc-a7e8-467e-8ef5-ae62aef52fc0")
      {:ok, %Phone{}}

      iex> get_phone("910afada-d4b1-4b03-994d-4d80af4f4c64")
      {:error, :not_found}

  """
  def get_phone(id) do
    case Phone |> Repo.get(id) |> Repo.preload(:account) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  @doc """
  Creates a phone.

  ## Examples

      iex> create_phone(%{field: value})
      {:ok, %Account{}}

      iex> create_phone(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_phone(%{"account_id" => account_id} = attrs) do
    attrs = Map.put(attrs, "verified", false)

    attrs =
      if from(a in Phone, where: a.account_id == ^account_id) |> Repo.exists?(),
        do: attrs,
        else: Map.put(attrs, "default", true)

    %Phone{}
    |> Phone.changeset(attrs)
    |> Repo.insert()
  end

  def create_phone(_),
    do:
      {:error,
       %Phone{}
       |> Ecto.Changeset.change(%{})
       |> Ecto.Changeset.add_error(:account_id, "is required")}

  @doc """
  Updates a phone.

  ## Examples

  iex> update_phone(phone, %{field: new_value})
  {:ok, %Phone{}}

  iex> update_phone(phone, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_phone(%Phone{default: true} = phone, attrs) do
    attrs = Map.put(attrs, "verified", false)

    with {:ok, _} <- Phone.set_default(phone) do
      phone
      |> Phone.changeset(attrs)
      |> Repo.update()
    end
  end

  def update_phone(%Phone{} = phone, attrs) do
    phone
    |> Phone.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a phone.

  ## Examples

      iex> delete_phone(phone)
      {:ok, %Phone{}}

      iex> delete_phone(phone)
      {:error, %Ecto.Changeset{}}

  """
  def delete_phone(%Phone{account_id: account_id} = phone) do
    ids =
      from(a in Phone,
        where: a.account_id == ^account_id,
        select: a.id
      )
      |> Repo.all()

    do_phone_delete(phone, ids)
  end

  defp do_phone_delete(_, ids) when ids |> length <= 1,
    do:
      {:error,
       %Phone{}
       |> Ecto.Changeset.change(%{})
       |> Ecto.Changeset.add_error(:default, "At least one default phone is required")}

  defp do_phone_delete(phone, ids) do
    with id <- ids |> Enum.find(fn id -> id != phone.id end),
         {:ok, _} <- Phone.set_default(%Phone{id: id, account_id: phone.account_id}) do
      Repo.delete(phone)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking phone changes.

  ## Examples

      iex> change_phone(phone)
      %Ecto.Changeset{data: %Phone{}}

  """
  def change_phone(%Phone{} = phone, attrs \\ %{}) do
    Phone.changeset(phone, attrs)
  end
end
