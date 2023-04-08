defmodule AccountsManagementAPIWeb.AuthController do
  @moduledoc """
  The Auth controller.
  Generate the JWT token for the organization.
  """
  use AccountsManagementAPIWeb, :controller

  action_fallback(AccountsManagementAPIWeb.FallbackController)

  alias AccountsManagementAPI.Users
  alias AccountsManagementAPIWeb.Auth.Guardian

  # /api/auth
  def create(conn, %{"email" => email, "password" => pass}) do
    with sysid <- conn |> get_req_header("system-identifier") |> List.first(),
         [account] <- [system_identifier: sysid, email: email] |> Users.list_accounts(),
         {:ok, _} <- Argon2.check_pass(account, pass),
         {:ok, jwt, %{"exp" => exp}} <- account |> Guardian.encode_and_sign(%{"sysid" => sysid}) do
      conn
      |> put_status(:created)
      |> put_resp_header("authorization", jwt)
      |> render("show.json", %{
        token: jwt,
        expiration: exp,
        type: "Bearer",
        account_id: account.id
      })
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render("401.json")
    end
  end

  # /api/auth/refresh
  def create(conn, %{}) do
    with [token] <- conn |> get_req_header("authorization"),
         {:ok, _, {new_token, %{"exp" => exp, "sub" => sub}}} <-
           Guardian.refresh(token |> String.replace("Bearer ", "")) do
      conn
      |> put_status(:created)
      |> put_resp_header("authorization", new_token)
      |> render("show.json", %{
        token: new_token,
        expiration: exp,
        type: "Bearer",
        account_id: sub
      })
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render("401.json")
    end
  end
end
