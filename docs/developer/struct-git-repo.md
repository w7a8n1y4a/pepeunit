# Структура GIT репозитория

Структурые элементы описанные здесь используются [Pepeunit](/conception/overview) для различных целей: начиная с генерации [архивов с программами](/developer/struct-archive-update) и заканчивая созданием [UnitNode](/definitions#unitnode).

## Минимальный набор файлов

Ниже представлен минимальный набор файлов в [Git](/definitions#git) репозитории, требующийся для корректного создания [Repo](/definitions#repo) и дальнейшей эксплуатации [Unit](/definitions#unit).

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
- [readme.md](/definitions#readme-file) - описание проекта, содержащее основную информацию о его назначении, установке и использовании, [требования к структуре](/developer/struct-readme)
- [env_example.json](/definitions#env-example-json) - отвечает за требующиеся для [Unit](/definitions#unit) переменные окруженияю, [требования к структуре](/developer/struct-env-json)
- [schema_example.json](/definitions#schema-example-json) - отвечает за схему взаимодействия [Unit](/definitions#unit) с [Pepeunit](/conception/overview), а также за `Input` и `Output` которые будут у [Unit](/definitions#unit), [требования к структуре](/developer/struct-schema-json)
- `LICENSE` - лицензия на усмотрение автора. Все репозитории [Pepeunit](/conception/overview) имеют лицензию `AGPL v3`
- `.gitignore` - перечисляет файлы и папки, которые [Git](/definitions#git) должен игнорировать и не включать в контроль версий, [подробнее .gitignore](https://git-scm.com/docs/gitignore).

:::danger
[.pepeignore](/definitions#pepeignore) хоть и не является обязательным файлом, его следует указывать почти всегда, когда вы создаёте свой [Unit](/definitions#unit) для платформ с ограниченным размером памяти
:::

## Как заполнить .gitignore

Здесь должны содержаться файлы и папки, которые [Git](/definitions#git) должен проигнорировать при версионировании, обычно это следующие категории файлов:
1. Окружения из библиотек как например `.venv` из `python`
1. Cекреты которые не должны быть опубликованы, применимо к [Pepeunit](/conception/overview) - это [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json), в других репозиториях аналогичную функцию часто выполняют `.env` файлы.

Пример минимального [.gitignore](https://git-scm.com/docs/gitignore) файла для [Pepeunit](/conception/overview):
```gitignore
.idea
.nvim
env.json
schema.json
tmp
```

## Размер репозиториев для Pepeunit

У [Pepeunit](/conception/overview) достаточно строгие требования к размеру репозиториев. Это связано с тем что данные придётся хранить на стороне [Pepeunit](/conception/overview). Cтандартное ограничение `50МБ`, но [Администраторы](/mechanics/roles#admin) [инстансов](/definitions#instance) могут увеличить данный лимит установив значение `BACKEND_MAX_EXTERNAL_REPO_SIZE` в [Backend ENV](/deployment/env-variables#backend).

:::danger
Для выполнения такого строгого требования не рекомендуется хранить в репозиториях картинки и бинарные файлы.
:::

Для микроконтроллеров в [Pepeunit](/conception/overview) есть система чистки репозитория перед генерацией архива с программой, данный алгоритм удалаяет определённые файлы и дирректории. Подробнее об этой механике можно узнать в разделе [структура архивов с обновлениями](/developer/struct-archive-update)