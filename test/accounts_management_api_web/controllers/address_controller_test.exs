defmodule AccountsManagementAPIWeb.AddressControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPIWeb.Auth.AuthHelper
  alias AccountsManagementAPI.Accounts
  alias AccountsManagementAPI.Accounts.Address

  doctest AccountsManagementAPIWeb.AddressController

  @invalid_attrs %{
    type: nil,
    name: nil,
    line_1: nil,
    city: nil,
    state: nil,
    country_code: nil,
    zip_code: nil,
    default: nil,
    user_id: nil
  }

  setup do
    user = insert(:user)

    {:ok, conn: AuthHelper.new_conn(user.id), user: user}
  end

  describe "index" do
    test "lists all user addresses", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user}/addresses")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create address" do
    test "renders address when data is valid", %{conn: conn, user: user} do
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

      conn = post(conn, ~p"/api/users/#{user}/addresses", body)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(AuthHelper.new_conn(user.id), ~p"/api/users/#{user}/addresses/#{id}")

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

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/users/#{user}/addresses", address: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update address" do
    setup [:create_address]

    test "renders address when data is valid", %{
      conn: conn,
      address: %Address{id: id} = address,
      user: user
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

      conn = put(conn, ~p"/api/users/#{user}/addresses/#{id}", body)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(AuthHelper.new_conn(user.id), ~p"/api/users/#{user}/addresses/#{id}")

      assert %{
               "user_id" => address.user_id,
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

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_address]

    test "deletes chosen user", %{conn: conn, user: user, address: address} do
      insert_list(3, :address, user: user, default: false)

      conn = delete(conn, ~p"/api/users/#{user}/addresses/#{address}")
      assert response(conn, 204)

      conn = AuthHelper.new_conn(user.id) |> get(~p"/api/users/#{user}/addresses/#{address}")

      assert response(conn, 404)
    end

    test "deletes default address set another one", %{
      conn: conn,
      user: user,
      address: address
    } do
      add2 = insert(:address, user: user, default: false)

      conn = delete(conn, ~p"/api/users/#{user}/addresses/#{address}")
      assert response(conn, 204)

      {:ok, address} = Users.get_address(add2.id)
      assert address.default
    end

    test "deletes fails if is the last address", %{
      conn: conn,
      user: user,
      address: address
    } do
      conn = delete(conn, ~p"/api/users/#{user}/addresses/#{address}")

      assert %{
               "default" => [
                 "At least one default address is required"
               ]
             } = json_response(conn, 422)["errors"]
    end
  end

  defp create_address(_) do
    user = insert(:user)
    address = insert(:address, user: user)

    %{user: user, address: address}
  end
end
