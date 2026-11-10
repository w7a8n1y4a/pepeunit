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

Позволяет создать синтетическую нагрузку в виде Unit, отправляющих MQTT сообщения. Дополнительные [ENV переменные Backend](/deployment/env-variables/backend) позволяют настроить нагрузку:

Переменная | По умолчанию | Значения | Что делает
-- | -- | -- | --
`PU_TEST_LOAD_MQTT_DURATION` | `120` | `1`–`3600` | Время выполнения теста в секундах
`PU_TEST_LOAD_MQTT_UNIT_COUNT` | `100` | `1`–`1024` | Число Unit, которые будут выполнять запросы
`PU_TEST_LOAD_MQTT_RPS` | `200` | `1`–`1024` | Нагрузка, которую будет создавать каждый Unit
`PU_TEST_LOAD_MQTT_VALUE_TYPE` | `Text` | `Text` / `Number` | Тип отправляемых значений
`PU_TEST_LOAD_MQTT_DUPLICATE_COUNT` | `10` | `1`–`32` | Число повторяющихся сообщений подряд
`PU_TEST_LOAD_MQTT_MESSAGE_SIZE` | `15` | `1`–`512` | Размер MQTT сообщений в символах
`PU_TEST_LOAD_MQTT_POLICY_TYPE` | `TimeWindow` | `LastValue` / `NRecords` / `TimeWindow` / `Aggregation` | Тип политики [DataPipe](/deployment/dependencies/datapipe) для обработки всех сообщений в тесте
`PU_TEST_LOAD_MQTT_WORKERS` | `10` | `1`–`128` | Число процессов `multiprocessing`, создающих нагрузку

:::danger
[Backend](/deployment/dependencies/backend) использует всегда только `1` воркер `Gunicorn` для обработки MQTT сообщений. Он способен обработать `~4000 rps` сообщений из системных топиков `domain.com/+/+/+/pepeunit`. Для топиков [DataPipe](/deployment/dependencies/datapipe) c паттерном `domain.com/+/pepeunit` количество сообщений может составлять `~25000 rps`, так как они обрабатываются через `Golang`.
:::

## Тестирование REST

Команда для запуска:
```bash
make test-load-rest
```
или
```bash
uv run locust -f tests/load/locustfile.py
```

Позволяет создать синтетическую нагрузку на публичные ручки Instance. Дополнительные [ENV переменные Backend](/deployment/env-variables/backend):

Переменная | По умолчанию | Значения | Что делает
-- | -- | -- | --
`LOCUST_HEADLESS` | `True` | `True` / `False` | `CLI` формат работы `locust`
`LOCUST_USERS` | `400` | `1`–`8192` | Число виртуальных [Пользователей](/development-pepeunit/mechanics/roles#user), которые будут создавать нагрузку
`LOCUST_SPAWN_RATE` | `10` | `1`–`8192` | Нарастание числа виртуальных [Пользователей](/development-pepeunit/mechanics/roles#user) в секунду. При значениях по умолчанию `400` пользователей появятся за `40` секунд
`LOCUST_RUN_TIME` | `120` | `1`–`3600` | Время выполнения теста в секундах

:::info
По умолчанию проверяются публичные ручки текущего инстанса:

- `GET /pepeunit/api/v1/instances/current`
- `GET /pepeunit/api/v1/peers`
- `GET /pepeunit/api/v1/peers/urls`
- `GET /pepeunit/api/v1/peers/repos`
- `GET /pepeunit/api/v1/error_codes`

Ручки списков вызываются со случайными параметрами `offset`, `limit` и `trust_status`.
:::

:::warning
Время ожидания клиентом до отправки следующего запроса составляет `1` секунду, соответственно `rps ~= числу пользователей`. Каждый виртуальный пользователь случайно выбирает одну из ручек
:::

