# Redis

[Redis](https://redis.io/) - кластерная база данных формата `NoSQL`, использующая парадигму `key-value`.

:::info
Используется [Backend](/deployment/dependencies/backend), [DataPipe](/deployment/dependencies/datapipe) и [EMQX](/deployment/dependencies/emqx) для следующих задач:
1. Установка [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe) токена для [EMQX](/deployment/dependencies/emqx)
1. Верификация [Пользователей](/development-pepeunit/mechanics/roles#user) [Telegram](/definitions#telegram)
1. Авторизация [Grafana](/deployment/dependencies/grafana)
1. Хранилище состояний для [Telegram Bot](/definitions#telegram-bot)
1. Передача команд изменения конфигурации для [DataPipe](/deployment/dependencies/datapipe)
:::