import Config

# Database configuration for development
config :shop1_cmms, Shop1Cmms.Repo,
  username: "postgres",
  password: "admin",
  hostname: "localhost",
  port: 5433,
  database: "Shop1",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
config :shop1_cmms, Shop1CmmsWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "your-secret-key-base-here-should-be-64-characters-long-in-production",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:shop1_cmms, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:shop1_cmms, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :shop1_cmms, Shop1CmmsWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/shop1_cmms_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :shop1_cmms, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Configure Oban to use local adapter in development
config :shop1_cmms, Oban, testing: :manual
