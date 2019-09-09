import Config

config :logger, level: :debug

config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:application, :query_time, :response_status]

config :deribit, Deribit.InfluxDBConnection,
  database: "stock",
  host: "localhost",
  http_opts: [insecure: true],
  pool: [max_overflow: 10, size: 50],
  port: 8086,
  scheme: "http",
  writer: Instream.Writer.Line

if File.exists?(__ENV__.file |> Path.dirname() |> Path.join("local.exs")) do
  import_config "local.exs"
end
