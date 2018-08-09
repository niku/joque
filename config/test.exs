use Mix.Config

config :joque, Joque.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "joque_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
