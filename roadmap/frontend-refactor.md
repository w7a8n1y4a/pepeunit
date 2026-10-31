# Рефактор фронтенда в клиент

Клиент — Flutter-приложение в этом репозитории. Ограничения UI лежат в коде и в `.cursor/rules/` (`client.mdc`, `hive-ui.mdc`, `hex-layout.mdc`, `hex-scale.mdc`). Раскладка сот — в [layout.md](layout.md) и в `hex-layout.mdc`. Собранные экраны — в файлах аккаунта, репозиториев, уведомлений и аппаратов. Остальные файлы этой папки — план и решения, которых в правилах нет.

Именование согласовано с кодом (`lib/navigation/sections.dart`, `lib/hive/hex_scene.dart`, `lib/main.dart`). Расхождения со старыми черновиками намеренны.

## Статус

| Область | Состояние |
| --- | --- |
| Аккаунт и сеть | сделано |
| Репозитории | сделано; сота «Создать аппарат» открывает форму |
| Уведомления | сделано |
| Аппараты | сделано; [units.md](units.md) |
| Dashboards / Library | заглушки |
| OpenAPI-генерация, Inter, фон-мозаика, апдейты, документация в клиенте | план |
| Масштаб главного меню, переходы и линии между сотами | план |

### Код

- Полный охват пользовательских ручек OpenAPI; исключения: Grafana datasource, Telegram-обвязка, Prometheus и прочий сервисный слой
- Кеш картинок уже сессионная карта по origin и uuid (аватары, иконки инстансов и репозиториев). Политика вытеснения ещё не задана

Флаги на главном меню уже в `menuSectionEnabled`:

- без target доступны только `people`, `peers`, `library`
- `alerts` скрывается при `pu_ff_notification_enable == false`
- `dashboards` скрывается при `pu_ff_grafana_integration_enable == false`

## Файлы

- [Раскладка](layout.md) — позиция соты, порядок появления, меню, масштаб
- [Навигация](navigation.md) — родитель сущности, deep links, типы экранов
- [Аккаунт и сеть](account.md)
- [Репозитории](registry.md)
- [Аппараты](units.md)
- [Уведомления](alerts.md)
- [Комбинированные интерфейсы](interfaces.md)
- [Документация в клиенте](client-docs.md)
- [Обновления](updates.md)
- [Фон](background.md)
- [Анимация](animation.md)
- [Разделы](sections.md) — Units, Dashboards, Library, System design, UX
