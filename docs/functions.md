# Функции

## CI/CD для микроконтроллеров

Pepeunit способен на основе внешних [Git](definitions#git) репозиториев из [Gitlab](definitions#gitlab) и [Github](definitions#github) инстансов, генерировать прошивки для [IoT](definitions#iot) устройств работающих на [Micropython](definitions#micropython).

## Настройка политик доступа

[Pepeunit](definitions#pepeunit) позволяет регулировать уровни доступа `Пользователь`-`Unit` и `Unit`-`Unit`. Пользователи имеют роли, определяющие глубину взаимодействия с узлом. [Repo](definitions#repo), [Unit](definitions#unit), [UnitNode](definitions#unitnode) сущности имеют уровни видимости, определяющие кому будет предоставлен доступ до них.

## Управление устройствами IoT

[Pepeunit](definitions#pepeunit) предоставляет несколько способов передачи информации в [Unit](definitions#unit)
- [MQTT](definitions#mqtt) - `EMQX`
- [Frontend](definitions#frontend) - `Vue 3`
- [REST](definitions#rest) - `Swagger`
- [GQL](definitions#gql) - `Strawberry`
- [ChatBot](definitions#chatbot) - `Telegram`

## Отслеживание состояния Unit

[Pepeunit](definitions#pepeunit) позволяет отслеживать состояние [Unit](definitions#unit) при помощи системы наименования топиков. Функционал наколения статистики изменения данных по времени для определённых [UnitNode](definitions#unitnode) также присутствует.

## Федеративное взаимодействие

[Pepeunit](definitions#pepeunit) - федеративная платформа, отдельные [Узлы](definitions#instance) которой, могут узнавать о других [Узлах](definitions#instance) и объединятся в большую сеть для взаимодействия. [Unit](definitions#unit) могут взаимодействовать с другими [Unit](definitions#unit) даже если они находятся на разных [Узлах](definitions#instance).