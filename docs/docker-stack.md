# Docker Stack Overview

## Container Philosophy

- One service per container
- Persistent configs under `/srv/<service>`
- Restart policies enabled
- Logs accessed via `docker logs`

---

## Update Strategy

```bash
docker pull <image>
docker stop <container>
docker rm <container>
docker compose ... ***Need to check this line
