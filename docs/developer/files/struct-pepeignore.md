# .pepeignore

:::info Для чего нужно удаление?
1. Объём `flash` памяти у микроконтолеров ограничен. Следовательно большие файлы, например: `LICENSE AGPL v3` - `33.71 кБ` - будут занимать значительный объём `flash` памяти.
1. Когда автоматически генерируется архив для обновлений, его нужно отчистить от лишних файлов, [.pepeignore](/definitions#pepeignore) как раз предоставляет список для отчистки.
:::

[.pepeignore](/definitions#pepeignore) выделяет паттерны файлов и папок аналогично [.gitignore](/definitions#gitignore). [Pepeunit](/conception/overview) получает пути всех файлов подходящих под паттерн и удаляет их.

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