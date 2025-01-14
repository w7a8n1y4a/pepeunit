# Структура GIT репозитория

Структурые элементы описанные здесь используются Pepeunit для различных целей начиная с генерации прошивок и заканчивая созданием UnitNode.

## Минимальный набор файлов

Ниже представлен минимальный набор файлов в Git репозитории, требующийся для корректного создания Repo и дальнейшей эксплуатации Unit.

```bash
~/best_unit$ tree
.
├── env_example.json
├── .git
    └── ...
├── .gitignore
├── LICENSE
├── readme.md
└── schema_example.json
```

Рассмотрим каждый файл:
- readme.md - описание проекта, содержащее основную информацию о его назначении, установке и использовании, [требования к структуре](/developer/struct-readme)
- env_example.json - отвечает за требующиеся для Unit переменные окруженияю, [требования к структуре](/developer/struct-env-json)
- schema_example.json - отвечает за схему взаимодействия Unit с Pepeunit, а также за `Input` и `Output` которые будут у Unit, [требования к структуре](/developer/struct-schema-json)
- LICENSE - лицензия на усмотрение автора, все репозитории Pepeunit имеют лицензию `AGPL v3`
- .gitignore - перечисляет файлы и папки, которые Git должен игнорировать и не включать в контроль версий. Пример заполнения чуть ниже

## Как заполнить .gitignore

Здесь должны содержаться файлы и папки, которые Git должен проигнорировать при версионировании, обычно это следующие категории файлов:
1. Окружения из библиотек как например `.venv` из `python`
1. Cекреты которые не должны быть опубликованы, применимо к Pepeunit - это env.json и schema.json, в других репозиториях аналогичную функцию часто выполняют `.env` файлы.

Пример минимального `.gitignore` файла для Pepeunit:
```gitignore
.idea
.nvim
env.json
schema.json
tmp
```

## Размер репозиториев для Pepeunit

У Pepeunit достаточно строгие требования к размеру репозиториев. Это связано с тем что данные придётся хранить на стороне Pepeunit. Поэтому объём стандартно ограничен объёмом в `25МБ`, администраторы узлов могут увеличить данный лимит, но это может привести к задержке некоторых операций.

Для выполнения такого строгого требования не рекомендуется хранить в репозиториях картинки и бинарные файлы.

Для микроконтроллеров в Pepeunit есть система чистки репозитория перед генерацией архива с программой, данный алгоритм удалаяет определённые файлы и дирректории. Подробнее об этой механике можно узнать в разделе [структура архивов с обновлениями](/developer/struct-archive-update)