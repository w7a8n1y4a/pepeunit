# Visibility levels - Public, Internal and Private

The visibility level of an entity determines who can find it, get information about it and work with it as someone else's.

Only [Unit and UnitIO](/development-pepeunit/mechanics/entities#core-entities) have a visibility level. `UnitGroup`, `Dashboard`, `Notification` and settings are visible only to the creator.

Visibility level | Who sees it
-- | --
`Public` | Everyone, including a [Bot](/development-pepeunit/mechanics/roles#bot) that has not signed in
`Internal` | Any signed-in [User](/development-pepeunit/mechanics/roles#user) and any `Unit` of this instance
`Private` | The creator and the agents to whom the creator granted [access](/development-pepeunit/mechanics/permission), that is, `User` and `Unit`. Works within the instance

A role does not bypass visibility: `Admin` and `Owner` see someone else's `Private` only with granted access, like everyone. There is one exception: internal `Backend` calls. For how access is checked in requests and lists, see [Access checks on requests](/development-pepeunit/mechanics/permission#access-checks-on-requests).

`Repo` has no levels: a public `Repo` is seen by everyone, a private one is seen in the list by all signed-in `User`, and a `Bot` does not see it. The creator does not grant access to a private `Repo`: only someone who has specified their own platform credentials, and whose credentials have the `Valid` status, can synchronize it and create a `Unit` from it, see [Repo](/development-pepeunit/mechanics/entities#repo).

## Relation between Unit and UnitIO

A `UnitIO` cannot be more visible than its `Unit`: if a `Unit` became stricter, its `UnitIO` automatically become stricter.

`Unit` level | What the `UnitIO` can be
-- | --
`Public` | Any: `Public`, `Internal` or `Private`
`Internal` | `Internal` or `Private`
`Private` | Only `Private`

For example, a `Unit` became `Private`: all its `UnitIO` with the `Public` or `Internal` level also became `Private`. If you later make the `Unit` `Public` again, they will not soften back by themselves: their level has to be returned manually in the `Settings` of each `UnitIO`.

The visibility of a `Unit` is changed in the client: `Units` → `Unit` → `Settings` → `Visibility`. For a `UnitIO`: `Unit` → `UnitIO` → `Settings` → `Visibility`.

## Capabilities of the entity creator

The creator has full access to manage their own entities.

### Repo

- Changing their own credentials
- Synchronizing the Git repository inside Pepeunit
- Creating a `Unit` based on the `Repo`
- Deleting the `Repo` if it has no `Unit`

### Unit

- Viewing the version, state and logs of the `Unit`
- Setting and resetting `env.json`
- Downloading the firmware and [compiled](/development-pepeunit/mechanics/update-system) packages
- MQTT commands: `Update`, `SchemaUpdate`, `EnvUpdate`, `LogSync` and `Reset`
- `Unit` settings: visibility, update rules and version, icon
- Granting [access](/development-pepeunit/mechanics/permission)
- Deleting the `Unit`

### UnitIO

- Viewing the state
- Setting a value in an `Input` and sending it over MQTT
- Creating and deleting a `Link`
- `UnitIO` settings: visibility, `is_rewritable_input`, `max_connections`
- Granting access
- All aspects of managing [DataPipe](/deployment/dependencies/datapipe)

## Agent capabilities for visible entities

For other people's entities that an agent has seen thanks to visibility or granted access, the capabilities are limited.

### Repo

- Viewing information about the `Repo` and its size
- Synchronization and creating a `Unit`. For a public `Repo` it is available to all `User`, for a private one only with credentials in the `Valid` status

### Unit

- Viewing information about the current version and state of the `Unit`

### UnitIO

- Viewing the state
- Setting values in an `Input` and sending them over MQTT. A `Unit` (unlike a `User`) can write only to an `Input` with `is_rewritable_input` enabled
- Creating a `Link` between two visible `UnitIO`: the output of one `Unit` and the input of another. The `max_connections` limit applies on both sides, and both `Unit` get a [Permission](/development-pepeunit/mechanics/permission#permission-from-link) to each other's `UnitIO`

:::warning
Other people's `env.json`, logs, MQTT commands, firmware and state storage of a `Unit` cannot be obtained, even if the `Unit` is `Public`. Adding someone else's `UnitIO` to a `Dashboard` is also not possible: only the creator can do that.
:::
