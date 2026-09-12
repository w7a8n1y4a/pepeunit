# Viewing Operation Tasks

::::info Where to find it?
On the home page, click the `Operation Tasks` icon in the top bar. The section is available only to authorized [Users](/en/development-pepeunit/mechanics/roles#user)
::::

An [Operation Task](/en/definitions#operation-task) is a record of a task that a [User](/en/development-pepeunit/mechanics/roles#user) or an [Administrator](/en/development-pepeunit/mechanics/roles#admin) started manually. Users do not create the records themselves: the [Backend](/en/deployment/dependencies/backend) creates them when a button is pressed, answers the UI immediately, and updates the status when the work finishes.

::::tip
While tasks are running, a red counter on the tasks icon in the header shows the number of tasks with the `Running` status.
::::

## Filters and table

::::info
Status filters can be enabled separately. While the modal is open, the list refreshes every `7` seconds. At the bottom you can see `next update in Ns`.
::::

Column | What it shows
-- | --
`Task` | Task type
`Status` | `Running`, `Success`, or `Error`
`Started` | Start time
`Duration` | How long the task has already been running, or how long it took
`Result` | Short summary. For integration tests there is an icon instead of text; it opens the full log

## Task types

Type | Who starts it | What it does
-- | -- | --
`Integration Tests` | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Runs [Backend](/en/deployment/dependencies/backend) integration tests. Usually takes `3` minutes or more. [Learn more](/en/user/operation-task/integration-tests)
`Scan All Instances` | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Force-polls all trusted external [Instances](/en/definitions#instance). The button is available only when `PU_FF_FEDERATION_ENABLE` is enabled. The same command cannot be started again for `10` minutes
`Scan Instance` | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Force-polls one trusted external [Instance](/en/definitions#instance)
`Update All Registries` | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Synchronizes local copies of all [RepositoryRegistry](/en/definitions#repositoryregistry) entries
`Update Registry` | A [User](/en/development-pepeunit/mechanics/roles#user) with access to the registry | Synchronizes the local copy of one [RepositoryRegistry](/en/definitions#repositoryregistry)
`Update All Units Firmware` | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Sends a firmware update to all [Units](/en/definitions#unit) that allowed auto-update from a [Repo](/en/definitions#repo) with `Auto-update` enabled
`Update Units Firmware` | Creator of the [Repo](/en/definitions#repo) | Sends a firmware update to [Units](/en/definitions#unit) of that [Repo](/en/definitions#repo) that have auto-update enabled

::::warning
Each [User](/en/development-pepeunit/mechanics/roles#user) sees only their own tasks. Another user's record cannot be read by `uuid`.
::::
