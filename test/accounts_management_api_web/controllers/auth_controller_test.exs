defmodule AccountManagementAPIWeb.AuthControllerTest do
  use AccountsManagementAPIWeb.ConnCase

  import AccountsManagementAPI.Test.Factories

  alias AccountsManagementAPIWeb.Auth.{AuthHelper, Guardian}

  @valid_pass "QWERTY123!!asdfgh"

  setup %{conn: conn} do
    user =
      insert(:user,
        email: "john_wick@gmail.com",
        password: @valid_pass,
        password_hash: @valid_pass |> Bcrypt.hash_pwd_salt()
      )

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> AuthHelper.with_valid_authorization_header(user.id)

    {:ok, user: user, conn: conn}
  end

  describe "post /api/auth" do
    test "with valid user and password key generate JWT", %{
      user: user,
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
        "user_id" => user_id,
        "expires_in" => exp,
        "token_type" => "Bearer"
      } = json_response(conn, 201)

      assert user_id == user.id
      assert exp > DateTime.utc_now() |> DateTime.to_unix()

      assert {:ok,
              %{
                "exp" => ^exp,
                "sub" => ^user_id
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

  describe "post /api/auth/refresh" do
    test "with valid  JWT", %{
      user: user,
      conn: conn
    } do
      old_jwt =
        conn |> get_req_header("authorization") |> List.first() |> String.replace("Bearer ", "")

      conn = post(conn, ~p"/api/auth/refresh")

      %{
        "access_token" => jwt,
        "user_id" => user_id,
        "expires_in" => exp,
        "token_type" => "Bearer"
      } = json_response(conn, 201)

      assert user_id == user.id
      assert old_jwt != jwt
      assert exp > DateTime.utc_now() |> DateTime.to_unix()

      assert {:ok,
              %{
                "exp" => ^exp,
                "sub" => ^user_id
              }} = jwt |> Guardian.decode_and_verify()
    end

    test "with expired JWT return error", %{user: user} do
      {:ok, expired_jwt, _} =
        Guardian.encode_and_sign(user, %{
          "exp" => DateTime.utc_now() |> DateTime.add(-10) |> DateTime.to_unix()
        })

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> expired_jwt)

      conn = post(conn, ~p"/api/auth/refresh")

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end

    test "without jwt return error" do
      conn =
        build_conn()
        |> put_req_header("accept", "application/json")

      conn = post(conn, ~p"/api/auth/refresh")

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end
  end
end
