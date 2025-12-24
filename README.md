# HomeLab
A home media platform + sysadmin learning environment, running on a mini PC with Ubuntu Server.
It is **documentation-first**, designed to function as both a reference and an operational runbook.

---

## What this server is
  - Single-node Ubuntu Server
  - Docker-based media stack
  - VPN-only administrative access
  - Hardened SSH (key-only, no LAN/WAN exposure)
  - LVM-managed storage with clean separation of concerns

---

## Primary Services
| Service | Purpose |
|------|------|
| Plex | Media streaming |
| Sonarr | TV automation |
| Radarr | Movie automation |
| Jackett | Indexer aggregation |
| qBittorrent | Torrent client |

All services run in docker and persist data under '/srv'.

---

## Access Model
- No public SSH
- No router port forwarding
- VPN (Tailscale) required for admin access
- SSH keys only (additional hardening needed here)
- Per-device access control (additional hardening needed here)

---

## Admin access
  - Bash
    ssh "USER@serverName"
