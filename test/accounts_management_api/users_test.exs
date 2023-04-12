defmodule AccountsManagementAPI.UsersTest do
  use AccountsManagementAPI.DataCase

  alias AccountsManagementAPI.Users

  describe "accounts" do
    alias AccountsManagementAPI.Users.Account

    import AccountsManagementAPI.Test.Factories

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
      "status" => nil
    }

    test "list_accounts/0 returns all accounts" do
      %{} = account = insert(:account)

      assert Users.list_accounts() == [
               %{account | password: nil, addresses: [], phones: []}
             ]
    end

    test "get_account!/1 returns the account with given id" do
      account = insert(:account)

      assert Users.get_account(account.id) ==
               {:ok, %{account | password: nil, addresses: [], phones: []}}
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
        "start_date" => ~N[2023-03-31 09:07:00]
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
        "status" => "pending"
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
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = insert(:account)
      assert {:error, %Ecto.Changeset{}} = Users.update_account(account, @invalid_attrs)

      assert {:ok, %{account | password: nil, addresses: [], phones: []}} ==
               Users.get_account(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = insert(:account)
      assert {:ok, %Account{}} = Users.delete_account(account)
      assert Users.get_account(account.id) == {:error, :not_found}
    end

    test "change_account/1 returns an account changeset" do
      account = insert(:account)
      assert %Ecto.Changeset{} = Users.change_account(account)
    end
  end

  describe "addresses" do
    alias AccountsManagementAPI.Users.Address

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
      "account" => nil
    }

    test "get_account/1 with preload: :addresses returns all addresses" do
      %{} = account = insert(:account)
      address = insert(:address, account: account)
      address2 = insert(:address, account: account)
      insert(:address)

      {:ok, account} = Users.get_account(account.id)

      assert account.addresses |> Enum.map(& &1.id) == [address.id | [address2.id]]
    end

    test "get_address/1 returns the address with given id" do
      account = insert(:account)
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

  describe "phones" do
    alias AccountsManagementAPI.Users.Phone

    import AccountsManagementAPI.Test.Factories

    @invalid_attrs %{
      "type" => nil,
      "name" => nil,
      "number" => nil,
      "default" => nil,
      "verified" => nil,
      "account" => nil
    }

    test "get_account/1 with preload: :phones returns all phones" do
      %{} = account = insert(:account)
      phone = insert(:phone, account: account)
      phone2 = insert(:phone, account: account)
      insert(:phone)

      {:ok, account} = Users.get_account(account.id)

      assert account.phones |> Enum.map(& &1.id) == [phone.id | [phone2.id]]
    end

    test "get_phone/1 returns the phone with given id" do
      account = insert(:account)
      phone = insert(:phone, account: account)

      account = %{account | password: nil}

      assert {
               :ok,
               %AccountsManagementAPI.Users.Phone{
                 account: loaded_account,
                 account_id: account_id
               }
             } = Users.get_phone(phone.id)

      assert loaded_account == account
      assert account_id == account.id
    end

    test "create_phone/1 with valid data creates an phone" do
      account = insert(:account)

      valid_attrs = %{
        "type" => "personal",
        "name" => "some name",
        "number" => "+1234567890",
        "account_id" => account.id
      }

      assert {:ok, %Phone{} = phone} = Users.create_phone(valid_attrs)

      assert phone.type == "personal"
      assert phone.name == "some name"
      assert phone.number == "+1234567890"
      assert phone.account_id == account.id
      assert phone.default == true
      assert phone.verified == false

      valid_attrs = %{
        "type" => "business",
        "name" => "work phone",
        "number" => "+9876543210",
        "account_id" => account.id
      }

      assert {:ok, %Phone{} = phone} = Users.create_phone(valid_attrs)

      assert phone.type == "business"
      assert phone.name == "work phone"
      assert phone.number == "+9876543210"
      assert phone.account_id == account.id
      assert phone.default == false
      assert phone.verified == false
    end

    test "create_phone/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_phone(@invalid_attrs)
    end

    test "update_phone/2 with valid data updates the phone" do
      account = insert(:account)
      phone = insert(:phone, account: account)
      # phone2 becomes default
      %{id: id} = insert(:phone, account: account, default: true)

      update_attrs = %{
        "type" => "personal",
        "name" => "work phone edited",
        "number" => "9999999999",
        "default" => true
      }

      assert {:ok, %Phone{} = phone} = Users.update_phone(phone, update_attrs)
      assert phone.type == "personal"
      assert phone.name == "work phone edited"
      assert phone.number == "9999999999"
      assert phone.default == true
      assert phone.verified == false

      # check that phone2 is not default anymore
      assert {:ok, %Phone{default: false}} = Users.get_phone(id)
    end

    test "update_phone/2 with invalid data returns error changeset" do
      phone = insert(:phone, account: insert(:account))

      assert {:error, %Ecto.Changeset{}} = Users.update_phone(phone, @invalid_attrs)

      {:ok, restored_phone} = Users.get_phone(phone.id)
      assert %{phone | account: nil} == %{restored_phone | account: nil}
    end

    test "delete_phone/1 deletes the phone" do
      account = insert(:account)
      phones = insert_list(3, :phone, account: account)
      phone = phones |> Enum.at(1)

      assert {:ok, %Phone{}} = Users.delete_phone(phone)
      assert Users.get_phone(phone.id) == {:error, :not_found}
    end

    test "change_phone/1 returns an phone changeset" do
      phone = insert(:phone)
      assert %Ecto.Changeset{} = Users.change_phone(phone)
    end
  end
end
