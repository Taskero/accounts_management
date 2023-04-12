defmodule AccountsManagementAPIWeb.PhoneControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPIWeb.Auth.AuthHelper
  alias AccountsManagementAPI.Accounts
  alias AccountsManagementAPI.Accounts.Phone

  doctest AccountsManagementAPIWeb.PhoneController

  @invalid_attrs %{
    type: nil,
    name: nil,
    number: nil,
    default: nil,
    verified: nil,
    user_id: nil
  }

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> AuthHelper.with_valid_authorization_header(user.id)

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all user phones", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user}/phones")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create phone" do
    test "renders phone when data is valid", %{conn: conn, user: user} do
      body =
        """
        {
          "phone": {
            "type": "personal",
            "name": "my cool phone",
            "number": "+1234567890"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/users/#{user}/phones", body)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = AuthHelper.new_conn(user.id) |> get(~p"/api/users/#{user}/phones/#{id}")

      assert %{
               "id" => ^id,
               "type" => "personal",
               "name" => "my cool phone",
               "number" => "+1234567890"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/users/#{user}/phones", phone: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update phone" do
    setup [:create_phone]

    test "renders phone when data is valid", %{
      conn: conn,
      phone: %Phone{id: id} = phone,
      user: user
    } do
      body =
        """
        {
          "phone": {
              "number": "9999999999",
              "type": "business"
          }
        }
        """
        |> Jason.decode!()

      conn = put(conn, ~p"/api/users/#{user}/phones/#{id}", body)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = AuthHelper.new_conn(user.id) |> get(~p"/api/users/#{user}/phones/#{id}")

      assert %{
               "user_id" => phone.user_id,
               "default" => true,
               "id" => id,
               "number" => "9999999999",
               "name" => phone.name,
               "type" => "business",
               "verified" => false
             } == json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_phone]

    test "deletes chosen user", %{conn: conn, user: user, phone: phone} do
      insert_list(3, :phone, user: user, default: false)

      conn = delete(conn, ~p"/api/users/#{user}/phones/#{phone}")
      assert response(conn, 204)

      assert AuthHelper.new_conn(user.id)
             |> get(~p"/api/users/#{user}/phones/#{phone.id}")
             |> response(404)
    end

    test "deletes default phone set another one", %{
      conn: conn,
      user: user,
      phone: phone
    } do
      add2 = insert(:phone, user: user, default: false)

      conn = delete(conn, ~p"/api/users/#{user}/phones/#{phone}")
      assert response(conn, 204)

      {:ok, phone} = Accounts.get_phone(add2.id)
      assert phone.default
    end

    test "deletes fails if is the last phone", %{
      conn: conn,
      user: user,
      phone: phone
    } do
      conn = delete(conn, ~p"/api/users/#{user}/phones/#{phone}")

      assert %{
               "default" => [
                 "At least one default phone is required"
               ]
             } = json_response(conn, 422)["errors"]
    end
  end

  defp create_phone(_) do
    user = insert(:user)
    phone = insert(:phone, user: user)

    %{user: user, phone: phone}
  end
end
