# Всё о сущности Unit

[Unit](/definitions#unit) - это центральная сущность в [Pepeunit](/conception/overview), обладающая уникальным именем на [Узле](/definitions#instance), она представляет физичеcкое [IoT](/definitions#iot) устройство внутри системы [Pepeunit](/conception/overview).

[Unit](/definitions#unit) можно создать только отстыковав его от [Repo](/definitions#repo) - это может сделать любой позователь при наличии доступов - через [Frontend](/definitions#frontend) или [API](/definitions#api).

[Unit](/definitions#unit) можно настроить, указав будет ли он обновляться автоматически при обновлении [Repo](/definitions#repo) или же обновление будет происходить исключительно вручную с указанием [Ветки](/definitions#git-branch) и [Коммита](/definitions#git-commit).

В момент создания [Unit](/definitions#unit), на основании выбранной версии и [schema_example.json](/definitions#schema-example-json) - будут сгенерированы [UnitNode](/definitions#unitnode) отвечающие за точки взаимодействия с [Unit](/definitions#unit)

Настройка [Unit](/definitions#unit) по мимо видимости, доступов и настройки обновлений - включает в себя заполнение файла [env.json](/definitions#env-json). Файл является очень важным, так как содержит конфиденциальные данные о подключении физического устройства к [Pepeunit](/conception/overview), в том числе пароли от `WiFi` в случае физических устройств по типу `esp8266`.

::: tip Механизм заполнения файла окружения Unit
1. Пользователь первично видит только те переменные, которые [Pepeunit](/conception/overview) не может заполнить сам, обычно это данные о подключении к `WiFi`.
1. Пользователь заполняет значения переменных и отправляет их в [Pepeunit](/conception/overview)
1. [Pepeunit](/conception/overview) присылает полностью заполненный [env.json](/definitions#env-json)
1. Пользователь может внести изменения по своему желанию если это требуется
1. [env.json](/definitions#env-json) отправляется в [Pepeunit](/conception/overview) где шифруется и сохраняется до востребования.
:::

Когда настройка виртуального [Unit](/definitions#unit) в [Pepeunit](/conception/overview) завершена, следует создать ваше [IoT](/definitions#iot) устройство физически. После установки [Micropython](/definitions#micropython) на ваше устройство, вам нужно загрузить на него микропрограмму. Её можно получить напрямую из интерфейса [Unit](/definitions#unit) в вашем [Узле](/definitions#instance) [Pepeunit](/conception/overview).

Вы можете скачать микропрограмму в формате `zip` или `tar`, и при помощи вспомогательного `ПО` загрузить его на устройство [IoT](/definitions#iot) c уже предустановленным [Micropython](/definitions#micropython), после чего ваше [IoT](/definitions#iot) устройство начнёт работу.
