defmodule AccountsManagementAPI.Test.Factories do
  @moduledoc """
  Define factories for use in tests.
  """

  use ExMachina.Ecto, repo: AccountsManagementAPI.Repo

  alias AccountsManagementAPI.Accounts.{User, Address, Phone}

  def user_factory do
    %User{
      email: Faker.Internet.email(),
      password: Faker.Internet.slug(),
      # password_hash: Faker.Internet.slug() |> Argon2.hash_pwd_salt(),
      password_hash: Faker.Internet.slug() |> Bcrypt.hash_pwd_salt(),
      name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      confirmed_at: DateTime.utc_now(),
      locale: "en",
      picture: Faker.Internet.url(),
      start_date: DateTime.utc_now(),
      status: "active"
    }
  end

  def address_factory do
    %Address{
      type: "personal",
      name: Faker.Internet.slug(),
      line_1: Faker.Address.street_address(),
      city: Faker.Address.city(),
      state: Faker.Address.state(),
      country_code: Faker.Address.country_code(),
      zip_code: Faker.Address.postcode(),
      default: true,
      user: build(:user)
    }
  end

  def phone_factory do
    %Phone{
      type: "personal",
      name: Faker.Internet.slug(),
      number: Faker.Phone.EnUs.phone(),
      default: true,
      verified: false,
      user: build(:user)
    }
  end

  # TODO: not here
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
