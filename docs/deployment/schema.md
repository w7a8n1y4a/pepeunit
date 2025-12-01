# Схема взаимодействия сервисов

![img](/schemas/main_schema.svg)

:::warning
Стрелками на схеме обозначены направления движения данных
:::

Буква | Значение
-- | --
`a` | `CRUD` операции с основными сущностями [Backend](/definitions#backend)
`b` | `MQTT` взаимодействие: [Backend](/definitions#backend) настраивает [EMQX MQTT Broker](/definitions#mqtt-broker) через [REST](/definitions#rest), [Backend](/definitions#backend) подписывается на топики по паттерну `example.com/+/+/+/pepeunit`
`c` | `CRUD` операции: над [DataPipe](/definitions#datapipe) данными и логами `Unit`
`d` | `Read Write` операции: установка [Backend](/definitions#backend) и [DataPipe](/definitions#datapipe) токена для [EMQX MQTT Broker](/definitions#mqtt-broker), верификация пользователей `Telegram`, авторизация [Grafana](/deployment/dependencies/grafana), хранилище состояний для `Telegram Bot`, передача команд изменения конфигурации для [DataPipe](/definitions#datapipe)
`e` | `Read` операции: авторизация [Backend](/definitions#backend) и [DataPipe](/definitions#datapipe)
`f` | Множественный `UPDATE` для состояний [UnitNode](/definitions#unitnode), запрос [UnitNode](/definitions#unitnode) с включеным [DataPipe](/definitions#datapipe)
`g` | `MQTT` взаимодействие: [DataPipe](/definitions#datapipe) подписывается на топики по паттерну `example.com/+/pepeunit`
`h` | Множественные `INSERT` для данных [UnitNode](/definitions#unitnode), вызов массового `DELETE` для `n_last_entry`
`i` | `Read` операции: получение команд изменения конфигурации от [Backend](/definitions#backend)
`j` | [REST](/definitions#rest)
`k` | [REST](/definitions#rest)
`L` | [REST](/definitions#rest)
`m` | [REST](/definitions#rest)
`n` | [REST](/definitions#rest)
`o` | `Any Programming Lang`
`p` | [REST](/definitions#rest)
`q` | `/var/run/docker.sock:ro` + `/var/lib/docker/containers:ro`
`r` | `/var/run/docker.sock:ro`