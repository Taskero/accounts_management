defmodule AccountManagementAPIWeb.AuthControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPIWeb.Auth.{AuthHelper, Guardian}

  @system_identifier "my_cool_system"
  @valid_pass "QWERTY123!!asdfgh"

  setup %{conn: conn} do
    account =
      insert(:account,
        system_identifier: @system_identifier,
        email: "john_wick@gmail.com",
        password: @valid_pass,
        password_hash: @valid_pass |> Argon2.hash_pwd_salt()
      )

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("system-identifier", @system_identifier)
      |> AuthHelper.with_valid_authorization_header(account.id)

    {:ok, account: account, conn: conn}
  end

  describe "post /api/auth" do
    test "with valid user and password key generate JWT", %{
      account: account,
      conn: conn
    } do
      body =
        """
        {
          "email": "john_wick@gmail.com",
          "password": "#{@valid_pass}"
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/auth", body)

      %{
        "access_token" => jwt,
        "account_id" => account_id,
        "expires_in" => exp,
        "token_type" => "Bearer"
      } = json_response(conn, 201)

      assert account_id == account.id
      assert exp > DateTime.utc_now() |> DateTime.to_unix()

      assert {:ok,
              %{
                "exp" => ^exp,
                "sub" => ^account_id,
                "sysid" => @system_identifier
              }} = jwt |> Guardian.decode_and_verify()
    end

    test "with invalid pass return error", %{conn: conn} do
      body =
        """
        {
          "email": "john_wick@gmail.com",
          "password": "wrong"
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/auth", body)

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end

    test "with invalid sysid return error" do
      body =
        """
        {
          "email": "john_wick@gmail.com",
          "password": "#{@valid_pass}"
        }
        """
        |> Jason.decode!()

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("system-identifier", "not_existing_sysid")

      conn = post(conn, ~p"/api/auth", body)

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end

    test "with invalid email return error", %{conn: conn} do
      body =
        """
        {
          "email": "not_existsk@gmail.com",
          "password": "#{@valid_pass}"
        }
        """
        |> Jason.decode!()

      conn = post(conn, ~p"/api/auth", body)

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end
  end
end
