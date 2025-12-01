# DataPipe

Имеет два определения:

1. `DataPipe` как cервис [Backend](/deployment/dependencies/backend) - отвечает за получение информации из топиков с паттерном `example.com/+/pepeunit` и фильтрацию получаемых из них данных для сохранения в [Clickhouse](/deployment/dependencies/clickhouse) и [Postgresql](/deployment/dependencies/postgresql). [Подробнее о переменных окружения](/deployment/env-variables/data-pipe)
1. `DataPipe` как парадигма обработки данных - состоит из конфигурации [YML](#yml) и предназначен для производительного накопления данных из топиков [UnitNode](/definitions#unitnode) согласно настройкам из [YML](#yml). У [Pepeunit](/conception/overview) есть глубокая интеграция с [Grafana](/deployment/dependencies/grafana) для визуализации данных из `DataPipe`. [Подробнее о настройке DataPipe](/user/data-pipe#datapipe)
