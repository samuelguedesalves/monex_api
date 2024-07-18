# General application configuration
import Config

config :monex, ecto_repos: [Monex.Repo]

# Configures the endpoint
config :monex, MonexWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: MonexWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Monex.PubSub,
  live_view: [signing_salt: "611F2uYh"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :monex, Monex.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: {Monex.CustomLoggerFormatter, :format},
  metadata: [:module]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
