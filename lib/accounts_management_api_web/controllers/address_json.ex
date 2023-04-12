defmodule AccountsManagementAPIWeb.AddressJSON do
  alias AccountsManagementAPI.Accounts.Address

  @doc """
  Renders a list of addresses.
  """
  def index(%{addresses: addresses}) do
    %{data: for(address <- addresses, do: data(address))}
  end

  @doc """
  Renders a single address.
  """
  def show(%{address: address}) do
    %{data: data(address)}
  end

  defp data(%Address{} = address) do
    %{
      id: address.id,
      type: address.type,
      name: address.name,
      line_1: address.line_1,
      line_2: address.line_2,
      city: address.city,
      state: address.state,
      country_code: address.country_code,
      zip_code: address.zip_code,
      default: address.default,
      user_id: address.user_id
    }
  end
end
