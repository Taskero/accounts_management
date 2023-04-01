defmodule AccountsManagementAPI.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AccountsManagementAPI.Users` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        confirmed_at: ~N[2023-03-31 09:07:00],
        email: "some email",
        email_verified: true,
        last_name: "some last_name",
        locale: "some locale",
        name: "some name",
        password_hash: "some password_hash",
        picture: "some picture",
        start_date: ~N[2023-03-31 09:07:00],
        status: "some status",
        system_identifier: "some system_identifier"
      })
      |> AccountsManagementAPI.Users.create_account()

    account
  end
end
