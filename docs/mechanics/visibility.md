# Уровни видимости - Public, Internal и Private

::: tip На что влияет уровень видимости?
От `уровня видимости` сущности зависит кто может получить о ней информацию и/или провзаимодействовать с ней
:::

### Public

- предоставляет [доступ](/mechanics/permission) всем

### Internal

- предоставляет [доступ](/mechanics/permission) до сущности только авторизованным [Пользователям](/mechanics/roles.html#user) [инстанса](/definitions#instance) или всем [Unit](/definitions#unit) находящихся в [инстансе](/definitions#instance)

### Private

- предоставляет [доступ](/mechanics/permission) до сущности только создателю и агентам которых укажет создатель. Работает в пределах [инстанса](/definitions#instance)

---

# Возможности создателя сущностей

Создатель имеет `абсолютно полный доступ` по управлению своими cущностями.

### Repo

- Просмотр распределения [Unit](/definitions#unit) по версиям
- Создание [Unit](/definitions#unit) на основе [Repo](/definitions#repo)
- Обновление [Git](/definitions#git) репозитория внутри [Pepeunit](/conception/overview)
- Обновление всех связанных [Unit](/definitions#unit)
- Настройки [Repo](/definitions#repo)
- Выдача [доступов](/mechanics/permission)
- Удаление [Repo](/definitions#repo)

### Unit

- Просмотр информации о текущей версии [Unit](/definitions#unit)
- Просмотр информации о состоянии [Unit](/definitions#unit)
- Установка [env.json](/definitions#env-json)
- Скачивание `Firmware` и скомпилированных пакетов
- Команды обновления по [MQTT](/definitions#mqtt) - `Firmware`, `Schema` и `Env`
- Настройки [Unit](/definitions#unit)
- Выдача [доступов](/mechanics/permission)оступов
- Удаление [Unit](/definitions#unit)

### UnitNode

- Просмотр состояния
- Установка значений с отправкой в `Input` через [MQTT](/definitions#mqtt)
- Создание связей для `Input`
- Настройки [UnitNode](/definitions#unitnode)
- Выдача [доступов](/mechanics/permission)

---

# Возможности агентов для видимых сущностей

Агенты имеют ограниченный [доступ](/mechanics/permission) до чужих сущностей, которые они видят с помощью `системы видимости`:

### Repo

- Просмотр распределения [Unit](/definitions#unit) по версиям
- Создание [Unit](/definitions#unit) на основе [Repo](/definitions#repo)

### Unit

- Просмотр информации о текущей версии [Unit](/definitions#unit)
- Просмотр информации о состоянии [Unit](/definitions#unit)

### UnitNode

- Просмотр состояния
- Установка значений с отправкой в `Input` через [MQTT](/definitions#mqtt)
- Создание связей для `Input`