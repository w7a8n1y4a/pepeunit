# Pepeunit MVP
## Pepeunit - IoT система с графовым управлением

## Типы нод

0. `repo_unit`
1. `unit`
1. `input_variable`
1. `output_variable`
1. `user`

## Типы связей между `input_variable` и `output_variable`

0. Запись - по доступу и флагу внутри ноды для `input_variable`
1. Чтение - по доступу для `output_variable`

## Система доступа
- Аналогия с `gitlab` и `fediverse`

0. Без регистрации
1. Пользователи узла
2. Пользователи других узлов
    - подразумевается что `unit` могут брать данные из доверенных `pepeunit` экземпляров, по `uuid`

# Представление о работе системы

## Нода `repo_unit`
- `repo_unit` может создать любой пользователь узла, имя репозитория для локального хранения соответствует `./repositories/<uuid>`
- Возможность доступа до удалённых репозиториев с закрытым доступом
    - применение `AES` шифрования для хранения кредов внутри, ноды
- При установке инстанса, можно добавить стандартные репозитории `unit` от разработчиков `pepeunit`

### Cоздание
0. Вводится название
1. Вводится ссылка для клонирования репозитория
1. Галочка для закрытых репозиториев
    - по умолчанию публичные
1. Вводятся креды до закрытого репозитория, если они нужны
1. Для открытых установок юзером требуется ограничить размер репозитория 10 МБ
1. Установка прав доступа
1. Установка периода синхронизации локальной копии репозитория с удалённым - по умолчанию 1 раз в день
    - всегда есть кнопка принудительного обновления для создателя
1. Галочка отключения синхронизации - в этом случае останется только ручная синхронизация
1. Нажать на кнопку создать
1. Автомитически колонируется удалённый репозиторий
    - специальная дирректория внутри рабочего экземпляра `./repositories/<uuid>`
1. Автомитически стягиваются все доступные ветки - `git fetch`
1. Удалённый репозиторий обязательно содержит два файла `env_example.json` и `schema.json`
    - `env_example.json` - содержит образец нужных переменных окружения контроллера, которые `pepeunit` будет генерировать
    - `schema.json` - содержит набор переменных требуемых для работы `unit`, 4 типа:
        - `world_state` - содержит информацию из внешнего мира - генерируется сервером при ответе на запросы `unit`
            - время по UTC-0
        - `unit_state` - содержит общую информацию о `unit` - хранится внутри ноды
            - `ip` аддрес
            - используемая память
            - время с момента запуска
            - мощность сигнала `wifi` и тд
            - версия прошивки - коммит который использован
        - `input_variables` - управляющие переменные
            - Задаются пользователем или через `output` другого `unit`, возможно так же задать через `open api`
        - `output_variables` - результирующие переменные `unit` 
            - Задаются исключительно физическим `unit`


### Настройка
- Правила:
    - пока нода не настроена нельзя создать ноду `unit` от `repo_unit`

- Установка дефолтной ветки для `unit`: c этой ветки `unit` с автосинхронизацией, будут брать код
    - при создании `unit`, пользователь может отменить эту синхронизацию и выбрать константный комит тег и ветку, в обход настроек `repo_unit`

### Обновление
- Правила:
    - cсылка на репозиторий неможет быть изменена
        - причина в подключении чужих устройств к вашей ноде `pepe_unit`
        - вы ответсвтенны не только за свои устройства, если вы публикуете инстанс

0. Изменение прав доступа
1. Изменение названия ноды
1. Изменение периода синхронизации 

### Удаление
- Правило: нельзя удалить пока есть `unit`, которые прилинкованы к `repo_unit`

0. Кнопка удаления и всё

## Нода `unit`

- `unit` - это сущность внутри `pepeunit`, отражающая состояние удалённого физического устройства. Это могут быть следующие устройства:
    - любое устройство способное зашифровать body запроса через `AES` и отправить `http` запрос
    - `esp8266`, `esp32`, микро ЭВМ по типу rpi и многие другие
    - возможно в будущем будет реализация других протоколов `mqtt` и `websokets`, последний особенно интересен, т.к. позволит управлять чем-либо с минимальными задержками

### Создание

0. Пользватель нажимает на `repo_node` и нажимает на кнопку создать `unit`
    - альтернатива потянуть за ноду с зажатым `shift`
1. Пользователь заполняет данные о `node`
    - Вписывается название `unit`
    - Пользователь выбирает уровень доступа до `unit`
    - Галочка синхронизации версии с `repo_unit` - по умолчанию включена
        - во включенном состоянии пользователь не может выбрирать теги коммиты и ветку, но ему показываются текущие
    - Если синхронизация отключена пользователь может выбрать коммит тег и ветку
