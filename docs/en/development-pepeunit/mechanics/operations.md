# Operations and notifications

Pepeunit does not keep a request open for long actions. The Backend starts the action in the background, replies `204` right away, and when the action finishes, sends the result to the `User` as a notification. This is how the global commands of the [Admin](/development-pepeunit/mechanics/roles#admin) and the [Owner](/development-pepeunit/mechanics/roles#owner) work, as do the daily summaries.

## Operations

Every manually started operation is recorded as an `OperationTask` with a type, start and end times, a status (`Running`, `Success` or `Error`) and a result. `OperationTask` is not served through the API: the result arrives as a notification to whoever started the operation.

Operation | Type | Who starts it | What it does
-- | -- | -- | --
Synchronize one `Repo` | `UpdateRepo` | A `User` with access to the `Repo` | Replaces the local copy of the [Repo](/development-pepeunit/mechanics/entities#repo) and downloads the releases, see [Repo update](/development-pepeunit/mechanics/update-system#repo-update)
Synchronize all `Repo` | `UpdateAllRepos` | `Admin` | The same again for all `Repo` of the instance
Mass `Unit` update | `UpdateAllUnitsFirmware` | `Admin` | Sends the `UPDATE` command to every `Unit` with auto update and returns how many succeeded and how many did not
Poll neighbors | `ScanAllPeers` | `Admin` | Polls all `Trust` [Peer](/development-pepeunit/mechanics/federation). No more than once every 10 minutes
Poll one neighbor | `ScanPeer` | `Admin` | Polls one `Peer` and reports the address and the ping
Integration tests | `IntegrationTests` | `Admin` | Runs the [integration tests](/development-pepeunit/tests/integration-test) on the instance itself
Restart | `RebootInstance` | `Owner` | Restarts the Backend. The result arrives after the start

In the client, the global operations are gathered in `Network` → `Management`: `Tests`, `Poll neighbors`, `Update repositories`, `Update all` and `Reboot`.

The `Admin` can also start tests, polling of neighbors and the update of all `Repo` with the `/control` command in the Telegram Bot.

Some operations run on a schedule without an `OperationTask`: every hour at `:00` the `Unit` are updated and the `Peer` are polled, and at `:30` the `Repo` are synchronized. For details see the [update system](/development-pepeunit/mechanics/update-system) and [federation](/development-pepeunit/mechanics/federation).

## Notifications

A `Notification` belongs to one `User` and is stored in the database. The list is in `Alerts`, and new ones arrive in the client as the stream `GET /pepeunit/api/v1/notifications/stream`. If Telegram is enabled, they also arrive in the Telegram Bot.

Type | What it contains | For whom
-- | -- | --
`InstanceDailyState` | The top Backend errors for the day | `Admin` and `Owner`
`UnitDailySummary` | Up to 10 of the user's `Unit` with the number of errors (`Error` and `Critical`) for the day | Every `User` who has `Unit`
`DataPipeAlert` | A [DataPipe](/deployment/dependencies/datapipe) alert: a filter or a rule fired on a `UnitIO` | The creator of the `UnitIO`
Operation types (`UpdateRepo`, `ScanAllPeers` and the others from the table above) | The result of the operation: status, time and result | Whoever started it

Every notification has a short line for the list and Telegram, a table and a full text. One notification can be marked as read (`PATCH /notifications/{uuid}/read`) or all at once (`PATCH /notifications/read`).

### Notification settings

Every `User` has their own `NotificationSettings`: `Account` → `Settings` → `Notifications`.

Setting | Meaning
-- | --
`Summaries` | Receive `InstanceDailyState` and `UnitDailySummary`
`UTC time` | At what time of day to send the summaries, `16:00` by default
`DataPipe` | Receive `DataPipeAlert`. The DataPipe rule itself does not change
`Telegram` | Duplicate any notification to the Telegram Bot

Operation results are always sent: they cannot be turned off.

Notifications are not delivered to a blocked `User`.

Notifications work when the `pu_ff_notification_enable` flag is on. The limits on text size and on the frequency of sending to Telegram are set by the [Owner](/development-pepeunit/mechanics/roles#owner) in the instance settings: `pu_notification_*`.
