# Рефактор фронтенда в клиент

Клиент — Flutter-приложение в этом репозитории. Сделанное и ограничения UI лежат в коде и в `.cursor/rules/` (`client.mdc`, `hive-ui.mdc`, `hex-layout.mdc`). Раскладка сот — в [layout.md](layout.md) и в `hex-layout.mdc`. Остальные файлы этой папки — план и решения, которых в правилах нет.

Именование согласовано с кодом (`lib/navigation/sections.dart`, `lib/hive/hex_scene.dart`, `lib/main.dart`). Расхождения со старыми черновиками намеренны.

## Статус

| Область | Состояние |
| --- | --- |
| Units / Registry / Dashboards / Alerts / Library | заглушки |
| OpenAPI-генерация, Inter, фон-мозаика, апдейты, docs-in-client | план |
| Масштаб главного меню, анимации, deep links unit/repo/UnitIO | план |

### Код

- Полный охват пользовательских ручек OpenAPI; исключения: Grafana datasource, Telegram-обвязка, Prometheus и прочий сервисный слой
- Кеш картинок (аватары/иконки инстансов) — довести до явной политики

Флаги на главном меню, сверх общей оговорки в `client.mdc` (`menuSectionEnabled`):

- без target доступны только `people`, `peers`, `library`
- `alerts` скрывается при `pu_ff_notification_enable == false`
- `dashboards` скрывается при `pu_ff_grafana_integration_enable == false`

## Файлы

- [Раскладка](layout.md) — позиция соты, порядок появления, меню, масштаб
- [Навигация](navigation.md) — родитель сущности, deep links, типы экранов
- [Аккаунт и сеть](account.md)
- [Комбинированные интерфейсы](interfaces.md)
- [Документация в клиенте](client-docs.md)
- [Обновления](updates.md)
- [Фон](background.md)
- [Анимация](animation.md)
- [Разделы](sections.md) — Units, Library, System design, UX
