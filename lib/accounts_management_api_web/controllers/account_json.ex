defmodule AccountsManagementAPIWeb.AccountJSON do
  alias AccountsManagementAPI.Users.Account

  @doc """
  Renders a list of accounts.
  """
  def index(%{accounts: accounts}) do
    %{data: for(account <- accounts, do: data(account))}
  end

  @doc """
  Renders a single account.
  """
  def show(%{account: account}) do
    %{data: data(account)}
  end

  defp data(%Account{} = account) do
    %{
      id: account.id,
      email: account.email,
      password_hash: account.password_hash,
      email_verified: account.email_verified,
      name: account.name,
      last_name: account.last_name,
      picture: account.picture,
      locale: account.locale,
      status: account.status,
      start_date: account.start_date,
      confirmed_at: account.confirmed_at,
      system_identifier: account.system_identifier
    }
  end
end
