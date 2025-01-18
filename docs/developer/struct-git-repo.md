# Структура GIT репозитория

Структурые элементы описанные здесь используются [Pepeunit](/conception/overview) для различных целей начиная с генерации прошивок и заканчивая созданием [UnitNode](/definitions#unitnode).

## Минимальный набор файлов

Ниже представлен минимальный набор файлов в [Git](/definitions#git) репозитории, требующийся для корректного создания Repo и дальнейшей эксплуатации [Unit](/definitions#unit).

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
- [readme.md](/developer/struct-readme) - описание проекта, содержащее основную информацию о его назначении, установке и использовании, [требования к структуре](/developer/struct-readme)
- [env_example.json](/definitions#env-example-json) - отвечает за требующиеся для [Unit](/definitions#unit) переменные окруженияю, [требования к структуре](/developer/struct-env-json)
- [schema_example.json](/definitions#schema-example-json) - отвечает за схему взаимодействия [Unit](/definitions#unit) с [Pepeunit](/conception/overview), а также за `Input` и `Output` которые будут у [Unit](/definitions#unit), [требования к структуре](/developer/struct-schema-json)
- LICENSE - лицензия на усмотрение автора, все репозитории [Pepeunit](/conception/overview) имеют лицензию `AGPL v3`
- .gitignore - перечисляет файлы и папки, которые [Git](/definitions#git) должен игнорировать и не включать в контроль версий. Пример заполнения чуть ниже

## Как заполнить .gitignore

Здесь должны содержаться файлы и папки, которые [Git](/definitions#git) должен проигнорировать при версионировании, обычно это следующие категории файлов:
1. Окружения из библиотек как например `.venv` из `python`
1. Cекреты которые не должны быть опубликованы, применимо к [Pepeunit](/conception/overview) - это [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json), в других репозиториях аналогичную функцию часто выполняют `.env` файлы.

Пример минимального `.gitignore` файла для [Pepeunit](/conception/overview):
```gitignore
.idea
.nvim
env.json
schema.json
tmp
```

## Размер репозиториев для Pepeunit

У [Pepeunit](/conception/overview) достаточно строгие требования к размеру репозиториев. Это связано с тем что данные придётся хранить на стороне [Pepeunit](/conception/overview). Поэтому объём стандартно ограничен объёмом в `25МБ`, администраторы узлов могут увеличить данный лимит, но это может привести к задержке некоторых операций.

Для выполнения такого строгого требования не рекомендуется хранить в репозиториях картинки и бинарные файлы.

Для микроконтроллеров в [Pepeunit](/conception/overview) есть система чистки репозитория перед генерацией архива с программой, данный алгоритм удалаяет определённые файлы и дирректории. Подробнее об этой механике можно узнать в разделе [структура архивов с обновлениями](/developer/struct-archive-update)