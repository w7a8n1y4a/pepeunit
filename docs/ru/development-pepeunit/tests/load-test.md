# Нагрузочные тесты - Backend

:::info
Нагрузочные тесты - это часть репозитория [Backend](/deployment/dependencies/backend), единственная задача которой - проверка, выдерживает ли [Backend](/deployment/dependencies/backend) заданное число запросов в секунду.
:::

## Тестирование MQTT

Команда для запуска:
```bash
make test-load-mqtt
```
или
```bash
uv run python -m tests.load.load_test_mqtt
```

Позволяет создать синтетическую нагрузку в виде [Unit](/definitions#unit), отправляющих [MQTT](/definitions#mqtt) сообщения. Дополнительные [ENV переменные Backend](/deployment/env-variables/backend) позволяют настроить нагрузку:

Переменная | По умолчанию | Значения | Что делает
-- | -- | -- | --
`PU_TEST_LOAD_MQTT_DURATION` | `120` | `1`–`3600` | Время выполнения теста в секундах
`PU_TEST_LOAD_MQTT_UNIT_COUNT` | `100` | `1`–`1024` | Число [Unit](/definitions#unit), которые будут выполнять запросы
`PU_TEST_LOAD_MQTT_RPS` | `200` | `1`–`1024` | Нагрузка, которую будет создавать каждый [Unit](/definitions#unit)
`PU_TEST_LOAD_MQTT_VALUE_TYPE` | `Text` | `Text` / `Number` | Тип отправляемых значений
`PU_TEST_LOAD_MQTT_DUPLICATE_COUNT` | `10` | `1`–`32` | Число повторяющихся сообщений подряд
`PU_TEST_LOAD_MQTT_MESSAGE_SIZE` | `15` | `1`–`512` | Размер [MQTT](/definitions#mqtt) сообщений в символах
`PU_TEST_LOAD_MQTT_POLICY_TYPE` | `TimeWindow` | `LastValue` / `NRecords` / `TimeWindow` / `Aggregation` | Тип политики [DataPipe](/deployment/dependencies/datapipe) для обработки всех сообщений в тесте
`PU_TEST_LOAD_MQTT_WORKERS` | `10` | `1`–`128` | Число процессов `multiprocessing`, создающих нагрузку

:::danger
[Backend](/deployment/dependencies/backend) использует всегда только `1` воркер `Gunicorn` для обработки [MQTT](/definitions#mqtt) сообщений. Он способен обработать `~4000 rps` сообщений из системных топиков `domain.com/+/+/+/pepeunit`. Для топиков [DataPipe](/deployment/dependencies/datapipe) c паттерном `domain.com/+/pepeunit` количество сообщений может составлять `~25000 rps`.
:::

## Тестирование REST и GQL

Команда для запуска:
```bash
make test-load-rest
```
или
```bash
uv run locust -f tests/load/locustfile.py
```

Позволяет создать синтетическую нагрузку на публичные ручки [Instance](/definitions#instance). Дополнительные [ENV переменные Backend](/deployment/env-variables/backend):

Переменная | По умолчанию | Значения | Что делает
-- | -- | -- | --
`LOCUST_HEADLESS` | `True` | `True` / `False` | `CLI` формат работы `locust`
`LOCUST_USERS` | `400` | `1`–`8192` | Число виртуальных [Пользователей](/development-pepeunit/mechanics/roles#user), которые будут создавать нагрузку
`LOCUST_SPAWN_RATE` | `10` | `1`–`8192` | Нарастание числа виртуальных [Пользователей](/development-pepeunit/mechanics/roles#user) в секунду. При значениях по умолчанию `400` пользователей появятся за `40` секунд
`LOCUST_RUN_TIME` | `120` | `1`–`3600` | Время выполнения теста в секундах

:::info
По умолчанию проверяются публичные ручки текущего инстанса:

- `GET /pepeunit/api/v1/instances/current`
- `GET /pepeunit/api/v1/instances`
- `POST /pepeunit/graphql` - `getInstancesUrls`
- `POST /pepeunit/graphql` - `getInstancesRegistries`
:::

:::warning
Время ожидания клиентом до отправки следующего запроса составляет `1` секунду, соответственно `rps ~= числу пользователей`. Нагрузка делится между REST и GQL классами пользователей
:::

:::danger
[REST](/definitions#rest) и [GQL](/definitions#gql) запросы обрабатываются многопоточно, увеличение числа воркеров почти линейно увеличивает число обрабатываемых запросов в единицу времени. `4` воркера `Gunicorn` выдерживают `~400rps` без перезагрузок. Процентили в миллисекундах:
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
:::
