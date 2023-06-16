defmodule Ship.Repo do
  use Ecto.Repo,
    otp_app: :ship,
    adapter: Ecto.Adapters.Postgres
end
