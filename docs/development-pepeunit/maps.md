# Все репозитории Pepeunit

## Основные репозитории
Purpose | Lang | Work | Issue | Stack
-- | -- | -- | -- | --
Documentation | `TS`, `md` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit) | [Github](https://github.com/w7a8n1y4a/pepeunit) | `Vue`, `VitePress`
Deploy | `Python`, `Bash` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy) | [Github](https://github.com/w7a8n1y4a/pepeunit_deploy) | `Docker`, `Docker Compose`
Backend | `Python` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_backend) | [Github](https://github.com/w7a8n1y4a/pepeunit_backend) | `Fastapi`, `Sqlalchemy`, `Httpx`, `Strawberry`, `AioGram`, `Fastapi-MQTT`
DataPipe | `Golang` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_data_pipe) | [Github](https://github.com/w7a8n1y4a/pepeunit_data_pipe) | `Paho-MQTT`
Frontend | `TS` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_frontend) | [Github](https://github.com/w7a8n1y4a/pepeunit_frontend) | `React`, `Vite`, `3d-force-graph`

## Библиотеки

Purpose | Lang | Registry | Work | Issue | Stack
-- | -- | -- | -- | -- | --
Client Micropython | `Micropython` | [Releases](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/releases) | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client) | [Github](https://github.com/w7a8n1y4a/pepeunit_micropython_client) | `mrequests`, `shutil`, `tarfile`, `umqtt.simple`
Client Python | `Python` | [PyPi](https://pypi.org/project/pepeunit-client/) | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_python_client) | [Github](https://github.com/w7a8n1y4a/pepeunit_python_client) | `Paho-mqtt`, `httpx`
Client Golang | `Golang` | [go.dev](https://pkg.go.dev/github.com/w7a8n1y4a/pepeunit_go_client) | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_go_client) | [Github](https://github.com/w7a8n1y4a/pepeunit_go_client) | `Paho-mqtt`

## Инфраструктурные Unit

Purpose | Lang | Work | Issue | Stack
-- | -- | -- | -- | --
Integration Tests | `json`, `md` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit) | - | -
Load Tests | `json` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/universal_load_unit) | - | -
Public Platform Tests | - | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test) | [Github](https://github.com/w7a8n1y4a/github_unit_pub_test) | -
Private Platform Tests | - | `do it yourself` | `do it yourself` | -

## Unit

Purpose | Lang | Hardware | Work and Issue | Stack
-- | -- | -- | -- | --
Donut for pick command edged input Unit | `Golang` | `Any` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/go/go_hotkeys) | `ebiten-v2`, `pepeunit_go_client`
WiFi temp sensor ds18b20 | `Micropython` | `esp8266`, `esp32` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/esp8266/temp-sensor-ds18b20) | `pepeunit_micropython_client`
4pin fan regulator on ds18b20 | `Micropython` | `esp32` | [Gitlab](https://git.pepemoss.com/pepe/pepeunit/units/esp32/fan-regulator-ds18b20.git) | `pepeunit_micropython_client`
