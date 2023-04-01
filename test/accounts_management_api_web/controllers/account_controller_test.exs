defmodule AccountsManagementAPIWeb.AccountControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPI.Users.Account

  doctest AccountsManagementAPIWeb.AccountController

  @system_identifier "my_cool_system"

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

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("system-identifier", @system_identifier)

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all accounts", %{conn: conn} do
      conn = get(conn, ~p"/api/accounts")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create account" do
    test "renders account when data is valid", %{conn: conn} do
      body =
        """
        {
          "account": {
              "email": "jwick@gmail.com",
              "password": "Cool!Password",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/accounts", body)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(new_conn(), ~p"/api/accounts/#{id}")

      assert %{
               "id" => ^id,
               "confirmed_at" => nil,
               "email" => "jwick@gmail.com",
               "email_verified" => false,
               "last_name" => "Wick",
               "locale" => "es",
               "name" => "John",
               "picture" => nil,
               "start_date" => nil,
               "status" => "pending",
               "system_identifier" => @system_identifier
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/accounts", account: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders invalid email", %{conn: conn} do
      body =
        """
        {
          "account": {
              "email": "jwick.com",
              "password": "Cool!Password",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/accounts", body)
      assert %{"email" => ["is not valid"]} = json_response(conn, 422)["errors"]
    end

    test "renders invalid pass", %{conn: conn} do
      body =
        """
        {
          "account": {
              "email": "jwick@gmail.com",
              "password": "short",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/accounts", body)

      assert %{
               "password" => [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ]
             } = json_response(conn, 422)["errors"]

      body =
        """
        {
          "account": {
              "email": "jwick@gmail.com",
              "password": "short123sss12312312",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/accounts", body)

      assert %{
               "password" => [
                 "at least one upper case character"
               ]
             } = json_response(conn, 422)["errors"]
    end
  end

  describe "update account" do
    setup [:create_account]

    test "renders account when data is valid", %{conn: conn, account: %Account{id: id} = account} do
      body =
        """
        {
          "account": {
              "email": "john_wick@gmail.com",
              "locale": "en"
          }
        }
        """
        |> Jason.decode!()

      conn = put(conn, ~p"/api/accounts/#{account}", body)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(new_conn(), ~p"/api/accounts/#{id}")

      %{
        "id" => ^id,
        "email" => email,
        "locale" => locale
      } = json_response(conn, 200)["data"]

      assert email == "john_wick@gmail.com"
      assert locale == "en"
    end

    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn = put(conn, ~p"/api/accounts/#{account}", account: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete account" do
    setup [:create_account]

    test "deletes chosen account", %{conn: conn, account: account} do
      conn = delete(conn, ~p"/api/accounts/#{account}")
      assert response(conn, 204)

      conn = get(new_conn(), ~p"/api/accounts/#{account}")

      assert response(conn, 404)
    end
  end

  defp create_account(_) do
    account = insert(:account, system_identifier: @system_identifier)

    %{account: account}
  end

  defp new_conn() do
    build_conn() |> put_req_header("system-identifier", @system_identifier)
  end
end
