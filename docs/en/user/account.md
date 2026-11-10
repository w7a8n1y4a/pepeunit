# Account

The `Account` section. How passwordless sign-in works: [Key sign-in](/development-pepeunit/mechanics/authentication).

Cell | What it does
-- | --
`Registration` | Creates an `ML-DSA-87` key pair and registers the account: `Generate key`. The next registration can be started no sooner than 2 minutes later
`Login` | `Load key`: pick the key file or drop it on the cell
`Download key` | Saves the private key to a file
`Settings` | Profile, language, notifications
`Sign out` | Removes the key from this app

:::danger
A lost private key cannot be recovered. Keep the file apart from the device you work on. Whoever gets the file will sign in to your account.
:::

## Profile

The login and avatar (PNG) are stored in the app. They go to the server only when you tap `Send to favorite`, no more than once a minute. The login is needed for searching users, [Unit](/user/unit/create-unit) and access do not depend on it.

Cell | What it does
-- | --
`Upload avatar` | Pick a PNG or drop a file
`Change login` | A new login
`Send to favorite` | Sends the login and avatar to the favorite instance
`Pull from favorite` | Replaces the local login and avatar with those on the instance

A [favorite instance](/user/network) is required.

## Application

`Settings` → `Application`: the interface language and the time zone. Stored only in the app.

## Notifications

`Settings` → `Notifications`: what to send, see [Alerts](/user/alerts#settings).
