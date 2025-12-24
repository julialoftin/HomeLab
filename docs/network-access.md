# Network & Access Model

## VPN

- Tailscale (WireGuard-based)
- No port forwarding
- Encrypted device mesh
- MagicDNS enabled

---

## SSH Access

- VPN-only
- Key-based authentication
- Root login disabled
- Password authentication disabled

### Allowed Interfaces
- `tailscale0` only

---

## Device Access

- Admin laptop (primary)
- Mobile device (secondary)
- Devices revocable via VPN or key removal

---

## Firewall Philosophy

- Default deny inbound
- Explicit allow rules
- Interface-scoped SSH rules

