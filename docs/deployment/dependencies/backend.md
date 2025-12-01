# Backend

Имеет два определения:

1. `Backend` в широком смысле - набор сервисов, обеспечивающих взаимодействие всех агентов [Pepeunit](/conception/overview):
    - [Пользователей](/development-pepeunit/mechanics/roles.html#user)
    - [Frontend](/definitions#frontend)
    - [Unit](/definitions#unit)
    - [Gitlab](/definitions#gitlab)
    - [Github](/definitions#github)
    - [Telegram](/definitions#telegram)
1. `Backend` сервис - главная составляющая `Backend` в широком смысле. Размещается на сервере и обеспечивает: обработку, хранение и анализ информации - а так же предоставляет разные [API](/definitions#api) для взаимодействия:
    - [MQTT](/definitions#mqtt) - `fastapi-mqtt`
    - [REST](/definitions#rest) - `swagger`
    - [GQL](/definitions#gql) - `strawberry`
    - [Telegram Bot](/definitions#telegram) - `AioGram`
