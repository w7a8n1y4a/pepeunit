# DataPipe

## DataPipe как cервис Backend

Высокопроизводительный обработчик данных написанный на [Golang](/definitions#golang) - отвечает за получение информации из топиков с паттерном `example.com/+/pepeunit` и фильтрацию получаемых из них данных для сохранения в [Clickhouse](/deployment/dependencies/clickhouse) и [Postgresql](/deployment/dependencies/postgresql).

:::info
[Подробнее о переменных окружения](/deployment/env-variables/data-pipe)
:::


## DataPipe как парадигма обработки данных

Состоит из инструкции по обработке данных в формате [YML](#yml) - предназначен для производительного накопления данных из топиков [UnitNode](/definitions#unitnode).

У [Pepeunit](/conception/overview) есть глубокая интеграция с [Grafana](/deployment/dependencies/grafana) для визуализации данных из `DataPipe`.

:::info
[Подробнее о настройке DataPipe](/user/data-pipe#datapipe)
:::
