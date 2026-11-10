# Federation

## Main tasks of Federation

1. For UnitNode, the ability to create a link between instances to receive data with qos <= 1
1. Synchronization of public Repo Registry, for a single registry of available repositories
1. The ability for a user to download all of their data - to make a backup of their account

## UnitNode link between instances

A UnitNode link between instances, including between different users, is signed with the users' private keys on the users' side. Two signatures are needed.

1. The owner of the unit on the first instance signs the request with their private key: which output of their UnitNode writes to which input of a UnitNode on the second instance.
1. The owner of the unit on the second instance receives a notification from the other instance asking to sign the link. The notification already contains the signature made with the private key of the user who owns the unit on the first instance.
1. The link is enabled after the second signature. Until then, messages to this input are not accepted.
1. Both instances must have the initiator's accounts, for pair
1. The domain is verified through a separate https request

## Moderation of instances in the federation
1. Automatic ban (increment 1, 7, 30 days) of external UnitNode that exceed the limits between instances
1. An automatic system for breaking trust between instances by adding an instance to a blacklist
1. Manual disconnection of instances by the administrator using blacklists. For extreme cases

## Load

Once an hour [MessageProcessor](/roadmap/message-processor) compares the total Unit load with the instance resources and sets a status:

1. Green — available for creating Unit, load < 70%
1. Yellow — the system is on the verge of throttling, load > 70% < 90%
1. Red — the system is throttling, load > 90%
    - Some Unit are forcibly disabled, system throttling is returned as the error

## MessageProcessor improvements

### External interaction

1. Everything works on the current table of external links + signatures
    - this table shows where to relay internal messages
    - this table shows which messages can be trusted from outside
1. Transport - gRPC
1. When sending mqtt -> gRPC, when receiving gRPC -> mqtt
1. Sets ttl and other message parameters to avoid loops and duplicates
1. Denies service when the limit of external messages is exceeded
1. Breaks trust between instances if there are many anomalous topics

- Secure and stable external communication

### Mechanism for signing a link between two UnitNode on different instances

- The user trusts both instances
- There are always two signatures. The second is placed on an already half-signed contract, which arrives as a notification
- One multi-account on different instances: the same account signs both times with its private key: the second time on the other instance.
- Two multi-accounts on different instances: the second signature is made by another owner, after checking the fingerprint of the other party's permanent public key. It is important that the account of the first multi-account is present on both instances
- revision number

| # | Stage | What happens | Keys |
|---|---|---|---|
| 1 | First signature | The initiator signs the contract: which output of which Unit writes to which input, the revision number. The link is still disabled | The initiator's permanent private key |
| 2 | Half-signed contract | A notification arrives at the second instance. It already contains the first signature. The same account signs a second time with its private key. Another account checks the fingerprint and signs with its own | Second signature: the same private key or the private key of the second owner |
| 3 | Enabling | The link is enabled only after the second signature. Before it, messages to this input are not accepted | Both signatures match the permanent public keys |
| 4 | Delivery | The sender's instance passes the body, the Unit uuid, the output and the input over gRPC to the domain from the link. The domain is verified by a separate https request | There is no signature at this step |
| 5 | Receiving | The receiver's instance puts the body into the input if the sender's domain is the one in the link, and both signatures on the contract match | The permanent public keys of the signers |

- A link can be revoked with a new revision number: again the first signature, then the half-signed contract and the second signature. Or by deleting the contract on your side.
- A deep refactor of the tables will be required for external instances to work correctly
