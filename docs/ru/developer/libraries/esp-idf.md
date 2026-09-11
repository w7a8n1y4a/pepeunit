# ESP-IDF

:::info
[Компилируемый](/definitions#compilable) и имеет полную функциональность [Pepeunit Framework](/developer/libraries/framework)
:::

Компонент [ESP-IDF](/definitions#esp-idf) `5.4+` для интеграции [Unit](/definitions#unit) с [Pepeunit](/conception/overview). Публичный API сосредоточен в `pu_client.h`.

## Установка

Добавьте репозиторий в проект [ESP-IDF](/definitions#esp-idf) как компонент:

```cmake
cmake_minimum_required(VERSION 3.16)
set(EXTRA_COMPONENT_DIRS "/path/to/pepeunit_esp_idf_client")
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(my_pepeunit_device)
```

Либо положите библиотеку в каталог `components/` приложения. Требуется [ESP-IDF](/definitions#esp-idf) `>=5.4`.

Приложение должно предоставить:

- инициализированный `NVS` или свой `pu_storage_t`
- таблицу разделов с поддержкой `OTA`, если используется встроенное обновление
- готовое сетевое соединение до `pu_client_start()`, если `manage_wifi=false`
- `CONFIG_MBEDTLS_CERTIFICATE_BUNDLE=y` для `HTTPS`

Полный пример находится в `examples/basic`. `env.json` и `schema.json` хранятся в `NVS`, а не компилируются в прошивку.

## Пример

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

Чтобы воспользоваться примером, создайте [Unit](/definitions#unit) на основе репозитория [universal_test_unit](https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit) на любом инстансе. Полученные `env.json` и `schema.json` нужно загрузить в `NVS` устройства, как это делает `examples/basic`.

## Важные особенности

1. Библиотека требует [ESP-IDF](/definitions#esp-idf) `>=5.4` и рассчитана на семейство `ESP32`
1. MQTT всегда работает по `mqtt://host:port` без TLS
1. Для HTTP по умолчанию используется `HTTPS`. Обычный `HTTP` или отключение проверки сертификата требуют одновременно `CONFIG_PU_ALLOW_INSECURE_TRANSPORT=y` и соответствующего runtime-флага
1. `env.json`, `schema.json` и журнал `log.json` хранятся в `NVS`, а не вшиваются в прошивку
1. Стандартные команды `update/pepeunit`, `env_update/pepeunit`, `schema_update/pepeunit`, `log_sync/pepeunit` и `reset/pepeunit` обрабатываются клиентом до пользовательского `on_input`
1. `pu_client_stop()` и `pu_client_destroy()` нельзя вызывать из callback компонента — управление жизненным циклом нужно вынести в задачу приложения
