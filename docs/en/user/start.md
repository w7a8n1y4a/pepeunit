# Getting started

The Pepeunit client opens in a browser at the instance address and is installed as an app on Linux, macOS, Windows, Android, and iOS: `Library` → `About` → `Native apps`.

## Choosing an instance

In a browser, the instance that served the page is already chosen. In the app, choose it yourself: `Network` → `Search instances` → the instance card → `Make favorite`. All sections work with the favorite instance: [Network](/user/network#favorite-instance).

## Account

There are no passwords: an account is a file with a private key.

1. `Account` → `Registration` → `Generate key`
1. `Account` → `Download key` and hide the file: without it you cannot get back into the account
1. Next time: `Account` → `Login` → `Load key`

One key works for all instances. More: [Account](/user/account).

## Sections

Section | What it is for | When it is available
-- | -- | --
`Account` | Key, profile, app settings | Always
`Network` | Choosing an instance, users, management | Always
`Library` | Documentation, client update | Always
`Repositories` | [Repo](/user/repo) with programs for devices | After signing in on the favorite instance
`Units` | [Unit](/user/unit/create-unit), their inputs, outputs, and data | After signing in on the favorite instance
`Dashboards` | [Grafana](/user/dashboards) charts | After signing in, if Grafana is enabled on the instance
`Alerts` | [List of notifications](/user/alerts) | After signing in, if notifications are enabled on the instance

## First Unit

1. [Add a Repo](/user/repo) with a program or take a ready-made public one
1. [Create a Unit](/user/unit/create-unit) from this `Repo`
1. [Fill in the environment variables and run the Unit on a device](/user/unit/create-physic-unit)
1. [Watch logs and values](/user/unit/manage), [link Units to each other](/user/unit/io)

What a `User` can do, and what `Admin` and `Owner` can: [Roles](/development-pepeunit/mechanics/roles).

## How the screen works

Every screen is a set of hexagonal cells.

- `Back` - the return cell. It also closes an open window
- A tip for a cell: a long press, a long click, or a mouse wheel click
- The mouse wheel or a two-finger pinch changes how many cells fit on the screen. In menus the number of cells does not change
- A long list is paged with the arrows of the cell with the range of records, and the sorting is changed there too
- An error is shown as a separate cell: tap it to read and copy the text
- All screens on one map: `Library` → `Tree of 6 paths`
