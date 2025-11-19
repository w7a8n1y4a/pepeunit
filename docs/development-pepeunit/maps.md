# Все репозитории Pepeunit

## Основные репозитории
Purpose | Lang | Gitlab | Github | Stack
-- | -- | -- | -- | --
Documentation | `TS`, `md` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit) | [Github](https://github.com/w7a8n1y4a/pepeunit) | `Vue`, `VitePress`
Deploy | `Python`, `Bash` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy) | [Github](https://github.com/w7a8n1y4a/pepeunit_deploy) | `Docker`, `Docker Compose`
Backend | `Python` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_backend) | [Github](https://github.com/w7a8n1y4a/pepeunit_backend) | `Fastapi`, `Sqlalchemy`, `Httpx`, `Strawberry`, `AioGram`, `Fastapi-MQTT`
DataPipe | `Golang` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_data_pipe) | [Github](https://github.com/w7a8n1y4a/pepeunit_data_pipe) | `Paho-MQTT`
Frontend | `TS` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_frontend) | [Github](https://github.com/w7a8n1y4a/pepeunit_frontend) | `React`, `Vite`, `3d-force-graph`

## Библиотеки

Purpose | Lang | Gitlab | Github | Stack
-- | -- | -- | -- | --
Client Micropython | `Micropython` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client) | [Github](https://github.com/w7a8n1y4a/pepeunit_micropython_client) | `mrequests`, `shutil`, `tarfile`, `umqtt`
Client Python | `Python` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_python_client) | [Github](https://github.com/w7a8n1y4a/pepeunit_python_client) | `Paho-mqtt`, `httpx`
Client Golang | `Golang` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_go_client) | [Github](https://github.com/w7a8n1y4a/pepeunit_go_client) | `Paho-mqtt`

## Инфраструктурные Unit

Purpose | Lang | Gitlab | Github | Stack
-- | -- | -- | -- | --
Integration Tests | `json`, `md` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit) | - | -
Load Tests | `json` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/universal_load_unit) | - | -
Public Platform Tests | - | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test) | [Github](https://github.com/w7a8n1y4a/github_unit_pub_test) | -
Private Platform Tests | - | `self make` | `self make` | -

## Unit

Purpose | Lang | hardware | Gitlab | Github | Stack
-- | -- | -- | -- | -- | --
Donut for pick command edged input Unit | `Golang` | `Any` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/go/go_hotkeys) | - | `ebiten-v2`, `pepeunit_go_client`
WiFi temp sensor ds18b20 | `Micropython` | `esp8266`, `esp32` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/esp8266/temp-sensor-ds18b20) | - | `pepeunit_micropython_client`
4pin fan regulator by ds18b20 | `Micropython` | `esp32` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/esp32/wifi_pc_fan_4_pin) | - | `pepeunit_micropython_client`
