# Load tests - Backend

::::info
Load tests are a part of the [Backend](/en/deployment/dependencies/backend) repository whose only task is to verify whether the [Backend](/en/deployment/dependencies/backend) can handle a given number of requests per second.
::::

## MQTT testing

Run command:
```bash
make test-load-mqtt
```
or
```bash
uv run python -m tests.load.load_test_mqtt
```

This creates synthetic load in the form of [Unit](/en/definitions#unit) instances that send [MQTT](/en/definitions#mqtt) messages. Additional [Backend ENV variables](/en/deployment/env-variables/backend) let you configure the load:

Variable | Default | Values | Purpose
-- | -- | -- | --
`PU_TEST_LOAD_MQTT_DURATION` | `120` | `1`–`3600` | Test duration in seconds
`PU_TEST_LOAD_MQTT_UNIT_COUNT` | `100` | `1`–`1024` | Number of [Unit](/en/definitions#unit) instances that will send requests
`PU_TEST_LOAD_MQTT_RPS` | `200` | `1`–`1024` | Load that each [Unit](/en/definitions#unit) will generate
`PU_TEST_LOAD_MQTT_VALUE_TYPE` | `Text` | `Text` / `Number` | Type of sent values
`PU_TEST_LOAD_MQTT_DUPLICATE_COUNT` | `10` | `1`–`32` | Number of consecutive duplicate messages
`PU_TEST_LOAD_MQTT_MESSAGE_SIZE` | `15` | `1`–`512` | Size of [MQTT](/en/definitions#mqtt) messages in characters
`PU_TEST_LOAD_MQTT_POLICY_TYPE` | `TimeWindow` | `LastValue` / `NRecords` / `TimeWindow` / `Aggregation` | [DataPipe](/en/deployment/dependencies/datapipe) policy type for processing all messages in the test
`PU_TEST_LOAD_MQTT_WORKERS` | `10` | `1`–`128` | Number of `multiprocessing` worker processes creating the load

::::danger
The [Backend](/en/deployment/dependencies/backend) always uses only `1` `Gunicorn` worker to process [MQTT](/en/definitions#mqtt) messages. It can handle about `~4000 rps` for system topics `domain.com/+/+/+/pepeunit`. For [DataPipe](/en/deployment/dependencies/datapipe) topics with the pattern `domain.com/+/pepeunit`, the throughput can reach `~25000 rps`.
::::

## REST and GQL testing

Run command:
```bash
make test-load-rest
```
or
```bash
uv run locust -f tests/load/locustfile.py
```

This creates synthetic load against the public [Instance](/en/definitions#instance) endpoints. Additional [Backend ENV variables](/en/deployment/env-variables/backend):

Variable | Default | Values | Purpose
-- | -- | -- | --
`LOCUST_HEADLESS` | `True` | `True` / `False` | `CLI` mode for running `locust`
`LOCUST_USERS` | `400` | `1`–`8192` | Number of virtual [Users](/en/development-pepeunit/mechanics/roles#user) that will generate load
`LOCUST_SPAWN_RATE` | `10` | `1`–`8192` | Ramp-up of virtual [Users](/en/development-pepeunit/mechanics/roles#user) per second. With the default values, `400` users appear in `40` seconds
`LOCUST_RUN_TIME` | `120` | `1`–`3600` | Test duration in seconds

::::info
By default the public endpoints of the current instance are tested:

- `GET /pepeunit/api/v1/instances/current`
- `GET /pepeunit/api/v1/instances`
- `POST /pepeunit/graphql` - `getInstancesUrls`
- `POST /pepeunit/graphql` - `getInstancesRegistries`
::::

::::warning
Client wait time before sending the next request is `1` second, therefore `rps ~= number of users`. The load is split between REST and GQL user classes
::::

::::danger
[REST](/en/definitions#rest) and [GQL](/en/definitions#gql) requests are processed in multiple threads; increasing the number of workers almost linearly increases the number of requests processed per unit time. `4` `Gunicorn` workers can handle `~400 rps` without restarts. Percentiles in milliseconds:
```
Type     Name                                    50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
GET      /pepeunit/api/v1/instances              11     14     17     19     28     44     82    110    260    550    550   9600
GET      /pepeunit/api/v1/instances/current      11     14     16     18     27     41     78    110    290    400    400   9697
POST     gql:getInstancesRegistries              12     15     17     19     26     38     62     84    200    540    540   9614
POST     gql:getInstancesUrls                    12     14     17     18     27     40     64     93    350    540    540   9686
--------|------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                              12     14     17     19     27     41     71    100    260    540    550  38597
```
::::
