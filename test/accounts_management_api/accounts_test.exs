defmodule AccountsManagementAPI.AccountsTest do
  use AccountsManagementAPI.DataCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPI.Accounts
  alias AccountsManagementAPI.Accounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = insert(:user)
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = insert(:user)
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = insert(:user)

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, "CoolPassword123!")
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = insert(:user)
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = insert(:user)
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = Faker.Internet.email()
      {:ok, user} = Accounts.register_user(%{email: email, password: "CoolPassword123!"})
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = Faker.Internet.email()
      password = "CoolPassword123!"

      changeset =
        Accounts.change_user_registration(
          %User{},
          %{email: email, password: password}
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: insert(:user)}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "CoolPassword123!", %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, "CoolPassword123!", %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_user_email(user, "CoolPassword123!", %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = insert(:user)
      password = "CoolPassword123!"

      {:error, changeset} = Accounts.apply_user_email(user, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, "invalid", %{email: Faker.Internet.email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = Faker.Internet.email()
      {:ok, user} = Accounts.apply_user_email(user, "CoolPassword123!", %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: insert(:user)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = insert(:user)
      email = Faker.Internet.email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: insert(:user)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "CoolPassword123!", %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, "CoolPassword123!", %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: "CoolPassword123!"})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, "CoolPassword123!", %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, "CoolPassword123!", %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: insert(:user)}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: insert(:user).id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = insert(:user)
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = insert(:user)
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: insert(:user)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/1" do
    setup do
      user = insert(:user)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Accounts.confirm_user(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Accounts.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: insert(:user)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = insert(:user)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: insert(:user)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: "new valid password"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "users" do
    alias AccountsManagementAPI.Accounts.User

    import AccountsManagementAPI.Test.Factories

    @invalid_attrs %{
      "confirmed_at" => nil,
      "email" => nil,
      "last_name" => nil,
      "locale" => nil,
      "name" => nil,
      "picture" => nil,
      "start_date" => nil,
      "status" => nil
    }

    test "list_users/0 returns all users" do
      %{} = user = insert(:user)

      assert Accounts.list_users() == [
               %{user | password: nil, addresses: [], phones: []}
             ]
    end

    test "get_user!/1 returns the user with given id" do
      user = insert(:user)

      assert Accounts.get_user(user.id) ==
               {:ok, %{user | password: nil, addresses: [], phones: []}}
    end

    test "create_user/1 with valid data creates an user" do
      valid_attrs = %{
        "confirmed_at" => ~N[2023-03-31 09:07:00],
        "email" => "bar@foo.com",
        "last_name" => "some last_name",
        "locale" => "en",
        "name" => "some name",
        "password" => "some!Password_hash",
        "picture" => "some picture",
        "start_date" => ~N[2023-03-31 09:07:00]
      }

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.confirmed_at == ~N[2023-03-31 09:07:00]
      assert user.email == "bar@foo.com"
      assert user.last_name == "some last_name"
      assert user.locale == "en"
      assert user.name == "some name"
      assert user.password_hash != nil
      assert user.picture == "some picture"
      assert user.start_date == ~N[2023-03-31 09:07:00]
      assert user.status == "pending"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)

      update_attrs = %{
        "confirmed_at" => ~N[2023-04-01 09:07:00],
        "email" => "bar@foo.com",
        "last_name" => "some updated last_name",
        "locale" => "en",
        "name" => "some updated name",
        "password" => "someUpdatedPassword_hash!",
        "picture" => "some updated picture",
        "start_date" => ~N[2023-04-01 09:07:00],
        "status" => "pending"
      }

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.confirmed_at == ~N[2023-04-01 09:07:00]
      assert user.email == "bar@foo.com"
      assert user.last_name == "some updated last_name"
      assert user.locale == "en"
      assert user.name == "some updated name"
      assert user.picture == "some updated picture"
      assert user.start_date == ~N[2023-04-01 09:07:00]
      assert user.status == "pending"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)

      assert {:ok, %{user | password: nil, addresses: [], phones: []}} ==
               Accounts.get_user(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == {:error, :not_found}
    end

    test "change_user/1 returns an user changeset" do
      user = insert(:user)
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "addresses" do
    alias AccountsManagementAPI.Accounts.Address

    import AccountsManagementAPI.Test.Factories

    @invalid_attrs %{
      "type" => nil,
      "name" => nil,
      "line_1" => nil,
      "city" => nil,
      "state" => nil,
      "country_code" => nil,
      "zip_code" => nil,
      "default" => nil,
      "user" => nil
    }

    test "get_user/1 with preload: :addresses returns all addresses" do
      %{} = user = insert(:user)
      address = insert(:address, user: user)
      address2 = insert(:address, user: user)
      insert(:address)

      {:ok, user} = Accounts.get_user(user.id)

      assert user.addresses |> Enum.map(& &1.id) == [address.id | [address2.id]]
    end

    test "get_address/1 returns the address with given id" do
      user = insert(:user)
      address = insert(:address, user: user)

      user = %{user | password: nil}

      assert {
               :ok,
               %AccountsManagementAPI.Accounts.Address{
                 user: loaded_user,
                 user_id: user_id
               }
             } = Accounts.get_address(address.id)

      assert loaded_user == user
      assert user_id == user.id
    end

    test "create_address/1 with valid data creates an address" do
      user = insert(:user)

      valid_attrs = %{
        "type" => "personal",
        "name" => "some name",
        "line_1" => "123, Evergreen Terrace",
        "city" => "Springfield",
        "state" => "Oregon",
        "country_code" => "US",
        "zip_code" => "12345",
        "user_id" => user.id
      }

      assert {:ok, %Address{} = address} = Accounts.create_address(valid_attrs)

      assert address.type == "personal"
      assert address.name == "some name"
      assert address.line_1 == "123, Evergreen Terrace"
      assert address.line_2 == nil
      assert address.city == "Springfield"
      assert address.state == "Oregon"
      assert address.country_code == "US"
      assert address.zip_code == "12345"
      assert address.user_id == user.id
      assert address.default == true

      valid_attrs = %{
        "type" => "business",
        "name" => "work address",
        "line_1" => "123, Evergreen Terrace",
        "line_2" => "behind the tree",
        "city" => "Springfield",
        "state" => "Oregon",
        "country_code" => "US",
        "zip_code" => "12345",
        "user_id" => user.id
      }

      assert {:ok, %Address{} = address} = Accounts.create_address(valid_attrs)

      assert address.type == "business"
      assert address.name == "work address"
      assert address.line_1 == "123, Evergreen Terrace"
      assert address.line_2 == "behind the tree"
      assert address.city == "Springfield"
      assert address.state == "Oregon"
      assert address.country_code == "US"
      assert address.zip_code == "12345"
      assert address.user_id == user.id
      assert address.default == false
    end

    test "create_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_address(@invalid_attrs)
    end

    test "update_address/2 with valid data updates the address" do
      user = insert(:user)
      address = insert(:address, user: user)
      # address2 becomes default
      %{id: id} = insert(:address, user: user, default: true)

      update_attrs = %{
        "type" => "personal",
        "name" => "work address edited",
        "line_1" => "123, Evergreen Terrace edited",
        "line_2" => "behind the tree edited",
        "city" => "Springfield edited",
        "state" => "Oregon edited",
        "country_code" => "AR",
        "zip_code" => "54321",
        "default" => true
      }

      assert {:ok, %Address{} = address} = Accounts.update_address(address, update_attrs)
      assert address.type == "personal"
      assert address.name == "work address edited"
      assert address.line_1 == "123, Evergreen Terrace edited"
      assert address.line_2 == "behind the tree edited"
      assert address.city == "Springfield edited"
      assert address.state == "Oregon edited"
      assert address.country_code == "AR"
      assert address.zip_code == "54321"
      assert address.default == true

      # check that address2 is not default anymore
      assert {:ok, %Address{default: false}} = Accounts.get_address(id)
    end

    test "update_address/2 with invalid data returns error changeset" do
      address = insert(:address, user: insert(:user))

      assert {:error, %Ecto.Changeset{}} = Accounts.update_address(address, @invalid_attrs)

      {:ok, restored_address} = Accounts.get_address(address.id)
      assert %{address | user: nil} == %{restored_address | user: nil}
    end

    test "delete_address/1 deletes the address" do
      user = insert(:user)
      addresses = insert_list(3, :address, user: user)
      address = addresses |> Enum.at(1)

      assert {:ok, %Address{}} = Accounts.delete_address(address)
      assert Accounts.get_address(address.id) == {:error, :not_found}
    end

    test "change_address/1 returns an address changeset" do
      address = insert(:address)
      assert %Ecto.Changeset{} = Accounts.change_address(address)
    end
  end

  describe "phones" do
    alias AccountsManagementAPI.Accounts.Phone

    import AccountsManagementAPI.Test.Factories

    @invalid_attrs %{
      "type" => nil,
      "name" => nil,
      "number" => nil,
      "default" => nil,
      "verified" => nil,
      "user" => nil
    }

    test "get_user/1 with preload: :phones returns all phones" do
      %{} = user = insert(:user)
      phone = insert(:phone, user: user)
      phone2 = insert(:phone, user: user)
      insert(:phone)

      {:ok, user} = Accounts.get_user(user.id)

      assert user.phones |> Enum.map(& &1.id) == [phone.id | [phone2.id]]
    end

    test "get_phone/1 returns the phone with given id" do
      user = insert(:user)
      phone = insert(:phone, user: user)

      user = %{user | password: nil}

      assert {
               :ok,
               %AccountsManagementAPI.Accounts.Phone{
                 user: loaded_user,
                 user_id: user_id
               }
             } = Accounts.get_phone(phone.id)

      assert loaded_user == user
      assert user_id == user.id
    end

    test "create_phone/1 with valid data creates an phone" do
      user = insert(:user)

      valid_attrs = %{
        "type" => "personal",
        "name" => "some name",
        "number" => "+1234567890",
        "user_id" => user.id
      }

      assert {:ok, %Phone{} = phone} = Accounts.create_phone(valid_attrs)

      assert phone.type == "personal"
      assert phone.name == "some name"
      assert phone.number == "+1234567890"
      assert phone.user_id == user.id
      assert phone.default == true
      assert phone.verified == false

      valid_attrs = %{
        "type" => "business",
        "name" => "work phone",
        "number" => "+9876543210",
        "user_id" => user.id
      }

      assert {:ok, %Phone{} = phone} = Accounts.create_phone(valid_attrs)

      assert phone.type == "business"
      assert phone.name == "work phone"
      assert phone.number == "+9876543210"
      assert phone.user_id == user.id
      assert phone.default == false
      assert phone.verified == false
    end

    test "create_phone/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_phone(@invalid_attrs)
    end

    test "update_phone/2 with valid data updates the phone" do
      user = insert(:user)
      phone = insert(:phone, user: user)
      # phone2 becomes default
      %{id: id} = insert(:phone, user: user, default: true)

      update_attrs = %{
        "type" => "personal",
        "name" => "work phone edited",
        "number" => "9999999999",
        "default" => true
      }

      assert {:ok, %Phone{} = phone} = Accounts.update_phone(phone, update_attrs)
      assert phone.type == "personal"
      assert phone.name == "work phone edited"
      assert phone.number == "9999999999"
      assert phone.default == true
      assert phone.verified == false

      # check that phone2 is not default anymore
      assert {:ok, %Phone{default: false}} = Accounts.get_phone(id)
    end

    test "update_phone/2 with invalid data returns error changeset" do
      phone = insert(:phone, user: insert(:user))

      assert {:error, %Ecto.Changeset{}} = Accounts.update_phone(phone, @invalid_attrs)

      {:ok, restored_phone} = Accounts.get_phone(phone.id)
      assert %{phone | user: nil} == %{restored_phone | user: nil}
    end

    test "delete_phone/1 deletes the phone" do
      user = insert(:user)
      phones = insert_list(3, :phone, user: user)
      phone = phones |> Enum.at(1)

      assert {:ok, %Phone{}} = Accounts.delete_phone(phone)
      assert Accounts.get_phone(phone.id) == {:error, :not_found}
    end

    test "change_phone/1 returns an phone changeset" do
      phone = insert(:phone)
      assert %Ecto.Changeset{} = Accounts.change_phone(phone)
    end
  end
end
