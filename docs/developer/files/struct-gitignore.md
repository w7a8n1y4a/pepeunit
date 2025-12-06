# .gitignore

:::info
Cодержит файлы и папки, которые [Git](/definitions#git) должен проигнорировать при версионировании, обычно это следующие категории файлов:
1. Окружения из библиотек, как например `.venv` из `python`
1. Cекреты, которые не должны быть опубликованы. Применимо к [Pepeunit](/conception/overview), это [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json), в других репозиториях аналогичную функцию часто выполняют `.env` файлы.
:::

## Пример
```gitignore
.idea
.nvim
env.json
schema.json
tmp
```