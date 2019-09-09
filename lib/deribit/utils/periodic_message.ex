defmodule Deribit.Utils.PeriodicMessage do
  @moduledoc """
  Небольшой helper для периодических тасков. Сохраняет интервал
  и возвращает ссылку на сообщение, которое триггерит выполнение таска.
  Сообщения отправляются обычным образом - то есть, нужно обрабатывать
  их с помощью `handle_info/2` внутри `GenServer`, `GenStage` и так далее.
  """
  defstruct [:ref, :interval]

  def new(interval) do
    %__MODULE__{
      ref: :erlang.make_ref() |> :erlang.ref_to_list() |> :erlang.list_to_atom(),
      interval: interval
    }
  end

  @doc """
  Планирует отправку сообщения через заданный интервал.
  """
  def schedule(msg) do
    Process.send_after(self(), msg, msg.interval)
  end

  @doc """
  Планирует отправку сообщения через кастомный интервал.
  Первоначальный интервал не меняется.
  """
  def schedule(msg, interval) do
    Process.send_after(self(), msg, interval)
  end

  @doc """
  Отправляет следующее сообщение прямо сейчас.
  """
  def right_now(msg) do
    send(self(), msg)
  end
end
