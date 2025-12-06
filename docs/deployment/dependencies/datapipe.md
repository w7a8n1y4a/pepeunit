# DataPipe

## DataPipe как cервис Backend

`DataPipe-сервис` - высокопроизводительный обработчик данных, написанный на [Golang](/definitions#golang). Отвечает за получение данных из топиков с паттерном `example.com/+/pepeunit`, с последующей их фильтрацией для сохранения в [ClickHouse](/deployment/dependencies/clickhouse) и [PostgreSQL](/deployment/dependencies/postgresql).

:::info
[Подробнее о переменных окружения](/deployment/env-variables/data-pipe)
:::


## DataPipe как парадигма обработки данных

`DataPipe` состоит из инструкции по обработке данных в формате [YML](#yml) и предназначен для производительного накопления данных из топиков [UnitNode](/definitions#unitnode).

У [Pepeunit](/conception/overview) используется глубокая интеграция с [Grafana](/deployment/dependencies/grafana) для визуализации данных из `DataPipe`.

:::info
[Настройка DataPipe](/user/datapipe/datapipe)

[Примеры DataPipe](/user/datapipe/example)

[Импорт данных в DataPipe](/user/datapipe/import)
:::