1. Пользователь нажимает кнопку создать
1. Создаётся нода `unit`, так же ноды входящих и выходящих переменных по `schema.json` из нужной ветки и тега(коммита) `repo_unit`
1. Создаётся связь между `unit` и `repo_unit`, в связь записывается версия, тег, ветка
1. Генерируется `env.json` для `unit`, автоматически проставляются только определённые обязательные переменные
    - `PEPEUNIT_URL` - `link` до экземпляра `pepeunit` в который добавлена нода
    - `PEPEUNIT_TOKEN` - `jwt` токен, c шифрованной средней частью
    - `SYNC_ENCRYPT_KEY` - используется для `AES` шифрования с двух сторон, `pepeunit` -> `unit`, `unit` -> `pepeunit`
        - Это замена `https`, т.к. стандартные библиотеки `micropython` не поддерживают ассинхронные ключи для любого сайта
        - Известная проблема на форумах `micropython`, если есть идеи или уже готовые реализации, пишите рассмотрим
        - Используется `АES` шифрование 32 битными ключами. Это защищает от атак человек по середине
        - Так же это решает задачу защиты данных в локальной сети
    - `SECRET_KEY` - используется по аналогии с `jwt` токенами, может быть использован для подписи или какого-то дополнительного шифрования, так же 32 битный
1. Шифруется `env.json` и сохраняется в `unit` ноду
1. Нода `unit` на этом этапе готова к эксплуатации на стороне `pepeunit`

### Создание физически

0. Пользователь создаёт или покупает физическое устройство
1. Пользователь заходит на узел `pepeunit` нажимает на `unit`, видит параметры из `unit_state`, а так же ссылку на скачивание `zip` архива
1. Архив содержит `env.json` файл и обрезанную версию репозитория
    - архив сам по себе генерируется каждый раз заного при скачивании, строится на основе версии первичного репозитория
    - при генерации из репозитория удаляются все `example` и `.git` папка с лишними данными
1. Пользователь скачивает `zip` архив
1. Разархивировав программу контроллера, добавляет в `env.json` недостающие переменные с самой секретной информацией - `wifi`: `WIFI_SSID` и `WIFI_PASS`
1. Пользователь окрывает через `PyMakr`
1. Пользователь загружает программу в контроллер
1. Пользователь запускает устройство

### Обновление
- Правила:
    - повторяющиеся ноды остаются
    - новые ноды добавляются
    - отсутствующие удаляются
        - удаляется так же и связи
        - для удалённых экземпляров `pepeunit`, удалённые ноды становятся не доступными
        - история данных так-же удаляется 

0. Может быть полностью автоматическим, при помощи системы автообновлений в `repo_unit`
1. Может быть ручным по кнопке - при этом выбирается версия

### Обновление физически

1. Может быть по `OTA`, автоматически с сохранением существующего `env.json`
1. Может быть ручным по кнопке в `unit`
1. Может быть физическим, c новой заливкой прошивки

### Удаление

0. Удаляет `unit` и все связанные с ним данные

## Нода `user`

### Создание
- Администратор узла:
    - может в ручную верифицировать
    - может включить верификацию электропочт
    - может отключить регистрацию

0. Логин
1. Электропочта
1. Пароль
1. Кнопка зарегистрироваться

### Обновление

0. Пароль

### Удаление
- Либо Админ, либо инициатива пользователя

0. Удаляются все связанные ноды

## Работа `fediverse` в `pepeunit`
- Администратор узла:
    - может отключить `fediverse`
    - может отсекать не доверенные узлы
    - может блокировать определённых пользователей на узле

0. Публичные ноды - всем в интернете
1. Ноды узла - всем на узле
1. Приватные ноды - только создателю

# Todo

## Дампы

0. `neo4j`
1. `.env` от `pepeunit` - очень важная информация т.к. креды и секретная инфа в `neo4j` так же зашифрована
2. `./repositories/*`

## SLS - State Logger System

0. Прямое логирование
1. Среднее по времени
2. Медиана по времени

## Бот телеги

0. Алертинг по превышению и принижению значений переменных данных
1. Возможность делать борды из кнопок переменных управления и вывод данных из переменных `output`
1. Требуется ли алертинг неудачных обновлений?

## Графана 

0. Возможность делать борды из данных с реляционных таблиц по запросу в `open api`
1. Требуется ли реляционная бд для этого ?
