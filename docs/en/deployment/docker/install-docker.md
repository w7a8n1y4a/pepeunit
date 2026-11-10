# Installing Docker and Docker Compose

## What the server needs

- `Docker` with the `Docker Compose` plugin: the `docker compose` command (with a space) is required, not the old `docker-compose`. All commands in the documentation are written for the plugin
- `Python 3` and `git`
- `bash`

## Installing Docker

The instructions are for `debian 12`; on other `unix` systems the commands are similar. Install `Docker` as `root`:
```bash
sudo su
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

Check the installation:
```bash
docker --version
docker run hello-world
```

To allow another user to use `docker`:
```bash
sudo usermod -aG docker <user-name>
```

Enable autostart:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Installing Docker Compose

The installation script installs `Docker Compose` together with `Docker`. Check:
```bash
docker compose version
```

If the plugin is missing, install it from your distribution's packages, for example for `debian`:
```bash
sudo apt-get install docker-compose-plugin
```

## Installing Python and Git

```bash
sudo apt-get install python3 git
```
