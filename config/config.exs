# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# Configures Elixir's Logger
config :logger, :console, metadata: :all

config :deribit,
  api_url: "wss://www.deribit.com/ws/api/v2/",
  pair: "BTC-PERPETUAL"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
