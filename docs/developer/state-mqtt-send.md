# Отправка состояния Unit через MQTT

:::warning
Поддерживаемые топики состояний должны быть отражены в [schema_example.json](/definitions#schema-example-json)  в разделе `output_base_topic`.

[Unit](/definitions#unit) должен отправлять форматированные данные в топики, которые указаны. [Pepeunit](/conception/overview) обязуется обработать их по единому паттерну, описанному в данном разделе.
:::

Всего в [Pepeunit](/conception/overview) есть два топика отвечающий за отправку состояния:
1. `state/pepeunit` - `output_base_topic`
1. `log/pepeunit` `output_base_topic`

## state/pepeunit - output_base_topic

:::info Когда [Unit](/definitions#unit) отправляет данные в этот топик?
1. Каждые `PU_STATE_SEND_INTERVAL` секунд указанные в [env.json](/definitions#env-json).
:::

Данные отправляемые [Unit](/definitions#unit), преобразуются на стороне [Pepeunit](/conception/overview) в отображение состояния в меню [Unit](/definitions#unit). Также данное состояние можно получить через [REST](/definitions#rest) и [GQL](/definitions#gql).

### Формат сообщений в топик `state/pepeunit`

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

Разберём каждый ключ:
- `ifconfig` - данные о подключении к сети в формате `[ip, subnet, gateway, dns]`
- `millis` - время в миллисекундах с момента старта программы или время `unix` также в миллисекундах
- `mem_free` - свободная `RAM` память в Байтах
- `mem_alloc` - используемая `RAM` память в Байтах
- `freq` - частота работы кристала в Гц
- `statvfs` - состояние файловой системы `flash` памяти, позволяет вычислить сколько `flash` памяти используется и осталось:
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
- `pu_commit_version` - ключ `PU_COMMIT_VERSION` из [env.json](/definitions#env-json) файла [Unit](/definitions#unit). Данный ключ используется в [системе обновлений](/development-pepeunit/mechanics/update-system) [Pepeunit](/conception/overview), для отслеживания текущей версии [Unit](/definitions#unit).

:::danger
Для корректной работы статусов обновлений у [Unit](/definitions#unit), требуется отправлять `pu_commit_version`
:::

:::warning
Размер передаваемого [Unit](/definitions#unit) состояния ограничен количеством символов указанных в переменной окружения `PU_MQTT_MAX_PAYLOAD_SIZE` из [Backend ENV](/deployment/env-variables#backend). По умолчанию это значение составляет `50000` символов.
:::

:::info
[Pepeunit](/conception/overview) не обязывает отправлять все ключи указанные в примере, можно отправить например только два ключа `millis` и `pu_commit_version`
:::

### Алгоритм отправки

1. Каждые `STATE_SEND_INTERVAL` секунд опросить состояние системы
1. Отформатировать данные для отправки в `json` формате
1. Отправить данные в топик `state/pepeunit` из `output_base_topic`, указанный в [schema.json](/definitions#schema-json)

## log/pepeunit - output_base_topic

:::info Когда [Unit](/definitions#unit) отправляет данные в этот топик?
1. Если [Unit](/definitions#unit) сам считает нужным отправить лог или набор логов для отображения [Пользователю](/development-pepeunit/mechanics/roles.html#user)
2. В случае получения команды в топике `log_sync/pepeunit`, [подробнее](/developer/default-mqtt-command#формат-сообщения-в-топик-log-sync-pepeunit)
:::

Данные отправляемые [Unit](/definitions#unit), преобразуются на стороне [Pepeunit](/conception/overview) в меню логов [Unit](/definitions#unit). Также данные логи можно получить через [REST](/definitions#rest) и [GQL](/definitions#gql).

### Формат сообщений в топик `log/pepeunit`

Поддерживается несколько форматов отправки логов:

1. Отправка одного лога напрямую:
    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)",
        "create_datetime": "2025-04-08T11:27:52.044394"
    }
    ```
1. Отправка одного лога напрямую, без указания времени:
    ```json
    {
        "level": "Info",
        "text": "Subscribed: 83 (0, 0, 0, 0, 0)"
    }
    ```
1. Отправка множества логов:
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
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic env_update",
            "create_datetime": "2025-04-08T11:41:15.974031"
        }
    ]
    ```
1. Отправка множества логов, без указания времени:
    ```json
    [
        {
            "level": "Info",
            "text": "Subscribed: 5 (0, 0, 0, 0, 0)"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic log_sync"
        },
        {
            "level": "Debug",
            "text": "Unit 7d99d194-fe09-4737-b991-0a67cff966d7 get msg from topic env_update"
        }
    ]
    ```

Разберём каждый ключ и логику обработки на стороне [Pepeunit](/conception/overview):
- `level` - указывает уровень логирования и может принимать следующие значения: `Debug, Info, Warning, Error, Critical`
- `text` - содержание лога в текстовом формате, желательно укладывать в `256` символов для корректного отображения в [Frontend](/definitions#frontend)
- `create_datetime` - необязательный ключ, указывающий временную метку для [Pepeunit](/conception/overview). Именно данная метка отображается [Пользователю](/development-pepeunit/mechanics/roles.html#user), в случае отсутствия [Pepeunit](/conception/overview) действует по следующим алгоритмам:
    1. Если сообщение содержит один лог и данный ключ отсутствует, берётся время когда [Pepeunit](/conception/overview) получил сообщение.
    2. Если отправлено множество логов и данный ключ отсутствует, [Pepeunit](/conception/overview) берёт текущее время для самого первого элемента листа и добавляет по 1 секунде для каждого последующего элемента c целью сохранить порядок логов полученный от [Unit](/definitions#unit).

:::warning
Размер передаваемого [Unit](/definitions#unit) лога ограничен количеством символов указанных в переменной окружения `PU_MQTT_MAX_PAYLOAD_SIZE` из [Backend ENV](/deployment/env-variables#backend). По умолчанию это значение составляет `50000` символов.

По умолчанию время жизни логов ограничено `86400` секундами. За это отвечает переменная `PU_UNIT_LOG_EXPIRATION` из [Backend ENV](/deployment/env-variables#backend).
:::

### Алгоритм отправки

1. Отформатировать данные для отправки в `json` формате
1. Отправить данные в топик `log/pepeunit` из `output_base_topic`, указанный в [schema.json](/definitions#schema-json)
