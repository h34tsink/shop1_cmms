import Config

# Configure Ecto repos
config :shop1_cmms, ecto_repos: [Shop1Cmms.Repo]

# Configure your database
config :shop1_cmms, Shop1Cmms.Repo,
  username: "postgres",
  password: "admin",
  hostname: "localhost",
  port: 5433,
  database: "Shop1",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configures the endpoint
config :shop1_cmms, Shop1CmmsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: Shop1CmmsWeb.ErrorHTML, json: Shop1CmmsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Shop1Cmms.PubSub,
  live_view: [signing_salt: "your-signing-salt"]

# Configures the mailer
config :shop1_cmms, Shop1Cmms.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  shop1_cmms: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.0",
  shop1_cmms: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Oban for background jobs
config :shop1_cmms, Oban,
  repo: Shop1Cmms.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, mailers: 20, pm_scheduling: 5]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uses config_env()/0 (available in Mix.Config since Elixir 1.11+) instead of Mix.env/0.
# Safely only imports if the file actually exists to avoid runtime warnings in releases.
env_config = Path.join([__DIR__, "#{config_env()}.exs"])
if File.exists?(env_config) do
  import_config env_config
end
