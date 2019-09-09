defmodule Deribit.Pipeline.Streamer do
  use GenStage

  require Logger

  alias Deribit.Utils.JsonRpc2Client
  alias Deribit.Utils.GenStageBuffer
  alias Deribit.Utils.PeriodicMessage

  @start_client PeriodicMessage.new(1000 * 60)

  @deribit_api_url "wss://www.deribit.com/ws/api/v2/"
  @deribit_channel "trades.BTC-PERPETUAL.raw"

  defmodule State do
    defstruct [:buf, client: :none]
  end

  # Interface

  def start_link(opts) do
    GenStage.start_link(__MODULE__, :ok, opts)
  end

  # Callbacks

  @impl true
  def init(:ok) do
    Logger.info("Starting #{__MODULE__}...")

    state = %State{
      buf: GenStageBuffer.new()
    }

    PeriodicMessage.right_now(@start_client)

    {:producer, state}
  end

  @impl true

  def handle_demand(incoming_demand, state) do
    noreply_push_events(state, incoming_demand)
  end

  @impl true

  def handle_info(@start_client, %State{client: :none} = state) do
    {:ok, client} = JsonRpc2Client.start_link(@deribit_api_url)
    state = %{state | client: client}

    {:ok, _result} = subscribe(client, @deribit_channel)

    noreply_push_events(state)
  end

  def handle_info(@start_client, state) do
    noreply_push_events(state)
  end

  def handle_info({:sub, event}, state) do
    buf =
      event
      |> parse_many_events()
      |> GenStageBuffer.store_many(state.buf)

    state = %{state | buf: buf}
    noreply_push_events(state)
  end

  # Impl

  def noreply_push_events(state, demand \\ 0) do
    {buf, events} = GenStageBuffer.load(state.buf, demand)
    state = %{state | buf: buf}
    {:noreply, events, state}
  end

  def subscribe(client, channel) do
    JsonRpc2Client.call(client, "public/subscribe", %{channels: [channel]})
  end

  def parse_many_events(%{"params" => %{"data" => events}}) do
    events
    |> Enum.map(&parse_event/1)
  end

  def parse_many_events(_else), do: []

  def parse_event(event) do
    %{
      trade_id: event["trade_id"],
      price: event["price"] |> Decimal.from_float(),
      timestamp: event["timestamp"],
      instrument_name: event["instrument_name"]
    }
  end
end
