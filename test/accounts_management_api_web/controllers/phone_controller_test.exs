defmodule AccountsManagementAPIWeb.PhoneControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPIWeb.Auth.AuthHelper
  alias AccountsManagementAPI.Users
  alias AccountsManagementAPI.Users.Phone

  doctest AccountsManagementAPIWeb.PhoneController

  @invalid_attrs %{
    type: nil,
    name: nil,
    number: nil,
    default: nil,
    verified: nil,
    account_id: nil
  }

  setup %{conn: conn} do
    account = insert(:account)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> AuthHelper.with_valid_authorization_header(account.id)

    {:ok, conn: conn, account: account}
  end

  describe "index" do
    test "lists all account phones", %{conn: conn, account: account} do
      conn = get(conn, ~p"/api/accounts/#{account}/phones")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create phone" do
    test "renders phone when data is valid", %{conn: conn, account: account} do
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

      conn = post(conn, ~p"/api/accounts/#{account}/phones", body)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = AuthHelper.new_conn(account.id) |> get(~p"/api/accounts/#{account}/phones/#{id}")

      assert %{
               "id" => ^id,
               "type" => "personal",
               "name" => "my cool phone",
               "number" => "+1234567890"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn = post(conn, ~p"/api/accounts/#{account}/phones", phone: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update phone" do
    setup [:create_phone]

    test "renders phone when data is valid", %{
      conn: conn,
      phone: %Phone{id: id} = phone,
      account: account
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

      conn = put(conn, ~p"/api/accounts/#{account}/phones/#{id}", body)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = AuthHelper.new_conn(account.id) |> get(~p"/api/accounts/#{account}/phones/#{id}")

      assert %{
               "account_id" => phone.account_id,
               "default" => true,
               "id" => id,
               "number" => "9999999999",
               "name" => phone.name,
               "type" => "business",
               "verified" => false
             } == json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn = put(conn, ~p"/api/accounts/#{account}", account: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete account" do
    setup [:create_phone]

    test "deletes chosen account", %{conn: conn, account: account, phone: phone} do
      insert_list(3, :phone, account: account, default: false)

      conn = delete(conn, ~p"/api/accounts/#{account}/phones/#{phone}")
      assert response(conn, 204)

      assert AuthHelper.new_conn(account.id)
             |> get(~p"/api/accounts/#{account}/phones/#{phone.id}")
             |> response(404)
    end

    test "deletes default phone set another one", %{
      conn: conn,
      account: account,
      phone: phone
    } do
      add2 = insert(:phone, account: account, default: false)

      conn = delete(conn, ~p"/api/accounts/#{account}/phones/#{phone}")
      assert response(conn, 204)

      {:ok, phone} = Users.get_phone(add2.id)
      assert phone.default
    end

    test "deletes fails if is the last phone", %{
      conn: conn,
      account: account,
      phone: phone
    } do
      conn = delete(conn, ~p"/api/accounts/#{account}/phones/#{phone}")

      assert %{
               "default" => [
                 "At least one default phone is required"
               ]
             } = json_response(conn, 422)["errors"]
    end
  end

  defp create_phone(_) do
    account = insert(:account)
    phone = insert(:phone, account: account)

    %{account: account, phone: phone}
  end
end
