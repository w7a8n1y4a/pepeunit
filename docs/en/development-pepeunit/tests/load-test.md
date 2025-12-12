# Load tests - Backend

::::info
Load tests are a part of the [Backend](/en/deployment/dependencies/backend) repository whose only task is to verify whether the [Backend](/en/deployment/dependencies/backend) can handle a given number of requests per second.
::::

## MQTT testing

Run command:
```bash
python -m tests.load.load_test_mqtt
```

This creates synthetic load in the form of [Unit](/en/definitions#unit) instances that send [MQTT](/en/definitions#mqtt) messages. Additional [Backend ENV variables](/en/deployment/env-variables/backend) let you configure the load using the following parameters:

Backend variable | What it does
-- | --
`PU_TEST_LOAD_MQTT_DURATION` | Test duration in seconds
`PU_TEST_LOAD_MQTT_UNIT_COUNT` | Number of [Unit](/en/definitions#unit) instances that will send requests
`PU_TEST_LOAD_MQTT_RPS` | Load (RPS) that each [Unit](/en/definitions#unit) will generate
`PU_TEST_LOAD_MQTT_VALUE_TYPE` | Type of sent variables: `Text` or `Number`
`PU_TEST_LOAD_MQTT_DUPLICATE_COUNT` | Number of consecutive duplicate messages
`PU_TEST_LOAD_MQTT_MESSAGE_SIZE` | Size of [MQTT](/en/definitions#mqtt) messages in characters
`PU_TEST_LOAD_MQTT_POLICY_TYPE` | Policy type for processing all messages in the test: `LastValue`, `NRecords`, `TimeWindow`, `Aggregation`
`PU_TEST_LOAD_MQTT_WORKERS` | Number of `multiprocessing` worker processes creating the load

::::danger
The [Backend](/en/deployment/dependencies/backend) always uses only `1` `Gunicorn` worker to process [MQTT](/en/definitions#mqtt) messages. It can handle about `~4000 rps` for system topics `domain.com/+/+/+/pepeunit`. For [DataPipe](/en/deployment/dependencies/datapipe) topics with the pattern `domain.com/+/pepeunit`, the throughput can reach `~25000 rps`.
::::

## REST and GQL testing

Run command:
```bash
locust -f tests/load/locustfile.py
```

This creates synthetic load in the form of [GQL](/en/definitions#gql) and [REST](/en/definitions#rest) requests to the most heavily loaded endpoints. Additional [Backend ENV variables](/en/deployment/env-variables/backend) let you configure the load using the following parameters:

Backend variable | What it does
-- | --
`LOCUST_HEADLESS` | `CLI` mode for running `locust`
`LOCUST_USERS` | Number of [Users](/en/development-pepeunit/mechanics/roles.html#user) that will generate load
`LOCUST_SPAWN_RATE` | Ramp-up rate for [Users](/en/development-pepeunit/mechanics/roles.html#user) from `0` to `400` with a step of `10`, i.e. the ramp-up will take `~= 40 seconds`
`LOCUST_RUN_TIME` | Test duration in seconds

::::info
By default the following endpoints are tested:

- https://domian.com/pepeunit/api/v1/metrics/
- https://domian.com/pepeunit
- https://domian.com/pepeunit/graphql - `getBaseMetrics`
::::

::::warning
Client wait time before sending a request is `1 second`, therefore `rps ~= number of users`.
::::

::::danger
[REST](/en/definitions#rest) and [GQL](/en/definitions#gql) requests are processed in multiple threads; increasing the number of workers almost linearly increases the number of requests processed per unit time. `4` `Gunicorn` workers can handle `~400 rps` without restarts. Percentiles in milliseconds:
```bash
Type     Name                             50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|---------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
GET      /pepeunit                          6      8     10     11     19     31     54     73    180    230    240  13227
GET      /pepeunit/api/v1/metrics/         14     18     21     24     33     45     64     82    180    230    270  13126
POST     /pepeunit/graphql                 10     12     14     16     24     38     60     72    150    270    290  13257
--------|---------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                        10     13     16     18     27     39     60     75    180    270    290  39610
```
::::


