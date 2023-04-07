defmodule AccountsManagementAPIWeb.AddressController do
  use AccountsManagementAPIWeb, :controller

  alias AccountsManagementAPI.Users
  alias AccountsManagementAPI.Users.{Address, Account}

  action_fallback(AccountsManagementAPIWeb.FallbackController)

  def index(conn, %{"account_id" => account_id}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()

    {:ok, account} =
      sysid
      |> Users.get_account(account_id)

    render(conn, :index, addresses: account.addresses)
  end

  def create(conn, %{"address" => address_params, "account_id" => account_id}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()
    address_params = address_params |> Map.put("account_id", account_id)

    with {:ok, %Account{} = account} <- Users.get_account(sysid, account_id),
         {:ok, %Address{} = address} <- Users.create_address(address_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/accounts/#{account}/addresses/#{address.id}")
      |> render(:show, address: address)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()

    with {:ok,
          %Address{
            account: %Account{
              system_identifier: ^sysid
            }
          } = address} <- Users.get_address(id) do
      render(conn, :show, address: address)
    end
  end

  def update(conn, %{"id" => id, "address" => address_params}) do
    with sysid <- conn |> get_req_header("system-identifier") |> List.first(),
         address_params <- address_params |> Map.delete("account_id"),
         {:ok,
          %Address{
            account: %Account{
              system_identifier: ^sysid
            }
          } = address} <- Users.get_address(id),
         {:ok, %Address{} = address} <- Users.update_address(address, address_params) do
      render(conn, :show, address: address)
    end
  end

  def delete(conn, %{"id" => id}) do
    with sysid <- conn |> get_req_header("system-identifier") |> List.first(),
         {:ok,
          %Address{
            account: %Account{
              system_identifier: ^sysid
            }
          } = address} <- Users.get_address(id),
         {:ok, %Address{}} <- Users.delete_address(address) do
      send_resp(conn, :no_content, "")
    end
  end
end
