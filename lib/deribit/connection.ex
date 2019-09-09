defmodule Deribit.InfluxDBConnection do
  use Instream.Connection, otp_app: :deribit

  def convert_event_to(event, series_module) do
    event
    |> Map.from_struct()
    |> Enum.map(fn
      {key, %Decimal{} = v} -> {key, v |> Decimal.to_float()}
      {key, v} -> {key, v}
    end)
    |> Map.new()
    |> series_module.from_map()
  end
end
