defmodule AccountsManagementAPIWeb.AuthController do
  @moduledoc """
  The Auth controller.
  Generate the JWT token for the organization.
  """
  use AccountsManagementAPIWeb, :controller

  action_fallback(AccountsManagementAPIWeb.FallbackController)

  require Logger

  alias AccountsManagementAPI.Accounts
  alias AccountsManagementAPIWeb.Auth.Guardian

  # /api/auth
  def create(conn, %{"email" => email, "password" => pass}) do
    with {:ok, user} <- seek_user(email),
         {:ok, _} <- Argon2.check_pass(user, pass),
         {:ok, jwt, %{"exp" => exp}} <- user |> Guardian.encode_and_sign(%{}) do
      conn
      |> put_status(:created)
      |> put_resp_header("authorization", jwt)
      |> render("show.json", %{
        token: jwt,
        expiration: exp,
        type: "Bearer",
        user_id: user.id
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
        user_id: sub
      })
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render("401.json")
    end
  end

  def seek_user(email) do
    case [email: email] |> Accounts.list_users() do
      [user] ->
        {:ok, user}

      _ ->
        Logger.info("User not found for #{email}")
        {:error, :not_found}
    end
  end
end
