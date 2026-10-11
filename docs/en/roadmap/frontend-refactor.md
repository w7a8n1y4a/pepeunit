# Frontend refactor

- merging the documentation with the client (archiving the frontend repository)
- an update system and update recommendations for the client
- multilingual ru/en
- next to a feature there are buttons to view the documentation (the documentation is restructured for this, into short notes), or better, a long hover on any button pulls in a fragment from the documentation

## Framework change

Full move to Flutter, for multiplatform support

## State management change

- Clients get broader state management: JSON for binaries and storage in the browser

## UI concept change

- Adaptivity
- Interfaces should become more alive: how requests are processed, button presses, and so on
- A websocket may be needed for some events

## Style update

Move to shadcn where possible. Most likely, some custom solutions based on shadcn components will need to be written somewhere.

## Federation sign-in through a global account

A permanent key is born on the desktop. The client that talks to instances receives only a one-time intermediate key.

| # | Stage | What happens | Keys |
|---|---|---|---|
| 1 | Registration | The desktop generates a permanent pair and shows a seed phrase. No network is needed. | The user's permanent pair. The private key is encrypted with a PIN and stays on the desktop. The public key is the account name. |
| 2 | Federation poll | The desktop reads `/instances/current` cards and neighbor lists. | Instance public keys. The key a node returns at its URL is checked against the copy held by neighbors. |
| 3 | Node selection | The user marks where to sign in. | Already verified public keys of the selected instances. |
| 4 | Intermediate key | The desktop creates a new pair and signs a permit: the permanent public key, the intermediate public key, one sign-in for each selected instance, a short lifetime. A file with the intermediate private key and the permit is given to the client. | The permit is signed by the permanent private key, which stays on the desktop. The file contains the intermediate private key. |
| 5 | Challenge | The client asks the instance for the domain, a one-time nonce, and a lifetime of 1–2 minutes. | The instance public key confirms that the request went to the selected node. |
| 6 | Signature | The client signs the challenge and attaches the permit. | Intermediate private key. The permanent private key does not take part in this step. |
| 7 | Check | The instance accepts the response if the challenge is fresh, the domain is its own, the signature matches the intermediate public key, the permit is signed by the permanent public key, the lifetime is still valid, and this permit has not yet been used on this node. After success the node marks the permit as used. | Intermediate public key and permanent public key. Signing in again with this file on this node no longer works. |
| 8 | Local user | The instance finds or creates a user by the permanent public key. On an empty node they are an admin; on a live node they are a regular user. | The permanent public key is written to the database. The intermediate key does not become an identity. |
| 9 | JWT | The instance issues a token with the local user's uuid for `pu_auth_token_expiration`, 31 days by default. | The token is signed by the instance secret `pu_secret_key`. |


- Steps 5–9 repeat on every selected instance
- The signature in step 6 is new every time; the file is the same. On each node it is consumed separately.
- A user has a lifetime on an instance: if they have no active units and have not signed in for 2 years, they are removed

## Interface changes

### Sign-in

When opening an instance address in the browser or opening the pepeunit app on a PC or phones:

- Basic network parameters, from a full export of 1 instance
- List of known instances, with the most basic parameters and sign-in/sign-out buttons
- Global account registration menu
- Global account sign-in menu
- Account edit menu, login + picture
- Sign in to all instances button, with a cooldown
- Button to sync data with instances (sends the new login + picture)
- Instance management menu
    - binaries will include the top 10 instances by users by default
    - allowlists, blocklists, and manual add
- Link to the docs

## Honeycomb

The field is one instance. Containment stays visible: a registry is land, a Repo is a patch, a Unit is a cell. An edge appears only while a cell is open, and runs from jack to jack.

| Entity | Where it sits on the field |
|---|---|
| Instance | Another field. The switcher moves the camera there |
| RepositoryRegistry | Land: address, platform, sync |
| Repo | A patch inside the land |
| Unit | A cell |
| UnitNode | A jack inside an opened cell |
| UnitNodeEdge | A wire between jacks of the opened cell |
| DataPipe | A mark and the source on the jack |
| Visibility | The stroke of the cell or the jack |
| User | The one looking. Their own cells are warmer |
| Permission | The list "who can open this" on an opened cell, Repo, or jack. The agent is a person or a Unit |
| Dashboard and panel | A glass layer over the field. A lens sits on a jack and leaves with the layer |
| Notification | A strip at the edge. A tap moves the camera to the cell |
