# Структура архивов c обновлениями

[Pepeunit](/conception/overview) умеет генеририровать готовые архивы с обновлениями для [Unit](/definitions#unit), при этом алгоритм генерации разный для [Компилируемых](/definitions#compilable) и [Интерпритируемых](/definitions#interpreterable) [Repo](/definitions#repo) ,

## Компилируемые

1. Вычисляется [таргет версия](/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Добавляются [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) на основе [таргет версии](/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл [env.json](/definitions#env-json) записывается [таргет версия](/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) - ключ = `COMMIT_VERSION`
1. Создаётся файл Архива - `tgz`, `tar` или `zip`

## Интерпритируемые

1. Вычисляется [таргет версия](/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Создаётся временное представление файлов находящихся в этом [коммите](/definitions#git-commit)
1. Удаляются файлы не участвующие в работе [Unit](/definitions#unit) на основе [.pepeignore](/definitions#pepeignore)
1. Добавляются [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) на основе [таргет версии](/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл [env.json](/definitions#env-json) записывается [таргет версия](/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) - ключ = `COMMIT_VERSION`
1. Создаётся файл Архива - `tgz`, `tar` или `zip`


## .pepeignore

:::info Для чего нужно удаление?
Объём `flash` памяти у микроконтоллеров обычно до `30кБ`. Следовательно большие файлы, например: `LICENSE AGPL v3` - `33.71 кБ` - абсолютно точно не поместятся в `flash` память. Т.к. В [Pepeunit](/conception/overview) есть функционал автоматических обновлений, нужна система чистки файлов текущей версии перед отправкой [Unit](/definitions#unit).
:::

[.pepeignore](/definitions#pepeignore) выделяет паттерны файлов и папок аналогично [.gitignore](https://git-scm.com/docs/gitignore). [Pepeunit](/conception/overview) получает пути всех файлов подходящих под паттерн и удаляет их.

Чистка происходит в момент генерации архива обновления для [Unit](/definitions#unit), Пример заполнения:
```.pepeignore
.git
.gitignore
.pepeignore
env_example.json
schema_example.json
docs
model
README.md
LICENSE
```