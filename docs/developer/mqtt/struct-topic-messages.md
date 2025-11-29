# Структура сообщений в MQTT топиках

:::info
Сообщения через [MQTT](/definitions#mqtt) топики передаются в текстовом формате.
:::

:::danger
Разработчики [Unit](/definitions#unit) всегда могут применить дополнительное шифрование поверх текстовых данных, которое сочтут нужным. Например алгоритм `aes-gcm-256` на основе `PU_ENCRYPT_KEY` встроен в [клиентские библиотеки](/developer/libraries/framework).
:::

:::warning
Размер передаваемого [Unit](/definitions#unit) сообщения с префиксом `/pepeunit` на конце - ограничен количеством символов указанных в переменной окружения `PU_MQTT_MAX_PAYLOAD_SIZE` из [Backend ENV](/deployment/env-variables#backend). По умолчанию это значение составляет `50000` символов.
:::

## DataPipe
Для простых сообщений текстом и числами, можно организовать обработку через [DataPipe](/definitions#datapipe). [Подробнее о настройке DataPipe](/user/data-pipe#datapipe)
