# Storage Architecture (LVM)

## Logical Volumes

| Mount | Purpose |
|----|----|
| `/` | OS |
| `/srv/downloads` | Temporary downloads |
| `/srv/plex/media` | Permanent media |

---

## Design Rules

- Never download directly to media
- Temporary data is disposable
- Media volume is expandable
- No symlinks between mounts

---

## Resizing Guidance

- Stop all writers before resizing
- Shrink filesystem before LV
- Grow filesystem after LV extend
