defmodule AccountsManagementAPIWeb.UserJSON do
  alias AccountsManagementAPI.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      last_name: user.last_name,
      picture: user.picture,
      locale: user.locale,
      status: user.status,
      start_date: user.start_date,
      confirmed_at: user.confirmed_at
    }
  end
end
