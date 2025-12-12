# Updating a Unit

## Automatic update

Will be triggered automatically depending on the [Unit update settings](/en/user/unit/create-unit-pepeunit#блок-автообновлении) and the [mass update flags for the Repo](/en/user/git-repository/settings-repo.md#флаги-массовых-обновлении).

## Manual with version change

It is enough to open the [Unit](/en/definitions#unit) settings and change the [commit](/en/definitions#git-commit) and/or [branch](/en/definitions#git-branch). After clicking the `Update` button, an [MQTT command](/en/developer/mqtt/default-mqtt-command#update-update-pepeunit) will automatically be sent to update the [Unit](/en/definitions#unit).

## Manual without version change

To update a [Unit](/en/definitions#unit) without changing the version, use the `Send update MQTT message` tab in the main menu. The commands listed there are responsible for forcing an update of information on the [Unit](/en/definitions#unit) side:

1. `Firmware` — sends an [MQTT command](/en/developer/mqtt/default-mqtt-command#update-update-pepeunit) for a full program update, as if you had done it manually when creating a [Unit](/en/definitions#unit). When using the [Pepeunit libraries](/en/developer/libraries/framework), a forced update can be skipped if the [commit](/en/definitions#git-commit) `hash` is the same; this behavior can be configured via client parameters.
1. `Schema` — sends an [MQTT command](/en/developer/mqtt/default-mqtt-command#schema-update-schema-update-pepeunit) to update the `Output->Input` interaction schema. This is useful when a new link has been added and a full program update is not required.
1. `Env` — sends an [MQTT command](/en/developer/mqtt/default-mqtt-command#env-update-env-update-pepeunit) to update the [env.json](/en/definitions#env-json) file. This command is especially useful when all required variables are moved into [env_example.json](/en/definitions#env-example-json) by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer), and a full [Unit](/en/definitions#unit) program update is not needed.
1. `Log` — sends an [MQTT command](/en/developer/mqtt/default-mqtt-command.html#log-sync-log-sync-pepeunit) requesting local logs from the [Unit](/en/definitions#unit). This command deletes all logs stored in [Pepeunit](/en/conception/overview) and expects the [Unit](/en/definitions#unit) to send logs via [MQTT](/en/definitions#mqtt). It is especially useful when the [Unit](/en/definitions#unit) has critical errors or was temporarily disconnected from the network.


