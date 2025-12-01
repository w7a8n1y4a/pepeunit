# Схема взаимодействия сервисов

![img](/schemas/main_schema.svg)

:::warning
Стрелками на схеме обозначены направления движения данных
:::

Буква | Значение
-- | --
`a` | `CRUD` операции с основными сущностями [Backend](/deployment/dependencies/backend)
`b` | `MQTT` взаимодействие: [Backend](/deployment/dependencies/backend) настраивает [EMQX](/deployment/dependencies/emqx) через [REST](/definitions#rest), [Backend](/deployment/dependencies/backend) подписывается на топики по паттерну `example.com/+/+/+/pepeunit`
`c` | `CRUD` операции: над [DataPipe](/deployment/dependencies/datapipe) данными и логами `Unit`
`d` | `Read Write` операции: установка [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe) токена для [EMQX](/deployment/dependencies/emqx), верификация пользователей в [Telegram Bot](/definitions#telegram-bot), авторизация [Grafana](/deployment/dependencies/grafana), хранилище состояний для [Telegram Bot](/definitions#telegram-bot), передача команд изменения конфигурации для [DataPipe](/deployment/dependencies/datapipe)
`e` | `Read` операции: авторизация [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe)
`f` | Множественный `UPDATE` для состояний [UnitNode](/definitions#unitnode), запрос [UnitNode](/definitions#unitnode) с включеным [DataPipe](/deployment/dependencies/datapipe)
`g` | `MQTT` взаимодействие: [DataPipe](/deployment/dependencies/datapipe) подписывается на топики по паттерну `example.com/+/pepeunit`
`h` | Множественные `INSERT` для данных [UnitNode](/definitions#unitnode), вызов массового `DELETE` для `n_last_entry`
`i` | `Read` операции: получение команд изменения конфигурации от [Backend](/deployment/dependencies/backend)
`j` | [REST](/definitions#rest)
`k` | [REST](/definitions#rest)
`L` | [REST](/definitions#rest)
`m` | [REST](/definitions#rest)
`n` | [REST](/definitions#rest)
`o` | `Any Programming Lang`
`p` | [REST](/definitions#rest)
`q` | `/var/run/docker.sock:ro` + `/var/lib/docker/containers:ro`
`r` | `/var/run/docker.sock:ro`