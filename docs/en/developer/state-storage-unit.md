# Unit state storage

Allows a [Unit](/en/definitions#unit) to store textual data directly in [Pepeunit](/en/conception/overview). This storage is well suited for the following categories of data:

1. The last state of the [Unit](/en/definitions#unit)
1. Cached user input data from [Users](/en/development-pepeunit/mechanics/roles#user)
1. Data that is large by microcontroller standards

::::tip
The [Unit](/en/definitions#unit) state storage is long-term memory that the [Unit](/en/definitions#unit) can use at any time.
::::

::::danger
The size of this storage is limited by the size of [encrypted objects](/en/development-pepeunit/mechanics/cipher) on a [Pepeunit](/en/conception/overview) instance.
::::

## Sending data to the storage

To set a value, follow this algorithm:

1. Compute the [Unit](/en/definitions#unit) `uuid` based on the `PU_AUTH_TOKEN` JWT from [env.json](/en/definitions#env-json).
1. Convert your value or data structure into a string.
1. Make a request. The `PU_HTTP_TYPE` and `PU_DOMAIN` variables are available inside [env.json](/en/definitions#env-json):

    ```bash
    curl -X 'POST' \
    'PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/set_state_storage/{Unit.uuid}' \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d '{
    "state": "best_data_for_save_in_storage"
    }'
    ```

::::info
You can easily convert this `curl` request into an `http` request in any programming language—just pass a copy of it to an LLM.
::::

## Retrieving data from the storage

To retrieve a value, follow this algorithm:

1. Compute the [Unit](/en/definitions#unit) `uuid` based on the `PU_AUTH_TOKEN` JWT from [env.json](/en/definitions#env-json).
1. Make a request. The `PU_HTTP_TYPE` and `PU_DOMAIN` variables are available inside [env.json](/en/definitions#env-json):
    - `PU_HTTP_TYPE://PU_DOMAIN/pepeunit/api/v1/units/get_state_storage/{Unit.uuid}`
1. Convert the string returned by [Pepeunit](/en/conception/overview) into your data structure or value.


