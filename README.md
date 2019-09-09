# psychic-computing-machine

In order to run application run the following commands:

```bash
# Run InfluxDB
docker-compose up -d
# Fetch dependencies
mix deps.get
# Run app
mix run --no-halt
```


## Data layout

Timeframes are stored in series

* ohlc_1m - data with 1 minute resolution. This is the base timeframe for every other one.
* ohlc_5m - 5 minute resolution. This timeframe is implemented as continuous query (or view in SQL parlance).
* ohlc_4h - 4 hours resolution. This timeframe is implemented as continuous query (or view in SQL parlance).
* ohlc_1d - 1 day resolution. This timeframe is implemented as continuous query (or view in SQL parlance).
* ohlc_1w - 1 week resolution. This timeframe is implemented as continuous query (or view in SQL parlance).
