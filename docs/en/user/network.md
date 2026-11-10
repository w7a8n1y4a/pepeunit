# Network

The `Network` section: Pepeunit instances, users, and instance management. How instances learn about each other: [Federation](/development-pepeunit/mechanics/federation).

## Favorite instance

The favorite instance is the one the app works with: it holds your account, `Unit`, `Repo`, and `Dashboard`. In a browser, the instance that served the page becomes the favorite.

1. `Network` → `Search instances`: the list of known instances. The search field filters by address. The color and captions of the cell show trust, ping, and version
1. Open the card of the instance you need
1. `Make favorite`. If you have no account on it, the client registers one with the same key

`Demote` in the card clears the choice. Data on the server is not deleted.

## Instance card

Cell | What it shows or does
-- | --
`Instance` | Address, version, state. On the favorite, a tap refreshes the sign-in
`Summary` | Number of users, `Unit`, `Repo`, the version and flags of the instance. The icon copies the address
`Telegram Bot` | Opens the instance bot to link [notifications](/user/alerts#settings)
`Users` | List of users of the favorite instance
`Manage instance` | Settings and commands, [Owner](/development-pepeunit/mechanics/roles#owner) only
`Moderation` | For a neighboring instance: `Trust`, `Block`, `Scan`, `Delete`. [Admin](/development-pepeunit/mechanics/roles#admin) and `Owner` only

## Your own instance lists

`Search instances` → `Search settings`. The lists are stored only in the app and affect the search:

- `Add locally` - adds the `/instances/current` address of an instance the search does not know yet. Nothing is registered on the server
- `Allowed` - if the list is not empty, the search shows only it
- `Denied` - instances the search hides

## Users

`Users` in the card of the favorite instance: search by login and a user card with the role and status.

- `Owner` assigns and removes the `Admin` role: `Grant admin`, `Revoke admin`
- `Admin` and `Owner` block and unblock: `Block`, `Unblock`

See [Roles](/development-pepeunit/mechanics/roles).

## Instance management

`Manage instance` is opened by `Owner`:

- `Settings`: instance parameters, instance avatar. See [Instance settings](/deployment/instance-settings)
- `Commands`: `Tests`, `Poll neighbors`, `Update repositories`, `Update all`, `Reboot`. The result arrives as a [notification](/user/alerts), and what each command does: [Operations and notifications](/development-pepeunit/mechanics/operations)
- `Add instance`: registers a neighbor by its `/instances/current` address on the favorite instance
