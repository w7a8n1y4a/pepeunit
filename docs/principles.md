# Принципы работы
::: tip Какие задачи решают принципы?
Принципы обеспечивают целостность работы системы и определяют, то как [Pepeunit](definitions#pepeunit) взаимодействует с сущностями, которые его составляют, а также определяют стандартное поведение пользователя и [Unit](definitions#unit)
:::

## Зависимости

::: tip Для чего нужны зависимости приложению Pepeunit?
Зависимости - дополнительные приложения требующиеся для корректной работы [Pepeunit](definitions#pepeunit)
:::

### MQTT Broker EMQX

[MQTT Broker](definitions#mqtt-broker) - обеспечивает прямое взаимодействие через 1883 и 8883 порты между [Unit](definitions#unit) и [Backend](definitions#backend). Его можно назвать рельсой данных, на которую завязано основное взаимодействие.

::: tip Ключевые моменты
[Backend](definitions#backend) выполняет функцию регулятора, а именно:
1. Авторизация всех [Unit](definitions#unit) для доступа к определённым топикам
1. Агрегация данных из определённых топиков, согласно политике имён топиков
1. Управление [Unit](definitions#unit), при помощи публикации в опредённые топики
:::

[Unit](definitions#unit) могут взаимодействовать напрямую между собой через [MQTT Broker](definitions#mqtt-broker), если это определено политиками доступа к топикам, а [MQTT Broker](definitions#mqtt-broker) в свою очередь запрашивает авторизацию у [Backend](definitions#backend) или в автономном режиме из сгенерированного [ACL List](definitions#acl-list).

Перевичное конфигурирование [MQTT Broker](definitions#mqtt-broker) осуществляется вручную, при помощи генератора `.env` файла в [Backend](definitions#backend). Последующее взаимодействие идёт по средствам [API](definitions#api) запросов. Брокер `EMQX` на два порядка производительней чем [Backend](definitions#backend), но благодаря системе кэширования авторизации `EMQX` и кэшированию через [Redis](definitions#redis), [Backend](definitions#backend) может справится с нагрузкой.

### База данных Postgresql

[Postgresql](definitions#postgresql) - обеспечивает хранение информации о всех сущностях, и доступах. Также обеспечивает сохранение статистической информации о состояниях [UnitNode](definitions#unitnode) и данных о существующих [Узлах](definitions#instance) [Pepeunit](definitions#pepeunit). Взаимодействует напрямую с [Backend](definitions#backend).

### Redis

[Redis](definitions#redis) - обеспечивает кэширование и хранение промежуточной информации о состоянии [UnitNode](definitions#unitnode), при общении [Unit](definitions#unit) c [MQTT Broker](definitions#mqtt-broker). Взаимодействует напрямую с [Backend](definitions#backend).

## Сущности

::: tip Что такое сущности в Pepeunit?
Основные элементы системы с которыми взаимодействуют пользователи и физические [IoT](definitions#iot) устройства.
:::

### Repo

[Repo](definitions#repo) - это создаваемая пользователем сущность с уникальным именем на [Узле](definitions#instance), содержащая в себе информацию о репозитории [Git](definitions#git).

Репозиторий [Git](definitions#git) может быть размещён на [Узле](definitions#instance) [Gitlab](definitions#gitlab) или [Github](definitions#github). [Pepeunit](definitions#pepeunit) умеет скачивать не только публичные репозитории, но и закрытые, для этого требуется указать токен доступа до репозитория. Токены доступа хранятся в шифрованном виде и доступны только создателю [Repo](definitions#repo).

По умолчанию [Repo](definitions#repo) будет синхронизироваться с удалённым репозиторием каждые 24 часа, но это время можно сократить до 10 минут или отменить синхронизацию вовсе и делать её только вручную. У создателя всегда есть возможность заставить [Repo](definitions#repo) принудительно синхронизироваться по нажатию кнопки.

При настройке [Repo](definitions#repo) требуется указать ветку по умолчанию - это позволит автоматически обновляться отстыкованным [Unit](definitions#unit), у которых стоит флаг о автоматическом обновлении. Важно отметить, что отстыковать [Unit](definitions#unit) от [Repo](definitions#repo) нельзя пока не указана ветка по умолчанию.

Так же есть возможность указать флаг, который бы заставлял [Unit](definitions#unit) обновляться только при появлении нового [Тега](definitions#git-tag)

::: tip Механизм работы обновлений
1. Происходит автоматическая или ручная инициализация обновления [Repo](definitions#repo)
1. [Pepeunit](definitions#pepeunit) проверяет [schema.json](definitions#schema-json) и [env_example.json](definitions#env-example-json) в выбранной версии на корректность
1. [Pepeunit](definitions#pepeunit) последовательно проходит по каждому отстыкованному [Unit](definitions#unit) и актуализирует следующую информацию:
    - [schema.json](definitions#schema-json) в выбранной версии [Repo](definitions#repo) проверяется на наличие нужных категорий топиков.Если топиков нет, то создаётся сущность [UnitNode](definitions#unitnode). Если сущность [UnitNode](definitions#unitnode) существует, но её нет в [schema.json](definitions#schema-json) она будет удалена.
    - [env_example.json](definitions#env-example-json) в версии [Repo](definitions#repo) сверяется с зашифрованным [env.json](definitions#env-json) на наличие нужных для работы переменных.
1. [Pepeunit](definitions#pepeunit) последовательно отправляет каждому подходящему [Unit](definitions#unit) требование об обновлении по [OTA](definitions#ota), через топик [MQTT](definitions#mqtt)
1. [Unit](definitions#unit) видят требование о обновлении, сравнивают версию своей текущей микропрограммы и новой версии от [Pepeunit](definitions#pepeunit). При не совпадении версий - обновляют свою микропрограмму по [OTA](definitions#ota). При совпадении версий - игнорируют.
:::

:::warning Важно
[Repo](definitions#repo) невозможно его удалить, если на него ссылается хотябы один [Unit](definitions#unit)
:::

### Unit

[Unit](definitions#unit) - это центральная сущность в [Pepeunit](definitions#pepeunit), обладающая уникальным именем на [Узле](definitions#instance), она представляет физичеcкое [IoT](definitions#iot) устройство внутри системы [Pepeunit](definitions#pepeunit).

[Unit](definitions#unit) можно создать только отстыковав его от [Repo](definitions#repo) - это может сделать любой позователь при наличии доступов - через [Frontend](definitions#frontend) или [API](definitions#api).

[Unit](definitions#unit) можно настроить, указав будет ли он обновляться автоматически при обновлении [Repo](definitions#repo) или же обновление будет происходить исключительно вручную с указанием [Ветки](definitions#git-branch) и [Коммита](definitions#git-commit).

В момент создания [Unit](definitions#unit), на основании выбранной версии и [schema.json](definitions#schema-json) - будут сгенерированы [UnitNode](definitions#unitnode) отвечающие за точки взаимодействия с [Unit](definitions#unit)

Настройка [Unit](definitions#unit) по мимо видимости, доступов и настройки обновлений -  включает в себя заполнение файла [env.json](definitions#env-json). Файл является очень важным, так как содержит конфиденциальные данные о подключении физического устройства к [Pepeunit](definitions#pepeunit), в том числе пароли от `WiFi`.

::: tip Механизм заполнения файла окружения Unit
1. Пользователь первично видит только те переменные, которые [Pepeunit](definitions#pepeunit) не может заполнить сам, обычно это данные о подключении к `WiFi`.
1. Пользователь заполняет значения переменных и отправляет их в [Pepeunit](definitions#pepeunit)
1. [Pepeunit](definitions#pepeunit) присылает полностью заполненный [env.json](definitions#env-json)
1. Пользователь может внести изменения по своему желанию если это требуется
1. [env.json](definitions#env-json) отправляется в [Pepeunit](definitions#pepeunit) где шифруется и сохраняется до востребования.
:::

Когда настройка виртуального [Unit](definitions#unit) в [Pepeunit](definitions#pepeunit) завершена, следует создать ваше [IoT](definitions#iot) устройство физически. После установки [Micropython](definitions#micropython) на ваше устройство, вам нужно загрузить на него микропрограмму. Её можно получить напрямую из интерфейса [Unit](definitions#unit).

Вы можете скачать микропрограмму в формате `zip` или `tar`, и при помощи вспомогательного `ПО` загрузить его на устройство [IoT](definitions#iot) c уже предустановленным [Micropython](definitions#micropython), после чего ваше [IoT](definitions#iot) устройство начнёт работу.

### UnitNode

[UnitNode](definitions#unitnode) - это автоматически генерируемые сущности связанные с [Unit](definitions#unit), они cоздаются на основе файла [schema.json](definitions#schema-json), который содержится в разных версиях [Repo](definitions#repo).

Каждая сущность [UnitNode](definitions#unitnode) может иметь два типа `Input` или `Output`. При этом между [UnitNode](definitions#unitnode) разных [Unit](definitions#unit), могут быть связи - от одного `Output` к многим `Input`. Всё взаимодействие между [UnitNode](definitions#unitnode) происходит при этом через [MQTT Broker](definitions#mqtt-broker). [Backend](definitions#backend) при этом заниматся только авторизацией [Unit](definitions#unit) для доступа до определённых топиков.


::: warning Нюансы работы UnitNode
`Input` тип для [UnitNode](definitions#unitnode) можно понимать как точку из которой [Unit](definitions#unit) получает данные от внешнего мира. Положить данные в данную точку можно любым из [API](definitions#api), которые поддерживаются в [Backend](definitions#backend).

`Input` [UnitNode](definitions#unitnode) могут ограничить доступ на свою перезапись для других [Unit](definitions#unit)  - это нужно когда есть потребность обеспечить доступ только для пользователей, с такими [UnitNode](definitions#unitnode) нельзя создать связь.

В `Output` информацию может помещать только сам [Unit](definitions#unit), которому принадлежит [UnitNode](definitions#unitnode). [Unit](definitions#unit) может это осуществить через любой доступный [API](definitions#api) в [Backend](definitions#backend).

`Output` [UnitNode](definitions#unitnode) с определёнными названиями, могут заставлять [Pepeunit](definitions#pepeunit) накапливать статистику по их состоянию во времени. Это могут быть например датчики температуры - отправляющие сообщения каждую секунду, [Pepeunit](definitions#pepeunit) позволит найти средне часовые температуры.
:::

---

## Уровни видимости сущностей

::: tip На что влияет уровень видимости?
От уровня видимости сущностей будет зависеть кто их сможет увидеть и/или провзаимодействовать. Всего уровня видимости 3.
:::

### Public

- предоставляет доступ до сущности всем

### Internal

- предоставляет доступ до сущности только авторизованным пользователям [Узла](definitions#instance) или всем [Unit](definitions#unit)

### Private

- предоставляет доступ до сущности только создателю и указанным доверенным пользователям [Узла](definitions#instance) или отдельным [Unit](definitions#unit)

---

## Роли

::: tip Какую функцию несут роли пользователей в системе?
Роль пользователя влияет на его возможности при использовании [Узла](definitions#instance) [Pepeunit](definitions#pepeunit).
:::

### Admin

Aдминистратор - владелец, выполняющий функции модератора, имеет полномочия полного управления [Узлом](definitions#instance) [Pepeunit](definitions#pepeunit).

:::tip Возможности Администратора
- блокирование пользователей, при нарушении условий использования [Узла](definitions#instance)
- блокирование работы отдельных [Unit](definitions#unit), при нарушении условий использования [Узла](definitions#instance)
- блокирование взаимодействия [Узел](definitions#instance)-[Узел](definitions#instance), если это нарушает работу текущего [Узла](definitions#instance) [Pepeunit](definitions#pepeunit)
- имеет доступ к настройке лимитов для создания [Unit](definitions#unit)
- имеет доступ ко всем сущностям, но не может получить информацию о зашифрованных данных напрямую через [Pepeunit](definitions#pepeunit)
:::

:::danger Очень важно!!!!
Стоит понимать что имея досутп до `.env` файла [Pepeunit](definitions#pepeunit), Администратор может расшифровать ваши [env.json](definitions#env-json) файлы. Поэтому используйте только [Pepeunit](definitions#pepeunit) [Узлы](definitions#instance), которым вы можете доверить информацию из своих [env.json](definitions#env-json) файлов.
:::

### User

Пользователь - человек, зарегистрированный на [Узле](definitions#instance) [Pepeunit](definitions#pepeunit).

::: tip Возможности обычного пользователя
- имеет доступ к созданию [Repo](definitions#repo), [Unit](definitions#unit) и [UnitNode](definitions#unitnode)
- имеет доступ к сущностям чей уровень видимости `Public`, `Internal` или `Private` если предоставлен доступ
:::

### Bot

Внешний агент - обычный пользователь интернета или любая программа.

::: tip Возможности внешнего агента
- Может взаимодействовать только с сущностями у которых уровень видимости соответствует Public
:::

---

## Шифрование

[Pepeunit](definitions#pepeunit) использует шифрование `AES256` с `16 байтовым` инициирующим вектором и `32 байтовым` ключом - схема шифрования `CBC`

```python
def aes_encode(data: str, key: str = settings.encrypt_key) -> str:
    """
    data: any python str
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: (base64 str - iv).(base64 str - encrypted data)
    """
    key = base64.b64decode(key.encode())
    iv = os.urandom(16)

    # set encrypter
    encrypter = pyaes.Encrypter(pyaes.AESModeOfOperationCBC(key, iv))
    # encrypted binary to base64 str
    cipher = base64.b64encode(encrypter.feed(data) + encrypter.feed()).decode('utf-8')

    return f"{base64.b64encode(iv).decode('utf-8')}.{cipher}"


def aes_decode(data: str, key: str = settings.encrypt_key) -> str:
    """
    data: (base64 str - iv).(base64 str - encrypted data)
    key: (base64 str) 16, 24, 32 bytes sync encrypt key
    return: decode python str
    """
    key = base64.b64decode(key.encode())
    iv = base64.b64decode(data.split('.')[0].encode())

    # set decrypter
    decrypter = pyaes.Decrypter(pyaes.AESModeOfOperationCBC(key, iv))
    # data (iv).(encrypted text) to binary encrypted text
    cipher = base64.b64decode(data.split('.')[1].encode())

    return (decrypter.feed(cipher) + decrypter.feed()).decode('utf-8')
```

::: tip Какие данные шифрует Pepeunit?
Все конфиденциальные данные, а именно:
1. Динамическая соль, использующаяся для хэширования пароля пользователя
1. Авторизационные данные, отвестветвенные за доступ до приватных репозиториев
1. Файлы окружений - [env.json](definitions#env-json) от [Unit](definitions#unit)
:::

---

## Федерация
