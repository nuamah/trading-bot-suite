# PHASE 01 — Infrastructure (Ubuntu VPS + Docker)

## VPS baseline

- **OS**: Ubuntu 22.04+ recommended
- **User**: use a non-root user with sudo
- **Firewall**: allow SSH (22). If you want the Freqtrade API reachable externally, also allow 8080 (ideally restricted by IP).

## System update

```bash
sudo apt update && sudo apt -y upgrade
sudo apt -y install ca-certificates curl gnupg
```

## Install Docker Engine + Compose plugin

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify:

```bash
docker --version
docker compose version
```

## Allow your user to run Docker

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

## Deploy the project folder

Copy `trading-bot-suite/` to your VPS (example with rsync):

```bash
rsync -av --delete trading-bot-suite/ user@your-vps:/opt/trading-bot-suite/
```

## Directory permissions

Freqtrade writes logs/data inside `user_data/`.

```bash
sudo mkdir -p /opt/trading-bot-suite
sudo chown -R "$USER:$USER" /opt/trading-bot-suite
```

## Secrets hygiene

- Copy `.env.example` to `.env` on the VPS and fill values.
- Keep `.env` private (permissions `600` is a good baseline).
- Select your execution profile using `CONFIG_PROFILE` (`demo` | `live` | `testnet`).

```bash
cd /opt/trading-bot-suite
cp .env.example .env
chmod 600 .env
```

## Optional: harden API access

The sample config enables the Freqtrade API on port 8080.

Recommended approaches:
- bind to localhost and access via SSH tunnel, **or**
- firewall 8080 to your IP only, **or**
- put behind a reverse proxy with auth + TLS.
