defmodule MonexApi.Factory do
  use ExMachina.Ecto, repo: MonexApi.Repo

  def user_params_factory do
    %{
      first_name: "Samuel",
      last_name: "Guedes",
      email: "samuel.guedes@email.com",
      password: "123456",
      balance: 10_000
    }
  end

  def transaction_params_factory do
    %{
      amount: 100,
      from_user: 99,
      to_user: 100
    }
  end
end
