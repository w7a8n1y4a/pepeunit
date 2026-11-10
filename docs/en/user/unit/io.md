# Inputs and outputs

A `UnitIO` is an input (`Input`) or an output (`Output`) of a `Unit`: one MQTT topic from `input_topic` and `output_topic` of the [schema_example.json](/developer/files/struct-schema-example-json) file. They appear on their own when a `Unit` is created and updated. Standard topics such as `state/pepeunit` do not get into the list.

`Units` → `Unit` → `Inputs and outputs`, then choose the one you need. The `UnitIO` menu:

Cell | What it does | Who
-- | -- | --
`Topic` | Topic, type, and visibility. A tap rereads the data | Everyone who sees the `UnitIO`
`Value` | The last value | Everyone who sees the `UnitIO`
`Settings` | Link limit, visibility, overwriting | Creator
`DataPipe` | [Data pipeline](/user/datapipe/datapipe) | Creator, if the conditions from the pipeline article are met
`Links` | Links to outputs of other `Unit`, only for `Input` | Everyone who sees the `UnitIO`
`Access` | Who is allowed to use a private `UnitIO` | Creator, only for `Private`

## Value

`Value` opens the last value of the topic. For your own `Input` it is editable, and `Send` publishes the text to MQTT exactly as typed. Check the type of the value yourself: the client converts nothing.

## Settings

Setting | What it means
-- | --
`Max links` | How many `Link` a `UnitIO` can have
`Visibility` | Not softer than that of the `Unit`, see [Visibility](/development-pepeunit/mechanics/visibility#relation-between-unit-and-unitio)
`Rewritable` | Whether another `Unit` can write to this `Input`

Then `Save`.

## Links

A `Link` connects the output of one `Unit` to the input of another: the output address goes into the [schema.json](/developer/files/struct-schema-json) of the input, and the `Unit` subscribes to it. `Input` → `Links` → `Add`, then choose a `Unit` and its output. After creation Pepeunit itself sends the schema update command to the `Unit` with the input. If the `Unit` was offline, tap `Update schema` in `Manage unit` → `Commands`.

A tap on a link deletes it: the creator of the link or the creator of the input can do this.

- Both `UnitIO` must be visible to you, and neither must have used up its `Max links`
- Pepeunit itself grants the needed permissions so that linked `Unit` see each other even on private `UnitIO`, see [Permissions](/development-pepeunit/mechanics/permission#permission-from-link)

## Access

`Access` → `Add` → `User` or `Unit` → pick from the list. A tap on an agent in the list revokes the access immediately, without confirmation. What an access gives: [Permissions](/development-pepeunit/mechanics/permission).
