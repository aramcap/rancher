# Rancher/RKE2 scripts

## RKE2

Server:
```sh
curl -sfL https://raw.githubusercontent.com/aramcap/rancher/main/rke2/rke2-install-server.sh | sh -
```

Options:
- RKE2_VERSION: defaults to v1.26.8+rke2r1
- RKE2_SERVER: optional
- RKE2_TOKEN: optional
- TLS_SAN: optional
- CONTROL_PLANE_DEDICATED: defaults to true

Example with options:
```sh
curl -sfL https://raw.githubusercontent.com/aramcap/rancher/main/rke2/rke2-install-server.sh | TLS_SAN="fixed.internal.local" sh -
```

Agent:
```sh
curl -sfL https://raw.githubusercontent.com/aramcap/rancher/main/rke2/rke2-install-agent.sh | sh -
```

Options:
- RKE2_SERVER: mandatory
- RKE2_TOKEN: mandatory

## Rancher

```sh
curl -sfL https://raw.githubusercontent.com/aramcap/rancher/main/rke2/rke2-install-server.sh | sh -
```
