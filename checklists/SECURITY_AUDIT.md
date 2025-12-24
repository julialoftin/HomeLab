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

## 3. VPN (Tailscale)

### Requirements
  - VPN required for administrative access
  - No port forwarding configured on router
  - Device approval enabled
  - Ability to revoke devices quickly

### Audit Checklist
- [ ] VPN client running on server
- [ ] VPN connected on admin devices
- [ ] Only trusted devices present
- [ ] MagicDNS enabled
- [ ] VPN ACLs reviewed (if in use)

### Verification Commands
```bash
tailscale status
tailscale ip -4
```

## 4. Firewall (UFW)

### Requirements
  - Default deny inbound
  - Explicit allow rules only
  - No unnecessary open ports
  - SSH restricted by interface

### Audit Checklist
- [ ] Default incoming policy: deny
- [ ] SSH blocked on LAN/WAN
- [ ] Media ports limited to LAN/VPN
- [ ] No unexpected allow rules

### Verification Commands
```bash
sudo ufw status verbose
sudo ufw show added
```

## 5. Docker Security

### Requirements
  - Containers run as non-root where possible
  - Docker socket not exposed to containers
  - No secrets committed to images or compose files
  - Restart policies enabled

### Audit Checklist
- [ ] Docker daemon running
- [ ] No containers running privileged unless required
- [ ] No exposed admin UIs to WAN
- [ ] Images reasonably up to date

### Verification Commands
```bash
docker ps
docker inspect <container>
docker info
```

## 6. Storage and Data Safety

### Requirements
  - OS, downloads, and media separated
  - Adequate free space maintained
  - No downloads stored directly on OS volume

### Audit Checklist
- [ ] /srv/downloads used only for temporary data
- [ ] /srv/plex/media used only for permanent media
- [ ] No unexpected mounts
- [ ] Sufficient free disk space

### Verification Commands
```bash
df -h
lsblk
mount
```

## 7. Logging & Monitoring

### Requirements
  - SSH logs accessible
  - Docker logs accessible
  - No unexplained authentication attempts

### Audit Checklist
- [ ] SSH logs reviewed
- [ ] Docker logs available
- [ ] No repeated failed logins

### Verification Commands
```bash
sudo journalctl -u ssh --since "7 days ago"
docker logs <container>
```

## 8. Administrative Practices

### Requirements
  - Changes planned and documented
  - Rollback path understood
  - Emergency access available

### Audit Checklist
- [ ] Change checklist followed
- [ ] Runbooks up to date
- [ ] Emergency console access available
- [ ] Backup plan documented (even if manual)

## 9. Findings & Actions

### Findings
(Document any issues found here)

### Remediation Actions
(Document actions taken or planned)




