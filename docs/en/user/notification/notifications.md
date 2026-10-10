# Notifications

::::info Where to find it?
On the home page, click the `Notifications` icon in the top bar. The section is available to an authorized [User](/en/development-pepeunit/mechanics/roles#user) if the instance has `PU_FF_NOTIFICATION_ENABLE` on
::::

::::warning
The list contains only your notifications
::::

## Filters and table

The `All`, `Unread`, and `Read` buttons leave all records, only unread ones, or only read ones. The `Types` button turns types on and off one by one.

Column | What it shows
-- | --
`Type` | Notification type
`Text` | Short line. Hover shows the table. The icon opens the full log if there is one
`Created` | Creation time
`Status` | `Read`, or a `Mark read` button

`Mark all read` marks all of your unread records as read.

## Settings

Settings are in the menu of your own name, the `Notification Settings` button. The settings row is created together with the account.

Toggle | Default | What it does
-- | -- | --
`Daily summaries` | on | Creates daily summaries of the instance and [Units](/en/definitions#unit)
`HH:MM UTC` | `16:00` | Summary time, `00:00`–`23:59` UTC
`Data pipe alerts` | on | Live page updates for [DataPipe](/en/user/datapipe/datapipe#alerts) alerts. A [Telegram](/en/definitions#telegram) message is sent when `Telegram delivery` is on and a chat is linked. The record in the list and the rule in the pipeline stay
`Telegram delivery` | on | Messages in the [Telegram Bot](/en/definitions#telegram-bot). The list and live page updates stay. The button is present when `PU_FF_TELEGRAM_BOT_ENABLE` is on

<a id="command-results"></a>

Manual command results always arrive: integration tests, [Instance](/en/definitions#instance) polling, [RepositoryRegistry](/en/definitions#repositoryregistry) updates, and [Unit](/en/definitions#unit) firmware updates.

## Delivery

A live update of the open page goes to any [User](/en/development-pepeunit/mechanics/roles#user) who is not blocked, when the setting for that type is on. A [Telegram](/en/definitions#telegram) message is sent when the user has a linked chat and `Telegram delivery` is on. A summary is created when `Daily summaries` is on. A [DataPipe](/en/deployment/dependencies/datapipe) alert always lands in the list, reaches the page when `Data pipe alerts` is on, and reaches the chat when `Telegram delivery` is also on and a chat is linked.

In the [Telegram Bot](/en/definitions#telegram-bot), the `/alerts` command opens your notifications. The short text goes to the chat, a press shows the table, and integration tests have a full-log button. There is a pause between messages to one chat, and the whole instance has a shared rate limit. The numbers are set by [Backend variables](/en/deployment/env-variables/backend).

## Types

Type | Kind | Who | Description
-- | -- | -- | --
`InstanceDailyState` | Periodic | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Up to `3` groups of `ERROR` and `CRITICAL` from [Backend](/en/deployment/dependencies/backend) logs for the day. The source is [Loki](/en/deployment/dependencies/loki)
`UnitDailySummary` | Periodic | [User](/en/development-pepeunit/mechanics/roles#user) with their own [Units](/en/definitions#unit) | Up to `10` of their own [Units](/en/definitions#unit) with the largest number of `Error` and `Critical` logs for the day
<span id="datapipe-alert"></span>`DataPipeAlert` | DataPipe | Creator of the [Unit](/en/definitions#unit) | A [UnitNode](/en/definitions#unitnode) value violated the `alerts` block. The line has the [Unit](/en/definitions#unit) name, the value, and the check; the table also has the topic. [How to set the rule](/en/user/datapipe/datapipe#alerts)
`IntegrationTests` | Operation | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | [Backend](/en/deployment/dependencies/backend) integration tests. The full log is the `pytest` output. [Learn more](/en/user/notification/integration-tests)
`ScanAllInstances` | Operation | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Poll of all trusted external [Instances](/en/definitions#instance). The button is present when `PU_FF_FEDERATION_ENABLE` is on. Repeat after `10` minutes. Result `Scanned N, failed M`
`ScanInstance` | Operation | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Poll of one trusted external [Instance](/en/definitions#instance)
`UpdateAllRegistries` | Operation | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Sync of local copies of every [RepositoryRegistry](/en/definitions#repositoryregistry)
`UpdateRegistry` | Operation | [User](/en/development-pepeunit/mechanics/roles#user) with access to the registry | Sync of the local copy of one [RepositoryRegistry](/en/definitions#repositoryregistry)
`UpdateUnitsFirmware` | Operation | Creator of the [Repo](/en/definitions#repo) | Firmware update of [Units](/en/definitions#unit) of this [Repo](/en/definitions#repo) that have auto-update on
`UpdateAllUnitsFirmware` | Operation | [Administrator](/en/development-pepeunit/mechanics/roles#admin) | Firmware update of every [Unit](/en/definitions#unit) that allowed auto-update from a [Repo](/en/definitions#repo) with `Auto-update` on

- Periodic ones are created once a day, at the minute from `HH:MM UTC`, for a [User](/en/development-pepeunit/mechanics/roles#user) with `Daily summaries` on. A blocked user does not get a summary.
- An operation leaves two records: `Running` at start and `Success` or `Error` after it finishes. The table has the status, start time, end time, and a short result line.
