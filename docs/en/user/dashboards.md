# Dashboards

A `Dashboard` is a [Grafana](/deployment/dependencies/grafana) page with charts of the data of your `UnitIO`. The `Dashboards` section is available after signing in if the instance has the `pu_ff_grafana_integration_enable` flag on, see [Instance settings](/deployment/instance-settings#flags). A dashboard is visible only to its creator.

A `DashboardPanel` is one chart on a dashboard. In the client it is called `Panel`.

Grafana draws the data of a [DataPipe](/user/datapipe/datapipe): only your own `UnitIO` with DataPipe enabled and configured gets into a panel.

## Creating

1. `Dashboards` → `Add dashboard`, enter a name: 4-20 characters, Latin letters, digits, `_`, `.`, `-`. Then `Create dashboard`
1. Open the dashboard → `Panels` → `Add`. Enter a title, choose the `Type` (the kind of Grafana chart), and tap `Create`
1. Open the panel → `Inputs and outputs` → `Add`. Choose a `Unit` and its `UnitIO`, then `Link`
1. Go back to the dashboard and tap `Send to Grafana`
1. `Open in Grafana`

Flags on `Link`:

Flag | What it means
-- | --
`Only last value` | Show only the last value, not the history
`Value as JSON` | Parse the value as JSON, for panel types that need it

One panel can hold no more `UnitIO` than the instance setting `pu_datapipe_limit_unit_io_per_one_panel` allows, `10` by default.

## Working

Dashboard cell | What it does
-- | --
`Information` | Sync state, Grafana version, time of the last upload
`Send to Grafana` | Moves the dashboard and panels to Grafana. Needed after every change: it does not update by itself
`Open in Grafana` | Opens the dashboard. No password is needed, sign-in goes through Pepeunit
`Delete dashboard` | After confirmation, deletes the dashboard and its panels from Pepeunit

In a panel: `Inputs and outputs` leads to the list of linked `UnitIO`, and a tap on a `UnitIO` removes it from the panel. The `UnitIO` itself and its data stay. `Delete` removes the panel.
