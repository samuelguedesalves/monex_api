defmodule MonexApi.Factory do
  use ExMachina.Ecto, repo: MonexApi.Repo

  def user_params_factory do
    %{
      "email" => "some@gmail.com",
      "name" => "Some User",
      "password" => "123456",
      "amount" => 2000
    }
  end

  def transaction_params_factory do
    %{
      "amount" => 2000,
      "from_user" => Ecto.UUID.generate(),
      "to_user" => Ecto.UUID.generate()
    }
  end
end
