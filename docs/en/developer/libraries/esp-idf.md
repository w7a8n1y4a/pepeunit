# ESP-IDF

::::info
[Compilable](/en/definitions#compilable) and implements the full [Pepeunit Framework](/en/developer/libraries/framework) feature set
::::

[ESP-IDF](/en/definitions#esp-idf) `5.4+` component for integrating a [Unit](/en/definitions#unit) with [Pepeunit](/en/conception/overview). The public API is concentrated in `pu_client.h`.

## Installation

Add the repository to an [ESP-IDF](/en/definitions#esp-idf) project as a component:

```cmake
cmake_minimum_required(VERSION 3.16)
set(EXTRA_COMPONENT_DIRS "/path/to/pepeunit_esp_idf_client")
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(my_pepeunit_device)
```

Or place the library in the application's `components/` directory. [ESP-IDF](/en/definitions#esp-idf) `>=5.4` is required.

The application must provide:

- an initialized `NVS` or its own `pu_storage_t`
- a partition table with `OTA` support if the built-in update is used
- a ready network connection before `pu_client_start()` if `manage_wifi=false`
- `CONFIG_MBEDTLS_CERTIFICATE_BUNDLE=y` for `HTTPS`

A full example is in `examples/basic`. `env.json` and `schema.json` are stored in `NVS` and are not compiled into the firmware.

## Example

```c
#include "pu_client.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cJSON.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "nvs_flash.h"

static pu_client_t *client;
static int64_t inc;

static void handle_input_messages(pu_client_t *instance, const char *key,
                                  const char *topic, const uint8_t *payload,
                                  size_t length, void *context)
{
    (void)key;
    (void)context;
    char topic_name[64];
    if (pu_client_find_topic_by_unit_node(
            instance, topic, PU_SEARCH_TOPIC_FULL_NAME, PU_SEARCH_SCOPE_INPUT,
            topic_name, sizeof(topic_name)) != ESP_OK) {
        return;
    }
    if (strcmp(topic_name, "input/pepeunit") == 0) {
        pu_client_log(instance, PU_LOG_DEBUG, "Get from input/pepeunit: %.*s",
                      (int)length, (const char *)payload);
    }
}

static void test_set_get_storage(pu_client_t *instance)
{
    if (pu_client_set_state_storage(
            instance, "This line is saved in Pepeunit Instance") != ESP_OK) {
        pu_client_log(instance, PU_LOG_ERROR, "Test set get storage failed");
        return;
    }
    pu_client_log(instance, PU_LOG_INFO, "Success set state");

    char *state = NULL;
    size_t length = 0;
    if (pu_client_get_state_storage(instance, &state, &length) != ESP_OK) {
        pu_client_log(instance, PU_LOG_ERROR, "Test set get storage failed");
        free(state);
        return;
    }
    pu_client_log(instance, PU_LOG_INFO, "Success get state: %.*s",
                  (int)length, state == NULL ? "" : state);
    free(state);
}

static void test_get_units(pu_client_t *instance)
{
    char topic_url[256];
    if (pu_client_get_output_topic(instance, "output/pepeunit", 0, topic_url,
                                   sizeof(topic_url)) != ESP_OK) {
        return;
    }

    char *json = NULL;
    size_t length = 0;
    if (pu_client_get_input_by_output(instance, topic_url, 1, 0, &json,
                                      &length) != ESP_OK) {
        free(json);
        return;
    }
    cJSON *nodes = cJSON_ParseWithLength(json, length);
    free(json);
    cJSON *count = cJSON_GetObjectItemCaseSensitive(nodes, "count");
    pu_client_log(instance, PU_LOG_INFO, "Found %d unit nodes",
                  cJSON_IsNumber(count) ? count->valueint : 0);

    cJSON *first = cJSON_GetArrayItem(
        cJSON_GetObjectItemCaseSensitive(nodes, "unit_nodes"), 0);
    cJSON *uuid = cJSON_GetObjectItemCaseSensitive(first, "uuid");
    if (cJSON_IsString(uuid)) {
        const char *uuids[] = {uuid->valuestring};
        char *units_json = NULL;
        size_t units_length = 0;
        if (pu_client_get_units_by_nodes(instance, uuids, 1, 1, 0, &units_json,
                                         &units_length) == ESP_OK) {
            pu_client_log(instance, PU_LOG_INFO, "Units: %.*s",
                          (int)units_length, units_json);
        }
        free(units_json);
    }
    cJSON_Delete(nodes);
}

static void test_cipher(pu_client_t *instance)
{
    char key[64];
    if (pu_client_env_get_string(instance, "PU_ENCRYPT_KEY", key,
                                 sizeof(key)) != ESP_OK) {
        return;
    }
    const uint8_t text[] = "pepeunit cipher test";
    char *wire = NULL;
    uint8_t *plain = NULL;
    size_t plain_length = 0;
    if (pu_crypto_aes_gcm_encode(key, text, sizeof(text) - 1, &wire) ==
        ESP_OK) {
        pu_client_log(instance, PU_LOG_INFO, "Cipher data %s", wire);
        pu_crypto_aes_gcm_decode(key, wire, &plain, &plain_length);
        pu_client_log(instance, PU_LOG_INFO, "Decoded data: %.*s",
                      (int)plain_length, plain == NULL ? "" : (char *)plain);
    }
    free(wire);
    free(plain);
}

static void application_task(void *argument)
{
    pu_client_t *instance = argument;
    while (!pu_client_is_connected(instance)) {
        vTaskDelay(pdMS_TO_TICKS(500));
    }

    for (;;) {
        char payload[32];
        snprintf(payload, sizeof(payload), "%lld", (long long)++inc);
        pu_client_log(instance, PU_LOG_DEBUG, "Send to output/pepeunit: %s",
                      payload);
        pu_client_publish_to_topics(instance, "output/pepeunit", payload);
        if (inc % 50 == 0) {
            test_set_get_storage(instance);
            test_get_units(instance);
            test_cipher(instance);
        }
        (void)pu_client_delay_env_int64(instance, "DELAY_PUB_MSG", 5, 1, 3600);
    }
}

void app_main(void)
{
    ESP_ERROR_CHECK(nvs_flash_init());

    pu_client_config_t config = PU_CLIENT_CONFIG_DEFAULT();
    config.manage_wifi = true;
    config.callbacks.on_input = handle_input_messages;

    ESP_ERROR_CHECK(pu_client_create(&config, &client));
    ESP_ERROR_CHECK(pu_client_start(client));
    xTaskCreate(application_task, "application", 16384, client, 4, NULL);
}
```

To use the example, create a [Unit](/en/definitions#unit) from the [universal_test_unit](https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit) repository on any instance. The resulting `env.json` and `schema.json` must be uploaded into the device `NVS`, as `examples/basic` does.

## Important notes

1. The library requires [ESP-IDF](/en/definitions#esp-idf) `>=5.4` and targets the `ESP32` family
1. MQTT always uses `mqtt://host:port` without TLS
1. HTTP uses `HTTPS` by default. Plain `HTTP` or disabling certificate verification requires both `CONFIG_PU_ALLOW_INSECURE_TRANSPORT=y` and the matching runtime flag
1. `env.json`, `schema.json`, and the `log.json` journal are stored in `NVS` and are not baked into the firmware
1. Standard commands `update/pepeunit`, `env_update/pepeunit`, `schema_update/pepeunit`, `log_sync/pepeunit`, and `reset/pepeunit` are handled by the client before the user `on_input`
1. `pu_client_stop()` and `pu_client_destroy()` must not be called from a component callback — lifecycle management must be moved to an application task
