# Output->Input links between UnitNodes

::::info
[More details about the Output/Input mechanism](/en/developer/files/struct-schema-json.html#топики-разработчика)
::::

## Creating a link

1. Open the menu of the [UnitNode](/en/definitions#unitnode) you are interested in with type `Input`.
1. Find the green `Related Output` button and click it.
1. At the bottom of the modal window, find and click the `Search by Unit` button — a search modal for [Units](/en/definitions#unit) will appear.
1. When you click a specific [Unit](/en/definitions#unit), the available `Output` topics will expand.
1. Click `add` next to the `Output` you want to link to.
1. [Pepeunit](/en/conception/overview) will automatically send the [SCHEMA_UPDATE - schema_update/pepeunit](/en/developer/mqtt/default-mqtt-command#schema-update-schema-update-pepeunit) command, forcing the [Unit](/en/definitions#unit) to update its interaction schema on its side.

## Deleting a link

1. Open the menu of the [UnitNode](/en/definitions#unitnode) you are interested in with type `Input`.
1. Find the green `Related Output` button and click it — you will see a list of [Units](/en/definitions#unit) whose `Output` topics send data to the current `Input`.
1. Click the [Unit](/en/definitions#unit) you need — a set of its `Output` topics will be shown.
1. Select the `Output` and click `delete`.
1. [Pepeunit](/en/conception/overview) will automatically send the [SCHEMA_UPDATE](/en/developer/mqtt/default-mqtt-command#schema-update-schema-update-pepeunit) command, forcing the [Unit](/en/definitions#unit) to update its interaction schema on its side.


