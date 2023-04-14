defmodule AccountsManagementAPIWeb.AuthJSON do
  @moduledoc false

  @doc false
  def show(%{token: token, expiration: expiration, type: type, user_id: user_id}) do
    %{
      access_token: token,
      expires_in: expiration,
      token_type: type,
      user_id: user_id
    }
  end

  def render("401.json", _assigns) do
    %{errors: %{detail: "Unauthorized"}}
  end
end
