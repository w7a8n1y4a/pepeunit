# Установка Docker и Docker Compose

## Что нужно на сервере

- `Docker` с плагином `Docker Compose` (команда `docker compose`, через пробел)
- `Python 3` и `git`
- `bash`

## Установка Docker

:::info
Инструкция для `debian 12`, на других `unix`-системах команды похожи.
:::

Установите `Docker` от имени `root`:
```bash
sudo su
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

Проверьте установку:
```bash
docker --version
docker run hello-world
```

Чтобы разрешить `docker` другому пользователю:
```bash
sudo usermod -aG docker <user-name>
```

Включите автозапуск:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Установка Docker Compose

Скрипт установки ставит `Docker Compose` вместе с `Docker`. Проверьте:
```bash
docker compose version
```

Если плагина нет, установите его из пакетов дистрибутива, например для `debian`:
```bash
sudo apt-get install docker-compose-plugin
```

:::warning
Нужна команда `docker compose` (плагин), а не старая `docker-compose`. Все команды в документации написаны для плагина.
:::

## Установка Python и Git

```bash
sudo apt-get install python3 git
```
