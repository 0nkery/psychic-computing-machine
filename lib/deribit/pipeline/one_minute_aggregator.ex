defmodule Deribit.Pipeline.OneMinuteAggregator do
  use GenStage

  require Logger

  alias Deribit.Pipeline.Block

  # Interface

  def start_link(opts) do
    {producer, opts} = opts |> Keyword.pop(:producer)
    GenStage.start_link(__MODULE__, producer, opts)
  end

  # Callbacks

  def init(producer) do
    Logger.info("Starting #{__MODULE__}...")

    window =
      Flow.Window.fixed(1, :minute, fn event ->
        event.timestamp
      end)

    window = window |> Flow.Window.allowed_lateness(5, :second)

    {:ok, flow} =
      [producer]
      |> Flow.from_stages()
      |> Flow.partition(window: window)
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
      |> Flow.emit(:state)
      |> Flow.into_stages([])

    {:consumer, :ignore, subscribe_to: [{flow, cancel: :transient}]}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, &handle_event/1)
    {:noreply, [], state}
  end

  defp handle_event(event) do
  end

  defp round_to_minute(datetime) do
    {{datetime.year, datetime.month, datetime.day}, {datetime.hour, datetime.minute, 0}}
    |> Timex.to_unix()
  end
end
