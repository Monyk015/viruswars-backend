defmodule VirusWars.Repo do
  use Ecto.Repo,
    otp_app: :virus_wars,
    adapter: Ecto.Adapters.Postgres
end
