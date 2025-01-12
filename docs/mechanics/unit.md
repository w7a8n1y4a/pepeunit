# Всё о сущности Unit

`Unit` - это центральная сущность обладающая уникальным именем на [Узле](/definitions#instance) [Pepeunit](/conception/overview). Она представляет из себя интерфейс управления физичеcким устройством внутри системы [Pepeunit](/conception/overview).

`Unit` можно создать только отстыковав его от [Repo](/definitions#repo) - это может сделать любой позователь при наличии [доступов](/user/permission) - через [Frontend](/definitions#frontend) или [API](/definitions#api).

`Unit` можно настроить, указав будет ли он обновляться автоматически при обновлении [Repo](/definitions#repo) или же обновление будет происходить исключительно вручную с указанием [ветки](/definitions#git-branch) и [коммита](/definitions#git-commit).

В момент создания `Unit`, на основании выбранной версии и [schema_example.json](/definitions#schema-example-json) генерируются [UnitNode](/definitions#unitnode) отвечающие за точки взаимодействия с `Unit`.

При обновлении версии набор [UnitNode](/definitions#unitnode) может измениться - [Pepeunit](/conception/overview) будет автоматически удалять и создавать новые [UnitNode](/definitions#unitnode), чтобы соответствовать [schema_example.json](/definitions#schema-example-json).

Для первичного развёртывания `Unit` можно воспользоватья инструкцей [Создание Unit физически](/user/create-unit#создание-unit-физически)