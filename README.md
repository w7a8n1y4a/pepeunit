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
Аналогия с `gitlab` и `fedo`

0. Без регистрации
1. Пользователи узла
2. Пользователи других узлов - подразумевается что `unit` - могут брать данные из доверенных `pepeunit` экземпляров, по `uuid`

# Мысли о работе системы в целом

## Нода репозитория
- В зависимости от настройки узла создать ноду может Админ или любой пользователь
- У ноды можно так же настроить видимость для других пользователей
- Для доступа к специфичным `gitlab` инстансам и закрытым `github` репам, нужно внести креды для скачивания репозитория, хранить будем в шифрованном виде, aes шифрованием
- При установке инстанса, можно добавить стандартные репозитории `unit` от разработчиков `pepeunit`

### Cоздания ноды

0. Вводится название
1. Вводится ссылка для клонирования репозитория - это сделает работу с репозиториями не зависимой от других платформ
1. Для открытых установок юзером требуется ограничить размер репозитория 10 МБ
1. Установка прав доступа
1. Установка периода синхронизации локальной копии репозитория с удалённым - по умолчанию 1 раз в день
1. Нажать на кнопку создать
1. Автомитически колонируется удалённый репозиторий в специальную дирректорию приложения `pepeunit` - `git clone`
1. Автомитически стягиваются все доступные ветки - `git fetch`

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

## Создание нового `unit` в `pepeunit`

0. Пользватель нажимает на 
0. Пользователь создаёт ноду c `unit`
    - вписывается название
    - вписывает линк на репозиторий `unit` с программой для контроллера
    - репозиторий содержит обязательно два файла `env_example.json` и `schema.json`
        - `env_example.json` - содержит образец нужных переменных для генерации экземпляром pepeunit
        - `schema.json` - содержит набор переменных требуемых для работы `unit`, в основе это 4 типа:
            - `world_state` - содержит информацию из внешнего мира, которая генерируется сервером без участия других `unit` или пользователя
                - время по UTC-0
            - `unit_state` - содержит общую информацию обновляемую от устройства
                - ip аддрес
                - используемая память
                - время с момента запуска
                - мощность сигнала `wifi` и тд
            - `input_variables` - управляющие переменные `unit`, позволяют передать информацию из вне во внутрь контроллера. Задаются пользователем, через `open api` или через `output` другого `unit`
            - `output_variables` - результирующая переменная `unit`, позволяет передать информацию от `unit` в экземпляр `pepeunit`. Задаётся исключительно самим `unit`
    - Пользователь нажимает кнопку создать
    - Генерируется нода `unit`, так же ноды входящих и выходящих переменных по `schema.json`
    - Генерируется `env.json` для `unit`, автоматически проставляются только определённые обязательные переменные
        - `PEPEUNIT_URL` - `link` до экземпляра `pepeunit` который генерирует `env.json`
        - `PEPEUNIT_TOKEN` - `jwt` токен, c шифрованной средней частью
        - `SYNC_ENCRYPT_KEY` - используется для `AES` шифрования с двух сторон, `pepeunit` -> `unit`, `unit` -> `pepeunit`
            - Это замена `https`, т.к. стандартные библиотеки `micropython` не поддерживают большие ассинхронные ключи, поэтому используется `АES` шифрование 32 битными ключами. Известная проблема на форумах `micropython`, если есть идеи или уже готовые реализации, пишите рассмотрим
        - `SECRET_KEY` - используется по аналогии с `jwt` токенами, может быть использован для подписи или какого-то дополнительного шифрования, так же 32 битный
    - Шифруется `env.json` и сохраняется в `unit` ноду
    - `unit` на этом этапе готов к эксплуатации на стороне `pepeunit`
1. Пользователь нажимает на `unit`, видит параметры из `unit_state`, а так же ссылку на скачивание `env.json` файла
1. Пользователь скачивает `env.json` файл и добавляет в него пареметры подключения к своему `wifi` - `WIFI_SSID` и `WIFI_PASS`
1. Пользователь клонирует репозиторий, открывает через `PyMakr` программу своего `unit`
1. Добавляет сгенерированный `env.json` в программу, и загружает в контроллер `esp8266`
1. Пользователь запускаяет устройство
1. Пользователь может запросить обновление `env.json` - он сгенерируется заного, при этом прошивку нужно будет изменить в ручную, при этом данные будут взяты изнутри `pepeunit`, т.к. версия по ссылке могла уже измениться

## Обновление прошивки

0. Пользователь нажимает на обновление прошивки
1. Из уже введённого удалённого репозитория стягивается заного `json_example.json` и `schema.json`
1. Повторяющиеся ноды остаются, новые ноды добавляются, а отсутствующие удаляются. В случае удаления - удаляется так же и связи, для удалённых экземпляров `pepeunit` они становятся не доступными, история так-же удаляется.

## Получение данных за период

0. `Open API` - позволяет сделать доставание логов по `output` переменным через фильтр, он же может использоваться для `graphana`
1. `todo` обдумать - это должна быть реляционная бд или какая-то доп система?

# Todo

## Концепция хранения репозиториев внутри `pepeunit`

В основе бибилиотека `git python`

0. Админ добавляет на экземпляр верифицированные им самим репозитории - опять же ссылками, но при этом они скачиваются и хранятся в определённой папке. Обьём информации в них очень маленький, так что хватит
1. Нужна отедельная нода под каждый репозиторий
1. Нода репозитория может так же обновляться при этом - `git clone` и тд. Управление этой нодой отдельная темка, выбор веток, тегов и тд.
1. Новый `Unit` линкуется до ноды содержащей полную информацию о репозитории
1. Обновление в этом случае может быть полностью автоматическим по всем связанным `unit`, у нод `unit` должна быть возможность отписаться от автообновления
1. Пользователь при этом будет получать `zip` архив при создании ноды, в котором ему потребуется только добавить креды до роутера
1. При обновлении ноды может быть применён алгоритм обновления через eeprom
1. На узле можно разрешить добавлять пользовательские репозитории

## SLS - State Logger System

0. Прямое логирование
1. Среднее по времени
2. Медиана по времени

## Бот телеги

0. Алертинг по превышению и принижению значений переменных данных
1. Возможность делать борды из кнопок переменных управления

## Графана 

0. Возможность делать борды из данных с реляционных таблиц
