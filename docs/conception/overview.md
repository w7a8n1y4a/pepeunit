# Что такое Pepeunit?

:::tip
Pepeunit - платформа с открытым исходным кодом, основанная на принципах [Fediverse](definitions#fediverse) и [IoT](definitions#iot), предназначенная для организации устройств в единую, управляемую информационную систему.
:::

### CI/CD для Unit

[Pepeunit](definitions#pepeunit) способен на основе внешних [Git](definitions#git) репозиториев из [Gitlab](definitions#gitlab) и [Github](definitions#github), создавать готовые к использованию программы - это могут быть программы на основе [Интерпритируемых](definitions#interpreterable) или [Компилируемых](definitions#compilable) языков программирования.

### Управление устройствами IoT

[Pepeunit](definitions#pepeunit) предоставляет несколько способов взаимодействия с [Unit](definitions#unit)
- [MQTT](definitions#mqtt) - `EMQX`
- [Frontend](definitions#frontend) - `React`
- [REST](definitions#rest) - `Swagger`
- [GQL](definitions#gql) - `Strawberry`

### Управление топиками
[Pepeunit](definitions#pepeunit) позволяет отслеживать состояние [Unit](definitions#unit) при помощи системы именования топиков. [UnitNode](definitions#unitnode) могут образовывать связи Output -> Input для передачи информации между разными [Unit](definitions#unit).

### Настройка политик доступа

[Pepeunit](definitions#pepeunit) позволяет регулировать уровни доступа `Пользователь`-`Unit` и `Unit`-`Unit`. Глубина взаимодействия с платформой определяется ролью и доступами которые есть у пользователей. [Repo](definitions#repo), [Unit](definitions#unit), [UnitNode](definitions#unitnode) сущности у которых есть уровни видимости, определяющие каким пользователям или группам пользователей будет предоставлен частичный доступ.

### Федеративное взаимодействие

[Pepeunit](definitions#pepeunit) - федеративная платформа, отдельные [Узлы](definitions#instance) которой, могут узнавать о других [Узлах](definitions#instance) и объединятся в большую сеть для взаимодействия. [Unit](definitions#unit) могут взаимодействовать с другими [Unit](definitions#unit) даже если они находятся на разных [Узлах](definitions#instance).