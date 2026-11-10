# env.json

:::warning What is env.json for?
It is a contract between four parties: the Unit, Pepeunit, the [User](/development-pepeunit/mechanics/roles#user) and the instance owner:
1. For the values from env_example.json, the Unit takes data from env.json
1. Pepeunit fills in the standard variables when env.json is created for the first time
1. Pepeunit provides the Unit with authorization in [EMQX](/deployment/dependencies/emqx) and [Backend](/deployment/dependencies/backend) by the PU_AUTH_TOKEN token
1. Pepeunit allows env.json to be changed
1. Pepeunit stores env.json in [encrypted form](/development-pepeunit/mechanics/cipher)
1. Pepeunit gives env.json only to the creator of the Unit and to the Unit itself
1. The instance owner does not pass env.json to anyone except the parties of this contract
:::

Environment files, such as env.json or the [Backend variables](/deployment/env-variables/backend), adapt shared code to a specific device or application instance. With env.json you can configure a Unit and change its state without a full program update, and it also tells the Unit which instance it belongs to.

:::danger
env.json is secret, it must not be given to anyone. Use only trusted Pepeunit instances: the instance owner can technically decrypt env.json.
:::

Where to edit env.json in the client: `Units` → Unit → `Environment variables`.
