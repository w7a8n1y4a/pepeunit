# Структура архивов с обновлениями

:::info
Pepeunit собирает готовые архивы с обновлениями для Unit. Алгоритм разный для компилируемых и интерпретируемых Unit.
:::

Архив можно получить в форматах tgz, tar и zip: через [MQTT команду UPDATE](/developer/mqtt/default-mqtt-command#update-update-pepeunit) и REST, или в клиенте: `Аппараты` → Unit → `Управление аппаратом` → `Архивы программ`.

## Компилируемые

В архиве только конфигурация, сама программа скачивается отдельно, [подробнее](/developer/release-assets).

1. Вычисляется [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Добавляются env.json и schema.json для этой версии
1. В env.json записывается таргет версия: PU_COMMIT_VERSION
1. Создаётся архив tgz, tar или zip

## Интерпретируемые

1. Вычисляется [таргет версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit)
1. Создаётся временная копия файлов этого коммита
1. По [.pepeignore](/developer/files/struct-pepeignore) удаляются файлы, не нужные для работы Unit
1. Добавляются env.json и schema.json для этой версии
1. В env.json записывается таргет версия: PU_COMMIT_VERSION
1. Создаётся архив tgz, tar или zip
