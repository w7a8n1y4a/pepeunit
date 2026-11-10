# Alerts

The `Alerts` section is available after signing in if the instance has the `pu_ff_notification_enable` flag on. A `Notification` is visible only to its recipient. Types, recipients, and sources: [Operations and notifications](/development-pepeunit/mechanics/operations#notifications).

## List

New notifications appear on their own, there is no need to refresh the screen. Each cell shows the type, the time, and a short text. A tap opens the full text and marks the notification as read.

Cell | What it does
-- | --
`Filter` | Shows unread, read, or all. `Read all` and page flipping are here too
`Visible types` | Turns types on and off in the list. The list of types depends on the role

The time is shown in the time zone from `Account` → `Settings` → `Application`.

## Settings

`Account` → `Settings` → `Notifications`:

Cell | What it means
-- | --
`Summaries` | Receive `UnitDailySummary` and `InstanceDailyState`
`UTC time` | When to send the summaries. The arrows change the time in steps
`DataPipe` | Receive `DataPipeAlert`: an [alerts](/user/datapipe/datapipe#alerts) rule fired. The rule itself does not change
`Telegram` | Duplicate notifications to the Telegram bot of the instance

Operation results cannot be turned off.

If the instance has the Telegram bot enabled (`pu_ff_telegram_bot_enable`), link it: `Network` → the card of the favorite instance → `Telegram Bot`, then turn on `Telegram`. Linking is described in [Key sign-in](/development-pepeunit/mechanics/authentication#telegram).
