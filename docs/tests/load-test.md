# Нагрузочные тесты - Backend

[Подробнее о развёртывании нагрузочного репозитория](https://git.pepemoss.com/pepe/pepeunit/pepeunit_load_check.git)

## Тестирование MQTT

```bash
python load_test.py --url "https://localunit.pepeunit.com" --duration 120 --type mqtt --unit-count 40 --rps 100 --workers 10 --mqtt-admin "admin" --mqtt-password "password"
```

Позволяет создать синтетическую нагрузку в виде [Unit](/definitions#unit), отправляющих [MQTT](/definitions#mqtt) сообщения со следующими параметрами:
Параметр | Что делает ?
-- | --
`--url` | Ссылка на [Backend](/definitions#backend)
`--duration` | Время выполнения теста в секундах
`--type` | Тип - `mqtt`
`--unit-count` | Число [Unit](/definitions#unit) которые будут выполнять запросы
`--rps` | Нагрузка которую будет создавать каждый [Unit](/definitions#unit)
`--duplicate-count` | Число повторяюшихся сообщений подряд
`--message-size` | Размер [MQTT](/definitions#mqtt) сообщений в символах
`--workers` | Число процессов `multiprocessing` создающих нагрузку
`--mqtt-admin` | Имя администратора [EMQX MQTT Broker](/definitions#mqtt-broker), позволяет тесту, самому отследить момент, когда [Backend](/definitions#backend) отключится от привышения нагрузки
`--mqtt-password` | Пароль администратора [EMQX MQTT Broker](/definitions#mqtt-broker), позволяет тесту, самому отследить момент, когда [Backend](/definitions#backend) отключится от привышения нагрузки

:::danger
[Backend](/definitions#backend) использует только `1` воркер `Gunicorn` для обработки [MQTT](/definitions#mqtt) сообщений. Он способен обработать `~4000rps` пользовательских топиков `domain.com/+/pepeunit`.
:::

## Тестирование REST и GQL

Позволяет создать синтетическую нагрузку в виде [GQL](/definitions#gql) и [REST](/definitions#rest) запросов, на наиболее нагруженные участки:

```bash
locust -H "https://localunit.pepeunit.com" --headless -u 400 -r 10 --run-time 2m
```

Параметр | Что делает ?
-- | --
`-H` | Ссылка на Бэкенд
`--headless` | `CLI` формат работы `locust`
`-u` | Число пользователей, которые будут создавать нагрузку
`-r` | Нарастание числа пользователей, от `0` до `400`, c шагом `10`, т.е. нарастание нагрузки займёт `~= 40 секунд`
`--run-time` | Время выполнения теста

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
[REST](/definitions#rest) и [GQL](/definitions#gql) запросы обрабатываются многопоточно, увеличение числа вокеров, почти линейно увеличивает число обрабатываемых запросов в еденицу времени. `4` воркера `Gunicorn` выдерживают `~400rps` без перезагрузок. Процентили в миллисекундах:
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