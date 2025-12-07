# .pepeignore

:::info Для чего нужно удаление?
Память у микроконтолеров ограничена. Например, файл с лицензией `LICENSE AGPL v3` размером `33.71 кБ` может занять почти всю `flash` память, что недопустимо. Поэтому, прежде чем создавать архив, память необходимо отчистить от лишних файлов.
:::

[.pepeignore](/definitions#pepeignore) выделяет паттерны файлов и папок аналогично [.gitignore](/definitions#gitignore). [Pepeunit](/conception/overview) получает пути всех файлов, подходящих под паттерн, и удаляет их.

Чистка происходит в момент генерации архива обновления для [Unit](/definitions#unit), Пример заполнения:
```.pepeignore
.git
.gitignore
.pepeignore
env_example.jsonc
schema_example.json
pepeunit.toml
README.md
LICENSE
```