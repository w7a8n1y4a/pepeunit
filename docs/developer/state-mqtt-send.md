# Отправка состояния Unit через MQTT

:::warning
Поддерживаемые топики состояний должны быть отражены в [schema_example.json](/definitions#schema-example-json)  в разделе `output_base_topic`.

[Unit](/definitions#unit) должен отправлять форматированные данные в топики, котоыре указаны. [Pepeunit](/conception/overview) обязуется обработать их по единому паттерну, описанному в данном разделе.
:::

Всего в [Pepeunit](/conception/overview) есть один топик отвечающий за отправку состояния:
1. `output_base_topic` - `state/pepeunit`

## output_base_topic - state/pepeunit

:::info Когда [Unit](/definitions#unit) отправляет данные в этот топик?
1. Каждые `STATE_SEND_INTERVAL` секунд указанные в [env.json](/definitions#env-json).
:::

Данные отправляемые [Unit](/definitions#unit), преобразуются на стороне [Pepeunit](/conception/overview) в отображение состояния в меню [Unit](/definitions#unit). Также данное состояние можно получить через [REST](/definitions#rest) и [GQL](/definitions#gql).

## Формат сообщений в топки `state/pepeunit`

```json
{
    "ifconfig": ["192.168.0.3", "255.255.255.0", "192.168.0.1", "192.168.0.1"],
    "millis": 595925249.0,
    "mem_free": 12368.0,
    "mem_alloc": 25648.0,
    "freq": 80000000.0,
    "statvfs": [4096, 4096, 763, 716, 716, 0, 0, 0, 0, 255],
    "commit_version": "7f1b6564c4885432a17e5892e3c98f3a2ad33658"}
```

Разберём каждый ключ:
- `ifconfig` - данные о подключении к сети в формате `[ip, subnet, gateway, dns]`
- `millis` - время в миллисекундах с момента старта программы или время `unix` также в миллисекундах
- `mem_free` - свободная RAM память в Байтах
- `mem_alloc` - используемая RAM память в Байтах
- `freq` - частота работы кристала в Гц
- `statvfs` - состояние файловой системы flash памяти, позволяет вычислить сколько flash памяти используется и осталось:
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
- `commit_version` - хэш [коммита](/definitions#git-commit) текущей версии программы

:::danger
Для корректной работы статусов обновлений у [Unit](/definitions#unit), требуется отправлять `commit_version`
:::
:::info
[Pepeunit](/conception/overview) не обязывает отправлять все ключи указанные в примере, можно отправить например только два ключа `millis` и `commit_version`
:::

## Алгоритм отправки

1. Каждые `STATE_SEND_INTERVAL` секунд узнать состояние системы
1. Отформатировать данные для отправки в json формате
1. Отправить данные в топик `state/pepeunit` из `output_base_topic`, указанный в [schema.json](/definitions#schema-json)