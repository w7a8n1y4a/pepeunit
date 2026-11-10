# Структура сообщений в MQTT топиках

:::info
Сообщения в MQTT топиках передаются как текст.
:::

:::danger
[Разработчик Unit](/development-pepeunit/mechanics/roles#unit-developer) может дополнительно шифровать текст, как считает нужным. Например, алгоритм aes-gcm-256 на основе PU_ENCRYPT_KEY встроен в [клиентские библиотеки](/developer/libraries/framework).
:::

:::warning
Размер сообщения, которое Unit отправляет через [EMQX](/deployment/dependencies/emqx), ограничен настройкой инстанса pu_mqtt_max_payload_size, по умолчанию 256 КБ, см. [настройки инстанса](/deployment/instance-settings#mqtt).
:::

## DataPipe

Простые сообщения с текстом и числами можно обрабатывать через [DataPipe](/deployment/dependencies/datapipe): фильтровать, преобразовывать, хранить и получать по ним уведомления. Подробнее в [руководстве пользователя](/user/datapipe/datapipe).
