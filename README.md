# Pepeunit

<div align="center">
    <img align="center" src="https://pepeunit.com/pepeunit-og.jpg"  width="640" height="320">
</div>

**Демо** - [pepeunit.com](https://pepeunit.com)

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

## Кеш релизных сборок

Linux- и Android-job сохраняют кеш BuildKit в GitLab Container Registry:
`$CI_REGISTRY_IMAGE/build-cache:linux` и `:android`. Используются стандартные
`CI_REGISTRY`, `CI_REGISTRY_USER` и `CI_REGISTRY_PASSWORD`. Builder и временные
файлы удаляются после job, кеш слоёв остаётся между тегами. Первый запуск
заполняет кеш; ускорение подготовки SDK и зависимостей ожидается со следующего.
Для Android отдельно кешируются NDK, Gradle и плагины сборки до копирования
исходников приложения. Maven-зависимости приложения и компиляция изменённого
кода по-прежнему выполняются в сборочном слое.

`RELEASE_CACHE_REF` позволяет указать другой адрес кеша в том же registry;
пустое значение отключает кеширование. Linux ARM64 на x86-runner собирается
через QEMU: для ускорения самой компиляции нужен нативный ARM64-runner.

## Репозитории

| | |
| -- | -- |
| [pepeunit](https://github.com/w7a8n1y4a/pepeunit) | Клиент |
| [pepeunit_server](https://github.com/w7a8n1y4a/pepeunit_server) | Backend |
| [pepeunit_deploy](https://github.com/w7a8n1y4a/pepeunit_deploy) | Развёртывание |

[Карта всех репозиториев](https://pepeunit.com/library/docs?doc=development-pepeunit/maps) · [Поддержать проект](https://pepeunit.com/library/about/support)

## Лицензия

[AGPL-3.0](LICENSE)
