use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

config :joque,
  ecto_repos: [Joque.Repo]

config :ecto, :json_library, Jason

import_config "#{Mix.env()}.exs"
