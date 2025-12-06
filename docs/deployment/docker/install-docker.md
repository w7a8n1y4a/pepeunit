# Установка Docker и Docker Compose
## Установка Docker

:::info
Данное руководство для `debian 12`, однако может быть применимо для иных `unix`-систем.
:::

Данный набор команд позволит установить `Docker` в систему для пользователя `root`:
```bash
sudo su
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

Проверьте установку `Docker`:

```bash
docker --version
docker run hello-world
```

Если права для использования команды `docker` нужно предоставить другому пользователю, можно воспользоваться командой:
```bash
sudo su
sudo usermod -aG docker <user-name>
```

Установите `docker` в автозапуск:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Установка Docker Compose

Выполните команды:
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Проверьте установку `Docker Compose`:
```bash
docker-compose --version
```