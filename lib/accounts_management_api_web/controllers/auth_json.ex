defmodule AccountsManagementAPIWeb.AuthJSON do
  @moduledoc false

  @doc false
  def show(%{token: token, expiration: expiration, type: type, account_id: account_id}) do
    %{
      access_token: token,
      expires_in: expiration,
      token_type: type,
      account_id: account_id
    }
  end

  def render("401.json", _assigns) do
    %{errors: %{detail: "Unauthorized"}}
  end
end
