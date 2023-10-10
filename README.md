# Pepeunit MVP
## Pepeunit - IoT система с графовым управлением

## Типы нод

0. `Unit`
1. `Input variable`
2. `Output variable`
3. `repo_unit`

## Типы связей

0. Запись - по доступу и флагу внутри ноды для `Input variable`
1. Чтение - По доступу для `Output variable`

## Система доступа
- Аналогия с `gitlab` и `fedo`

0. Без регистрации
1. Пользователи узла
2. Пользователи других узлов - подразумевается что `unit` - могут брать данные из доверенных `pepeunit` экземпляров, по `uuid`

# Мысли о работе системы в целом
- репозиторий обязательно содержит два файла `env_example.json` и `schema.json`
    - `env_example.json` - содержит образец нужных переменных окружения контроллера, которые `pepeunit` будет генерировать
    - `schema.json` - содержит набор переменных требуемых для работы `unit`, 4 типа:
        - `world_state` - содержит информацию из внешнего мира, которая генерируется сервером без участия других `unit` или пользователя - генерируется сервером при ответе на запросы `unit`
            - время по UTC-0
        - `unit_state` - содержит общую информацию обновляемую от устройства - хранится внутри ноды
            - `ip` аддрес
            - используемая память
            - время с момента запуска
            - мощность сигнала `wifi` и тд
            - версия прошивки - коммит который использован
        - `input_variables` - управляющие переменные `unit`, позволяют передать информацию из вне во внутрь контроллера. Задаются пользователем, через `open api` или через `output` другого `unit`
        - `output_variables` - результирующая переменная `unit`, позволяет передать информацию от `unit` в экземпляр `pepeunit`. Задаётся исключительно самим `unit`

## Нода `repo_unit`
- В зависимости от настройки узла создать ноду может Админ или любой пользователь
- У ноды можно так же настроить видимость для других пользователей
- Для доступа к специфичным `gitlab` инстансам и закрытым `github` репам, нужно внести креды для скачивания репозитория, хранить будем в шифрованном виде, `AES` шифрованием
- При установке инстанса, можно добавить стандартные репозитории `unit` от разработчиков `pepeunit`

### Cоздания ноды
0. Вводится название
1. Вводится ссылка для клонирования репозитория - это сделает работу с репозиториями не зависимой от других платформ
1. Для открытых установок юзером требуется ограничить размер репозитория 10 МБ
1. Установка прав доступа
1. Установка периода синхронизации локальной копии репозитория с удалённым - по умолчанию 1 раз в день
1. Галочка отключения синхронизации
1. Галочка автоматического обновления верхней версии тега или коммита - по умолчания `true`
1. Нажать на кнопку создать
1. Автомитически колонируется удалённый репозиторий в специальную дирректорию приложения `pepeunit` - `git clone`
1. Автомитически стягиваются все доступные ветки - `git fetch`
1. Проверка на наличие файлов `env_example.json` и `schema.json`

### Настройка (Обновление)

#### Пока не настроено - нельзя создать ноду
- Установка дефолтной ветки для `unit` - при создании `unit`, пользователь может изменить
- Установка дефолтного коммита или дефолтного тега у `unit` - при создании `unit`, пользователь может изменить

0. Изменение дефолтной ветки
0. Изменение дефолтного коммита или дефолтного тега
1. Изменение прав доступа
1. Изменение названия
1. Изменение периода синхронизации
1. Ссылка на репозиторий неможет быть изменена

### Удаление
- Правило: нельзя удалить пока есть `unit`, которые прилинкованы к `repo_unit`

0. Кнопка удаления и всё

## Нода `unit`

- `unit` - это интерфейс настройки работы конетроллеров в удалённом формате, разрабатывается для синхронных запросов `esp8266`, возможно потом будет для `esp32` и для работы с сокетами

### Создание `unit` в `pepeunit`

0. Пользватель нажимает на `repo_node` и нажимает на кнопку создать `unit` - альтернатива потянуть за ноду с зажатым `shift`
1. Пользователь заполняет данные о `node`
    - Вписывается название `unit`
    - Пользователь выбирает уровень доступа до `unit`
    - Пользователь выбирает обновлять ли автоматически до последней версии из `repo_unit` - опционально, по умолчанию `false`, если true то выводится дефолтная ветка без возможности отредачить
    - У пользователя высветятся дефолтная ветка и коммит или тег - он может их изменить из выпадаек если автоматически проставлено - `false`
1. Пользователь нажимает кнопку создать
1. Создаётся нода `unit`, так же ноды входящих и выходящих переменных по `schema.json` из нужной ветки и тега(коммита) `repo_unit`
1. Генерируется `env.json` для `unit`, автоматически проставляются только определённые обязательные переменные
    - `PEPEUNIT_URL` - `link` до экземпляра `pepeunit` в который добавлена нода
    - `PEPEUNIT_TOKEN` - `jwt` токен, c шифрованной средней частью
    - `SYNC_ENCRYPT_KEY` - используется для `AES` шифрования с двух сторон, `pepeunit` -> `unit`, `unit` -> `pepeunit`
        - Это замена `https`, т.к. стандартные библиотеки `micropython` не поддерживают большие ассинхронные ключи, поэтому используется `АES` шифрование 32 битными ключами. Известная проблема на форумах `micropython`, если есть идеи или уже готовые реализации, пишите рассмотрим
    - `SECRET_KEY` - используется по аналогии с `jwt` токенами, может быть использован для подписи или какого-то дополнительного шифрования, так же 32 битный
1. Шифруется `env.json` и сохраняется в `unit` ноду
1. `unit` на этом этапе готов к эксплуатации на стороне `pepeunit`

### Создание `unit` физически в первый раз

1. Пользователь нажимает на `unit`, видит параметры из `unit_state`, а так же ссылку на скачивание `zip` архива
1. Архив содержит `env.json` файл и обрезанную версию репозитория, он находится на установленном теге и ветке, но из репозитория удаляются все `example` и `.git` папка для уменьшения общего веса
1. Пользователь скачивает `zip` архив
1. Разорхивировав программу контроллера, добавляет в `env.json` недостающие переменные с самой секретной информацией - `wifi`: `WIFI_SSID` и `WIFI_PASS`
1. Пользователь окрывает через `PyMakr` разорхивированный архив
1. Пользователь загружает программу в контроллер
1. Пользователь запускаяет устройство

### Обновление `unit` в `pepeunit`

#### Правило
- Повторяющиеся ноды остаются, новые ноды добавляются, а отсутствующие удаляются. В случае удаления - удаляется так же и связи, для удалённых экземпляров `pepeunit` они становятся не доступными, история так-же удаляется.

0. Может быть полностью автоматическим, при помощи системы автообновлений в `repo_unit`
1. Может быть ручным по кнопке
1. 

### Обновление `unit` физически

1. Может быть по `OTA`, автоматически с сохранением существующего `env.json`
1. Может быть ручным с заменой `env.json`

### Удаление `unit`

0. Удаляет `unit` и все связанные с ним данные

## Получение данных за период

0. `Open API` - позволяет сделать доставание логов по `output` переменным через фильтр, он же может использоваться для `graphana`
1. `todo` обдумать - это должна быть реляционная бд или какая-то доп система?

# Todo

## SLS - State Logger System

0. Прямое логирование
1. Среднее по времени
2. Медиана по времени

## Бот телеги

0. Алертинг по превышению и принижению значений переменных данных
1. Возможность делать борды из кнопок переменных управления и вывод данных из переменных `output`

## Графана 

0. Возможность делать борды из данных с реляционных таблиц
