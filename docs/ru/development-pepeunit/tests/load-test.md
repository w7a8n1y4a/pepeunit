# Нагрузочные тесты - Backend

:::info
Нагрузочные тесты - это часть репозитория [Backend](/deployment/dependencies/backend), единственная задача которой является проверка, выдерживает ли [Backend](/deployment/dependencies/backend) заданное число запросов в секунду. 
:::

## Тестирование MQTT

Команда для запуска:
```bash
python -m tests.load.load_test_mqtt
```

Позволяет создать синтетическую нагрузку в виде [Unit](/definitions#unit), отправляющих [MQTT](/definitions#mqtt) сообщения. Дополнительные [ENV переменные Backend](/deployment/env-variables/backend) позволяют настроить нагрузку по следующим параметрам:
Переменная Backend | Что делает ?
-- | --
`PU_TEST_LOAD_MQTT_DURATION` | Время выполнения теста в секундах
`PU_TEST_LOAD_MQTT_UNIT_COUNT` | Число [Unit](/definitions#unit), которые будут выполнять запросы
`PU_TEST_LOAD_MQTT_RPS` | Нагрузка, которую будет создавать каждый [Unit](/definitions#unit)
`PU_TEST_LOAD_MQTT_VALUE_TYPE` | Тип отправляемых переменных `Text` или `Number`
`PU_TEST_LOAD_MQTT_DUPLICATE_COUNT` | Число повторяющихся сообщений подряд
`PU_TEST_LOAD_MQTT_MESSAGE_SIZE` | Размер [MQTT](/definitions#mqtt) сообщений в символах
`PU_TEST_LOAD_MQTT_POLICY_TYPE` | Тип политики для обработки всех сообщений в тесте: `LastValue`, `NRecords`, `TimeWindow`, `Aggregation`
`PU_TEST_LOAD_MQTT_WORKERS` | Число процессов `multiprocessing`, создающих нагрузку

:::danger
[Backend](/deployment/dependencies/backend) использует всегда только `1` воркер `Gunicorn` для обработки [MQTT](/definitions#mqtt) сообщений. Он способен обработать `~4000 rps` сообщений из системных топиков `domain.com/+/+/+/pepeunit`. Для топиков [DataPipe](/deployment/dependencies/datapipe) c паттерном `domain.com/+/pepeunit` количество сообщений может составлять `~25000 rps`.
:::

## Тестирование REST и GQL

Команда для запуска:
```bash
locust -f tests/load/locustfile.py
```

Позволяет создать синтетическую нагрузку в виде [GQL](/definitions#gql) и [REST](/definitions#rest) запросов, на наиболее нагруженные участки. Дополнительные [ENV переменные Backend](/deployment/env-variables/backend) позволяют настроить нагрузку по следующим параметрам:

Переменная Backend | Что делает ?
-- | --
`LOCUST_HEADLESS` | `CLI` формат работы `locust`
`LOCUST_USERS` | Число [Пользователей](/development-pepeunit/mechanics/roles.html#user), которые будут создавать нагрузку
`LOCUST_SPAWN_RATE` | Нарастание числа [Пользователей](/development-pepeunit/mechanics/roles.html#user), от `0` до `400`, c шагом `10`, т.е. нарастание нагрузки займёт `~= 40 секунд`
`LOCUST_RUN_TIME` | Время выполнения теста в секундах

:::info
По умолчанию проверяются:

- https://domian.com/pepeunit/api/v1/metrics/
- https://domian.com/pepeunit
- https://domian.com/pepeunit/graphql - `getBaseMetrics`
:::

:::warning
Время ожидание клиентом, до отправки запроса составляет `1 секунду`, соответственно `rps ~= числу пользователей`
:::

:::danger
[REST](/definitions#rest) и [GQL](/definitions#gql) запросы обрабатываются многопоточно, увеличение числа вокеров, почти линейно увеличивает число обрабатываемых запросов в единицу времени. `4` воркера `Gunicorn` выдерживают `~400rps` без перезагрузок. Процентили в миллисекундах:
```bash
Type     Name                             50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|---------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
GET      /pepeunit                          6      8     10     11     19     31     54     73    180    230    240  13227
GET      /pepeunit/api/v1/metrics/         14     18     21     24     33     45     64     82    180    230    270  13126
POST     /pepeunit/graphql                 10     12     14     16     24     38     60     72    150    270    290  13257
--------|---------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                        10     13     16     18     27     39     60     75    180    270    290  39610
```
:::