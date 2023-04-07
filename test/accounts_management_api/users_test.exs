defmodule AccountsManagementAPI.UsersTest do
  use AccountsManagementAPI.DataCase

  alias AccountsManagementAPI.Users

  describe "accounts" do
    alias AccountsManagementAPI.Users.Account

    import AccountsManagementAPI.Test.Factories

    @system_identifier "my_cool_system"

    @invalid_attrs %{
      "confirmed_at" => nil,
      "email" => nil,
      "email_verified" => nil,
      "last_name" => nil,
      "locale" => nil,
      "name" => nil,
      "password_hash" => nil,
      "picture" => nil,
      "start_date" => nil,
      "status" => nil,
      "system_identifier" => nil
    }

    test "list_accounts/0 returns all accounts" do
      %{system_identifier: sysid} = account = insert(:account)

      assert Users.list_accounts(system_identifier: sysid) == [
               %{account | password: nil, addresses: []}
             ]
    end

    test "get_account!/1 returns the account with given id" do
      account = insert(:account, system_identifier: @system_identifier)

      assert Users.get_account(@system_identifier, account.id) ==
               {:ok, %{account | password: nil, addresses: []}}
    end

    test "create_account/1 with valid data creates an account" do
      valid_attrs = %{
        "confirmed_at" => ~N[2023-03-31 09:07:00],
        "email" => "bar@foo.com",
        "email_verified" => true,
        "last_name" => "some last_name",
        "locale" => "en",
        "name" => "some name",
        "password" => "some!Password_hash",
        "picture" => "some picture",
        "start_date" => ~N[2023-03-31 09:07:00],
        "system_identifier" => "some system_identifier"
      }

      assert {:ok, %Account{} = account} = Users.create_account(valid_attrs)
      assert account.confirmed_at == ~N[2023-03-31 09:07:00]
      assert account.email == "bar@foo.com"
      assert account.email_verified == true
      assert account.last_name == "some last_name"
      assert account.locale == "en"
      assert account.name == "some name"
      assert account.password_hash != nil
      assert account.picture == "some picture"
      assert account.start_date == ~N[2023-03-31 09:07:00]
      assert account.status == "pending"
      assert account.system_identifier == "some system_identifier"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = insert(:account)

      update_attrs = %{
        "confirmed_at" => ~N[2023-04-01 09:07:00],
        "email" => "bar@foo.com",
        "email_verified" => false,
        "last_name" => "some updated last_name",
        "locale" => "en",
        "name" => "some updated name",
        "password" => "someUpdatedPassword_hash!",
        "picture" => "some updated picture",
        "start_date" => ~N[2023-04-01 09:07:00],
        "status" => "pending",
        "system_identifier" => "some updated system_identifier"
      }

      assert {:ok, %Account{} = account} = Users.update_account(account, update_attrs)
      assert account.confirmed_at == ~N[2023-04-01 09:07:00]
      assert account.email == "bar@foo.com"
      assert account.email_verified == false
      assert account.last_name == "some updated last_name"
      assert account.locale == "en"
      assert account.name == "some updated name"
      assert account.picture == "some updated picture"
      assert account.start_date == ~N[2023-04-01 09:07:00]
      assert account.status == "pending"
      assert account.system_identifier == "some updated system_identifier"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = insert(:account, system_identifier: @system_identifier)
      assert {:error, %Ecto.Changeset{}} = Users.update_account(account, @invalid_attrs)

      assert {:ok, %{account | password: nil, addresses: []}} ==
               Users.get_account(@system_identifier, account.id)
    end

    test "delete_account/1 deletes the account" do
      account = insert(:account, system_identifier: @system_identifier)
      assert {:ok, %Account{}} = Users.delete_account(account)
      assert Users.get_account(@system_identifier, account.id) == {:error, :not_found}
    end

    test "change_account/1 returns an account changeset" do
      account = insert(:account, system_identifier: @system_identifier)
      assert %Ecto.Changeset{} = Users.change_account(account)
    end
  end

  describe "addresses" do
    alias AccountsManagementAPI.Users.Address

    import AccountsManagementAPI.Test.Factories

    @system_identifier "my_cool_system"

    @invalid_attrs %{
      "type" => nil,
      "name" => nil,
      "line_1" => nil,
      "city" => nil,
      "state" => nil,
      "country_code" => nil,
      "zip_code" => nil,
      "default" => nil,
      "account" => nil
    }

    test "get_account/1 with preload: :addresses returns all addresses" do
      %{system_identifier: sysid} = account = insert(:account)
      address = insert(:address, account: account)
      address2 = insert(:address, account: account)
      insert(:address)

      {:ok, account} =
        sysid
        |> Users.get_account(account.id)

      assert account.addresses |> Enum.map(& &1.id) == [address.id | [address2.id]]
    end

    test "get_address/1 returns the address with given id" do
      account = insert(:account, system_identifier: @system_identifier)
      address = insert(:address, account: account)

      account = %{account | password: nil}

      assert {
               :ok,
               %AccountsManagementAPI.Users.Address{
                 account: loaded_account,
                 account_id: account_id
               }
             } = Users.get_address(address.id)

      assert loaded_account == account
      assert account_id == account.id
    end

    test "create_address/1 with valid data creates an address" do
      account = insert(:account)

      valid_attrs = %{
        "type" => "personal",
        "name" => "some name",
        "line_1" => "123, Evergreen Terrace",
        "city" => "Springfield",
        "state" => "Oregon",
        "country_code" => "US",
        "zip_code" => "12345",
        "account_id" => account.id
      }

      assert {:ok, %Address{} = address} = Users.create_address(valid_attrs)

      assert address.type == "personal"
      assert address.name == "some name"
      assert address.line_1 == "123, Evergreen Terrace"
      assert address.line_2 == nil
      assert address.city == "Springfield"
      assert address.state == "Oregon"
      assert address.country_code == "US"
      assert address.zip_code == "12345"
      assert address.account_id == account.id
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
        "account_id" => account.id
      }

      assert {:ok, %Address{} = address} = Users.create_address(valid_attrs)

      assert address.type == "business"
      assert address.name == "work address"
      assert address.line_1 == "123, Evergreen Terrace"
      assert address.line_2 == "behind the tree"
      assert address.city == "Springfield"
      assert address.state == "Oregon"
      assert address.country_code == "US"
      assert address.zip_code == "12345"
      assert address.account_id == account.id
      assert address.default == false
    end

    test "create_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_address(@invalid_attrs)
    end

    test "update_address/2 with valid data updates the address" do
      account = insert(:account)
      address = insert(:address, account: account)
      # address2 becomes default
      %{id: id} = insert(:address, account: account, default: true)

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

      assert {:ok, %Address{} = address} = Users.update_address(address, update_attrs)
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
      assert {:ok, %Address{default: false}} = Users.get_address(id)
    end

    test "update_address/2 with invalid data returns error changeset" do
      address = insert(:address, account: insert(:account))

      assert {:error, %Ecto.Changeset{}} = Users.update_address(address, @invalid_attrs)

      {:ok, restored_address} = Users.get_address(address.id)
      assert %{address | account: nil} == %{restored_address | account: nil}
    end

    test "delete_address/1 deletes the address" do
      account = insert(:account)
      addresses = insert_list(3, :address, account: account)
      address = addresses |> Enum.at(1)

      assert {:ok, %Address{}} = Users.delete_address(address)
      assert Users.get_address(address.id) == {:error, :not_found}
    end

    test "change_address/1 returns an address changeset" do
      address = insert(:address)
      assert %Ecto.Changeset{} = Users.change_address(address)
    end
  end
end
