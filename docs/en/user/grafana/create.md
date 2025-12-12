# Dashboards

::::info Where to find it?
On the instance main page, find the search button in the top left corner. Select the [Dashboard](/en/definitions#dashboard) entity. In the bottom left part of the modal window you can click the `Create Dashboard` button.
::::

## Name requirements for Dashboards and Panels

1. Length from `4` to `20` characters
1. Allowed characters: `a-z, A-Z, 0-9 and _.-`

::::warning
The name cannot be changed later
::::

## Creating a Dashboard in Pepeunit

Creating a dashboard consists of three steps:

1. Create a [Dashboard](/en/definitions#dashboard); for this it is enough to enter a name.
1. Create `N` [panels](/en/definitions#visualization) for the [Dashboard](/en/definitions#dashboard); here you only need to enter a name and choose a type from the list. The types correspond to standard [Visualization](/en/definitions#visualization) options in [Grafana](/en/deployment/dependencies/grafana) plus one additional type: `Horly Heatmap`. You can later change the type in the dashboard itself in the [Grafana](/en/deployment/dependencies/grafana) interface, since you will have `modifier` rights in your organization.
1. Link [UnitNode](/en/definitions#unitnode) objects to a [panel](/en/definitions#visualization). Click the `UnitNodes` button for the specific panel; the selection interface is similar to linking `Output->Input`, except that you can choose both `Input` and `Output`.

At the linking stage you can set two flags:

1. `Only last value ?` — Allows you to query only the last value for this [UnitNode](/en/definitions#unitnode), regardless of the policy selected in the [DataPipe](/en/definitions#datapip).
1. `Value str to json ?` — Attempts to convert the `value` string into a `dict` object, which is useful if graphs or similar structures are stored in `value`.

::::warning
You can link any [UnitNode](/en/definitions#unitnode), but you will only be able to send data to [Grafana](/en/deployment/dependencies/grafana) for those that have a properly configured [DataPipe](/en/definitions#datapip).
::::

::::info
If your [DataPipe](/en/definitions#datapip) already has data, then during synchronization [Pepeunit](/en/conception/overview) will extract the keys and save them into the `columns` field of the `Datasource`, so you will not have to fill them in manually.
::::


