# Viewing Instances

::::info Where to find it?
On the instance home page, click the `Instances` icon in the top bar. The section is available to everyone if the instance has the `PU_FF_FEDERATION_ENABLE` flag enabled
::::

An [Instance](/en/definitions#instance) is another deployed [Pepeunit](/en/conception/overview) instance. The list shows which external instances the current one knows, whether they can be trusted, and what state they are in.

::::tip How do instances appear in the list?
Instances can be discovered automatically: when polling trusted neighbors, the current instance takes their known URLs and creates new records with the `Pending` status. Only an [Administrator](/en/development-pepeunit/mechanics/roles#admin) assigns a trust status to those records: `Trust` or `Blocking`. Without that decision, a discovered instance is not polled. An [Administrator](/en/development-pepeunit/mechanics/roles#admin) can also [add an instance manually](/en/user/instance/add-instance) — then the status is `Trust` immediately
::::

## Trust filters

At the top of the `Instances` modal you can turn statuses on and off. All three are enabled by default. At least one filter must stay active.

Status | Meaning
-- | --
`Trust` | An [Administrator](/en/development-pepeunit/mechanics/roles#admin) confirmed the instance. The current instance polls it and accepts state data
`Pending` | The instance was discovered automatically while polling trusted neighbors. No requests are sent to it until an [Administrator](/en/development-pepeunit/mechanics/roles#admin) clicks `Trust`
`Blocking` | The instance is blocked. No requests are sent to it

## Instances table

Column | What it shows
-- | --
`Domain` | Host of the external instance. The link opens it in a new tab
`Trust` | Trust status: `Trust`, `Pending`, or `Blocking`
`Collection` | Result of the last poll: `Success`, `Error`, `Timeout`, `Blocking`
`Ping` | Response time of the last successful poll, in milliseconds
`Version` | [Backend](/en/deployment/dependencies/backend) version of the external instance
`Units` | Number of public [Units](/en/definitions#unit)
`Users` | Number of [Users](/en/development-pepeunit/mechanics/roles#user)
`Tests` | Status of the latest [integration tests](/en/user/operation-task/integration-tests) and the success percentage

An empty list shows the text `No instances found`.
