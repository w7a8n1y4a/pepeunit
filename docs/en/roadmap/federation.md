# Federation

## Main federation tasks

1. For UnitNode, the ability to create a connection between instances to receive data with QoS <= 1.
1. Synchronization of public Repo Registries into a single registry of available repositories.
1. Ability for a user to fully download their data and back up their account.

## Instance moderation in federation
1. Automatic ban (incrementing by 1, 7, 30 days) of external UnitNodes that exceed limits between instances.
1. Automatic system for breaking trust between instances with adding the instance to a blacklist.
1. Manual disabling of instances by administrators through blacklists, for edge cases.

## Implementation through MessageProcessor

DataPipe -> MessageProcessor

gRPC, messages are signed with certificates, load status model from federation.

## Service tasks
1. The service is subscribed to all messages matching `+/+/pepeunit` and `+/+`.
1. The service separates external messages from internal ones by `domain.com`.
1. The service sends messages to external instances over gRPC, where they are received by the same service.
1. The service receives external messages over gRPC and republishes them to EMQX.
1. The service sets a set of message parameters, TTL, etc., to avoid loops and duplicates.
1. The service counts MPS for external domains, split by each domain and each topic.
1. The service decides when to break trust between instances.
1. The service decides when to block a Unit.
1. The service contains the configuration of all connections.
1. The service contains balance information.
