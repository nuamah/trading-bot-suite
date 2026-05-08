# PHASE 05 — Remote deploy (Git + SSH + Docker Compose)

This phase makes your VPS deployment repeatable:

- You **push** code changes from your PC to a Git remote (GitHub / GitLab / private bare repo).
- The VPS **pulls** updates and restarts the containers with a single command.

> **Security note**: do not expose the Freqtrade API (8080) publicly unless you understand and harden it. Prefer SSH tunneling.

---

## Option A (recommended): Pull-based deploy from GitHub/GitLab

### 1) Initialize and push this repo (from your PC)

From the project root (`trading-bot-suite/`):

```bash
git add .
git commit -m "Initial containerized trading bot suite"
```

Create a new repo on GitHub/GitLab, then add it as `origin` and push:

```bash
git remote add origin <YOUR_GIT_REMOTE_URL>
git push -u origin master
```

If you prefer `main`:

```bash
git branch -M main
git push -u origin main
```

### 2) Prepare the VPS

- Install Docker + Compose plugin (see `docs/PHASE_01_INFRA.md`)
- Install git:

```bash
sudo apt update
sudo apt install -y git
```

### 3) Clone onto the VPS

Pick a location (recommended):

```bash
sudo mkdir -p /opt/trading-bot-suite
sudo chown -R "$USER:$USER" /opt/trading-bot-suite
```

Clone:

```bash
git clone <YOUR_GIT_REMOTE_URL> /opt/trading-bot-suite
cd /opt/trading-bot-suite
```

Create the real `.env` on the VPS:

```bash
cp .env.example .env
nano .env
```

Start:

```bash
docker compose up -d
docker compose logs -f --tail=200
```

### 4) Deploy updates (one command)

After you push new commits from your PC:

```bash
bash /opt/trading-bot-suite/scripts/vps-deploy.sh /opt/trading-bot-suite
```

If you want the script globally runnable:

```bash
sudo ln -sf /opt/trading-bot-suite/scripts/vps-deploy.sh /usr/local/bin/trading-bot-deploy
trading-bot-deploy /opt/trading-bot-suite
```

---

## Option B: “Push-to-deploy” (bare repo on VPS + post-receive hook)

Use this if you don’t want GitHub/GitLab and prefer pushing directly to your VPS.

### 1) On the VPS, create a bare repo

```bash
sudo mkdir -p /opt/git
sudo chown -R "$USER:$USER" /opt/git

git init --bare /opt/git/trading-bot-suite.git
```

### 2) Create a deploy working tree

```bash
mkdir -p /opt/trading-bot-suite
```

### 3) Add a post-receive hook

Create `/opt/git/trading-bot-suite.git/hooks/post-receive`:

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/trading-bot-suite"
GIT_DIR="/opt/git/trading-bot-suite.git"
BRANCH="main"

mkdir -p "$APP_DIR"
git --work-tree="$APP_DIR" --git-dir="$GIT_DIR" checkout -f "$BRANCH"

cd "$APP_DIR"
if [[ ! -f ".env" ]]; then
  echo "Missing .env in $APP_DIR (create it once from .env.example)" >&2
  exit 1
fi

docker compose up -d --build
```

Make it executable:

```bash
chmod +x /opt/git/trading-bot-suite.git/hooks/post-receive
```

### 4) On your PC, add a remote pointing to the VPS

```bash
git remote add vps ssh://<USER>@<VPS_HOST>/opt/git/trading-bot-suite.git
git push vps main
```

Every push to `main` will auto-deploy.

---

## SSH setup notes

- Use SSH keys (avoid passwords).
- If your remote is GitHub/GitLab, use their recommended SSH key workflow.
- If pushing directly to the VPS, ensure `sshd` is hardened and the VPS firewall only allows necessary ports.

