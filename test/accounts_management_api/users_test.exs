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
      assert Users.list_accounts(system_identifier: sysid) == [%{account | password: nil}]
    end

    test "get_account!/1 returns the account with given id" do
      account = insert(:account, system_identifier: @system_identifier)

      assert Users.get_account(account.id, @system_identifier) ==
               {:ok, %{account | password: nil}}
    end

    test "create_account/1 with valid data creates a account" do
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

      assert {:ok, %{account | password: nil}} ==
               Users.get_account(account.id, @system_identifier)
    end

    test "delete_account/1 deletes the account" do
      account = insert(:account, system_identifier: @system_identifier)
      assert {:ok, %Account{}} = Users.delete_account(account)
      assert Users.get_account(account.id, @system_identifier) == {:error, :not_found}
    end

    test "change_account/1 returns a account changeset" do
      account = insert(:account, system_identifier: @system_identifier)
      assert %Ecto.Changeset{} = Users.change_account(account)
    end
  end
end
