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

  def address_factory do
    %AccountsManagementAPI.Users.Address{
      type: "personal",
      name: Faker.Internet.slug(),
      line_1: Faker.Address.street_address(),
      city: Faker.Address.city(),
      state: Faker.Address.state(),
      country_code: Faker.Address.country_code(),
      zip_code: Faker.Address.postcode(),
      default: true,
      account: build(:account)
    }
  end
end
