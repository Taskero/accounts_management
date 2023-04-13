defmodule AccountsManagementAPI.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias AccountsManagementAPI.Repo
  alias AccountsManagementAPI.Accounts.{User, UserToken, UserNotifier, Address, Phone}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  # USE `create_user` @doc """
  # Registers a user.

  # ## Examples

  #     iex> register_user(%{field: value})
  #     {:ok, %User{}}

  #     iex> register_user(%{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def register_user(attrs) do
  #   %User{}
  #   |> User.registration_changeset(attrs)
  #   |> Repo.insert()
  # end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The updated emails is stored at the `sent_to` field of the token.

  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, %{user | password: nil}}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user user is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("valid-token")
      %User{}

      iex> get_user_by_reset_password_token("invalid-token")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, %{user | password: nil}}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ########### Addresses ###########

  @doc """
  Gets a single address, including the parent user.

  ## Examples

      iex> get_address("51391cdc-a7e8-467e-8ef5-ae62aef52fc0")
      {:ok, %Address{}}

      iex> get_address("910afada-d4b1-4b03-994d-4d80af4f4c64")
      {:error, :not_found}

  """
  def get_address(id) do
    case Address |> Repo.get(id) |> Repo.preload(:user) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  @doc """
  Creates a address.

  ## Examples

      iex> create_address(%{field: value})
      {:ok, %User{}}

      iex> create_address(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_address(%{"user_id" => user_id} = attrs) do
    attrs =
      if from(a in Address, where: a.user_id == ^user_id) |> Repo.exists?(),
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
       |> Ecto.Changeset.add_error(:user_id, "is required")}

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
  def delete_address(%Address{user_id: user_id} = address) do
    ids =
      from(a in Address,
        where: a.user_id == ^user_id,
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
         {:ok, _} <- Address.set_default(%Address{id: id, user_id: address.user_id}) do
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
  Gets a single phone, including the parent user.

  ## Examples

      iex> get_phone("51391cdc-a7e8-467e-8ef5-ae62aef52fc0")
      {:ok, %Phone{}}

      iex> get_phone("910afada-d4b1-4b03-994d-4d80af4f4c64")
      {:error, :not_found}

  """
  def get_phone(id) do
    case Phone |> Repo.get(id) |> Repo.preload(:user) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  @doc """
  Creates a phone.

  ## Examples

      iex> create_phone(%{field: value})
      {:ok, %User{}}

      iex> create_phone(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_phone(%{"user_id" => user_id} = attrs) do
    attrs = Map.put(attrs, "verified", false)

    attrs =
      if from(a in Phone, where: a.user_id == ^user_id) |> Repo.exists?(),
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
       |> Ecto.Changeset.add_error(:user_id, "is required")}

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
  def delete_phone(%Phone{user_id: user_id} = phone) do
    ids =
      from(a in Phone,
        where: a.user_id == ^user_id,
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
         {:ok, _} <- Phone.set_default(%Phone{id: id, user_id: phone.user_id}) do
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

  ########### Users ###########

  @doc """

      ## Examples

      iex>  UsersManagementAPI.Accounts.list_users()
      [%UsersManagementAPI.Users.User{}]

  """
  def list_users() do
    from(a in User,
      left_join: adr in assoc(a, :addresses),
      left_join: p in assoc(a, :phones),
      preload: [:addresses, :phones]
    )
    |> Repo.all()
  end

  def list_users(opts) do
    query =
      from(a in User,
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
  Gets a single user.

  ## Examples

      iex> get_user("ebfbb184-06f6-4819-812a-3e242bdb42d3")
      {:ok, %User{}}

      iex> get_user("9b65193c-2293-4809-9d34-06a12ba3ddcf")
      {:error, :not_found}

  """
  def get_user(id) do
    case User |> Repo.get(id) |> Repo.preload([:addresses, :phones]) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    attrs = Map.drop(attrs, ["confirmed_at"])
    attrs = Map.put(attrs, "status", "pending")
    # TODO: set in config
    attrs = Map.merge(%{"locale" => "es"}, attrs)

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

  iex> update_user(user, %{field: new_value})
  {:ok, %User{}}

  iex> update_user(user, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end
end
