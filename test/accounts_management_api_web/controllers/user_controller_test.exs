defmodule AccountsManagementAPIWeb.AccountControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPIWeb.Auth.AuthHelper
  alias AccountsManagementAPI.Accounts.User

  doctest AccountsManagementAPIWeb.UserController

  @invalid_attrs %{
    confirmed_at: nil,
    email: nil,
    last_name: nil,
    locale: nil,
    name: nil,
    password_hash: nil,
    picture: nil,
    start_date: nil,
    status: nil
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
    test "lists all accounts", %{conn: conn} do
      conn = get(conn, ~p"/api/users")
      assert json_response(conn, 200)["data"] |> length == 1
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      body =
        """
        {
          "user": {
              "email": "jwick@gmail.com",
              "password": "Cool!Password",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/users", body)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn =
        build_conn()
        |> AuthHelper.with_valid_authorization_header(id)
        |> get(~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "confirmed_at" => nil,
               "email" => "jwick@gmail.com",
               "last_name" => "Wick",
               "locale" => "es",
               "name" => "John",
               "picture" => nil,
               "start_date" => nil,
               "status" => "pending"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders invalid email", %{conn: conn} do
      body =
        """
        {
          "user": {
              "email": "jwick.com",
              "password": "Cool!Password",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/users", body)
      assert %{"email" => ["is not valid"]} = json_response(conn, 422)["errors"]
    end

    test "renders invalid pass", %{conn: conn} do
      body =
        """
        {
          "user": {
              "email": "jwick@gmail.com",
              "password": "short",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/users", body)

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
          "user": {
              "email": "jwick@gmail.com",
              "password": "short123sss12312312",
              "name": "John",
              "last_name": "Wick",
              "locale": "es"
          }
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/users", body)

      assert %{
               "password" => [
                 "at least one upper case character"
               ]
             } = json_response(conn, 422)["errors"]
    end
  end

  describe "update user" do
    setup [:create_account]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      body =
        """
        {
          "user": {
              "email": "john_wick@gmail.com",
              "locale": "en"
          }
        }
        """
        |> Jason.decode!()

      conn = put(conn, ~p"/api/users/#{user}", body)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn =
        build_conn()
        |> AuthHelper.with_valid_authorization_header(user.id)
        |> get(~p"/api/users/#{id}")

      insert(:user)

      %{
        "id" => ^id,
        "email" => email,
        "locale" => locale
      } = json_response(conn, 200)["data"]

      assert email == "john_wick@gmail.com"
      assert locale == "en"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_account]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/api/users/#{user}")
      assert response(conn, 204)

      conn =
        build_conn()
        |> AuthHelper.with_valid_authorization_header(user.id)
        |> get(~p"/api/users/#{user}")

      assert response(conn, 404)
    end
  end

  defp create_account(_) do
    user = insert(:user)

    %{user: user}
  end
end
