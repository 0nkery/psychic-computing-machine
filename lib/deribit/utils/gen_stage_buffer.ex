defmodule Deribit.Utils.GenStageBuffer do
  @moduledoc """
  Буфер для `GenStage`, чтобы не писать везде `dispatch_events` и прочие
  однотипные операции.
  """
  defstruct [:queue, pending_demand: 0]

  def new do
    %__MODULE__{
      queue: :queue.new()
    }
  end

  @doc """
  Сохраняет в буфер событие.
  """
  @spec store(%__MODULE__{}, term()) :: %__MODULE__{}
  def store(buf, event) do
    queue = :queue.in(event, buf.queue)
    %{buf | queue: queue}
  end

  @spec store_many([term()], %__MODULE__{}) :: %__MODULE__{}
  def store_many(events, buf) do
    Enum.reduce(events, buf, fn event, buf -> store(buf, event) end)
  end

  @doc """
  Выгружает из буфера события. Возвращает обновленный буфер и список событий.
  """
  @spec load(%__MODULE__{}, Integer.t()) :: {%__MODULE__{}, [term()]}
  def load(buf, demand \\ 0) do
    {buf, events} = load(buf, buf.pending_demand + demand, [])
    events = events |> Enum.reverse()
    {buf, events}
  end

  defp load(buf, 0, events) do
    buf = %{buf | pending_demand: 0}
    {buf, events}
  end

  defp load(buf, demand, events) do
    case :queue.out(buf.queue) do
      {:empty, queue} ->
        buf = %{buf | queue: queue, pending_demand: demand}
        {buf, events}

      {{:value, event}, queue} ->
        buf = %{buf | queue: queue}
        load(buf, demand - 1, [event | events])
    end
  end
end
