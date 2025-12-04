# Создание Unit физически

## Настройка окружения

Перейдите в модальное окно [Unit](/definitions#unit) и нажмите на зелёную кнопку `Set Env Variable`, здесь вас встретят переменные которые нужно заполнить.

Обычно [Разработчики Unit](/development-pepeunit/mechanics/roles#unit-developer) преднастраивают их для корректной работы [Unit](/definitions#unit), но часть из них, как например: `WIFI_SSID` и `WIFI_PASS` - нужно заполнить вашими данными.

Подсказку о функциональном назначении каждой переменной, можно найти кликнув на ссылку удалённого репозитория - `Documentation Link`, там [Разработчики Unit](/development-pepeunit/mechanics/roles#unit-developer) обычно расписывают назначение 

После нажатия кнопки `Update`, переменные которые вы добавили сохранятся.

:::info
Переменные окружения хранится в [шифрованном](/development-pepeunit/mechanics/cipher) виде.
:::

:::warning
Кнопка `reset` - позволяет сбросить переменные до состояния предусмотренного [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer). Это состояние результат работы [алгоритма генерации env](/development-pepeunit/mechanics/alg-env)
:::

:::danger
До нажатия кнопки `Update` [системные переменные](/developer/files/struct-env-example-json) c префиксом `PU_` будут генерироваться заного каждый раз при запросе переменных. После нажатия `Update` они зафиксируются. 
:::

## Получение файлов развёртывания

В зависимости от того [Компилируемый](/definitions#compilable) ли у вас [Repo](/definitions#repo), процесс получения файлов будет отличаться:

### Компилируемый Repo

Вам потребуется скачать два компанента вашего будущего [Unit](/definitions#unit): 
1. Cкомпилированную часть из вкладки `Compiled Firmware Platforms`, содержащей ссылки на [платформы](/developer/release-assets) текущей [таргет версии](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) [Unit](/definitions#unit).
1. [Архив](/developer/files/struct-archive-update) из вкладки `Firmware with env.json and schema.json`.

Вам нужно будет расположить файлы из [архива](/developer/files/struct-archive-update) в одной дирректории с выбранной вами [платформой](/developer/release-assets), чтобы они увидели друг друга

### Интерпритируемый Repo

Достаточно скачать [архив](/developer/files/struct-archive-update) из вкладки `Firmware with env.json and schema.json`, в нём будут находиться все нужные вам файлы. После распаковки [архива](/developer/files/struct-archive-update) вы будете готовы перейти на следующую стадию.

:::info
Для [Micropython](/definitions#micropython) потребуется предварительно установить интерпритатор на физический [Unit](/definitions#unit)
:::

## Первое развёртывание

Обычно требуется загрузить файлы полученные на предыдущем этапе на ваш физический носитель и соблюсти условия запуска.

Для микроконтроллеров `esp32, stm ...` потребуется загрузить файлы в `flash` память и запустить работу устройства через кнопку `reset`.

Для `Desktop` приложений обычно достаточно запустить бинарный файл или вызвать командой интерпритатора нужный файл.

:::warning
Здесь не может быть универсального правила, т.к. [Unit](/definitions#unit) могут быть совершенно разнообразны, обычно [Разработчики Unit](/development-pepeunit/mechanics/roles#unit-developer) оставляют инструкцию как корректно заставить [Unit](/definitions#unit) работать в [Readme](/definitions#readme-md) [Git](/definitions#git) репозитория.
:::
