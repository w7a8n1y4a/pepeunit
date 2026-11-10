# schema_example.json

:::warning Для чего нужен schema_example.json?
Это контракт между [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer) и Pepeunit:
1. Разработчик гарантирует, что Unit работает со стандартными топиками из input_base_topic и output_base_topic, которые он указал
1. Разработчик гарантирует, что input_topic и output_topic работают так, как описано в его readme
1. Pepeunit гарантирует корректную работу со стандартными топиками
1. Pepeunit гарантирует, что UnitIO у Unit всегда соответствуют input_topic и output_topic из schema_example.json для выбранной версии
:::

## Структура

```json
{
    "input_base_topic": [
        "update/pepeunit",
        "env_update/pepeunit",
        "schema_update/pepeunit",
        "log_sync/pepeunit",
        "reset/pepeunit"
    ],
    "output_base_topic": [
        "state/pepeunit",
        "log/pepeunit"
    ],
    "input_topic": [
        "set_fan_state/pepeunit"
    ],
    "output_topic": [
        "current_fan_speed_percentage/pepeunit",
        "current_temp/pepeunit"
    ]
}
```

В файле всегда четыре ключа, и значение каждого - список. Список может быть пустым. Если ключа нет или значение не список, Unit не создастся.

Ключ | Что в нём | Подробности
-- | -- | --
input_base_topic | Стандартные команды, которые Unit готов выполнять | [Стандартные MQTT команды](/developer/mqtt/default-mqtt-command)
output_base_topic | Стандартные топики, в которые Unit публикует состояние и логи | [Стандартные MQTT топики состояния](/developer/mqtt/state-mqtt-send)
input_topic | Input топики Разработчика. По каждому Pepeunit создаёт Input UnitIO | [Топики Разработчика](/developer/files/struct-schema-json#топики-разработчика)
output_topic | Output топики Разработчика. По каждому Pepeunit создаёт Output UnitIO | [Топики Разработчика](/developer/files/struct-schema-json#топики-разработчика)

:::info
Название топика может содержать латинские буквы, цифры и символы / _ -
:::

:::info
С клиентскими библиотеками ([Micropython](/developer/libraries/micropython), [ESP-IDF](/developer/libraries/esp-idf), [Golang](/developer/libraries/golang), [Python](/developer/libraries/python)) можно указать все стандартные топики, они заработают сами.

Если вы пишете взаимодействие с Pepeunit без библиотек, оставьте только нужные.
:::

:::warning
Backend отправляет стандартную команду, только если её топик указан в input_base_topic. Без update/pepeunit Unit не получит команду обновления.
:::

:::warning
При создании Unit и при смене его версии Pepeunit создаёт недостающие и удаляет лишние Input и Output UnitIO, чтобы они совпали с файлом.
:::

## Постфикс /pepeunit

У топика Разработчика может быть постфикс /pepeunit на конце, как в примере. Он нужен, если данные должны обрабатываться [DataPipe](/deployment/dependencies/datapipe): он читает только такие топики. Для них же при создании автоматически включается политика LastValue, если это не отключено в [настройках инстанса](/deployment/instance-settings#datapipe) (pu_datapipe_default_last_value_enable).

Без постфикса DataPipe для UnitIO настроить нельзя, в остальном такой топик работает так же.
