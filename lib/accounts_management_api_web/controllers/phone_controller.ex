defmodule AccountsManagementAPIWeb.PhoneController do
  use AccountsManagementAPIWeb, :controller

  alias AccountsManagementAPI.Users
  alias AccountsManagementAPI.Users.{Phone, Account}

  action_fallback(AccountsManagementAPIWeb.FallbackController)

  def index(conn, %{"account_id" => account_id}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()

    {:ok, account} =
      sysid
      |> Users.get_account(account_id)

    render(conn, :index, phones: account.phones)
  end

  def create(conn, %{"phone" => phone_params, "account_id" => account_id}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()
    phone_params = phone_params |> Map.put("account_id", account_id)

    with {:ok, %Account{} = account} <- Users.get_account(sysid, account_id),
         {:ok, %Phone{} = phone} <- Users.create_phone(phone_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/accounts/#{account}/phones/#{phone.id}")
      |> render(:show, phone: phone)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    sysid = conn |> get_req_header("system-identifier") |> List.first()

    with {:ok,
          %Phone{
            account: %Account{
              system_identifier: ^sysid
            }
          } = phone} <- Users.get_phone(id) do
      render(conn, :show, phone: phone)
    end
  end

  def update(conn, %{"id" => id, "phone" => phone_params}) do
    with sysid <- conn |> get_req_header("system-identifier") |> List.first(),
         phone_params <- phone_params |> Map.delete("account_id"),
         {:ok,
          %Phone{
            account: %Account{
              system_identifier: ^sysid
            }
          } = phone} <- Users.get_phone(id),
         {:ok, %Phone{} = phone} <- Users.update_phone(phone, phone_params) do
      render(conn, :show, phone: phone)
    end
  end

  def delete(conn, %{"id" => id}) do
    with sysid <- conn |> get_req_header("system-identifier") |> List.first(),
         {:ok,
          %Phone{
            account: %Account{
              system_identifier: ^sysid
            }
          } = phone} <- Users.get_phone(id),
         {:ok, %Phone{}} <- Users.delete_phone(phone) do
      send_resp(conn, :no_content, "")
    end
  end
end
