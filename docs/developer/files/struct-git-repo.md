# Структура GIT репозитория

:::danger

У [Pepeunit](/conception/overview) строгие требования к размеру репозиториев - это связано с хранением репозиториев на стороне инстансов [Pepeunit](/conception/overview).

Cтандартное ограничение `50МБ`, но [Администраторы](/development-pepeunit/mechanics/roles#admin) инстансов могут увеличить данный лимит установив значение `PU_MAX_EXTERNAL_REPO_SIZE` в [Backend ENV](/deployment/env-variables/backend).

Для выполнения такого строгого требования не рекомендуется хранить в репозиториях картинки и бинарные файлы.

Для микроконтроллеров в [Pepeunit](/conception/overview) есть система очистки репозитория перед генерацией архива с программой. Данный алгоритм удалаяет определённые файлы и директории. Подробнее об этой механике можно узнать в разделе [структура архивов с обновлениями](/developer/files/struct-archive-update).
:::

## Набор файлов в репозитории Unit

Файлы которые [Pepeunit](/conception/overview) ожидает увидеть в репозитории [Unit](/definitions#unit):

```bash
$> tree -a -L 2
.
├── env_example.json
├── .git
│   └── ...
├── .gitignore
├── LICENSE
├── .pepeignore
├── pepeunit.toml
├── README.md
└── schema_example.json
```

- [schema_example.json](/definitions#schema-example-json)
- [env_example.json](/definitions#env-example-json)
- [pepeunit.toml](/definitions#pepeunit-toml)
- [readme.md](/definitions#readme-md)
- [.gitignore](/definitions#gitignore)
- [.pepeignore](/definitions#pepeignore) 
- [LICENSE](/definitions#license)
