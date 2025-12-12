# Service interaction schema

![img](/schemas/main_schema.svg)

::::warning
Arrows on the diagram indicate the direction of data flow.
::::

Letter | Meaning
-- | --
`a` | `CRUD` operations on the main [Backend](/en/deployment/dependencies/backend) entities
`b` | [MQTT](/en/definitions#mqtt) interaction: the [Backend](/en/deployment/dependencies/backend) configures [EMQX](/en/deployment/dependencies/emqx) via [REST](/en/definitions#rest), and subscribes to topics matching `example.com/+/+/+/pepeunit`
`c` | `CRUD` operations on [DataPipe](/en/deployment/dependencies/datapipe) data and [Unit](/en/definitions#unit) logs
`d` | `Read/Write` operations: storing the token for [EMQX](/en/deployment/dependencies/emqx) issued by [Backend](/en/deployment/dependencies/backend) and [DataPipe](/en/deployment/dependencies/datapipe), [User](/en/development-pepeunit/mechanics/roles#user) verification in the [Telegram Bot](/en/definitions#telegram-bot), [Grafana](/en/deployment/dependencies/grafana) authorization, state storage for the [Telegram Bot](/en/definitions#telegram-bot), sending configuration change commands for [DataPipe](/en/deployment/dependencies/datapipe)
`e` | `Read` operations: authorizing [Backend](/en/deployment/dependencies/backend) and [DataPipe](/en/deployment/dependencies/datapipe)
`f` | Multiple `UPDATE` operations for [UnitNode](/en/definitions#unitnode) states, [UnitNode](/en/definitions#unitnode) requests with [DataPipe](/en/deployment/dependencies/datapipe) enabled
`g` | [MQTT](/en/definitions#mqtt) interaction: [DataPipe](/en/deployment/dependencies/datapipe) subscribes to topics matching `example.com/+/pepeunit`
`h` | Multiple `INSERT` operations for [UnitNode](/en/definitions#unitnode) data and bulk `DELETE` for `n_last_entry`
`i` | `Read` operations: reading configuration change commands from the [Backend](/en/deployment/dependencies/backend)
`j` | [REST](/en/definitions#rest)
`k` | [REST](/en/definitions#rest)
`L` | [REST](/en/definitions#rest)
`m` | [REST](/en/definitions#rest)
`n` | [REST](/en/definitions#rest)
`o` | `Any Programming Lang`
`p` | [REST](/en/definitions#rest)
`q` | `/var/run/docker.sock:ro` + `/var/lib/docker/containers:ro`
`r` | `/var/run/docker.sock:ro`


