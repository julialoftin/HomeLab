# Security Audit

This document defines the **security posture, audit process, and verification steps**
for the home server environment documented in this repository.

It is intended to be:
- Run periodically (quarterly or after major changes)
- Executed manually by the administrator
- Used as a checklist and reasoning aid, not automation

---

## Scope

This audit covers:
- Operating system configuration
- SSH access controls
- VPN access model
- Firewall configuration
- Docker runtime exposure
- Storage and data safety
- Administrative practices

Out of scope:
- Application-level vulnerabilities (e.g., Plex CVEs)
- Media content legality
- Client device security

---

## Threat Model (High-Level)

### Primary Threats
- Unauthorized remote access
- Credential brute-force attacks
- Exposed admin interfaces
- Data loss due to misconfiguration
- Privilege escalation

### Assumptions
- Physical access to the server is trusted
- Admin devices (laptop / phone) are trusted
- VPN provider security is acceptable
- No hostile users on the LAN

---

## Audit Frequency

- **Quarterly** (recommended)
- **After any of the following:**
  - Firewall changes
  - SSH configuration changes
  - VPN configuration changes
  - New services exposed
  - Storage reconfiguration

---

## 1. Operating System Security

### Checks
- [ ] OS is a supported LTS release
- [ ] System packages are up to date
- [ ] No unexpected users exist
- [ ] Sudo access limited to admin users

### Verification Commands
```bash
lsb_release -a
apt list --upgradable
getent passwd
getent group sudo
```

## 2. SSH Configuration

### Requirements
  - SSH key-based authentication only
  - Password authentication disabled
  - Root login disabled
  - SSH restricted to VPN interface

### Audit Checklist
- [ ] PasswordAuthentication no
- [ ] PermitRootLogin no
- [ ] PubkeyAuthentication yes
- [ ] SSH allowed only on tailscale0
- [ ] No SSH access on LAN or WAN interfaces
- [ ] Separate keys per device
- [ ] Unused keys removed

### Verification Commands
```bash
sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin|pubkeyauthentication'
sudo ufw status verbose | grep 22
ls -l ~/.ssh/authorized_keys
```


