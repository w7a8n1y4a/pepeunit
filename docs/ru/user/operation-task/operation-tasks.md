# Просмотр Operation Tasks

:::info Где найти?
На главной странице в верхней панели нажмите иконку `Operation Tasks`. Раздел доступен только авторизованным [Пользователям](/development-pepeunit/mechanics/roles#user)
:::

[Operation Task](/definitions#operation-task) - это запись о задаче, которую [Пользователь](/development-pepeunit/mechanics/roles#user) или [Администратор](/development-pepeunit/mechanics/roles#admin) запустил вручную. Сами записи пользователи не создают: [Backend](/deployment/dependencies/backend) заводит их в момент нажатия кнопки, сразу отвечает интерфейсу и дописывает статус, когда работа закончилась.

:::tip
Пока задачи выполняются в шапке на иконке задач горит красный счётчик числа задач со статусом `Running`.
:::

## Фильтры и таблица

:::info
Фильтры статусов можно включать по отдельности. Пока модальное окно открыто, список обновляется каждые `7` секунд. Внизу видно `next update in Ns`.
:::

Колонка | Что показывает
-- | --
`Task` | Тип задачи
`Status` | `Running`, `Success` или `Error`
`Started` | Время запуска
`Duration` | Сколько задача уже выполняется или сколько заняла
`Result` | Краткий итог. Для интеграционных тестов вместо текста есть иконка, которая открывает полный лог

## Типы задач

Тип | Кто запускает | Что делает
-- | -- | --
`Integration Tests` | [Администратор](/development-pepeunit/mechanics/roles#admin) | Запускает интеграционные тесты [Backend](/deployment/dependencies/backend). Обычно занимает `3` минуты и больше. [Подробнее](/user/operation-task/integration-tests)
`Scan All Instances` | [Администратор](/development-pepeunit/mechanics/roles#admin) | Принудительно опрашивает все доверенные внешние [Instance](/definitions#instance). Кнопка есть только при включённом `PU_FF_FEDERATION_ENABLE`. Повторный запуск недоступен `10` минут
`Scan Instance` | [Администратор](/development-pepeunit/mechanics/roles#admin) | Принудительно опрашивает один доверенный внешний [Instance](/definitions#instance)
`Update All Registries` | [Администратор](/development-pepeunit/mechanics/roles#admin) | Синхронизирует локальные копии всех [RepositoryRegistry](/definitions#repositoryregistry)
`Update Registry` | [Пользователь](/development-pepeunit/mechanics/roles#user) с доступом к реестру | Синхронизирует локальную копию одного [RepositoryRegistry](/definitions#repositoryregistry)
`Update All Units Firmware` | [Администратор](/development-pepeunit/mechanics/roles#admin) | Отправляет обновление прошивки всем [Unit](/definitions#unit), которые разрешили автообновление от [Repo](/definitions#repo) с включённым `Auto-update`
`Update Units Firmware` | Создатель [Repo](/definitions#repo) | Отправляет обновление прошивки [Unit](/definitions#unit) этого [Repo](/definitions#repo), у которых включено автообновление

:::warning
Каждый [Пользователь](/development-pepeunit/mechanics/roles#user) видит только свои задачи. Чужую запись по `uuid` прочитать нельзя.
:::