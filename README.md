# Pepeunit

<div align="center">
    <img align="center" src="https://pepeunit.com/pepeunit-og.jpg"  width="640" height="320">
</div>

**Pepeunit** - открытая платформа для управления устройствами и программами (`Unit`) из Git репозиториев. Код `Unit` берётся из `GitLab` или `GitHub`, обновляется на устройстве удалённо, а сам `Unit` общается с другими через MQTT.

- **Unit из Git** - `Repo` с кодом, окружением и схемой топиков превращается в устройство; обновление по воздуху, логи и состояние в одном месте
- **Связи** - выход одного `Unit` подключается к входу другого без кода
- **Данные** - [DataPipe](https://pepeunit.com/library/docs?doc=user/datapipe/datapipe) собирает значения в `ClickHouse`, панели `Grafana` показывают их
- **Свой инстанс** - разворачивается одной командой `docker compose`; инстансы объединяются в [федерацию](https://pepeunit.com/library/docs?doc=development-pepeunit/mechanics/federation)
- **Без паролей** - аккаунт - это файл с приватным ключом, один на все инстансы
- **Библиотеки** - `Micropython`, `ESP-IDF`, `Python`, `Golang`

Этот репозиторий - клиент на `Flutter`: браузер, `Linux`, `macOS`, `Windows`, `Android` и `iOS`. Интерфейс собран из шестиугольных сот, тема тёмная, документация встроена в приложение.

## Документация

| | |
| -- | -- |
| [Начало работы](https://pepeunit.com/library/docs?doc=user/start) | Выбор инстанса, аккаунт, первый `Unit` |
| [Скачать клиенты](https://pepeunit.com/library/docs?doc=user/library) | Приложения для `Linux`, `macOS`, `Windows`, `Android`, `iOS`, обновление |
| [Развёртывание инстанса](https://pepeunit.com/library/docs?doc=deployment/docker/deploy) | Запуск через `docker compose` |
| [Настройки инстанса](https://pepeunit.com/library/docs?doc=deployment/instance-settings) | Флаги, лимиты, Telegram Bot |
| [Разработчику Unit](https://pepeunit.com/library/docs?doc=developer/alg-create-unit) | Как написать свой `Unit` |
| [Вклад в проект](https://pepeunit.com/library/docs?doc=development-pepeunit/contribution) | Как внести вклад |

## Репозитории

| | |
| -- | -- |
| [pepeunit](https://github.com/w7a8n1y4a/pepeunit) | Клиент |
| [pepeunit_server](https://github.com/w7a8n1y4a/pepeunit_server) | Backend |
| [pepeunit_deploy](https://github.com/w7a8n1y4a/pepeunit_deploy) | Развёртывание |

[Карта всех репозиториев](https://pepeunit.com/library/docs?doc=development-pepeunit/maps) · [Поддержать проект](https://pepeunit.com/library/about/support)

## Лицензия

[AGPL-3.0](LICENSE)
