# Redis

[Redis](https://redis.io/) is a clustered `NoSQL` database that uses the `key-value` paradigm.

::::info
It is used by [Backend](/en/deployment/dependencies/backend), [DataPipe](/en/deployment/dependencies/datapipe) and [EMQX](/en/deployment/dependencies/emqx) for the following tasks:
1. Storing the token for [EMQX](/en/deployment/dependencies/emqx) issued by [Backend](/en/deployment/dependencies/backend) and [DataPipe](/en/deployment/dependencies/datapipe)
1. [Telegram](/en/definitions#telegram) [User](/en/development-pepeunit/mechanics/roles#user) verification
1. [Grafana](/en/deployment/dependencies/grafana) authorization
1. State storage for the [Telegram Bot](/en/definitions#telegram-bot)
1. Passing configuration change commands for [DataPipe](/en/deployment/dependencies/datapipe)
::::

