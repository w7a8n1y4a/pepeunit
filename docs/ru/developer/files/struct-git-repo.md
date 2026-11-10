# Структура GIT репозитория

:::danger
Pepeunit хранит копию каждого Repo на инстансе, поэтому размер ограничен. По умолчанию это 50 МБ, владелец инстанса меняет предел настройкой pu_instance_repo_max_size, см. [настройки инстанса](/deployment/instance-settings#репозитории). Если Repo больше, синхронизация закончится ошибкой.

Не храните в репозитории картинки и бинарные файлы.

Для микроконтроллеров перед сборкой архива репозиторий очищается по правилам .pepeignore, подробнее в [структуре архивов с обновлениями](/developer/files/struct-archive-update).
:::

## Набор файлов в репозитории Unit

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

Файл | Нужен ли | Зачем
-- | -- | --
[schema_example.json](/developer/files/struct-schema-example-json) | Обязателен | Топики Unit
[env_example.json](/developer/files/struct-env-example-json) | Обязателен | Переменные окружения Unit
[pepeunit.toml](/developer/files/struct-pepeunit-toml) | Желателен | Машиночитаемое описание Unit
[readme.md](/developer/files/struct-readme) | Желателен | Документация для Пользователей, генерируется из pepeunit.toml
[.gitignore](/developer/files/struct-gitignore) | Желателен | Не даёт опубликовать env.json и schema.json
[.pepeignore](/developer/files/struct-pepeignore) | Для интерпретируемых Unit | Что не попадёт на устройство
LICENSE | Желателен | Лицензия проекта

Без schema_example.json или env_example.json Unit создать нельзя.
