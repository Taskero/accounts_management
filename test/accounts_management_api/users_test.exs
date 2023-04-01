defmodule AccountsManagementAPI.UsersTest do
  use AccountsManagementAPI.DataCase

  alias AccountsManagementAPI.Users

  describe "accounts" do
    alias AccountsManagementAPI.Users.Account

    import AccountsManagementAPI.UsersFixtures

    @invalid_attrs %{
      confirmed_at: nil,
      email: nil,
      email_verified: nil,
      last_name: nil,
      locale: nil,
      name: nil,
      password_hash: nil,
      picture: nil,
      start_date: nil,
      status: nil,
      system_identifier: nil
    }

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert Users.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Users.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      valid_attrs = %{
        confirmed_at: ~N[2023-03-31 09:07:00],
        email: "some email",
        email_verified: true,
        last_name: "some last_name",
        locale: "some locale",
        name: "some name",
        password_hash: "some password_hash",
        picture: "some picture",
        start_date: ~N[2023-03-31 09:07:00],
        status: "some status",
        system_identifier: "some system_identifier"
      }

      assert {:ok, %Account{} = account} = Users.create_account(valid_attrs)
      assert account.confirmed_at == ~N[2023-03-31 09:07:00]
      assert account.email == "some email"
      assert account.email_verified == true
      assert account.last_name == "some last_name"
      assert account.locale == "some locale"
      assert account.name == "some name"
      assert account.password_hash == "some password_hash"
      assert account.picture == "some picture"
      assert account.start_date == ~N[2023-03-31 09:07:00]
      assert account.status == "some status"
      assert account.system_identifier == "some system_identifier"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()

      update_attrs = %{
        confirmed_at: ~N[2023-04-01 09:07:00],
        email: "some updated email",
        email_verified: false,
        last_name: "some updated last_name",
        locale: "some updated locale",
        name: "some updated name",
        password_hash: "some updated password_hash",
        picture: "some updated picture",
        start_date: ~N[2023-04-01 09:07:00],
        status: "some updated status",
        system_identifier: "some updated system_identifier"
      }

      assert {:ok, %Account{} = account} = Users.update_account(account, update_attrs)
      assert account.confirmed_at == ~N[2023-04-01 09:07:00]
      assert account.email == "some updated email"
      assert account.email_verified == false
      assert account.last_name == "some updated last_name"
      assert account.locale == "some updated locale"
      assert account.name == "some updated name"
      assert account.password_hash == "some updated password_hash"
      assert account.picture == "some updated picture"
      assert account.start_date == ~N[2023-04-01 09:07:00]
      assert account.status == "some updated status"
      assert account.system_identifier == "some updated system_identifier"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = Users.update_account(account, @invalid_attrs)
      assert account == Users.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Users.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Users.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Users.change_account(account)
    end
  end
end
