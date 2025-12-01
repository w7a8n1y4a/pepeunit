# Redis

[Redis](https://redis.io/) - `NoSQL` кластерная база данных использующая парадигму `key-value`

:::info
Используется [Backend](/definitions#backend), [DataPipe](/definitions#datapipe) и [EMQX](/deployment/dependencies/emqx) для следующих задач:
1. Установка [Backend](/definitions#backend) и [DataPipe](/definitions#datapipe) токена для [EMQX MQTT Broker](/definitions#mqtt-broker)
1. Верификация пользователей `Telegram`
1. Авторизация [Grafana](/deployment/dependencies/grafana)
1. Хранилище состояний для `Telegram Bot`
1. Передача команд изменения конфигурации для [DataPipe](/definitions#datapipe)
:::