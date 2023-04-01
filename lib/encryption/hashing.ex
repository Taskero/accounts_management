defmodule Encryption.Hashing do
  @moduledoc """
  Hash binary data using the SHA-256 algorithm.
  """

  @doc """
  Hash the given value using SHA256
  """
  def hash(value) do
    :crypto.hash(:sha256, value <> get_salt(value)) |> Base.encode64()
  end

  # Get/use Phoenix secret_key_base as "salt" for one-way hashing
  # use the *value* to create a *unique* "salt" for each value that is hashed:
  defp get_salt(value) do
    secret_key_base =
      Application.get_env(:accounts_management_api, AccountsManagementAPIWeb.Endpoint)[
        :secret_key_base
      ]

    :crypto.hash(:sha256, value <> secret_key_base)
  end
end
