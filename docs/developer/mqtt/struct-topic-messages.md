# Структура сообщений в MQTT топиках

:::info
Сообщения через [MQTT](/definitions#mqtt) топики передаются в текстовом формате.
:::

:::danger
[Разработчики Unit](/development-pepeunit/mechanics/roles#unit-developer) всегда могут применить дополнительное шифрование поверх текстовых данных, которое сочтут нужным. Например алгоритм `aes-gcm-256` на основе `PU_ENCRYPT_KEY` встроен в [клиентские библиотеки](/developer/libraries/framework).
:::

:::warning
Размер передаваемого [Unit](/definitions#unit) сообщения через [EMQX](/deployment/dependencies/emqx) ограничен переменной окружения `PU_MQTT_MAX_PAYLOAD_SIZE` из [Backend ENV](/deployment/env-variables/backend).
:::

## DataPipe
Для простых сообщений с текстом и числами можно организовать обработку через [DataPipe](/deployment/dependencies/datapipe).
