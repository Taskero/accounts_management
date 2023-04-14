defmodule AccountsManagementAPIWeb.PhoneController do
  use AccountsManagementAPIWeb, :controller

  alias AccountsManagementAPI.Accounts
  alias AccountsManagementAPI.Accounts.{Phone, User}

  action_fallback(AccountsManagementAPIWeb.FallbackController)

  def index(conn, %{"user_id" => user_id}) do
    {:ok, user} = Accounts.get_user(user_id)

    render(conn, :index, phones: user.phones)
  end

  def create(conn, %{"phone" => phone_params, "user_id" => user_id}) do
    phone_params = phone_params |> Map.put("user_id", user_id)

    with {:ok, %User{} = _user} <- Accounts.get_user(user_id),
         {:ok, %Phone{} = phone} <- Accounts.create_phone(phone_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", ~p"/api/users/#{user}/phones/#{phone.id}")
      |> render(:show, phone: phone)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    with {:ok,
          %Phone{
            user: %User{}
          } = phone} <- Accounts.get_phone(id) do
      render(conn, :show, phone: phone)
    end
  end

  def update(conn, %{"id" => id, "phone" => phone_params}) do
    with phone_params <- phone_params |> Map.delete("user_id"),
         {:ok,
          %Phone{
            user: %User{}
          } = phone} <- Accounts.get_phone(id),
         {:ok, %Phone{} = phone} <- Accounts.update_phone(phone, phone_params) do
      render(conn, :show, phone: phone)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok,
          %Phone{
            user: %User{}
          } = phone} <- Accounts.get_phone(id),
         {:ok, %Phone{}} <- Accounts.delete_phone(phone) do
      send_resp(conn, :no_content, "")
    end
  end
end
