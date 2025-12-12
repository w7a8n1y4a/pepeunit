# UnitNode settings

::::warning
[UnitNodes](/en/definitions#unitnode) are created automatically; their number may change from version to version of a [Unit](/en/definitions#unit), depending on the content of the [schema_example.json](/en/definitions#schema-example-json) file. [Pepeunit](/en/conception/overview) itself keeps the set of [UnitNodes](/en/definitions#unitnode) up to date.
::::

::::info How to find a UnitNode?
1. Find the [Unit](/en/definitions#unit) you are interested in visually or via the search tab.
1. Right-click on the [Unit](/en/definitions#unit) if [UnitNodes](/en/definitions#unitnode) have not yet been displayed.
::::

## Visibility level

Choose a [visibility level](/en/development-pepeunit/mechanics/visibility).

## Maximum number of connections

Limits the number of `Output->Input` connections for a [UnitNode](/en/definitions#unitnode). This is used so as not to overload the RAM of very small [Units](/en/definitions#unit).

## Overwrite setting for Input

If the overwrite flag is set to `False`, then [Units](/en/definitions#unit) that have [access](/en/development-pepeunit/mechanics/permission) will not be able to write a new value via [REST](/en/definitions#rest) or [GQL](/en/definitions#gql). In other words, setting a value will only be possible for [Users](/en/development-pepeunit/mechanics/roles#user) with the appropriate [access](/en/development-pepeunit/mechanics/permission) and for topics linked via `Output->Input`.

::::info
This setting is needed to limit the ability of [Units](/en/definitions#unit) to overwrite information in [UnitNodes](/en/definitions#unitnode) that are [accessible](/en/development-pepeunit/mechanics/permission) to them.
::::


