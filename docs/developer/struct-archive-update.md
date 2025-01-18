# Структура архивов c обновлениями

 [Pepeunit](/conception/overview) умеет генеририровать готовые архивы с обновлениями для [Unit](/definitions#unit), при этом алгоритм генерации разный для компилируемых и интерпритируемых Repo,

## Компилируемые

1. Вычисляется [таргет версия](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Добавляются [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) на основе [таргет версии](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл [env.json](/definitions#env-json) записывается [таргет версия](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit) - ключ `COMMIT_VERSION`
1. Создаётся файл Архива - tgz, tar или zip

## Интерпритируемые

1. Вычисляется [таргет версия](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Создаётся временное представление файлов находящихся в этом [коммите](/definitions#git-commit)
1. Удаляются файлы не учавствующие в работе [Unit](/definitions#unit)
1. Добавляются [env.json](/definitions#env-json) и [schema.json](/definitions#schema-json) на основе [таргет версии](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл [env.json](/definitions#env-json) записывается [таргет версия](/developer/update-system#алгоритм-вычисления-текущеи-версии-unit) - ключ `COMMIT_VERSION`
1. Создаётся файл Архива - tgz, tar или zip

Набор файлов и дирректорий которые [Pepeunit](/conception/overview) удаляет:
```txt
.gitignore
env_example.json
.git
docs
model
readme.md
README.md
LICENSE
```

:::info Для чего нужно удаление?
Объём flash памяти у микроконтоллеров обычно очень маленький до 30кБ. Следовательно большие файлы например `LICENSE AGPL v3` - 33.71 кБ, абсолютно точно не поместятся в flash память. Если для ручной установки это не проблема, можно почистить лишние файлы, то для автоматических обновлений автоматическое удаление = единственный возможный выход.
:::