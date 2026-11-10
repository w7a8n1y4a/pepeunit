# Стандартные MQTT топики состояния

:::warning
Топики, в которые Unit отправляет состояние, должны быть указаны в schema_example.json в разделе output_base_topic.

Unit должен отправлять данные в формате, описанном ниже: Pepeunit обрабатывает их по единому правилу.
:::

В Pepeunit два топика для отправки состояния:
1. state/pepeunit: output_base_topic
1. log/pepeunit: output_base_topic

## state/pepeunit - output_base_topic

Unit отправляет состояние раз в PU_STATE_SEND_INTERVAL секунд из env.json. Pepeunit показывает его в клиенте: `Аппараты` → Unit → `Информация`. Его же можно получить через REST.

### Формат сообщений в топик state/pepeunit

```json
{
    "ifconfig": ["192.168.0.3", "255.255.255.0", "192.168.0.1", "192.168.0.1"],
    "millis": 595925249.0,
    "mem_free": 12368.0,
    "mem_alloc": 25648.0,
    "freq": 80000000.0,
    "statvfs": [4096, 4096, 763, 716, 716, 0, 0, 0, 0, 255],
    "pu_commit_version": "7f1b6564c4885432a17e5892e3c98f3a2ad33658"
}
```

Что значит каждый ключ:
- ifconfig: данные о сети в формате [ip, маска, шлюз, dns]
- millis: время в миллисекундах с запуска программы или unix время, тоже в миллисекундах
- mem_free: свободная RAM, в байтах
- mem_alloc: занятая RAM, в байтах
- freq: частота процессора, в Гц
- statvfs: состояние файловой системы во flash памяти, по нему считают, сколько памяти занято и сколько свободно:
    ```python
    [
        f_bsize,  # file system block size
        f_frsize,  # fragment size
        f_blocks,  # size of fs in f_frsize units
        f_bfree,  # number of free blocks
        f_bavail,  # number of free blocks for unprivileged users
        f_files,  # number of inodes
        f_ffree,  # number of free inodes
        f_favail,  # number of free inodes for unprivileged users
        f_flag,  # mount flags
        f_namemax,  # maximum filename length
    ]
    ```
- pu_commit_version: PU_COMMIT_VERSION из env.json. По нему Pepeunit следит за [обновлениями](/development-pepeunit/mechanics/update-system) и знает текущую версию Unit

:::danger
pu_commit_version обязателен: без него сообщение отклоняется. По нему же [команда UPDATE](/developer/mqtt/default-mqtt-command#update-update-pepeunit) получает статус успешной.
:::

Остальные ключи необязательны: можно отправить только millis и pu_commit_version. Неизвестные ключи Pepeunit отбрасывает. Размер сообщения ограничен, см. [структуру сообщений](/developer/mqtt/struct-topic-messages).

:::warning
Если слать состояние чаще, чем раз в PU_STATE_SEND_INTERVAL, лишние сообщения отбрасываются. Исключение: сообщение с новым pu_commit_version или отправленное, пока ждёт ответа команда обновления, принимается всегда.
:::

### Алгоритм отправки

1. Раз в PU_STATE_SEND_INTERVAL секунд опросить состояние системы
1. Собрать данные в json
1. Отправить в топик state/pepeunit из output_base_topic, указанный в schema.json

## log/pepeunit - output_base_topic

Unit отправляет данные в этот топик, когда сам решает показать [Пользователю](/development-pepeunit/mechanics/roles#user) один или несколько логов, или когда пришла команда в топик log_sync/pepeunit, [подробнее](/developer/mqtt/default-mqtt-command#формат-сообщения-в-топик-log-sync-pepeunit). Pepeunit показывает логи в клиенте: `Аппараты` → Unit → `Управление аппаратом` → `Логи`. Их же можно получить через REST.

### Формат сообщений в топик log/pepeunit

Поддерживаются четыре формата:

1. Один лог:
    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)",
        "create_datetime": "2025-04-08T11:27:52.044394"
    }
    ```
1. Один лог без времени:
    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)"
    }
    ```
1. Несколько логов:
    ```json
    [
        {
            "level": "Info",
            "text": "Subscribed: 5 (0, 0, 0, 0, 0)",
            "create_datetime": "2025-04-08T11:37:55.087036"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic log_sync",
            "create_datetime": "2025-04-08T11:38:22.828806"
        }
    ]
    ```
1. Несколько логов без времени:
    ```json
    [
        {
            "level": "Info",
            "text": "Subscribed: 5 (0, 0, 0, 0, 0)"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic log_sync"
        }
    ]
    ```

Ключи:
- level: уровень лога, один из Debug, Info, Warning, Error, Critical
- text: текст лога, лучше уложиться в 256 символов, чтобы он хорошо читался в клиенте
- create_datetime: необязательное время лога, именно оно показывается Пользователю. Если ключа нет:
    1. У одного лога берётся время получения сообщения
    1. У нескольких логов первый получает текущее время, а каждый следующий на секунду позже, чтобы сохранился порядок

Размер сообщения ограничен так же, как у состояния. Логи хранятся ограниченное время: срок задаёт pu_instance_unit_log_expiration, по умолчанию 86400 секунд, то есть сутки, см. [настройки инстанса](/deployment/instance-settings#unit).

### Алгоритм отправки

1. Собрать данные в json
1. Отправить в топик log/pepeunit из output_base_topic, указанный в schema.json
