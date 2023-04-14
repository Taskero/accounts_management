defmodule AccountsManagementAPIWeb.AddressController do
  use AccountsManagementAPIWeb, :controller

  alias AccountsManagementAPI.Accounts
  alias AccountsManagementAPI.Accounts.{Address, User}

  action_fallback(AccountsManagementAPIWeb.FallbackController)

  def index(conn, %{"user_id" => user_id}) do
    {:ok, user} = Accounts.get_user(user_id)

    render(conn, :index, addresses: user.addresses)
  end

  def create(conn, %{"address" => address_params, "user_id" => user_id}) do
    address_params = address_params |> Map.put("user_id", user_id)

    with {:ok, %User{} = _user} <- Accounts.get_user(user_id),
         {:ok, %Address{} = address} <- Accounts.create_address(address_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", ~p"/api/users/#{user}/addresses/#{address.id}")
      |> render(:show, address: address)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    with {:ok,
          %Address{
            user: %User{}
          } = address} <- Accounts.get_address(id) do
      render(conn, :show, address: address)
    end
  end

  def update(conn, %{"id" => id, "address" => address_params}) do
    with address_params <- address_params |> Map.delete("user_id"),
         {:ok,
          %Address{
            user: %User{}
          } = address} <- Accounts.get_address(id),
         {:ok, %Address{} = address} <- Accounts.update_address(address, address_params) do
      render(conn, :show, address: address)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok,
          %Address{
            user: %User{}
          } = address} <- Accounts.get_address(id),
         {:ok, %Address{}} <- Accounts.delete_address(address) do
      send_resp(conn, :no_content, "")
    end
  end
end
