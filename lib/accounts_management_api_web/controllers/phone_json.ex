defmodule AccountsManagementAPIWeb.PhoneJSON do
  alias AccountsManagementAPI.Accounts.Phone

  @doc """
  Renders a list of phones.
  """
  def index(%{phones: phones}) do
    %{data: for(phone <- phones, do: data(phone))}
  end

  @doc """
  Renders a single phone.
  """
  def show(%{phone: phone}) do
    %{data: data(phone)}
  end

  defp data(%Phone{} = phone) do
    %{
      id: phone.id,
      type: phone.type,
      name: phone.name,
      number: phone.number,
      default: phone.default,
      verified: phone.verified,
      user_id: phone.user_id
    }
  end
end
