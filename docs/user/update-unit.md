# Обновление Unit

## Ручное с изменением версии

Достаточно перейти в настройки [Unit](/definitions#unit) и изменить [коммит](/definitions#git-commit) и/или [ветку](/definitions#git-branch), после нажатия кнопки `Update` будет автоматически отправлена [MQTT команда](/developer/default-mqtt-command#update-update-pepeunit) на обновление [Unit](/definitions#unit)

## Ручное без изменения версии

Для обновления [Unit](/definitions#unit) в основном меню есть вкладка `Send update MQTT message`. Команды указанные там отвечают за принудительное обновление [Unit](/definitions#unit):

1. `Firmware` - отправляет [MQTT команду](/developer/default-mqtt-command#update-update-pepeunit) на полное обновление программы, как если бы вы сделали это вручную при создании [Unit](/definitions#unit)
2. `Schema` - отправляет [MQTT команду](/developer/default-mqtt-command#schema-update-schema-update-pepeunit) на обновление схемы взаимодействия `Output->Input`. Полезно когда была добавлен новая связь, при этом не потребуется полного обновления программы
3. `Env` - отправляет [MQTT команду](/developer/default-mqtt-command#env-update-env-update-pepeunit) на обновление [env.json](/definitions#env-json) файла. Данная команда особенно полезна когда все нужные переменные вынесены в [env_example.json](/definitions#env-example-json) разработчиком, при этомм не потребуется полного обновления программы [Unit](/definitions#unit)

## Автоматическое

Сработает само в зависимости от настроек [флагов массовых обновлений](/user/settings-repo.md#флаги-массовых-обновлении)
