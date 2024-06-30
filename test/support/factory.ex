defmodule MonexApi.Factory do
  use ExMachina.Ecto, repo: MonexApi.Repo

  def user_params_factory do
    %{
      "first_name" => "Samuel",
      "last_name" => "Guedes",
      "email" => "samuel.guedes@gmail.com",
      "password" => "123456",
      "balance" => 2000
    }
  end

  def transaction_params_factory do
    %{
      "amount" => 100,
      "user_id" => Ecto.UUID.generate()
    }
  end
end
