# PlexDash

PlexDash is a **terminal-based dashboard** written in Bash using `dialog`.  
It provides a lightweight, fast way to manage Plex-related Docker containers directly from an SSH session.

The goal of PlexDash is **operational convenience**, not full orchestration.

---

## What PlexDash Is

- A **TUI (text user interface)** dashboard
- Built with Bash + `dialog`
- Designed for **quick administrative actions**
- Docker-native (no Docker socket abstraction layers)

---

## What PlexDash Is Not

- A replacement for Docker Compose
- A monitoring system
- A web UI
- A scheduler or automation engine

PlexDash is intentionally simple and explicit.

---

## Features

### Current Features

- Interactive menu-driven interface
- Per-container management:
  - Start
  - Stop
  - Restart
  - Status
  - Resource usage (CPU / memory)
  - Port visibility
  - Container pruning
- Visual status indicators (running vs stopped)
- Safe defaults (no destructive actions without confirmation)

### Planned / Optional Enhancements

- Landing page with system stats
- ASCII banner (small, readable)
- Quick actions:
  - Restart all media services
  - Container health summary

---

## Supported Services

PlexDash is designed around a **media stack**, but is easily extensible.

Default services:

| Container | Purpose |
|---------|--------|
| plex | Media server |
| sonarr | TV automation |
| radarr | Movie automation |
| jackett | Indexer |
| qbittorrent | Torrent client |

Service names must match Docker container names.

---

## Requirements

### System Requirements

- Linux (tested on Ubuntu Server)
- Bash 4+
- Docker
- `dialog`

### Install Dependencies

```bash
sudo apt update
sudo apt install -y dialog
```

### Usage

Run PlexDash from an SSH session:
```bash
./plexdash.sh
```

or, if in PATH:
```bash
plexdash.sh
```

PlexDash runs entirely in the terminal and exits cleanly without affecting running containers unless explicitly instructed.

### How It Works (High-Level)
  - Uses docker ps to determine container state
  - Uses docker stats --no-stream for resource usage
  - Uses dialog menus for interaction
  - Does not run as root (relies on Docker group membership)

### Safety Notes
  - PlexDash assumes you are a trusted admin user
  - No authentication layer beyond SSH
  - Docker commands are executed directly
  - Use confirmations for any bulk actions

### Extending PlexDash
  - PlexDash is intentionally easy to modify.
## Adding a New Service
  - Edit the container map:
```bash
declare -A containers=(
  [plex]="Plex Media Server"
  [newservice]="My New Service"
)
```
  - Ensure the Docker container name matches the key.

### Troubleshooting
Containers Not Showing
  - Ensure container names match exactly
  - Check:
```bash
docker ps -a
```
Permission Denied Errors
  - Verify user is in the docker group:
```bash
groups
```

### Security Model
PlexDash relies on:
  - SSH key-based access
  - VPN-only SSH exposure
  - OS-level permissions

It intentionally avoids:
  - Running as root
  - Managing credentials
  - Exposing network services
