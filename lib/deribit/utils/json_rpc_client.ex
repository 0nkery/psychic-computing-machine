defmodule Deribit.Utils.JsonRpc2Client do
  @moduledoc """
  Простейший JSON-RPC2-клиент.
  """

  use WebSockex

  require Logger

  defmodule State do
    @enforce_keys [:forward_to]
    defstruct [:forward_to, inflight_requests: %{}]
  end

  # Interface

  def start_link(url, opts \\ []) do
    {forward_to, opts} = opts |> Keyword.pop(:forward_to, self())
    state = %State{forward_to: forward_to}
    WebSockex.start_link(url, __MODULE__, state, opts)
  end

  def cast(client, method, params) do
    from = self()

    id =
      DateTime.utc_now()
      |> DateTime.to_unix(:nanosecond)

    WebSockex.cast(client, {:call, %{method: method, params: params, id: id, from: from}})

    id
  end

  def call(client, method, params, timeout \\ 5000) do
    id = cast(client, method, params)

    receive do
      {^id, reply} ->
        reply

      msg ->
        {:error, {:unexpected_message, msg}}
    after
      timeout ->
        {:error, :timeout}
    end
  end

  # Impl

  @impl true
  def handle_cast({:call, msg}, state) do
    {from, msg} = msg |> Map.pop(:from)

    case msg |> Jason.encode() do
      {:ok, frame} ->
        state =
          Map.update(state, :inflight_requests, %{}, fn rqs ->
            rqs
            |> Map.put(msg.id, from)
          end)

        {:reply, {:text, frame}, state}

      {:error, reason} ->
        send(from, {msg.id, {:error, reason}})
        {:ok, state}
    end
  end

  @impl true
  def handle_frame({:text, frame}, state) do
    case Jason.decode(frame) do
      {:ok, %{"id" => id} = frame} ->
        case state.inflight_requests |> Map.pop(id, :none) do
          {:none, _inflight_requests} ->
            Logger.error("Unknown id of inflight request:\n#{inspect(frame)}")
            {:ok, state}

          {reply_to, inflight_requests} ->
            send(reply_to, {id, {:ok, frame}})
            state = %{state | inflight_requests: inflight_requests}
            {:ok, state}
        end

      {:ok, %{"method" => "subscription"} = frame} ->
        send(state.forward_to, {:sub, frame})
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to decode incoming frame: #{inspect(reason)}.\n#{frame}")
        {:ok, state}
    end
  end
end
