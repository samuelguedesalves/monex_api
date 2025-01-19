import Config

# Do not print debug messages in production
config :logger, level: :info

config :monex, Monex.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.get_env("SMTP_HOST"),
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  port: 2525,
  retries: 2
