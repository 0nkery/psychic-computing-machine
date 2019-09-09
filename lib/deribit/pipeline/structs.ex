defmodule Deribit.Pipeline.Block do
  @moduledoc """
  Структура для хранения Open/High/Low/Close-данных по инструменту.
  """

  @enforce_keys [:open, :high, :low, :close, :timestamp, :open_timestamp, :close_timestamp]

  defstruct [
    :open,
    :high,
    :low,
    :close,
    :timestamp,
    :open_timestamp,
    :close_timestamp
  ]
end

defmodule Deribit.Pipeline.Event do
  @enforce_keys [:trade_id, :price, :datetime, :timestamp, :instrument_name]
  defstruct [:trade_id, :price, :datetime, :timestamp, :instrument_name]
end
