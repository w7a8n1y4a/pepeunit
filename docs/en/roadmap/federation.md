# Federation

## Main federation tasks

1. For UnitNode, the ability to create a connection between instances to receive data with QoS <= 1.
1. Synchronization of public Repo Registries into a single registry of available repositories.
1. Ability for a user to fully download their data and back up their account.

## UnitNode links between instances

A UnitNode link between instances, including between different users, is signed with the users' private keys on the users' side. Two signatures are required.

1. The unit owner on the first instance signs the request with their private key: which output of their UnitNode writes to which input of a UnitNode on the second instance.
1. The unit owner on the second instance receives a notification from the other instance asking them to sign the link. The notification already contains the signature made with the private key of the user who owns the unit on the first instance.
1. The link is enabled after the second signature. Until then, messages to this input are not accepted.
1. Both instances must have the initiator's accounts, for the pair.
1. The domain is checked with a separate https request.

## Instance moderation in federation
1. Automatic ban (incrementing by 1, 7, 30 days) of external UnitNodes that exceed limits between instances.
1. Automatic system for breaking trust between instances with adding the instance to a blacklist.
1. Manual disabling of instances by administrators through blacklists, for edge cases.

## Load

Once an hour, [MessageProcessor](/en/roadmap/message-processor) compares the total Unit load with the instance resources and sets a status:

1. Green — available for creating Units, load < 70%
1. Yellow — the system is on the verge of throttling, load > 70% and < 90%
1. Red — the system is throttling, load > 90%
    - Some Units are forcibly disabled; system throttling is returned as an error

## MessageProcessor follow-up

### External interaction

1. Everything runs on the current table of external links plus signatures
    - this table shows where to relay internal messages
    - this table shows which messages from outside can be trusted
1. Transport is gRPC
1. On send, mqtt -> gRPC; on receive, gRPC -> mqtt
1. Sets ttl and other message parameters so there are no loops or duplicates
1. Refuses service when the external message limit is exceeded
1. Breaks trust between instances if there are many anomalous topics

- Secure and stable external communication

### Signing a link between two UnitNodes on different instances

- The user trusts both instances
- There are always two signatures. The second is placed on an already half-signed contract that arrives as a notification
- One multi-account across instances: the same account signs both times with its private key; the second time on the other instance.
- Two multi-accounts on different instances: the second signature is placed by the other owner, after checking the fingerprint of the other party's permanent public key. The first multi-account must be present on both instances
- revision number

| # | Stage | What happens | Keys |
|---|---|---|---|
| 1 | First signature | The initiator signs the contract: which output of which Unit writes to which input, and the revision number. The link is still disabled | The initiator's permanent private key |
| 2 | Half-signed contract | A notification arrives on the second instance. It already contains the first signature. The same account signs a second time with its private key. Another account checks the fingerprint and signs with its own | Second signature: the same private key, or the second owner's private key |
| 3 | Enable | The link is enabled only after the second signature. Until then, messages to this input are not accepted | Both signatures match the permanent public keys |
| 4 | Delivery | The sender instance transmits the body, Unit uuid, output, and input over gRPC to the domain from the link. The domain is checked with a separate https request | There is no signature at this step |
| 5 | Receive | The receiver instance puts the body into the input if the sender domain is the one in the link and both signatures on the contract match | Permanent public keys of the signers |

- A link can be revoked with a new revision number: first signature again, then a half-signed contract and the second signature. Or by deleting the contract on your side.
- A deep table refactor will be required so that external instances work correctly
