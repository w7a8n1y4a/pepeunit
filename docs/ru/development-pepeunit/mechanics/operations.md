# Операции и уведомления

Долгие действия Pepeunit не держат запрос открытым. Backend запускает действие в фоне, сразу отвечает `204`, а когда действие кончится, присылает результат `Пользователю` уведомлением. Так работают и глобальные команды [Admin](/development-pepeunit/mechanics/roles#admin) и [Owner](/development-pepeunit/mechanics/roles#owner), и ежедневные сводки.

## Операции

Каждая запущенная вручную операция записывается как `OperationTask` с типом, временем старта и конца, статусом (`Running`, `Success` или `Error`) и результатом. Через API `OperationTask` не отдаётся: результат придёт уведомлением тому, кто запустил операцию.

Операция | Тип | Кто запускает | Что делает
-- | -- | -- | --
Синхронизация одного `Repo` | `UpdateRepo` | `User` с доступом к `Repo` | Заменяет локальную копию [Repo](/development-pepeunit/mechanics/entities#repo) и загружает релизы
Синхронизация всех `Repo` | `UpdateAllRepos` | `Admin` | То же заново для всех `Repo` инстанса
Массовое обновление `Unit` | `UpdateAllUnitsFirmware` | `Admin` | Отправляет команду `UPDATE` каждому `Unit` с автообновлением и возвращает, сколько получилось и сколько нет
Опрос соседей | `ScanAllPeers` | `Admin` | Опрашивает все `Trust` [Peer](/development-pepeunit/mechanics/federation). Не чаще раза в 10 минут
Опрос одного соседа | `ScanPeer` | `Admin` | Опрашивает один `Peer` и сообщает адрес и пинг
Интеграционные тесты | `IntegrationTests` | `Admin` | Запускает [интеграционные тесты](/development-pepeunit/tests/integration-test) на самом инстансе
Перезапуск | `RebootInstance` | `Owner` | Перезапускает Backend. Результат придёт после старта

В клиенте глобальные операции собраны в `Сеть` → `Управление`: `Тесты`, `Опросить соседей`, `Обновить репозитории`, `Обновить все` и `Перезапуск`.

`Admin` может запустить тесты, опрос соседей и обновление всех `Repo` и командой `/control` в Telegram Bot.

:::info
Часть операций работает по расписанию без `OperationTask`: каждый час в `:00` обновляются `Unit` и опрашиваются `Peer`, а в `:30` синхронизируются `Repo`. Подробнее в [системе обновлений](/development-pepeunit/mechanics/update-system) и [федерации](/development-pepeunit/mechanics/federation).
:::

## Уведомления

`Notification` принадлежит одному `User` и хранится в базе. Список находится в `Уведомления`, а новые приходят в клиент потоком `GET /pepeunit/api/v1/notifications/stream`. Если включён Telegram, то ещё и в Telegram Bot.

Тип | Что в нём | Кому
-- | -- | --
`InstanceDailyState` | Топ ошибок Backend за сутки | `Admin` и `Owner`
`UnitDailySummary` | До 10 `Unit` пользователя с числом ошибок (`Error` и `Critical`) за сутки | Каждому `User`, у которого есть `Unit`
`DataPipeAlert` | Тревога [DataPipe](/deployment/dependencies/datapipe): фильтр или правило сработали на `UnitIO` | Создателю `UnitIO`
Типы операций (`UpdateRepo`, `ScanAllPeers` и другие из таблицы выше) | Итог операции: статус, время и результат | Тому, кто запустил

У каждого уведомления есть короткая строка для списка и Telegram, таблица и полный текст. Прочитать можно одно уведомление (`PATCH /notifications/{uuid}/read`) или все сразу (`PATCH /notifications/read`).

### Настройки уведомлений

У каждого `User` свои `NotificationSettings`: `Аккаунт` → `Настройки` → `Уведомления`.

Настройка | Что значит
-- | --
`Сводки` | Получать `InstanceDailyState` и `UnitDailySummary`
`Время UTC` | В какое время суток присылать сводки, по умолчанию `16:00`
`DataPipe` | Получать `DataPipeAlert`. Само правило DataPipe при этом не меняется
`Телеграм` | Дублировать любое уведомление в Telegram Bot

Итоги операций присылаются всегда: их отключить нельзя.

Заблокированному `User` уведомления не доставляются.

:::info Включение
Уведомления работают при включённом флаге `pu_ff_notification_enable`. Лимиты размеров текста и частоты отправки в Telegram [Owner](/development-pepeunit/mechanics/roles#owner) задаёт в настройках инстанса: `pu_notification_*`.
:::
