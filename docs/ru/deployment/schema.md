# Схема взаимодействия сервисов

![img](/schemas/main_schema.svg)

:::warning
Стрелками на схеме обозначены направления движения данных
:::

Буква | Значение
-- | --
`a` | `CRUD` операции с основными сущностями [Backend](/deployment/dependencies/backend)
`b` | MQTT взаимодействие: [Backend](/deployment/dependencies/backend) настраивает [EMQX](/deployment/dependencies/emqx) через REST, [Backend](/deployment/dependencies/backend) подписывается на топики по паттерну `example.com/+/+/+/pepeunit`
`c` | `CRUD` операции: над [DataPipe](/deployment/dependencies/datapipe) данными и логами Unit
`d` | `Read Write` операции: установка [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe) токена для [EMQX](/deployment/dependencies/emqx), привязка Telegram к [Пользователю](/development-pepeunit/mechanics/roles#user) в Telegram Bot, авторизация [Grafana](/deployment/dependencies/grafana), хранилище состояний для Telegram Bot, передача команд изменения конфигурации для [DataPipe](/deployment/dependencies/datapipe)
`e` | `Read` операции: авторизация [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe)
`f` | Множественный `UPDATE` для состояний UnitNode, запрос UnitNode с включенным [DataPipe](/deployment/dependencies/datapipe)
`g` | MQTT взаимодействие: [DataPipe](/deployment/dependencies/datapipe) подписывается на топики по паттерну `example.com/+/pepeunit`
`h` | Множественные `INSERT` для данных UnitNode, вызов массового `DELETE` для `n_last_entry`
`i` | `Read` операции: получение команд изменения конфигурации от [Backend](/deployment/dependencies/backend)
`j` | REST
`k` | REST
`L` | REST
`m` | REST
`n` | REST
`o` | `Any Programming Lang`
`p` | REST
`q` | `/var/run/docker.sock:ro` + `/var/lib/docker/containers:ro`
`r` | `/var/run/docker.sock:ro`