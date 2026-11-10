# Роли Пользователей и агенты

В Pepeunit запрос к [Backend](/deployment/dependencies/backend) делает агент. Агент бывает человеком, устройством, самим инстансом или внешним сервисом. Права агента зависят от его типа, а у человека ещё и от роли.

## Роли

Роль есть только у `User`. Она растёт по цепочке: `User` → `Admin` → `Owner`. Каждая следующая роль умеет всё, что умеет предыдущая, и ещё что-то своё.

Роль | Сколько на инстансе | Кто назначает
-- | -- | --
`User` | Любое число, но не больше `pu_instance_user_max_count` | Выдаётся при регистрации
`Admin` | Любое число | [Owner](#owner) в клиенте: `Сеть` → `Пользователи` → пользователь → `Сделать админом`
`Owner` | Только один | Администратор сервера командой `scripts/set_owner.py`, см. [Регистрация и Owner](/deployment/docker/deploy#регистрация-и-owner)

### Unit Developer

`Разработчик Unit` - не роль в Pepeunit, а человек, который пишет Git репозитории на GitLab или GitHub. Он напрямую с Pepeunit не работает: его код становится [Repo](/development-pepeunit/mechanics/entities#repo), из которого [Пользователи](#user) создают свои `Unit`.

Возможности `Разработчика Unit`:

- Вносит изменения в Git репозиторий
- Выпускает версии, которые попадают на инстанс при [обновлении](/development-pepeunit/mechanics/update-system)
- Описывает, как [заполнить env.json](/developer/files/struct-env-example-json) и какие топики есть у `Unit`

### User

`Пользователь` - человек, зарегистрированный в инстансе Pepeunit. Паролей нет: вход происходит по [паре ключей](/development-pepeunit/mechanics/authentication).

Возможности `Пользователя`:

- Создаёт `Repo`, `Unit`, `Link`, `UnitGroup` и `Dashboard`, а `UnitIO` получает сами при создании `Unit`
- Видит все `Repo`, включая приватные, а остальные сущности по [уровню видимости](/development-pepeunit/mechanics/visibility) и выданному [доступу](/development-pepeunit/mechanics/permission). Работать с приватным `Repo` может только со своими Кредами доступа, см. [Repo](/development-pepeunit/mechanics/entities#repo)
- Полностью управляет своими сущностями и больше ничьими
- Меняет свой профиль, иконку, настройки уведомлений и привязывает Telegram
- Видит список других `User`, список `Peer` и свои `Notification`
- Запускает синхронизацию `Repo`, к которому у него есть доступ

### Admin

`Администратор` - `User`, который помогает вести инстанс: следит за порядком и за соседями.

Возможности `Администратора`:

- Блокирует и разблокирует `User`. Токен заблокированного `User` Backend перестаёт принимать
- Добавляет `Peer`, переводит их в `Trust` или `Blocking`, удаляет, опрашивает один или все сразу, см. [Федерацию](/development-pepeunit/mechanics/federation)
- Запускает [глобальные операции](/development-pepeunit/mechanics/operations): интеграционные тесты, обновление всех `Repo` и массовое обновление `Unit`
- Каждый день в выбранное время получает уведомление `InstanceDailyState` с ошибками инстанса

:::warning Чего `Admin` не может
Особых прав на чужие сущности у `Admin` нет: он работает с ними по тем же правилам [видимости](/development-pepeunit/mechanics/visibility) и [доступа](/development-pepeunit/mechanics/permission), что и любой `User`. Настройки инстанса, перезапуск и выдача роли `Admin` ему недоступны.

Но администратор сервера, у которого есть доступ к машине, технически может расшифровать любые [шифрованные](/development-pepeunit/mechanics/cipher) данные: ключи лежат в `.env`.
:::

### Owner

`Владелец` - единственный `User` с полным управлением инстансом. Это тот, кто развернул Pepeunit или назначен им.

Возможности `Владельца`:

- Всё, что умеет [Admin](#admin)
- Выдаёт и снимает роль `Admin`
- Читает и меняет [настройки инстанса](/deployment/instance-settings): лимиты, MQTT, DataPipe, уведомления и флаги `pu_ff_*`, которые включают и выключают возможности инстанса
- Меняет иконку инстанса
- Перезапускает инстанс. Результат приходит уведомлением `RebootInstance`

Если запустить `scripts/set_owner.py` с другим `uuid`, новый `User` станет `Owner`, а прежний вернётся в `User`. Роль `Owner` нельзя выдать или снять через API.

## Агенты

### Bot

`Bot` - любой, кто ещё не прошёл авторизацию: посетитель сайта, скрипт или Telegram Bot.

Возможности `Bot`:

- Регистрируется и входит: создаёт `User`, запрашивает [challenge](/development-pepeunit/mechanics/authentication) и меняет подпись на токен
- Видит публичные `Repo` и сущности с уровнем `Public`
- Читает публичное состояние инстанса `GET /pepeunit/api/v1/instances/current` и списки `Peer`. Именно так [опрашивают друг друга инстансы](/development-pepeunit/mechanics/federation)

### Unit

`Unit` - устройство или программа. Авторизуется бессрочным токеном `PU_AUTH_TOKEN` из [env.json](/developer/files/struct-env-example-json#стандартные-переменные-pepeunit).

Возможности `Unit`:

- Получает свои [env.json](/development-pepeunit/mechanics/alg-env), схему, прошивку и целевую версию
- Хранит своё [состояние](/developer/state-storage-unit) в `Unit State Storage`
- Шлёт по MQTT состояние и логи, а также значения своих `Output`
- Видит `Unit` и `UnitIO` по тем же правилам [видимости](/development-pepeunit/mechanics/visibility), что и `User`, а в `Input` другого `Unit` пишет, только если у него включено `is_rewritable_input`
- Не может менять чужие `Unit`, создавать `Repo` и управлять доступами

### Backend

`Backend` - сам [Backend](/deployment/dependencies/backend), когда он ходит в собственный API. Его токен подписан доменом инстанса. Проверки видимости для `Backend` отключены, а сам он нужен для проверки MQTT прав в [EMQX](/deployment/dependencies/emqx) и для фоновых задач.

### Grafana и GrafanaUnitIO

Агенты [Grafana](/deployment/dependencies/grafana):

- `Grafana` - токен, который `User` получает для входа в Grafana (по одноразовому тикету). Он умеет читать профиль этого `User`
- `GrafanaUnitIO` - токен панели `Dashboard`. Он умеет только запрашивать данные `UnitIO`, добавленных в эту панель

## Статусы

У `User` два статуса: `Active` и `Blocked`. Заблокированного агента Backend отклоняет при проверке токена, поэтому его запросы не доходят до сервисов.
