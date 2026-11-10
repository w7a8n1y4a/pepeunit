# Instance federation

Pepeunit can be deployed many times, and each instance lives on its own: it has its own users, `Unit` and data. Federation exists so that instances know about each other and share public `Repo`. User data is not passed between instances.

From the client, a user sees all known instances in `Network` → `Peer search` and can switch to any of them. The [Repo](/development-pepeunit/mechanics/entities#repo) of one instance appear on neighboring ones, so the catalog of programs for `Unit` is shared.

Federation works if the [Owner](/development-pepeunit/mechanics/roles#owner) has turned on the `pu_ff_federation_enable` flag in the [instance settings](/deployment/instance-settings). If the flag is off, polling and scanning do not run.

## Peer

Another instance that this instance knows about is stored as a [Peer](/development-pepeunit/mechanics/entities#peer):

Field | Meaning
-- | --
`url` | The neighbor's `.../instances/current` address. Unique
`trust_status` | `Trust`, `Pending` or `Blocking`
`last_collection_status` | The result of the last poll: `Success`, `Timeout`, `Error` or `Blocking`
`last_ping` | Response time in milliseconds
`last_success_datetime`, `last_attempt_datetime` | When a poll succeeded and when the last one happened
`consecutive_success_count` | How many polls in a row succeeded
`last_collection_error` | The text of the last error, no longer than 256 characters
`state` | The last received `/instances/current`

The address is validated on adding: the scheme is `http` or `https`, there is a host, and there are no query parameters, fragment, or login and password. In addition, the address must point to `/instances/current`.

## What each instance serves

All addresses are public. They are read by a [Bot](/development-pepeunit/mechanics/roles#bot), without signing in:

Address | What it serves
-- | --
`GET /pepeunit/api/v1/instances/current` | The name and version, links (swagger, Grafana, Telegram Bot), contacts, `pu_ff_*` flags, public settings, state (start time and integration test result), metrics: the number of users, `Repo`, `Unit`, `UnitIO` and `Link`, the icon and coordinates
`GET /pepeunit/api/v1/peers` | The list of all `Peer` with their state
`GET /pepeunit/api/v1/peers/urls` | The addresses of all `Peer`
`GET /pepeunit/api/v1/peers/repos` | Public `Repo`: address and platform

Responses are assembled into a cache that is refreshed once a minute and after any change to a `Peer`. Metrics are counted only over public entities.

## How an instance polls a Peer

Only `Peer` with the `Trust` status are polled. One poll is three requests: `instances/current`, `peers/urls` and `peers/repos`; the lists are read in pages of `pu_instance_max_pagination_size`. Pepeunit builds the `peers/*` links from the `/instances/` address in `url`.

1. All `Trust` are polled every hour at `:00`, but with a spread of up to an hour, so that instances do not poll each other at the same time
1. On success, the `Peer` saves the state and the ping and its success counter grows
1. On failure, the status and the error text are saved and the success counter is reset. A `403` or `451` response is treated as `Blocking`: the neighbor has closed access itself
1. Addresses from the response that are not in the list (and are not equal to the instance's own address) are added as `Pending`: Pepeunit neither polls nor deletes them, the decision is made by the [Admin](/development-pepeunit/mechanics/roles#admin)
1. Public `Repo` that are not yet on the instance are created as public
1. A `Trust` `Peer` that has not responded for more than `pu_instance_retention_days` days is polled once more and deleted if that poll fails too

## What the Admin does

Action | How
-- | --
Add a `Peer` | `POST /pepeunit/api/v1/peers`: immediately with the `Trust` status. In the client: `Network` → `Management` → `Track`, the button is available to the [Owner](/development-pepeunit/mechanics/roles#owner)
Switch to `Trust` or `Blocking` | In the `Peer` card: `Moderation` → `Trust` or `Block`. Returning to `Pending` is not possible
Poll now | `Moderation` → `Scan`: one `Peer`, the result arrives as a [notification](/development-pepeunit/mechanics/operations)
Poll all at once | No more than once every 10 minutes, with a spread of up to 10 minutes
Delete a `Peer` | `Moderation` → `Delete`. If the address is found in other instances' lists, it appears again as `Pending`

Public `Repo` of a `Peer` in the `Blocking` status that have already reached the instance stay.

## What the client does

The client has its own settings, unrelated to `Trust` and `Blocking` on the server:

- The `Favorite` instance is the one whose account, `Unit` and data the client shows
- `Allowed` and `Denied` are the client's local lists: a non-empty allow list leaves only the listed instances in search, instances in the deny list are hidden
- `Add a peer` and `Add locally` add an address to the client's search without creating a `Peer` on the server

These lists are stored only in the app.
