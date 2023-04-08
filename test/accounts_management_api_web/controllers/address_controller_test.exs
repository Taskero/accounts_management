defmodule AccountsManagementAPIWeb.AddressControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPIWeb.Auth.AuthHelper
  alias AccountsManagementAPI.Users
  alias AccountsManagementAPI.Users.Address

  doctest AccountsManagementAPIWeb.AddressController

  @system_identifier "my_cool_system"

  @invalid_attrs %{
    type: nil,
    name: nil,
    line_1: nil,
    city: nil,
    state: nil,
    country_code: nil,
    zip_code: nil,
    default: nil,
    account_id: nil
  }

  setup %{conn: conn} do
    account = insert(:account, system_identifier: @system_identifier)

    {:ok, conn: AuthHelper.new_conn(account.id), account: account}
  end

  describe "index" do
    test "lists all account addresses", %{conn: conn, account: account} do
      conn = get(conn, ~p"/api/accounts/#{account}/addresses")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create address" do
    test "renders address when data is valid", %{conn: conn, account: account} do
      body =
        """
        {
          "address": {
            "type": "personal",
            "name": "my cool address",
            "line_1": "123, Evergreen Terrace",
            "city": "Springfield",
            "state": "Oregon",
            "country_code": "US",
            "zip_code": "12345"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/accounts/#{account}/addresses", body)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(AuthHelper.new_conn(account.id), ~p"/api/accounts/#{account}/addresses/#{id}")

      assert %{
               "id" => ^id,
               "type" => "personal",
               "name" => "my cool address",
               "line_1" => "123, Evergreen Terrace",
               "city" => "Springfield",
               "state" => "Oregon",
               "country_code" => "US",
               "zip_code" => "12345"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn = post(conn, ~p"/api/accounts/#{account}/addresses", address: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update address" do
    setup [:create_address]

    test "renders address when data is valid", %{
      conn: conn,
      address: %Address{id: id} = address,
      account: account
    } do
      body =
        """
        {
          "address": {
              "line_1": "123, Evergreen Terrace edited",
              "line_2": "behind the tree"
          }
        }
        """
        |> Jason.decode!()

      conn = put(conn, ~p"/api/accounts/#{account}/addresses/#{id}", body)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(AuthHelper.new_conn(account.id), ~p"/api/accounts/#{account}/addresses/#{id}")

      assert %{
               "account_id" => address.account_id,
               "city" => address.city,
               "country_code" => address.country_code,
               "default" => true,
               "id" => id,
               "line_1" => "123, Evergreen Terrace edited",
               "line_2" => "behind the tree",
               "name" => address.name,
               "state" => address.state,
               "type" => address.type,
               "zip_code" => address.zip_code
             } == json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn = put(conn, ~p"/api/accounts/#{account}", account: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete account" do
    setup [:create_address]

    test "deletes chosen account", %{conn: conn, account: account, address: address} do
      insert_list(3, :address, account: account, default: false)

      conn = delete(conn, ~p"/api/accounts/#{account}/addresses/#{address}")
      assert response(conn, 204)

      conn =
        AuthHelper.new_conn(account.id) |> get(~p"/api/accounts/#{account}/addresses/#{address}")

      assert response(conn, 404)
    end

    test "deletes default address set another one", %{
      conn: conn,
      account: account,
      address: address
    } do
      add2 = insert(:address, account: account, default: false)

      conn = delete(conn, ~p"/api/accounts/#{account}/addresses/#{address}")
      assert response(conn, 204)

      {:ok, address} = Users.get_address(add2.id)
      assert address.default
    end

    test "deletes fails if is the last address", %{
      conn: conn,
      account: account,
      address: address
    } do
      conn = delete(conn, ~p"/api/accounts/#{account}/addresses/#{address}")

      assert %{
               "default" => [
                 "At least one default address is required"
               ]
             } = json_response(conn, 422)["errors"]
    end
  end

  defp create_address(_) do
    account = insert(:account, system_identifier: @system_identifier)
    address = insert(:address, account: account)

    %{account: account, address: address}
  end
end
