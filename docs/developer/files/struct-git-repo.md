# Структура GIT репозитория

Структурые элементы описанные здесь используются [Pepeunit](/conception/overview) для различных целей: начиная с генерации [архивов с программами](/developer/files/struct-archive-update) и заканчивая созданием [UnitNode](/definitions#unitnode).

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
- [readme.md](/definitions#readme-md) - описание проекта, содержащее основную информацию о его назначении, установке и использовании
- [env_example.json](/definitions#env-example-json) - отвечает за требующиеся для [Unit](/definitions#unit) переменные окруженияю
- [schema_example.json](/definitions#schema-example-json) - отвечает за схему взаимодействия [Unit](/definitions#unit) с [Pepeunit](/conception/overview), а также за `Input` и `Output` которые будут у [Unit](/definitions#unit)
- `LICENSE` - лицензия на усмотрение автора. Все репозитории [Pepeunit](/conception/overview) имеют лицензию `AGPL v3`
- [.gitignore](/definitions#gitignore) - перечисляет файлы и папки, которые [Git](/definitions#git) должен игнорировать и не включать в контроль версий, [подробнее .gitignore](https://git-scm.com/docs/gitignore).

:::danger
[.pepeignore](/definitions#pepeignore) хоть и не является обязательным файлом, его следует указывать почти всегда, когда вы создаёте свой [Unit](/definitions#unit) для платформ с ограниченным размером памяти
:::



## Размер репозиториев для Pepeunit

У [Pepeunit](/conception/overview) достаточно строгие требования к размеру репозиториев. Это связано с тем что данные придётся хранить на стороне [Pepeunit](/conception/overview). Cтандартное ограничение `50МБ`, но [Администраторы](/development-pepeunit/mechanics/roles#admin) [инстансов](/definitions#instance) могут увеличить данный лимит установив значение `PU_MAX_EXTERNAL_REPO_SIZE` в [Backend ENV](/deployment/env-variables#backend).

:::danger
Для выполнения такого строгого требования не рекомендуется хранить в репозиториях картинки и бинарные файлы.
:::

Для микроконтроллеров в [Pepeunit](/conception/overview) есть система чистки репозитория перед генерацией архива с программой, данный алгоритм удалаяет определённые файлы и дирректории. Подробнее об этой механике можно узнать в разделе [структура архивов с обновлениями](/developer/files/struct-archive-update)