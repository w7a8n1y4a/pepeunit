# Уведомления

:::info Где найти?
На главной странице в верхней панели нажмите иконку `Notifications`. Раздел доступен авторизованному [Пользователю](/development-pepeunit/mechanics/roles#user), если у инстанса включён `PU_FF_NOTIFICATION_ENABLE`
:::

:::warning
В списке только ваши уведомления
:::

## Фильтры и таблица

Кнопки `All`, `Unread` и `Read` оставляют все записи, только непрочитанные или только прочитанные. Кнопка `Types` включает и выключает типы по отдельности.

Колонка | Что показывает
-- | --
`Type` | Тип уведомления
`Text` | Короткая строка. Наведение показывает таблицу. Иконка открывает полный лог, если он есть
`Created` | Время создания
`Status` | `Read` или кнопка `Mark read`

`Mark all read` помечает прочитанными все свои непрочитанные записи.

## Настройки

Настройки лежат в меню своего имени, кнопка `Notification Settings`. Строка настроек создаётся вместе с учётной записью.

Переключатель | По умолчанию | Что делает
-- | -- | --
`Daily summaries` | включён | Создаёт ежедневные сводки инстанса и [Unit](/definitions#unit)
`HH:MM UTC` | `16:00` | Время сводок, `00:00`–`23:59` по UTC
`Data pipe alerts` | включён | Живое обновление страницы и [Telegram](/definitions#telegram) для алертов [DataPipe](/user/datapipe/datapipe#alerts). Запись в списке и правило в конвейере остаются
`Telegram delivery` | включён | Сообщения в [Telegram Bot](/definitions#telegram-bot). Список и живое обновление страницы остаются. Кнопка есть при включённом `PU_FF_TELEGRAM_BOT_ENABLE`

Итоги ручных команд приходят всегда: интеграционные тесты, опрос [Instance](/definitions#instance), обновление [RepositoryRegistry](/definitions#repositoryregistry) и прошивок [Unit](/definitions#unit).

## Доставка

Живое обновление открытой страницы и сообщение в [Telegram](/definitions#telegram) уходят верифицированному [Пользователю](/development-pepeunit/mechanics/roles#user). Сводка создаётся только ему и только при включённом `Daily summaries`. Алерт [DataPipe](/deployment/dependencies/datapipe) в список попадает в любом случае, а на страницу и в чат - когда включён `Data pipe alerts`.

В [Telegram Bot](/definitions#telegram-bot) команда `/alerts` открывает ваши уведомления. Короткий текст уходит в чат, по нажатию видна таблица, а у интеграционных тестов есть кнопка полного лога. Между сообщениями в один чат выдерживается пауза, у всего инстанса есть общий предел скорости. Числа задают [переменные Backend](/deployment/env-variables/backend).

## Типы

Тип | Вид | Кому | Описание
-- | -- | -- | --
`InstanceDailyState` | Периодический | [Администратор](/development-pepeunit/mechanics/roles#admin) | До `3` групп `ERROR` и `CRITICAL` из логов [Backend](/deployment/dependencies/backend) за сутки. Источник - [Loki](/deployment/dependencies/loki)
`UnitDailySummary` | Периодический | [Пользователь](/development-pepeunit/mechanics/roles#user) со своими [Unit](/definitions#unit) | До `10` своих [Unit](/definitions#unit) с наибольшим числом логов `Error` и `Critical` за сутки
`DataPipeAlert` | DataPipe | Создатель [Unit](/definitions#unit) | Значение [UnitNode](/definitions#unitnode) нарушило блок `alerts`. В строке имя [Unit](/definitions#unit), значение и проверка, в таблице ещё топик. [Как задать правило](/user/datapipe/datapipe#alerts)
`IntegrationTests` | Операция | [Администратор](/development-pepeunit/mechanics/roles#admin) | Интеграционные тесты [Backend](/deployment/dependencies/backend). В полном логе вывод `pytest`. [Подробнее](/user/notification/integration-tests)
`ScanAllInstances` | Операция | [Администратор](/development-pepeunit/mechanics/roles#admin) | Опрос всех доверенных внешних [Instance](/definitions#instance). Кнопка есть при `PU_FF_FEDERATION_ENABLE`. Повтор через `10` минут. Итог `Scanned N, failed M`
`ScanInstance` | Операция | [Администратор](/development-pepeunit/mechanics/roles#admin) | Опрос одного доверенного внешнего [Instance](/definitions#instance)
`UpdateAllRegistries` | Операция | [Администратор](/development-pepeunit/mechanics/roles#admin) | Синхронизация локальных копий всех [RepositoryRegistry](/definitions#repositoryregistry)
`UpdateRegistry` | Операция | [Пользователь](/development-pepeunit/mechanics/roles#user) с доступом к реестру | Синхронизация локальной копии одного [RepositoryRegistry](/definitions#repositoryregistry)
`UpdateUnitsFirmware` | Операция | Создатель [Repo](/definitions#repo) | Обновление прошивки [Unit](/definitions#unit) этого [Repo](/definitions#repo) с включённым автообновлением
`UpdateAllUnitsFirmware` | Операция | [Администратор](/development-pepeunit/mechanics/roles#admin) | Обновление прошивки всех [Unit](/definitions#unit), которые разрешили автообновление от [Repo](/definitions#repo) с включённым `Auto-update`

- Периодические создаются раз в сутки, в минуту из `HH:MM UTC`, у верифицированного [Пользователя](/development-pepeunit/mechanics/roles#user) с включённым `Daily summaries`.
- Операция оставляет две записи: `Running` при запуске и `Success` или `Error` после завершения. В таблице статус, время старта, время окончания и короткая строка результата.
