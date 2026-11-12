# Managing a Unit

`Units` → `Search`: a search field by name and a filter for whose `Unit` to show and with what visibility. A tap on a `Unit` opens its menu.

Cell | What it does | Who
-- | -- | --
`Unit card` | Name, visibility, version. A tap rereads the data | Everyone who sees the `Unit`
`Information` | Device state | Everyone who sees the `Unit`
`Repo card` | Opens the parent repository | Everyone who sees the `Unit`; access to the `Repo` is checked separately
`Inputs and outputs` | [UnitIO](/user/unit/io) | Everyone who sees the `Unit`
`Settings` | Avatar, name, visibility, branch, updates | Creator
`Manage unit` | Commands, logs, archives, storage, deletion | Creator
`Environment variables` | The `env.json` editor, see [Running a Unit on a device](/user/unit/create-physic-unit#environment-variables) | Creator
`Access` | Who is allowed to use a private `Unit`, see [Permissions](/development-pepeunit/mechanics/permission) | Creator, only for `Private`

Someone else's `Unit` allows only viewing: [what is available to agents](/development-pepeunit/mechanics/visibility#agent-capabilities-for-visible-entities).

## Information

Data from the last [state](/developer/mqtt/state-mqtt-send) the `Unit` sent. A tap on the cell opens the details:

- `Updates`: the device commit, target commit, and the status of the last update command. For the creator, the server resolves the target commit using the update mode, branch, and tags
- `Network`: addresses and network parameters
- Memory: `RAM` and `Flash`
- `Time` and `Frequency` of the processor

Device data is empty if the `Unit` has not been in touch yet.

## Settings

`Settings` → change the name, avatar (PNG), visibility, branch, and update parameters, then `Save`. Pepeunit recalculates the version and sends the `Unit` an update command, see the [Update system](/development-pepeunit/mechanics/update-system#when-a-unit-is-updated).

When the visibility of a `Unit` is tightened, its `UnitIO` are tightened by themselves, but they are not softened back: [Visibility](/development-pepeunit/mechanics/visibility#relation-between-unit-and-unitio).

## Manage unit

Cell | What it does
-- | --
`Commands` | Send the `Unit` an [MQTT command](/developer/mqtt/default-mqtt-command): `Update firmware`, `Update environment`, `Update schema`, `Sync logs`, `Restart unit`
`Logs` | The journal of the `Unit`. A filter by level, scrolling up loads older records, downloading is available
`Program archives` | `ZIP`, `TAR`, `TGZ` with the version for the device, see [Archive structure](/developer/files/struct-archive-update)
`Storage` | The contents of the [state storage](/developer/state-storage-unit), downloading is available
`Platforms` | Links to [builds](/developer/release-assets) for a compilable `Unit`
`Delete unit` | Confirmation, then irreversible deletion of the `Unit` with its `UnitIO`, `Link`, and permissions

:::info
A command arrives only if its topic is declared in `input_base_topic` of the [schema_example.json](/developer/files/struct-schema-example-json) file and the `Unit` is online. If nothing happens, check `Logs` and `Information`.
:::
