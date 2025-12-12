# Federation

## Main problem

The most popular protocol is ActivityPub; it is slow because it is `REST`. There is `matrix`, but if we use it, we will have to forward data from EMQX into `Matrix`.

For now, the main idea is to use EMQX bridge. But how exactly this will work needs to be studied.

:::danger
Until this problem is solved, the following items basically do not make sense.
:::

## Main federation tasks

### What can be implemented without federation protocols
1. Global search across existing Repo Registry instances.
1. Trusted instances system. Whether to trust an instance is decided by the owner of the current instance. This can be reduced to a system of allowlists or blocklists, preferably blocklists.
1. Automatic system for breaking trust between instances.
1. Ability for a user to fully export their data and create a backup of their account.

### What requires protocols
1. For public UnitNode, the ability to create a link between instances to receive data with QoS at least 1.
1. Automatic ban of external UnitNode that exceed limits.


## Consider federation on the Unit side

1. Shift the task of sending data to other Units onto the device itself, namely into its schema.
1. Such a policy will free instances from needing to maintain connections via a bridge or similar mechanism.
1. A Unit will have to publish data into several different EMQX brokers.
1. EMQX of other instances will have to delegate authorization back to the Unit's home instance.

Questions for this design:
1. How will a small Unit maintain connections to, for example, 50 other instances over MQTT?
