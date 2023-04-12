defmodule AccountsManagementAPIWeb.Auth.AuthHelper do
  @moduledoc """
  Helper to build conn with authorization header.
  """
  import Plug.Conn

  use AccountsManagementAPIWeb.ConnCase

  alias AccountsManagementAPI.Accounts.User
  alias AccountsManagementAPIWeb.Auth.Guardian

  @doc """
  Add a valid authorization header to the connection.

  ## Examples

    iex> conn |> AuthHelper.with_valid_authorization_header(user_id)
    conn
    iex> conn |> AuthHelper.with_valid_authorization_header()
    conn

  ### Example of use in a test
    alias AccountsManagementAPIWeb.Auth.AuthHelper

    setup %{conn: conn} do
      conn =
        conn
        |> AuthHelper.with_valid_authorization_header()

      {:ok, conn: conn}
    end
  """
  def with_valid_authorization_header(
        conn,
        user_id \\ "e281da89-3fa0-4487-9064-911ba0e83f1c"
      ) do
    conn |> create_with_valid_authorization_header(%User{id: user_id})
  end

  defp create_with_valid_authorization_header(conn, user) do
    {:ok, token, _} = user |> Guardian.encode_and_sign(%{})

    conn
    |> put_req_header("authorization", "Bearer " <> token)
    |> put_req_header("accept", "application/json")
  end

  def new_conn(user_id) do
    build_conn()
    |> put_req_header("accept", "application/json")
    |> with_valid_authorization_header(user_id)
  end
end
