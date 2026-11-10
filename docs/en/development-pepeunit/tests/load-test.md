# Load tests - Backend

Load tests are part of the [Backend](/deployment/dependencies/backend) repository: they check whether it withstands a given number of requests per second. The tests work with an already running instance at the `PU_DOMAIN` address, so run them on a test instance.

## MQTT testing

Command to run:
```bash
make test-load-mqtt
```
or
```bash
uv run python -m tests.load.load_test_mqtt
```

It creates synthetic load in the form of `Unit`s sending MQTT messages. Additional [Backend ENV variables](/deployment/env-variables/backend) let you tune the load:

Variable | Default | Values | What it does
-- | -- | -- | --
`PU_TEST_LOAD_MQTT_DURATION` | `120` | `1`–`3600` | Test duration in seconds
`PU_TEST_LOAD_MQTT_UNIT_COUNT` | `100` | `1`–`1024` | Number of `Unit`s that will make requests
`PU_TEST_LOAD_MQTT_RPS` | `200` | `1`–`1024` | Load that each `Unit` will create
`PU_TEST_LOAD_MQTT_VALUE_TYPE` | `Text` | `Text` / `Number` | Type of the values sent
`PU_TEST_LOAD_MQTT_DUPLICATE_COUNT` | `10` | `1`–`32` | Number of duplicate messages in a row
`PU_TEST_LOAD_MQTT_MESSAGE_SIZE` | `15` | `1`–`512` | Size of MQTT messages in characters
`PU_TEST_LOAD_MQTT_POLICY_TYPE` | `TimeWindow` | `LastValue` / `NRecords` / `TimeWindow` / `Aggregation` | [DataPipe](/deployment/dependencies/datapipe) policy type for processing all messages in the test
`PU_TEST_LOAD_MQTT_WORKERS` | `10` | `1`–`128` | Number of `multiprocessing` processes creating the load

The test publishes messages to [DataPipe](/deployment/dependencies/datapipe) topics with the pattern `domain.com/<uuid>/pepeunit`, so the load is received by the `Golang` DataPipe process, not by Python. The system topics `domain.com/+/+/+/pepeunit` (`Unit` state and logs) are handled by the Backend itself, and their throughput is noticeably lower. While the test is running, it checks once a second that the Backend is still subscribed to MQTT, and if the subscription is lost it writes `Backend crash` and stops. At the end the test prints `Backend sustained N rps`: compare this number with the given `PU_TEST_LOAD_MQTT_RPS * PU_TEST_LOAD_MQTT_UNIT_COUNT`.

## REST testing

Command to run:
```bash
make test-load-rest
```
or
```bash
uv run locust -f tests/load/locustfile.py
```

It creates synthetic load on the public endpoints of the Instance. Additional [Backend ENV variables](/deployment/env-variables/backend):

Variable | Default | Values | What it does
-- | -- | -- | --
`LOCUST_HEADLESS` | `True` | `True` / `False` | `CLI` mode of `locust`
`LOCUST_USERS` | `400` | `1`–`8192` | Number of virtual [Users](/development-pepeunit/mechanics/roles#user) that will create the load
`LOCUST_SPAWN_RATE` | `10` | `1`–`8192` | Growth in the number of virtual `User`s per second. With the default values, `400` users appear in `40` seconds
`LOCUST_RUN_TIME` | `120` | `1`–`3600` | Test duration in seconds

By default, the public endpoints of the current instance are checked:

- `GET /pepeunit/api/v1/instances/current`
- `GET /pepeunit/api/v1/peers`
- `GET /pepeunit/api/v1/peers/urls`
- `GET /pepeunit/api/v1/peers/repos`
- `GET /pepeunit/api/v1/error_codes`

List endpoints are called with random `offset`, `limit` and `trust_status` parameters. Each virtual user picks one of the endpoints at random. The time the client waits before sending the next request is `1` second, so `rps ~= number of users`.

