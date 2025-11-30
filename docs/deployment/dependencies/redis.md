# Redis

[Redis](https://redis.io/) - `NoSQL` кластерная база данных использующая парадигму `key-value`

1. Обеспечивает кэширование и хранение промежуточной информации о состоянии [UnitNode](/definitions#unitnode), во время обращения [Unit](/definitions#unit) к [MQTT Broker](/definitions#mqtt-broker) через топики.
1. Используется также для авторизации [Backend](/definitions#backend) в момент подписки на основной топик `unit.example.com/+/+/+/pepeunit` в [MQTT Broker](/definitions#mqtt-broker). Подписка на `unit.example.com/+/pepeunit` осуществляется стандартными средствами через [REST](/definitions#rest).
1. `Stream` используется для синхронизации конфигураций [Backend](/definitions#backend) и [DataPipe](/definitions#datapipe) сервисом.