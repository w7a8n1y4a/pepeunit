# Frontend

## Frontend в широком смысле

Набор из `2` сервисов: `Frontend` и [Grafana](/deployment/dependencies/grafana). Указанные сервисы вместе обеспечивают взаимодействие [Пользователей](/development-pepeunit/mechanics/roles.html#user) с [Backend](/deployment/dependencies/backend).

## Frontend сервис 

Веб приложение, доступное для скачивания открытым способом и предназаначенное для обеспечения взаимодействия [Пользователей](/development-pepeunit/mechanics/roles.html#user) c [Backend](/deployment/dependencies/backend) приложением средствами визуального интерфейса. Взаимодействует с [Backend](/deployment/dependencies/backend) при помощи:
- [REST](/definitions#rest)
- [GQL](/definitions#gql)

:::info
[Подробнее о переменных окружения](/deployment/env-variables/frontend)
:::
