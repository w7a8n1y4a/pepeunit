# Структура архивов c обновлениями

:::info
[Pepeunit](/conception/overview) умеет генеририровать готовые архивы с обновлениями для [Unit](/definitions#unit), при этом алгоритм генерации разный для [Компилируемых](/definitions#compilable) и [Интерпритируемых](/definitions#interpreterable) [Repo](/definitions#repo) ,
:::

## Компилируемые

1. Вычисляется [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Добавляются [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) на основе [таргет версии](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл [env.json](/definitions#env-json) записывается [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) - `PU_COMMIT_VERSION`
1. Создаётся файл Архива - `tgz`, `tar` или `zip`

## Интерпритируемые

1. Вычисляется [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Создаётся временное представление файлов находящихся в этом [коммите](/definitions#git-commit)
1. Удаляются файлы не участвующие в работе [Unit](/definitions#unit) на основе [.pepeignore](/definitions#pepeignore)
1. Добавляются [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) на основе [таргет версии](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл [env.json](/definitions#env-json) записывается [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) - `PU_COMMIT_VERSION`
1. Создаётся файл Архива - `tgz`, `tar` или `zip`
