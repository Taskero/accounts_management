defmodule AccountsManagementAPI.Test.Factories do
  @moduledoc """
  Define factories for use in tests.
  """

  use ExMachina.Ecto, repo: AccountsManagementAPI.Repo

  alias AccountsManagementAPI.Users.Account

  def account_factory do
    %Account{
      email: Faker.Internet.email(),
      password: Faker.Internet.slug(),
      password_hash: Faker.Internet.slug() |> Encryption.Hashing.hash(),
      email_verified: true,
      name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      confirmed_at: DateTime.utc_now(),
      locale: "en",
      picture: Faker.Internet.url(),
      start_date: DateTime.utc_now(),
      status: "active",
      system_identifier: Faker.Internet.slug()
    }
  end
end
