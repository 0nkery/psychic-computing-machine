defmodule Deribit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @streamer Deribit.Pipeline.Streamer
  @one_minute_aggregator Deribit.Pipeline.OneMinuteAggregator

  def start(_type, _args) do
    children = [
      Deribit.InfluxDBConnection,
      # Stock data processing pipeline
      {@streamer, name: @streamer},
      {@one_minute_aggregator, producer: @streamer}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Deribit.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
