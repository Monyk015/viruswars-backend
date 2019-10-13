use Mix.Config

# Configure your database
config :virus_wars, VirusWars.Repo,
  username: "postgres",
  password: "postgres",
  database: "virus_wars_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :virus_wars, VirusWarsWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
