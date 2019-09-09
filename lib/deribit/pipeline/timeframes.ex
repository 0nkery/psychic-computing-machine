defmodule Deribit.Pipeline.Timeframes do
  @moduledoc """
  Описание производных таймфреймов.
  """

  def ohlc_continuous_query(database_name, source, granularity) do
    """
    CREATE CONTINUOUS QUERY "cq_ohlc_#{granularity}" ON "#{database_name}"
    BEGIN
      SELECT last(close) AS close, max(high) AS high, min(low) AS low, first(open) AS open
      INTO ohlc_#{granularity}
      FROM #{source}
      GROUP BY time(#{granularity})
    END
    """
  end

  def frame_queries do
    database_name =
      :deribit
      |> Application.get_env(Deribit.InfluxDBConnection)
      |> Keyword.get(:database)

    source = "ohlc_1m"

    granularities = [
      "5m",
      "1h",
      "4h",
      "1d",
      "1w"
    ]

    granularities
    |> Enum.map(fn g ->
      ohlc_continuous_query(database_name, source, g)
    end)
  end
end
