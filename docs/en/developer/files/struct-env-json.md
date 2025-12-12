# env.json

::::warning What is the purpose of [env.json](/en/definitions#env-json)?
[env.json](/en/definitions#env-json) is a four‑party contract between the [Unit](/en/definitions#unit), [Pepeunit](/en/conception/overview), the [User](/en/development-pepeunit/mechanics/roles.html#user), and the [Administrator](/en/development-pepeunit/mechanics/roles#admin) of the [Pepeunit](/en/conception/overview) instance:

1. The [Unit](/en/definitions#unit) guarantees to all parties that it will use the values from [env.json](/en/definitions#env-json) as the runtime values for the variables declared in [env_example.json](/en/definitions#env-example-json).
1. [Pepeunit](/en/conception/overview) guarantees to all parties that when environment variables are first set in [env.json](/en/definitions#env-json), it will generate all standard variables.
1. [Pepeunit](/en/conception/overview) guarantees to all parties that the [Unit](/en/definitions#unit) will be able to authorize itself for topics and connections in [EMQX](/en/deployment/dependencies/emqx), and authorize itself in the [Backend](/en/deployment/dependencies/backend) using `PU_AUTH_TOKEN`.
1. [Pepeunit](/en/conception/overview) guarantees to all parties the ability to modify [env.json](/en/definitions#env-json).
1. [Pepeunit](/en/conception/overview) guarantees to all parties that [env.json](/en/definitions#env-json) will be stored in [encrypted form](/en/development-pepeunit/mechanics/cipher#шифрование).
1. [Pepeunit](/en/conception/overview) guarantees to all parties that only the creator of the [Unit](/en/definitions#unit) will have access to [env.json](/en/definitions#env-json).
1. The [Administrator](/en/development-pepeunit/mechanics/roles#admin) guarantees to all parties that [env.json](/en/definitions#env-json) will never be shared with anyone who is not a party to this contract.
::::

Configuration files such as [env.json](/en/definitions#env-json) or the [Backend ENV](/en/deployment/env-variables/backend) are mechanisms for individualizing shared code for a particular device or application instance.

::::danger
Use only trusted [Pepeunit](/en/conception/overview) instances. Make sure the [Administrator](/en/development-pepeunit/mechanics/roles#admin) of the [Pepeunit](/en/conception/overview) instance fulfills their contractual obligations regarding [env.json](/en/definitions#env-json).
::::

::::info What are the main properties of [env.json](/en/definitions#env-json)?
1. [env.json](/en/definitions#env-json) is a secret file and must not be shared with anyone.
1. [env.json](/en/definitions#env-json) allows convenient configuration and state updates of a [Unit](/en/definitions#unit) without fully updating the program files.
1. [env.json](/en/definitions#env-json) allows a [Unit](/en/definitions#unit) to know which [Pepeunit](/en/conception/overview) instance it belongs to.
1. [env.json](/en/definitions#env-json), through the `PU_AUTH_TOKEN` variable, allows [Pepeunit](/en/conception/overview) to perform authorization for a specific [Unit](/en/definitions#unit).
::::


