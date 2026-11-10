# Unit state storage

Lets a Unit store text data right in Pepeunit. Suitable for:
1. The last state of the Unit
1. [User](/development-pepeunit/mechanics/roles#user) input that needs to be remembered
1. Data that is too large for the microcontroller memory

:::danger
Data is stored in [encrypted form](/development-pepeunit/mechanics/cipher). The size is limited by the instance setting pu_instance_cipher_max_length, 1000000 characters by default, see more in the [instance settings](/deployment/instance-settings#basic).
:::

The storage contents are visible in the client: `Units` → Unit → `Manage unit` → `Storage`.

## Sending data to the storage

1. Get the Unit uuid from the PU_AUTH_TOKEN token in env.json
1. Convert the value or data structure to a string
1. Make the request. Take PU_HTTP_TYPE, PU_DOMAIN and PU_AUTH_TOKEN from env.json:
    ```bash
    curl -X 'POST' \
    'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/set_state_storage/{Unit.uuid}' \
    -H 'Content-Type: application/json' \
    -H 'x-auth-token: PU_AUTH_TOKEN' \
    -d '{
    "state": "best_data_for_save_in_storage"
    }'
    ```

The response comes without a body, with code 204. An empty string in state clears the storage.

:::info
curl is easy to turn into a request in any language: just show it to an LLM.
:::

## Getting data from the storage

1. Get the Unit uuid from the PU_AUTH_TOKEN token in env.json
1. Make the request:
    ```bash
    curl 'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_state_storage/{Unit.uuid}' \
    -H 'x-auth-token: PU_AUTH_TOKEN'
    ```
1. The response comes as a JSON string, that is, in quotes. Remove them and convert the text to your data structure or value

:::info
The /pepeunit prefix and the /api/v1 API version are taken from PU_APP_PREFIX and PU_API_ACTUAL_PREFIX in env.json. The client [libraries](/developer/libraries/framework) do this themselves.
:::
