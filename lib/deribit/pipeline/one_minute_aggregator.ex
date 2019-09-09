defmodule Deribit.Pipeline.OneMinuteAggregator do
  use GenStage

  require Logger

  alias Deribit.Pipeline.Block
  alias Deribit.Pipeline.OneMinuteSeries
  alias Deribit.Pipeline.Timeframes
  alias Deribit.InfluxDBConnection

  # Interface

  def start_link(opts) do
    {producer, opts} = opts |> Keyword.pop(:producer)
    GenStage.start_link(__MODULE__, producer, opts)
  end

  # Callbacks

  def init(producer) do
    Logger.info("Starting #{__MODULE__}...")

    Logger.info("Setting up continuous queries...")

    Timeframes.frame_queries()
    |> Enum.each(fn q ->
      result = InfluxDBConnection.execute(q, method: :post)

      Logger.info("""
        #{q}
        =>

        #{inspect(result)}
      """)
    end)

    window =
      Flow.Window.fixed(1, :minute, fn event ->
        event.timestamp
      end)

    window =
      window
      |> Flow.Window.allowed_lateness(5, :second)
      # Flush all the stuck windows every 2 minutes
      |> Flow.Window.trigger_periodically(2, :minute)

    {:ok, flow} =
      [producer]
      |> Flow.from_stages(max_demand: 10)
      |> Flow.partition(window: window, stages: 1)
      |> Flow.reduce(fn -> :empty end, fn event, block ->
        block =
          case block do
            :empty ->
              %Block{
                open: event.price,
                high: event.price,
                low: event.price,
                close: event.price,
                open_timestamp: event.timestamp,
                close_timestamp: event.timestamp,
                timestamp: event.datetime |> round_to_minute()
              }

            _not_new ->
              block
          end

        block =
          cond do
            Decimal.cmp(event.price, block.high) == :gt ->
              %{block | high: event.price}

            Decimal.cmp(event.price, block.low) == :lt ->
              %{block | low: event.price}

            true ->
              block
          end

        block =
          cond do
            event.timestamp < block.open_timestamp ->
              %{block | open: event.price, open_timestamp: event.timestamp}

            event.timestamp > block.close_timestamp ->
              %{block | close: event.price, close_timestamp: event.timestamp}

            true ->
              block
          end

        block
      end)
      |> Flow.on_trigger(fn
        state, _index, {:fixed, _ts, :watermark} ->
          {[], state}

        state, _index, {:fixed, _ts, :done} ->
          {[state], :empty}

        state, _index, {:fixed, _ts, {:periodically, _count, _unit}} ->
          {[state], :empty}
      end)
      |> Flow.into_stages([])

    {:consumer, :ignore, subscribe_to: [{flow, cancel: :transient, max_demand: 1}]}
  end

  def handle_events(events, _from, state) do
    points =
      events
      |> Enum.reject(fn event -> event == :empty end)
      |> Enum.map(fn event -> InfluxDBConnection.convert_event_to(event, OneMinuteSeries) end)

    case points do
      [] ->
        nil

      points ->
        case InfluxDBConnection.write(points) do
          :ok ->
            nil

          %{error: reason} ->
            Logger.error("Failed to save point: #{reason}")
        end
    end

    {:noreply, [], state}
  end

  def round_to_minute(datetime) do
    {{datetime.year, datetime.month, datetime.day}, {datetime.hour, datetime.minute, 0}}
    |> Timex.to_datetime()
    |> DateTime.to_unix(:nanosecond)
  end
end
