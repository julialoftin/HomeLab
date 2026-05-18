# PlexDash

PlexDash is a **terminal-based dashboard** written in Bash using `dialog`.
It provides a lightweight, fast way to manage a Plex media server stack directly from an SSH session — no web UI, no extra services, no dependencies beyond what a standard Docker host already has.

The goal of PlexDash is **operational convenience**, not full orchestration.

---

## What PlexDash Is

- A TUI (text user interface) dashboard
- Built with Bash + `dialog`
- Designed for quick administrative actions over SSH
- Docker-native (no socket abstraction layers)

## What PlexDash Is Not

- A replacement for Docker Compose
- A monitoring system
- A web UI
- A scheduler or automation engine

PlexDash is intentionally simple and explicit.

---

## Features

- System stats landing page on launch (uptime, load, memory, disk)
- Live container status with uptime for each service
- Active Plex stream count displayed in the main menu
- Per-container management:
  - Start, stop, restart
  - Resource usage (CPU / memory)
  - Port visibility
  - Live log tail (scrollable, exits cleanly)
- Image update checking with before/after diff (`[UPDATED]` vs `[current]`)
- Pull and restart only updated containers in one action
- Disk usage view across media, downloads, and root volumes with per-library breakdown
- Confirmation prompt before any destructive action

---

## Supported Stack

PlexDash is designed around a standard self-hosted media stack but is easily extensible.

| Container     | Purpose         |
|---------------|-----------------|
| plex          | Media server    |
| sonarr        | TV automation   |
| radarr        | Movie automation|
| jackett       | Indexer proxy   |
| qbittorrent   | Torrent client  |

Container names must match Docker container names exactly.

---

## Requirements

- Linux (tested on Ubuntu Server)
- Bash 4.0+
- Docker with Compose v2
- `dialog`
- `curl` (for Plex stream count)

```bash
sudo apt install dialog curl
```

---

## Installation

```bash
sudo cp plexdash.sh /usr/local/bin/plexdash
sudo chmod +x /usr/local/bin/plexdash
```

---

## Configuration

Edit the configuration block at the top of the script to match your setup:

```bash
PLEX_CONTAINER="plex"             # Container name for Plex
PLEX_PORT=32400                   # Plex web port
PLEX_CONFIG_DIR="/srv/plex/config"
PLEX_MEDIA_DIR="/srv/plex/media"
DOWNLOADS_DIR="/srv/downloads"
MEDIA_SUBDIRS=("Movies" "TV")     # Subdirectories shown in disk breakdown
COMPOSE_FILE="docker-compose.yml"

declare -A containers=(           # Container key → display name
    [plex]="Plex Media Server"
    [qbittorrent]="qBittorrent Client"
    ...
)

declare -A compose_dirs=(         # Container key → path to compose directory
    [plex]="/srv/plex"
    [qbittorrent]="/srv/qbittorrent"
    ...
)
```

The Plex API token is read automatically from `Preferences.xml` inside `PLEX_CONFIG_DIR`. No manual token setup is required.

### Adding a New Service

Add an entry to both maps:

```bash
declare -A containers=(
    ...
    [myservice]="My Service"
)

declare -A compose_dirs=(
    ...
    [myservice]="/srv/myservice"
)
```

The key must match the Docker container name exactly.

---

## Usage

```bash
plexdash
```

PlexDash runs entirely in the terminal and exits cleanly without affecting running containers unless explicitly instructed.

---

## How It Works

- Uses `docker ps` to determine container state and uptime
- Uses `docker stats --no-stream` for resource usage
- Reads Plex session count from the local Plex API
- Compares image SHAs before and after pulls to detect updates
- Uses `dialog` for all user interaction

---

## Security Model

PlexDash relies on:
- SSH key-based access
- VPN-only SSH/service exposure
- OS-level Docker group permissions

It intentionally avoids:
- Running as root
- Managing credentials
- Exposing network services

PlexDash assumes you are a trusted admin. There is no authentication layer beyond SSH.

---

## Troubleshooting

**Containers not showing**
- Ensure container names in the config match `docker ps` output exactly

**Permission denied errors**
- Verify your user is in the `docker` group: `groups`

**Plex stream count shows `?`**
- Verify `PLEX_CONFIG_DIR` points to the directory containing `Library/Application Support/Plex Media Server/Preferences.xml`
- Confirm Plex is running and reachable on `localhost:PLEX_PORT`
