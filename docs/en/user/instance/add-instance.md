# Adding an Instance

::::info Where to find it?
The `Instances` icon in the top bar, then the `Add Instance` button. Only an [Administrator](/en/development-pepeunit/mechanics/roles#admin) can add, confirm, block, and delete instances
::::

## About link

To add an external instance, you need a link to its public state `/instances/current`. On the external instance, any authorized [User](/en/development-pepeunit/mechanics/roles#user) can copy it in the `About` section.

1. Sign in to the target instance
1. Click your name in the top right corner
1. Click `About`
1. In the `Current Instance` block, copy the link with the button next to it

Link format:

```
https://domain.com/pepeunit/api/v1/instances/current
```

::::warning
The link must end with `/instances/current`. Only the `http` or `https` scheme is allowed. Do not add a `query`, `fragment`, or username and password to the `URL`
::::

## How to add an Instance

1. Open the `Instances` modal
1. Click `Add Instance`
1. Paste the `/current` link into the `Paste /current links` field
1. Click `Add`

After a successful add, the instance immediately gets the `Trust` status and appears in the list.

::::info
Instances can also be discovered automatically. Once an hour, the current instance polls all neighbors with the `Trust` status and takes their lists of known URLs and public [RepositoryRegistry](/en/definitions#repositoryregistry) entries. New URLs are created with the `Pending` status. Only an [Administrator](/en/development-pepeunit/mechanics/roles#admin) assigns a trust status to them: without `Trust`, a discovered instance is not polled
::::

## Confirmation, blocking, and deletion

Actions are available in the `Instances` list row and depend on the current status.

Status | Available buttons
-- | --
`Pending` | `Trust`, `Block`, `Delete`
`Trust` | `Block`, `Scan`, `Delete`
`Blocking` | `Trust`, `Delete`

1. `Trust` — start polling the instance and accept data from it
1. `Block` — stop polling. The current instance does not trust responses from such an instance
1. `Scan` — force-poll one trusted instance. Creates an [Operation Task](/en/definitions#operation-task) of type `Scan Instance`
1. `Delete` — delete the record

::::warning
An [Administrator](/en/development-pepeunit/mechanics/roles#admin) cannot set the `Pending` status. That quarantine is only for automatically discovered instances. Such records are not polled and are not deleted by retention
::::

## Forced scan of all instances

In the `Instances` list, the `Scan All` button starts polling all records with the `Trust` status. The task is stretched over about `10` minutes so it does not hit the network at once. The same command cannot be started again for `10` minutes.

An [Operation Task](/en/definitions#operation-task) of type `Scan All Instances` is created. The result looks like `Scanned N, failed M`.

## Automatic polling and retention

If the `PU_FF_FEDERATION_ENABLE` flag is on, the [Backend](/en/deployment/dependencies/backend) polls trusted instances every hour. Before polling, each instance is assigned a random delay of `1-3600 s`

An instance with the `Trust` status is deleted if a successful poll has not happened for longer than `PU_INSTANCE_RETENTION_DAYS`. A mandatory extra poll is performed before deletion. `Pending` records are not deleted automatically.

Related [Backend](/en/deployment/env-variables/backend) variables:

Variable | Purpose
-- | --
`PU_FF_FEDERATION_ENABLE` | Enables polling of external instances and the scan buttons
`PU_INSTANCE_RETENTION_DAYS` | How many days without a successful poll to keep a trusted instance, `1`–`120`
`PU_INSTANCE_MAX_STATE_SIZE` | Maximum size of an external instance response in bytes, `4096`–`65536`
`PU_ADMIN_EMAIL` | Public email that appears in the current instance contacts
`PU_ADMIN_TG` | Public [Telegram](/en/definitions#telegram) contact in the current instance card
`PU_HTTP_TIMEOUT` | Timeout for outgoing requests to external instances
`PU_HTTP_CONNECT_TIMEOUT` | Connection timeout used during polling
