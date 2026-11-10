# Update system

## Unit update settings

The update settings are stored in the `Unit` itself, not in the `Repo`. They are set on creation: `Units` → `Create unit` → `Updates`, and later in the `Unit` `Settings`.

Client setting | Field | Meaning
-- | -- | --
`Auto update` | `is_auto_update_unit` | The `Unit` moves to the new version by itself. When off, the version is pinned to the chosen commit
`Compilable` | `is_compilable_unit` | The `Unit` receives not the source code but a compiled file from the [release assets](/developer/release-assets) for its `Platform`
`Tags` | `is_only_tag_update` | Auto update takes only commits that have a tag
`Platform` | `target_firmware_platform` | Which platform the compiled file is needed for
`Branch` | `target_branch` | Which branch the version is taken from
`Commit` | `target_commit` | Needed only when auto update is off

:::warning Allowed combinations
- A compilable `Unit` with auto update takes only commits that have a tag: `Tags` must be turned on
- If auto update is off, the branch and the commit are required
- A compilable `Unit` with auto update off can only point to a commit that has a tag
:::

## Algorithm for calculating the current Unit version

The target version of a `Unit` is not stored; it is calculated anew each time on the local copy of the `Repo`. First, Pepeunit checks that the `target_branch` branch exists in the `Repo`. After that, the version depends on the settings:

Settings | Target version
-- | --
`Auto update` is off | The `target_commit` commit from the branch, found together with its tag, if there is one
`Auto update` is on, `Tags` or `Compilable` is on | The latest commit with a tag in the branch
`Auto update` is on, `Tags` and `Compilable` are off | The latest commit of the branch

If no version is found (for example, the branch has no tags), Pepeunit returns the error `Version is missing`. For a compilable `Unit`, Pepeunit also checks that the chosen version has a file for its `Platform`.

This version is the value of `PU_COMMIT_VERSION` in [env.json](/developer/files/struct-env-example-json#standard-pepeunit-variables), which Pepeunit writes in every time it issues env.json. The current version of a `Unit` is what the `Unit` itself sent in its [state](/developer/mqtt/state-mqtt-send#message-format-for-the-statepepeunit-topic).

## When a Unit is updated

### Repo update

The new version must first appear in the local copy of the `Repo`.

1. The `Repo` is synchronized with `GitLab` or `GitHub`: Pepeunit checks the size on the platform, replaces the local copy and downloads the `releases`
1. The `Repo` status changes to `Updated`, or to `Error` with the error text if something fails

How it starts | Who
-- | --
The `Synchronize` button in the `Repo` card | A `User` who has [access](/development-pepeunit/mechanics/entities#repo) to the `Repo`
Every hour at `:30` for all `Repo` | Pepeunit
The button that runs it for all `Repo` | [Admin](/development-pepeunit/mechanics/roles#admin), see [operations](/development-pepeunit/mechanics/operations)

If the previous synchronization is still running (status `Processing`) and less than `pu_instance_repo_min_interval_sync` seconds have passed since it started, a new one cannot be started. The size of the copy is limited by `pu_instance_repo_max_size`.

### Unit update

Pepeunit sends the `Unit` the MQTT command [UPDATE - update/pepeunit](/developer/mqtt/default-mqtt-command#update-update-pepeunit). The archive for it is built according to the [archive structure](/developer/files/struct-archive-update). The command is sent when:

1. The `Unit` settings change (`PATCH` `Unit`): Pepeunit recalculates the target version, updates `UnitIO` according to the new schema and sends `UPDATE`
1. The `Update firmware` button is pressed: `Units` → `Unit` → `Control` → `Commands`. Available only to the creator
1. Automatically, every hour at `:00`, for all `Unit` that have `Auto update` on
1. The [Admin](/development-pepeunit/mechanics/roles#admin) presses the button for all `Unit` at once

A `Unit` receives the command only if the `update/pepeunit` topic is declared in `input_base_topic` of its `schema_example.json`. Otherwise Pepeunit does not send the command.

For performance, `Repo` are synchronized at `:30`, and `Unit` are updated at `:00` of the next hour. A version released after `:30` reaches the `Unit` in about an hour and a half.

## What happens to UnitIO and env.json

When the version changes, Pepeunit matches the schema of the new version against the existing `UnitIO`:

- Topics that no longer exist are deleted together with their `UnitIO`
- New topics get new `UnitIO`
- The `UnitIO` of the remaining topics are kept with their settings and [Permission](/development-pepeunit/mechanics/permission)
- If an env.json is saved for the `Unit`, it is rebuilt for the new version by the [generation algorithm](/development-pepeunit/mechanics/alg-env), so that the new variables appear in it

## How Pepeunit learns the update arrived

A `Unit` has a firmware update status:

Status | When
-- | --
`RequestSent` | The `UPDATE` command has been sent. The time is remembered
`Success` | In the next `Unit` state, the version equals the target one
`Error` | The command could not be sent over MQTT, or more than two `PU_STATE_SEND_INTERVAL` have passed since sending and the version has not changed

While the status is `RequestSent`, the `Unit` state is accepted without a rate limit, so that the confirmation arrives as fast as possible. The status and the error text are visible in the client: `Units` → `Unit` → `Info` → `Updates`.
