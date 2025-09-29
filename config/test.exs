import Config

# Configure your database for tests
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :shop1_cmms, Shop1Cmms.Repo,
  username: "postgres",
  password: "admin",
  hostname: "localhost",
  port: 5433,
  database: "shop1_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :shop1_cmms, Shop1CmmsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_key_base_that_is_at_least_64_characters_long_for_phoenix_security_requirements",
  server: false

# In test we don't send emails.
config :shop1_cmms, Shop1Cmms.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable live view signing salt
config :shop1_cmms, Shop1CmmsWeb.Endpoint,
  live_view: [signing_salt: "test_salt"]

# Configure Oban for testing (disable it)
config :shop1_cmms, Oban,
  testing: :manual,
  plugins: false,
  queues: false

# Configure database to use second precision timestamps
config :shop1_cmms, Shop1Cmms.Repo,
  migration_timestamps: [type: :utc_datetime]
