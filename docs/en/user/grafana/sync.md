# Synchronization with Grafana

::::info Where to find it?
On the instance main page, find the search button in the top left corner. Select the [Dashboard](/en/definitions#dashboard) entity. At the bottom of the modal window there is a `Send Dashboard to Grafana` button.
::::

After you click `Send Dashboard to Grafana`, [Pepeunit](/en/conception/overview) performs multiple checks and sends the [Dashboard](/en/definitions#dashboard) in `json` format to [Grafana](/en/deployment/dependencies/grafana).

You can open your chart either via the instance search or by clicking the link in the [Dashboard](/en/definitions#dashboard) modal window.

::::info
You can click this button many times; each time [Grafana](/en/deployment/dependencies/grafana) will create a new version.
::::

::::warning
You can fully edit your [Dashboards](/en/definitions#dashboard) on the [Grafana](/en/deployment/dependencies/grafana) side, but keep in mind that after subsequent synchronizations you will have to redo all changes. To roll back versions, go to `settings.version` in [Grafana](/en/deployment/dependencies/grafana).
::::


