defmodule Monex.Repo do
  use Ecto.Repo,
    otp_app: :monex,
    adapter: Ecto.Adapters.Postgres
end
