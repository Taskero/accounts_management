defmodule AccountsManagementAPIWeb.UserController do
  use AccountsManagementAPIWeb, :controller

  alias AccountsManagementAPI.Accounts
  alias AccountsManagementAPI.Accounts.User

  action_fallback AccountsManagementAPIWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()

    render(conn, :index, users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    with {:ok, %User{} = user} <- Accounts.get_user(id) do
      render(conn, :show, user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    with user_params <- user_params |> Map.delete("status"),
         user_params <- user_params |> Map.delete("confirmed_at"),
         {:ok, user} <- Accounts.get_user(id),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, user} <- Accounts.get_user(id),
         {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
