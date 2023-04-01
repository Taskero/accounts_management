defmodule AccountsManagementAPIWeb.AccountController do
  use AccountsManagementAPIWeb, :controller

  alias AccountsManagementAPI.Users
  alias AccountsManagementAPI.Users.Account

  action_fallback AccountsManagementAPIWeb.FallbackController

  def index(conn, _params) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()

    accounts =
      [system_identifier: sysid]
      |> Users.list_accounts()

    render(conn, :index, accounts: accounts)
  end

  def create(conn, %{"account" => account_params}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()
    account_params = Map.put(account_params, "system_identifier", sysid)

    with {:ok, %Account{} = account} <- Users.create_account(account_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/accounts/#{account}")
      |> render(:show, account: account)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()

    with {:ok, %Account{} = account} <- Users.get_account(id, sysid) do
      render(conn, :show, account: account)
    end
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    with sysid <- conn |> get_req_header("system-identifier") |> List.first(),
         account_params <- account_params |> Map.delete("system_identifier"),
         account_params <- account_params |> Map.delete("status"),
         account_params <- account_params |> Map.delete("confirmed_at"),
         {:ok, account} <- Users.get_account(id, sysid),
         {:ok, %Account{} = account} <- Users.update_account(account, account_params) do
      render(conn, :show, account: account)
    end
  end

  def delete(conn, %{"id" => id}) do
    with sysid <- conn |> get_req_header("system-identifier") |> List.first(),
         {:ok, account} <- Users.get_account(id, sysid),
         {:ok, %Account{}} <- Users.delete_account(account) do
      send_resp(conn, :no_content, "")
    end
  end
end
