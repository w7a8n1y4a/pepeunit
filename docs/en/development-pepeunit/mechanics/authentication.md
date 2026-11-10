# Key-based sign-in

Pepeunit has no passwords. A `User` account is an `ML-DSA-87` key pair (the FIPS 204 standard). The public key is stored on the instance, the private key stays only with the person and never reaches the Backend. A database leak does not expose sign-ins: it contains only public keys. The signature is bound to the instance domain and is valid for one attempt, so it cannot be reused on another instance.

## Registration

1. The client creates a key pair on the device: `Account` → `Registration` → `Generate key`
1. The public key goes to the Backend in a request from a [Bot](/development-pepeunit/mechanics/roles#bot)
1. The Backend checks that it is a valid `ML-DSA-87` key of 2592 bytes, computes its `sha256` and saves both values
1. A `User` is created with the `User` role, the `Active` status, a generated icon and default notification settings
1. The client offers to save the private key: `Account` → `Download key`

:::danger
A lost private key cannot be recovered. Pepeunit has no other way to sign in to an account.
:::

There can be no more users on the instance than `pu_instance_user_max_count`. The login is optional and is needed only for convenient search, it can be set later: `Account` → `Settings` → `Change login`.

## Sign-in

Sign-in in the client: `Account` → `Sign in` → `Load key`. It consists of two requests. Both are made by a [Bot](/development-pepeunit/mechanics/roles#bot): the person is not authorized yet.

1. The client sends the `sha256` of the public key (`hash_public_key`)
1. The Backend finds the `User` and returns a `challenge`: a short-lived JWT (HS256, signed with `PU_SECRET_KEY`) with the fields `uuid`, `hash_public_key`, `domain`, `jti` and `exp`. The `jti` is written to [Redis](/deployment/dependencies/redis) for 120 seconds
1. The client signs the bytes of the `challenge` with the `ML-DSA-87` private key with an empty context and sends the `challenge` and the `signature`
1. The Backend checks the `challenge` (signature, expiry, `type`, `domain` equals `PU_DOMAIN`), verifies the signature against the public key of the `User` and deletes the `jti` from Redis. A `challenge` cannot be reused
1. The Backend issues the `User` token

The `User` token is a JWT (HS256, signed with `PU_SECRET_KEY`) with `uuid`, `type` and `exp`. The client passes the token in the `x-auth-token` header.

## Tokens of other agents

Token | Who gets it | Lifetime
-- | -- | --
`User` | A person after sign-in | `pu_instance_user_auth_token_expiration` from the [instance settings](/deployment/instance-settings)
`Unit` | A device, the value is in `PU_AUTH_TOKEN` | Permanent
`Backend` | The [Backend](/deployment/dependencies/backend) itself | Permanent
`Grafana` | The `User` who opens Grafana | 120 seconds
`GrafanaUnitIO` | Requests of a `Dashboard` panel | No expiry, bound to the panel

Every request goes through one check: the token is decoded, the `User` or `Unit` is found, and if the agent's status is `Blocked`, the request is rejected. That is why a block takes effect immediately, without waiting for the token to expire.

## Signing in to Grafana

A `User` opens `Grafana` from the client. The Backend issues a `Grafana` token for them, hides it in Redis under a one-time ticket and gives the ticket to the client. The ticket lives for 60 seconds and is deleted on first use, so the token never ends up in the address bar. The feature works only when the `pu_ff_grafana_integration_enable` flag is on.

## Telegram

A `User` can link Telegram if the `pu_ff_telegram_bot_enable` flag is on:

1. The client asks the Backend for a link to the bot. The Backend creates an 8-character code with a lifetime of 60 seconds and adds it to the link
1. The bot receives the code and writes `telegram_chat_id` to the `User`. One Telegram account can be linked to only one `User`
1. From then on the bot recognizes the `User` by `chat_id`, not by token, and does not let a blocked `User` in

## Where to look at the code

What | Where in the Backend
-- | --
Key check, `challenge`, signature | `app/services/auth/challenge.py`
Parsing the agent token | `app/services/auth/auth_service.py`
Token issuing | `app/dto/agent/abc.py`
Assigning the `Owner` | `scripts/set_owner.py`
