# All Pepeunit repositories

## Core repositories

Purpose | Lang | Work | Issue | Stack
-- | -- | -- | -- | --
Documentation | `TS`, `md` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/pepeunit) | [GitHub](https://github.com/w7a8n1y4a/pepeunit) | `Vue`, `VitePress`
Deploy | `Python`, `Bash` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_deploy) | [GitHub](https://github.com/w7a8n1y4a/pepeunit_deploy) | `Docker`, `Docker Compose`
Backend | `Python` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_backend) | [GitHub](https://github.com/w7a8n1y4a/pepeunit_backend) | `Fastapi`, `Sqlalchemy`, `Httpx`, `Strawberry`, `AioGram`, `Fastapi-MQTT`
DataPipe | `Golang` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_data_pipe) | [GitHub](https://github.com/w7a8n1y4a/pepeunit_data_pipe) | `Paho-MQTT`
Frontend | `TS` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/pepeunit_frontend) | [GitHub](https://github.com/w7a8n1y4a/pepeunit_frontend) | `React`, `Vite`, `3d-force-graph`

## Libraries

Purpose | Lang | Registry | Work | Issue | Stack
-- | -- | -- | -- | -- | --
Client Micropython | `Micropython` | [Releases](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/releases) | [GitLab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client) | [GitHub](https://github.com/w7a8n1y4a/pepeunit_micropython_client) | `mrequests`, `shutil`, `tarfile`, `umqtt.simple`
Client Python | `Python` | [PyPi](https://pypi.org/project/pepeunit-client/) | [GitLab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_python_client) | [GitHub](https://github.com/w7a8n1y4a/pepeunit_python_client) | `Paho-mqtt`, `httpx`
Client Golang | `Golang` | [go.dev](https://pkg.go.dev/github.com/w7a8n1y4a/pepeunit_go_client) | [GitLab](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_go_client) | [GitHub](https://github.com/w7a8n1y4a/pepeunit_go_client) | `Paho-mqtt`

## Infrastructure Units

Purpose | Lang | Work | Issue | Stack
-- | -- | -- | -- | --
Integration Tests | `json`, `md` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit) | - | -
Load Tests | `json` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/units/universal_load_unit) | - | -
Public Platform Tests | - | [GitLab](https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test) | [GitHub](https://github.com/w7a8n1y4a/github_unit_pub_test) | -
Private Platform Tests | - | `do it yourself` | `do it yourself` | -

## Units

Purpose | Lang | Hardware | Work and Issue | Stack
-- | -- | -- | -- | --
Bublik for pick command edged input Unit | `Golang` | `Any` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/units/go/hotkey_bublik) | `ebiten-v2`, `pepeunit_go_client`
WiFi temp sensor ds18b20 | `Micropython` | `esp8266`, `esp32` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/units/esp8266/temp-sensor-ds18b20) | `pepeunit_micropython_client`
4pin fan regulator on ds18b20 | `Micropython` | `esp32` | [GitLab](https://git.pepemoss.com/pepe/pepeunit/units/esp32/fan-regulator-ds18b20.git) | `pepeunit_micropython_client`


