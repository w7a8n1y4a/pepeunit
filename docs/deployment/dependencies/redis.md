# Redis

[Redis](https://redis.io/) - кластерная база данных формата `NoSQL`, использующая парадигму `key-value`.

:::info
Используется [Backend](/deployment/dependencies/backend), [DataPipe](/deployment/dependencies/datapipe) и [EMQX](/deployment/dependencies/emqx) для следующих задач:
1. Установка [Backend](/deployment/dependencies/backend) и [DataPipe](/deployment/dependencies/datapipe) токена для [EMQX](/deployment/dependencies/emqx)
2. Верификация [Пользователей](/development-pepeunit/mechanics/roles.html#user) [Telegram](/definitions#telegram)
3. Авторизация [Grafana](/deployment/dependencies/grafana)
4. Хранилище состояний для [Telegram Bot](/definitions#telegram-bot)
5. Передача команд изменения конфигурации для [DataPipe](/deployment/dependencies/datapipe)
:::