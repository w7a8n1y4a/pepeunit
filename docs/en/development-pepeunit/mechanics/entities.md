# Pepeunit entities

Entity names are the same in the [Backend](/deployment/dependencies/backend), the client and the documentation. The entity type is written with a capital letter, as in the code: `Repo`, `Unit`, `UnitIO`. [Role](/development-pepeunit/mechanics/roles), [visibility](/development-pepeunit/mechanics/visibility) and [access](/development-pepeunit/mechanics/permission) always refer to a specific entity.

## Core entities

Entity | What it is | Who creates it | Who sees it
-- | -- | -- | --
`User` | An instance account: a key pair, a [role](/development-pepeunit/mechanics/roles) and the status `Active` or `Blocked` | The person themselves at registration | Any signed-in `User`
`Repo` | A Git repository on `GitLab` or `GitHub`, a copy of which is stored on the instance | `User` or [Peer](/development-pepeunit/mechanics/federation) | `User` sees all `Repo`, [Bot](/development-pepeunit/mechanics/roles#bot) sees only public ones
`Unit` | A device or program created from a `Repo`. It has its own version, environment and token | `User` | [Visibility level](/development-pepeunit/mechanics/visibility)
`UnitIO` | An input (`Input`) or output (`Output`) of a `Unit`: one topic from `schema_example.json` | Pepeunit, when a `Unit` is created or updated | Visibility level
`Link` | A connection of the output of one `UnitIO` to the input of another | The `User` who sees both `UnitIO` | Together with its `Unit`
`UnitGroup` | A group of `Unit` for convenience. Does not affect access | `User` | Only the creator
`Permission` | A record that an agent (`User` or `Unit`) can see a `Unit` or `UnitIO` with the `Private` level | Pepeunit and the creator of the resource | The creator of the resource
`Dashboard` | A [Grafana](/deployment/dependencies/grafana) dashboard made of panels (`DashboardPanel`) to which `UnitIO` are added | `User` | Only the creator
`Peer` | Another Pepeunit instance that this instance knows about | [Admin](/development-pepeunit/mechanics/roles#admin) or Pepeunit itself when polling other `Peer` | `User` and `Bot`
`Notification` | A notification of one `User` | Pepeunit | Only the recipient
`NotificationSettings` | Notification settings of one `User` | Pepeunit | Only the owner of the settings
`OperationTask` | A record of a long operation started manually. The result arrives as a `Notification` | Pepeunit, when the operation starts | Through the recipient's `Notification`
`InstanceSettings` | The only record with the [instance settings](/deployment/instance-settings) | Pepeunit, on first start | Changed only by the [Owner](/development-pepeunit/mechanics/roles#owner)
`Icon` | A PNG image of a `User`, `Unit`, `UnitGroup` or of the instance itself. Stored in [PostgreSQL](/deployment/dependencies/postgresql) | Pepeunit generates it itself, the owner of the entity can upload their own | Anyone

Time series data is stored separately, in [ClickHouse](/deployment/dependencies/clickhouse): `Unit` logs and values from [DataPipe](/deployment/dependencies/datapipe).

## How entities are related

```text
User ─┬─ Repo ── Unit ── UnitIO ── Link ── UnitIO
      │            │        └── Permission
      │            └── UnitGroup (many to many)
      ├─ Dashboard ── DashboardPanel ── UnitIO
      └─ Notification, NotificationSettings
```

1. A `Unit` is always created from one `Repo` and belongs to one `User`
1. A `Unit` has as many `UnitIO` as there are topics in the `input_topic` and `output_topic` sections of the [schema_example.json](/developer/files/struct-schema-example-json) file. Standard topics from `input_base_topic` and `output_base_topic` do not create `UnitIO`
1. `UnitIO`, `Link` and `Permission` are deleted together with the `Unit`, and `Dashboard` and `DashboardPanel` together with their creator
1. A `Repo` cannot be deleted while it has a `Unit`. Only its creator can delete a `Repo`
1. A `User` is not deleted through the API: it can only be blocked

## Repo

There used to be two concepts: the repository storage and the `Repo` itself. Now it is a single `Repo` entity:

- `is_public_repository` divides `Repo` into public and private. A `Repo` has no visibility level like a `Unit` does
- A private `Repo` is visible in the list to any `User`, but it can be worked with (synchronized, used to create a `Unit`) only with your own platform `Credentials`. The credentials are stored [encrypted](/development-pepeunit/mechanics/cipher) separately for each `User` and have the status `Valid`, `NotVerified` or `Error`. You can work with the `Repo` only if the status is `Valid`
- Git synchronization status: `Updated`, `Processing` or `Error`
- The size of the copy on disk is limited by the `pu_instance_repo_max_size` setting, and the synchronization frequency by `pu_instance_repo_min_interval_sync`

## UnitIO

This entity used to be called `UnitNode`. Now it is `UnitIO` everywhere: the database table is `units_io`, and tests and notifications use `UnitIO`.

Field | What it means
-- | --
`type` | `Input` or `Output`
`topic_name` | Topic name from `schema_example.json`
`visibility_level` | [Visibility level](/development-pepeunit/mechanics/visibility), no looser than that of the `Unit`
`is_rewritable_input` | Whether another `Unit` can write to this `Input`
`max_connections` | How many `Link` a `UnitIO` can have
`state` | The last value that passed through the topic
`is_data_pipe_active` | Whether [DataPipe](/deployment/dependencies/datapipe) is enabled for this `UnitIO`. Available for topics with the `/pepeunit` suffix. If the `pu_datapipe_default_last_value_enable` setting is on, such `UnitIO` are created right away with the `LastValue` policy

## Peer

An external instance used to be called `Instance`. Now `Instance` is a whole deployed Pepeunit, and the other instances it knows about are called `Peer`. More in [Federation](/development-pepeunit/mechanics/federation).

Trust status | What it means
-- | --
`Trust` | The `Peer` is polled, its public `Repo` are added to the instance
`Pending` | The `Peer` was found at another `Peer`. Not polled until the [Admin](/development-pepeunit/mechanics/roles#admin) makes a decision
`Blocking` | The connection is forbidden, the `Peer` is not polled

## Agents and entities

Only a human is a `User` entity. The other participants of requests are called [agents](/development-pepeunit/mechanics/roles#agents): `Bot`, `Unit`, `Backend`, `Grafana` and `GrafanaUnitIO`. `Unit` is the only agent that has both its own entity and the right to call the API.
