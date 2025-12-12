# Связи Output->Input между UnitNode

:::info
[Подробнее о механизме Output Input](/developer/files/struct-schema-json.html#топики-разработчика)
:::

## Создание связи

1. Перейдите в меню интересующего вас [UnitNode](/definitions#unitnode) c типом `Input`
1. Найдите зелёную кнопку `Related Output` и нажмите её
1. Внизу модального окна найдите кнопку `Search by Unit` и нажмите на неё - появится модальное окно поиска по [Unit](/definitions#unit)
1. При нажатии на конкретный [Unit](/definitions#unit) раскроются доступные `Output`
1. Нажмите `add` напротив `Output`, с которым вы хотите создать связь
1. [Pepeunit](/conception/overview) автоматически отправит команду [SCHEMA_UPDATE - schema_update/pepeunit](/developer/mqtt/default-mqtt-command#schema-update-schema-update-pepeunit) обязующую [Unit](/definitions#unit) обновить схему взаимодействия на своей стороне

## Удаление связи

1. Перейдите в меню интересующего вас [UnitNode](/definitions#unitnode) c типом `Input`
1. Найдите зелёную кнопку `Related Output` и нажмите её - появится спсок [Unit](/definitions#unit) `Output` которых передают данные в текущий `Input`
1. Нажмите на нужный вам [Unit](/definitions#unit) - откроется набор `Output`
1. Выберите `Output` и нажмите `delete`
1. [Pepeunit](/conception/overview) автоматически отправит команду [SCHEMA_UPDATE](/developer/mqtt/default-mqtt-command#schema-update-schema-update-pepeunit), обязующую [Unit](/definitions#unit) обновить схему взаимодействия на своей стороне
