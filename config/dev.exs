use Mix.Config

config :joque, Joque.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "joque_dev",
  hostname: "localhost",
  pool_size: 10
