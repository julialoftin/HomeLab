## Resource Constraints

Plex is explicitly constrained to prevent host-level resource starvation during
transcoding or concurrent streams.

Although limits are defined under `deploy.resources.limits` in Compose, they are
**verified at runtime** and enforced via Docker cgroups.

Current limits:
- CPU: 5 cores
- Memory: 6 GiB

Verification:
```bash
docker inspect plex \
  --format 'NanoCpus={{.HostConfig.NanoCpus}} Memory={{.HostConfig.Memory}}'
```
