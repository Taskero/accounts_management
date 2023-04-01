defmodule AccountsManagementAPIWeb.AccountControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPI.Users.Account

  @system_identifier "my_cool_system"

  @create_attrs %{
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
    system_identifier: "THIS WILL BE OVERWRITTEN"
  }
  @update_attrs %{
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
    system_identifier: "THIS WILL BE OVERWRITTEN, NOT ALLOWED TO UPDATE"
  }
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
      conn = post(conn, ~p"/api/accounts", account: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(new_conn(), ~p"/api/accounts/#{id}")

      assert %{
               "id" => ^id,
               "confirmed_at" => "2023-03-31T09:07:00",
               "email" => "some email",
               "email_verified" => true,
               "last_name" => "some last_name",
               "locale" => "some locale",
               "name" => "some name",
               "password_hash" => "some password_hash",
               "picture" => "some picture",
               "start_date" => "2023-03-31T09:07:00",
               "status" => "some status",
               "system_identifier" => @system_identifier
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/accounts", account: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update account" do
    setup [:create_account]

    test "renders account when data is valid", %{conn: conn, account: %Account{id: id} = account} do
      conn = put(conn, ~p"/api/accounts/#{account}", account: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(new_conn(), ~p"/api/accounts/#{id}")

      assert %{
               "id" => ^id,
               "confirmed_at" => "2023-04-01T09:07:00",
               "email" => "some updated email",
               "email_verified" => false,
               "last_name" => "some updated last_name",
               "locale" => "some updated locale",
               "name" => "some updated name",
               "password_hash" => "some updated password_hash",
               "picture" => "some updated picture",
               "start_date" => "2023-04-01T09:07:00",
               "status" => "some updated status",
               "system_identifier" => @system_identifier
             } = json_response(conn, 200)["data"]
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
