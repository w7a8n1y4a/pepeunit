# Обновление Unit

## Ручное с изменением версии

Для этого достаточно перейти в настройки [Unit](/definitions#unit) и изменить [коммит](/definitions#git-commit) и/или [ветку](/definitions#git-branch), после нажатия кнопки `Update` запрос на полное обновление [Unit](/definitions#unit) будет отправлен автоматически

## Ручное без изменения версии

Для обновления [Unit](/definitions#unit) в основном меню есть вкладка `Send update MQTT message`. Команды указанные там отвечают за принудительное обновление [Unit](/definitions#unit):

1. `Firmware` - отправляет [Unit](/definitions#unit) [MQTT](/definitions#mqtt) запрос на полное обновление прграммы, как если бы вы сделали это вручную при создании [Unit](/definitions#unit)
2. `Schema` - отправляет [Unit](/definitions#unit) [MQTT](/definitions#mqtt) запрос на обновление схемы взаимодействия `Output->Input`. Полезно когда была добавлен новая связь, при этом не потребуется полного обновления программы
3. `Env` - отправляет [Unit](/definitions#unit) [MQTT](/definitions#mqtt) запрос на обновление [env.json](/definitions#env-json) файла. Данная команда особенно полезна когда все нужные переменные вынесены в [env_example.json](/definitions#env-example-json) разработчиком, при этомм не потребуется полного обновления программы [Unit](/definitions#unit)

## Автоматическое

Сработает само в зависимости от настроек [флагов массовых обновлений](/user/settings-repo.md#флаги-массовых-обновлении)
