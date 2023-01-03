defmodule MonexApi.Repo do
  use Ecto.Repo,
    otp_app: :monex_api,
    adapter: Ecto.Adapters.Postgres
end
