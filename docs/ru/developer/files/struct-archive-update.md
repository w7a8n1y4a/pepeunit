# Структура архивов c обновлениями

:::info
Pepeunit умеет генеририровать готовые архивы с обновлениями для Unit, при этом алгоритм генерации разный для Компилируемых и Интерпретируемых Repo ,
:::

## Компилируемые

1. Вычисляется [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Добавляются env.json и schema.json на основе [таргет версии](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл env.json записывается [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) - `PU_COMMIT_VERSION`
1. Создаётся файл Архива: `tgz`, `tar` или `zip`

## Интерпретируемые

1. Вычисляется [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Создаётся временное представление файлов находящихся в этом коммите
1. Удаляются файлы, не участвующие в работе Unit, на основе .pepeignore
1. Добавляются env.json и schema.json на основе [таргет версии](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. В файл env.json записывается [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) - `PU_COMMIT_VERSION`
1. Создаётся файл Архива: `tgz`, `tar` или `zip`
