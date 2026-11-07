# Рефактор фронтенда в клиент

Клиент — Flutter-приложение в этом репозитории. Ограничения UI лежат в коде и в `.cursor/rules/` (`client.mdc`, `hive-ui.mdc`, `hex-layout.mdc`, `hex-scale.mdc`). В этой папке осталось только то, что ещё предстоит сделать. Реализованное описано в коде и правилах.

## Что предстоит

| Область | Состояние |
| --- | --- |
| Library | заглушка: `PlaceholderPage`, сота «Скоро»; [sections.md](sections.md) |
| System design | план, кода нет; [sections.md](sections.md) |
| OpenAPI-генерация | план; `PepeunitApi` пишется вручную |
| Фон-мозаика | план; [background.md](background.md) |
| Апдейты | план; [updates.md](updates.md) |
| Документация в клиенте | план; [client-docs.md](client-docs.md) |
| Масштаб главного меню | план; [layout.md](layout.md) |
| Переходы, анимация, линии между сотами | план; [animation.md](animation.md) |
| Переход к родителю сущности, deep links | план; [navigation.md](navigation.md) |
| Комбинированные интерфейсы Unit | план; [interfaces.md](interfaces.md) |

## Открыто в коде

- Полный охват пользовательских ручек OpenAPI; исключения: Grafana datasource, Telegram-обвязка, Prometheus и прочий сервисный слой
- Кеш картинок — сессионная карта по origin и uuid. Политика вытеснения не задана
- Форма нового аппарата: выбор репозитория, ветки, коммита, обновлений и платформы возвращает результат через `context.pop`, и смена масштаба его теряет. Общий канал `beginPick` / `finishPick` (как у `NamePickPage.viaModel`) для этих экранов не подключён
- Экран `/units/pipe/:uuid/data` остался в коде, хода на него из меню DataPipe нет: подключить или удалить

## Файлы

- [Раскладка](layout.md) — масштаб главного меню
- [Навигация](navigation.md) — родитель сущности, deep links
- [Комбинированные интерфейсы](interfaces.md)
- [Документация в клиенте](client-docs.md)
- [Обновления](updates.md)
- [Фон](background.md)
- [Анимация](animation.md)
- [Разделы](sections.md) — Library, System design
