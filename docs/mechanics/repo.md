# Всё о сущности Repo

`Repo` - это создаваемая пользователем сущность с уникальным именем в [инстансе](/definitions#instance) [Pepeunit](/conception/overview), содержащая в себе информацию о внешнем репозитории [Git](/definitions#git).

Репозиторий [Git](/definitions#git) может быть размещён в [инстансе](/definitions#instance) [Gitlab](/definitions#gitlab) или [Github](/definitions#github). [Pepeunit](/conception/overview) умеет скачивать не только публичные репозитории, но и закрытые, для этого требуется указать токен доступа до репозитория. Токены доступа хранятся в [шифрованном](/mechanics/cipher) виде и доступны только создателю.

`Repo` синхронизируется с удалённым репозиторием каждый час. У создателя всегда есть возможность заставить `Repo` принудительно синхронизироваться по нажатию кнопки.

При настройке `Repo` требуется указать [ветку](/definitions#git-branch) по умолчанию - это позволит автоматически обновляться отстыкованным [Unit](/definitions#unit), у которых стоит флаг о автоматическом обновлении. Важно отметить, что отстыковать [Unit](/definitions#unit) от `Repo` нельзя пока не указана [ветка](/definitions#git-branch) по умолчанию.

Так же есть возможность указать флаг, который бы заставлял все автоматически обвновляемые [Unit](/definitions#unit) обновляться только при появлении нового [Тега](/definitions#git-tag)

::: tip Механизм работы обновлений
1. Происходит автоматическая или ручная инициализация обновления `Repo`
1. [Pepeunit](/conception/overview) проверяет [schema_example.json](/definitions#schema-example-json) и [env_example.json](/definitions#env-example-json) в выбранной версии на корректность
1. [Pepeunit](/conception/overview) последовательно проходит по каждому отстыкованному [Unit](/definitions#unit) и актуализирует следующую информацию:
    - [schema_example.json](/definitions#schema-example-json) в выбранной версии `Repo` проверяется на наличие нужных категорий топиков. Если топиков нет, то создаётся сущность [UnitNode](/definitions#unitnode). Если сущность [UnitNode](/definitions#unitnode) существует, но её нет в [schema_example.json](/definitions#schema-example-json) она будет удалена.
    - [env_example.json](/definitions#env-example-json) в версии `Repo` сверяется с [зашифрованным](/mechanics/cipher) [env.json](/definitions#env-json) на наличие нужных для работы переменных.
1. [Pepeunit](/conception/overview) последовательно отправляет каждому подходящему [Unit](/definitions#unit) команду обновления, через топик [MQTT](/definitions#mqtt)
1. [Unit](/definitions#unit) видят требование о обновлении, сравнивают версию своей текущей программы и новой версии от [Pepeunit](/conception/overview). При не совпадении версий - обновляются запрашивая нужные файлы через [REST](/definitions#rest). При совпадении версий - игнорируют. Данный этап может быть модифицирован разработчиками так как проходит на стороне [Unit](/definitions#unit)
:::

:::warning Важно
`Repo` невозможно удалить, если на него ссылается хотябы один [Unit](/definitions#unit)
:::
