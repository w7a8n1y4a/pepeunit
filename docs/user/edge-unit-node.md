# Связи Output->Input между UnitNode

## Создание связи

1. Перейдите в меню интересующего вас [UnitNode](/definitions#unitnode) c типом `Input`
1. Найдите зелёную кнопку `Related Output` и нажмите её
1. Внизу модального окна найдите кнопку `Search by Unit` и нажмите на неё - появится модальное окно поиска по [Unit](/definitions#unit)
1. При нажатии на конкретный [Unit](/definitions#unit) раскроются доступные `Output`
1. Нажмите `add` напротив `Output` с которым вы хотите создать связь
1. [Pepeunit](/conception/overview) автоматически отправит команду [SCHEMA_UPDATE - schema_update/pepeunit](/developer/default-mqtt-command#schema-update-schema-update-pepeunit) обязующую [Unit](/definitions#unit) обновить схему взаимодействия на своей стороне

## Удаление связи

1. Перейдите в меню интересующего вас [UnitNode](/definitions#unitnode) c типом `Input`
1. Найдите зелёную кнопку `Related Output` и нажмите её - появится спсок [Unit](/definitions#unit) `Output` которых передают данные в текущий `Input`
1. Нажмите на нужный вам [Unit](/definitions#unit) - откроется набор `Output`
1. Выберите `Output` и нажмите `delete`
1. [Pepeunit](/conception/overview) автоматически отправит команду [SCHEMA_UPDATE - schema_update/pepeunit](/developer/default-mqtt-command#schema-update-schema-update-pepeunit) обязующую [Unit](/definitions#unit) обновить схему взаимодействия на своей стороне

:::warning Почему существуют только связи `Output->Input`?
В парадигме протокола [MQTT](/definitions#mqtt) в топик информацию публикует издатель, а получить информацию из топика могут подпищики. Если перенести эту логику на [Pepeunit](/conception/overview) можно сделать следующий вывод:

- `Output` - топик в который [Unit](/definitions#unit) может отправить данные ([Unit](/definitions#unit) издатель для этого топика)
- `Input` - набор топиков из которых [Unit](/definitions#unit) может получить данные ([Unit](/definitions#unit) подпищик для этих топиков)

Таким образом когда мы создаём связь `Output->Input`, мы говорим [Unit](/definitions#unit) у которого есть `Input` дополнительно подписаться этим `Input` на `Output` другого [Unit](/definitions#unit). Т.е. [Unit](/definitions#unit) может получать в `Input` информацию от нескольких `Output` других [Unit](/definitions#unit).

Если бы существовала возможность создавать связи `Input->Output` - то это означало бы, что `Input` одного [Unit](/definitions#unit) инициирует или влияет на `Output` другого [Unit](/definitions#unit).
:::