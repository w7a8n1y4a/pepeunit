# Обновление Unit

## Автоматическое обновление
Сработает само в зависимости от настроек [обновлений у unit](/user/unit/create-unit-pepeunit#блок-автообновлении) и [флагов массовых обновлений у Repo](/user/git-repository/settings-repo.md#флаги-массовых-обновлении)

## Ручное с изменением версии

Достаточно перейти в настройки [Unit](/definitions#unit) и изменить [коммит](/definitions#git-commit) и/или [ветку](/definitions#git-branch), после нажатия кнопки `Update` будет автоматически отправлена [MQTT команда](/developer/mqtt/default-mqtt-command#update-update-pepeunit) на обновление [Unit](/definitions#unit)

## Ручное без изменения версии

Для обновления [Unit](/definitions#unit) в основном меню есть вкладка `Send update MQTT message`. Команды, указанные там, отвечают за принудительное обновление информации на стороне [Unit](/definitions#unit):

1. `Firmware` - отправляет [MQTT команду](/developer/mqtt/default-mqtt-command#update-update-pepeunit) на полное обновление программы, как если бы вы сделали это вручную при создании [Unit](/definitions#unit). При использовани [библиотек Pepeunit](/developer/libraries/framework) принудительное обновление может быть отменено при совпадении `hash` у [коммита](/definitions#git-commit), это поведение может быть настроено параметрами клиентов
1. `Schema` - отправляет [MQTT команду](/developer/mqtt/default-mqtt-command#schema-update-schema-update-pepeunit) на обновление схемы взаимодействия `Output->Input`. Полезно, когда была добавлен новая связь, при этом не потребуется полного обновления программы
1. `Env` - отправляет [MQTT команду](/developer/mqtt/default-mqtt-command#env-update-env-update-pepeunit) на обновление [env.json](/definitions#env-json) файла. Данная команда особенно полезна, когда все нужные переменные вынесены в [env_example.json](/definitions#env-example-json) [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer), при этом не потребуется полного обновления программы [Unit](/definitions#unit)
1. `Log` - отправляет [MQTT команду](/developer/mqtt/default-mqtt-command.html#log-sync-log-sync-pepeunit), запрашивающую у [Unit](/definitions#unit) локальные логи. Данная команда удаляет все логи, сохранённые в [Pepeunit](/conception/overview), и ожидает, что [Unit](/definitions#unit) отправит логи через [MQTT](/definitions#mqtt). Особенно полезна, когда у [Unit](/definitions#unit) возникают критические ошибки или он был временно отключён от сети
