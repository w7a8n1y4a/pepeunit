# Installing Docker and Docker Compose
## Installing Docker

::::info
This guide is written for `debian 12`, but it can be adapted for other `unix` systems.
::::

The following commands install `Docker` for the `root` user:
```bash
sudo su
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

Check that `Docker` is installed:
```bash
docker --version
docker run hello-world
```

If you need to allow another user to run `docker` commands, use:
```bash
sudo su
sudo usermod -aG docker <user-name>
```

Enable `docker` on system startup:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Installing Docker Compose

Run:
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Check that `Docker Compose` is installed:
```bash
docker-compose --version
```

