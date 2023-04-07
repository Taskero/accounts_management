defmodule AccountsManagementAPIWeb.Auth.Guardian do
  @moduledoc """
  Guardian configuration for the API.
  Authentication `token` based, with JWT tokens.
  """

  use Guardian, otp_app: :accounts_management_api

  alias AccountsManagementAPI.Users
  alias AccountsManagementAPI.Users.Account

  @doc """
  Subject of the Payload in the JWT.
  As subject we store the id of the user

  ## Examples
    iex> Management.subject_for_token(%{id: "72d6fe29-b325-4d1a-8117-434400ce16c8"})
    {:ok, "72d6fe29-b325-4d1a-8117-434400ce16c8"}
  """
  @spec subject_for_token(any, any) :: {:error, :no_user_provided} | {:ok, binary}
  def subject_for_token(%Account{id: id}, _claims),
    do: {:ok, id |> to_string()}

  def subject_for_token(_, _), do: {:error, :no_user_provided}

  @doc """
  In JWT this be found in the `sub` field.
  Get the list of organization ids from the claims and return the organizations.
  """
  @spec resource_from_claims(any) :: {:error, :no_sub_provided | :not_found} | {:ok, any}
  def resource_from_claims(%{"sub" => id, "sysid" => system_identifier}),
    do: Users.get_account(system_identifier, id)

  def resource_from_claims(_), do: {:error, :no_sub_provided}
end
