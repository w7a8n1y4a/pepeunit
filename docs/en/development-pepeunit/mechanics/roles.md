# User roles and agents

In Pepeunit, a request to the [Backend](/deployment/dependencies/backend) is made by an agent. An agent can be a human, a device, the instance itself or an external service. The rights of an agent depend on its type, and for a human also on the role.

## Roles

Only a `User` has a role. It grows along a chain: `User` → `Admin` → `Owner`. Each next role can do everything the previous one can, and something of its own.

Role | How many per instance | Who assigns it
-- | -- | --
`User` | Any number, but no more than `pu_instance_user_max_count` | Given at registration
`Admin` | Any number | [Owner](#owner) in the client: `Network` → `Users` → user → `Grant admin`
`Owner` | Only one | The server administrator with the `scripts/set_owner.py` command, see [Registration and Owner](/deployment/docker/deploy#registration-and-owner)

### Unit Developer

`Unit Developer` is not a role in Pepeunit, but a person who writes Git repositories on GitLab or GitHub. They do not work with Pepeunit directly: their code becomes a [Repo](/development-pepeunit/mechanics/entities#repo) from which [Users](#user) create their `Unit`.

Capabilities of the `Unit Developer`:

- Makes changes to the Git repository
- Releases versions that reach the instance on [update](/development-pepeunit/mechanics/update-system)
- Describes [how to fill in env.json](/developer/files/struct-env-example-json) and which topics a `Unit` has

### User

`User` is a person registered in a Pepeunit instance. There are no passwords: sign-in is done with a [key pair](/development-pepeunit/mechanics/authentication).

Capabilities of the `User`:

- Creates `Repo`, `Unit`, `Link`, `UnitGroup` and `Dashboard`, and gets `UnitIO` itself when a `Unit` is created
- Sees all `Repo`, including private ones, and other entities by [visibility level](/development-pepeunit/mechanics/visibility) and granted [access](/development-pepeunit/mechanics/permission). Can work with a private `Repo` only with their own access credentials, see [Repo](/development-pepeunit/mechanics/entities#repo)
- Fully manages their own entities and nobody else's
- Changes their profile, icon, notification settings and links Telegram
- Sees the list of other `User`, the list of `Peer` and their own `Notification`
- Starts synchronization of a `Repo` they have access to

### Admin

`Admin` is a `User` who helps run the instance: keeps order and watches the neighbors.

Capabilities of the `Admin`:

- Blocks and unblocks `User`. The Backend stops accepting the token of a blocked `User`
- Adds `Peer`, moves them to `Trust` or `Blocking`, deletes them, polls one or all at once, see [Federation](/development-pepeunit/mechanics/federation)
- Starts [global operations](/development-pepeunit/mechanics/operations): integration tests, update of all `Repo` and bulk update of `Unit`
- Every day at the chosen time receives an `InstanceDailyState` notification with the instance errors

:::warning What `Admin` cannot do
`Admin` has no special rights over other people's entities: it works with them under the same rules of [visibility](/development-pepeunit/mechanics/visibility) and [access](/development-pepeunit/mechanics/permission) as any `User`. Instance settings, reboot and granting the `Admin` role are not available to it.

But a server administrator who has access to the machine can technically decrypt any [encrypted](/development-pepeunit/mechanics/cipher) data: the keys are stored in `.env`.
:::

### Owner

`Owner` is the only `User` with full control of the instance. This is the one who deployed Pepeunit or was appointed by them.

Capabilities of the `Owner`:

- Everything the [Admin](#admin) can do
- Grants and revokes the `Admin` role
- Reads and changes the [instance settings](/deployment/instance-settings): limits, MQTT, DataPipe, notifications and the `pu_ff_*` flags that turn instance features on and off
- Changes the instance icon
- Reboots the instance. The result arrives as a `RebootInstance` notification

If you run `scripts/set_owner.py` with a different `uuid`, the new `User` becomes `Owner`, and the previous one goes back to `User`. The `Owner` role cannot be granted or revoked through the API.

## Agents

### Bot

`Bot` is anyone who has not yet been authorized: a site visitor, a script or a Telegram Bot.

Capabilities of the `Bot`:

- Registers and signs in: creates a `User`, requests a [challenge](/development-pepeunit/mechanics/authentication) and exchanges the signature for a token
- Sees public `Repo` and entities with the `Public` level
- Reads the public state of the instance `GET /pepeunit/api/v1/instances/current` and the `Peer` lists. This is how [instances poll each other](/development-pepeunit/mechanics/federation)

### Unit

`Unit` is a device or program. It is authorized with the permanent token `PU_AUTH_TOKEN` from [env.json](/developer/files/struct-env-example-json#standard-pepeunit-variables).

Capabilities of the `Unit`:

- Gets its [env.json](/development-pepeunit/mechanics/alg-env), schema, firmware and target version
- Stores its [state](/developer/state-storage-unit) in `Unit State Storage`
- Sends its state and logs over MQTT, as well as the values of its `Output`
- Sees `Unit` and `UnitIO` under the same [visibility](/development-pepeunit/mechanics/visibility) rules as `User`, and writes to the `Input` of another `Unit` only if it has `is_rewritable_input` enabled
- Cannot change other people's `Unit`, create `Repo` or manage access

### Backend

`Backend` is the [Backend](/deployment/dependencies/backend) itself when it calls its own API. Its token is signed with the instance domain. Visibility checks are disabled for the `Backend`, and it is needed for checking MQTT permissions in [EMQX](/deployment/dependencies/emqx) and for background tasks.

### Grafana and GrafanaUnitIO

Agents of [Grafana](/deployment/dependencies/grafana):

- `Grafana` is the token that a `User` gets to sign in to Grafana (with a one-time ticket). It can read the profile of this `User`
- `GrafanaUnitIO` is the token of a `Dashboard` panel. It can only request data of the `UnitIO` added to this panel

## Statuses

A `User` has two statuses: `Active` and `Blocked`. The Backend rejects a blocked agent when checking the token, so its requests do not reach the services.
