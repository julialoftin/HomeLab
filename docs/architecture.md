# Architecture

This document describes the **system architecture** of the home server environment,
including trust boundaries, component relationships, and design intent.

The goal is to provide a **clear mental model** of how the system works and why it is built this way.

---

## 1. Architecture Overview

The system is a **single-node home server** running Ubuntu Server, designed around:

- Dockerized application workloads
- VPN-only administrative access
- Explicit network trust boundaries
- Logical storage separation using LVM

This architecture intentionally avoids:
- Publicly exposed management services
- Router port forwarding
- Complex orchestration platforms

---

## 2. High-Level Logical Diagram

                       ┌───────────────────────┐
                       │        Internet        │
                       └───────────┬───────────┘
                                   │
                          (No inbound access)
                                   │
                ┌──────────────────▼──────────────────┐
                │            VPN (Tailscale)           │
                │        Encrypted device mesh         │
                └───────────┬───────────┬─────────────┘
                            │           │
             ┌──────────────▼───┐   ┌───▼──────────────┐
             │  Admin Laptop     │   │     Mobile       │
             │  • SSH key        │   │  • SSH key       │
             │  • VPN client     │   │  • VPN client    │
             └──────────┬────────┘   └────────┬────────┘
                        │                     │
                 SSH / HTTPS              SSH / HTTPS
                        │                     │
     ┌──────────────────▼─────────────────────▼──────────────────┐
     │                         Home Server                         │
     │                 Ubuntu Server (LTS)                         │
     │                                                              │
     │  ┌──────────────────── Firewall (UFW) ───────────────────┐ │
     │  │ • Default deny inbound                                  │ │
     │  │ • SSH allowed only on VPN interface                     │ │
     │  │ • Media ports restricted                                │ │
     │  └────────────────────────────────────────────────────────┘ │
     │                                                              │
     │  ┌──────────────────── Docker Engine ─────────────────────┐ │
     │  │                                                          │ │
     │  │  Plex        → Media streaming                           │ │
     │  │  Sonarr      → TV automation                             │ │
     │  │  Radarr      → Movie automation                          │ │
     │  │  Jackett     → Indexer aggregation                       │ │
     │  │  qBittorrent → Download client                           │ │
     │  │                                                          │ │
     │  └────────────────────────────────────────────────────────┘ │
     │                                                              │
     │  ┌──────────────────── Storage (LVM) ─────────────────────┐ │
     │  │  /                     → OS                              │ │
     │  │  /srv/downloads        → Temporary data                  │ │
     │  │  /srv/plex/media       → Permanent media                 │ │
     │  └────────────────────────────────────────────────────────┘ │
     └──────────────────────────────────────────────────────────────┘

---

## 3. Trust Boundaries

The system is divided into **three explicit trust zones**:

### 3.1 Internet (Untrusted)
- No inbound administrative access
- No exposed management ports
- No reliance on NAT traversal or port forwarding

### 3.2 VPN (Trusted)
- Encrypted access via Tailscale
- Required for:
  - SSH
  - Administrative web interfaces
- Device-level authentication and revocation

### 3.3 LAN (Semi-Trusted)
- Media streaming allowed
- Administrative access still routed through VPN
- No SSH exposure on LAN interfaces

---

## 4. Access Model

### Administrative Access
- VPN required
- SSH key-based authentication only
- Password authentication disabled
- Root login disabled
- Per-device SSH keys

### User Access
- Media services accessed via LAN or VPN
- No direct shell access for non-admin users

---

## 5. Application Architecture

### Container Runtime
- Docker Engine
- One service per container
- Restart policies enabled

### Application Responsibilities
- Plex: media serving
- Sonarr/Radarr: automation and orchestration
- Jackett: indexer abstraction
- qBittorrent: download client

### Design Principles
- Explicit ports
- Explicit volumes
- No container-to-container privilege escalation
- Minimal host integration

---

## 6. Storage Architecture

Storage is managed via **Logical Volume Manager (LVM)**.

### Logical Separation
- OS volume isolated from application data
- Downloads isolated from permanent media
- Media volume optimized for growth

### Benefits
- Safe resizing
- Reduced blast radius for disk issues
- Clear recovery strategy

---

## 7. Networking & Firewall Architecture

### Firewall (UFW)
- Default deny inbound
- Explicit allow rules only
- Interface-based SSH restrictions

### Networking Model
- Docker bridge networking for services
- VPN interface for admin access
- No exposed Docker management ports

---

## 8. Failure Domains & Resilience

### Designed For
- Power loss recovery
- Container restarts
- Disk resizing events
- Network interruptions

### Not Designed For
- High availability
- Multi-node failover
- Zero-downtime upgrades

These trade-offs are intentional given scope.

---

## 9. Design Goals & Non-Goals

### Goals
- Security over convenience
- Clarity over abstraction
- Recoverability over automation
- Learning real-world sysadmin patterns

### Non-Goals
- Kubernetes or orchestration complexity
- Public service exposure
- Fully automated CI/CD
- Enterprise-scale redundancy

---

## 10. Summary

This architecture prioritizes:
- Minimal attack surface
- Explicit trust boundaries
- Simple operational recovery
- Strong documentation over hidden complexity

It is intentionally **boring, understandable, and resilient** — by design.

