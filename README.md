# Coraza WAF with Caddy

This repository contains a Docker container running [Caddy](https://caddyserver.com/) with the [OWASP Coraza WAF](https://coraza.io/). The container is designed to be used as a WAF for a Docker service. The [OWASP Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset) will be used by default.

Currently, the assumption is made that this acts as an intermediate proxy between the ingress and the service to protect. There is no SSL configuration, rather than should be handled at the ingress.

- [Coraza WAF with Caddy](#coraza-waf-with-caddy)
  - [Important Notes](#important-notes)
  - [Examples](#examples)
    - [Docker Swarm Stack](#docker-swarm-stack)

## Important Notes

* The container is configured by default to run as a non-root user. The upstream Caddy containers run using root by default. To allow binding on ports <1024 `cap_net_bind_service` is added on the Caddy binary.
* If building the Docker container yourself, the CRS release must be version 4 or above. If you use earlier versions of the CRS, Caddy will fail to start with the following error:

```bash
Error: loading initial config: loading new config: loading http app module: provision http: server srv0: setting up route handlers: route 0: loading handler modules: position 0: loading module 'waf': provision http.handlers.waf: failed to compile rule (error parsing regexp: invalid or unsupported Perl syntax: `(?<`): FILES_NAMES|FILES "@rx (?<!&(?:[aAoOuUyY]uml)|&(?:[aAeEiIoOuU]circ)|&(?:[eEiIoOuUyY]acute)|&(?:[aAeEiIoOuU]grave)|&(?:[cC]cedil)|&(?:[aAnNoO]tilde)|&(?:amp)|&(?:apos));|['\"=]" "id:920120,phase:2,block,t:none,t:urlDecodeUni,msg:'Attempted multipart/form-data bypass',logdata:'%{MATCHED_VAR}',tag:'application-multi',tag:'language-multi',tag:'platform-multi',tag:'attack-protocol',tag:'OWASP_CRS',tag:'OWASP_CRS/PROTOCOL_VIOLATION/INVALID_REQ',tag:'CAPEC-272',ver:'OWASP_CRS/3.2.1',severity:'CRITICAL',setvar:'tx.anomaly_score_pl1=+%{tx.critical_anomaly_score}'"
```

## Examples

The following examples can be used to help get setup with the WAF.

### Docker Swarm Stack

This example can be used to protect a service running in a Docker swarm stack. The assumption is made that [Traefik](https://traefik.io/traefik/) will be used as the ingress.

```yaml
---

# Docker compose for example for the Coraza WAF

version: '3.8'

services:

  ## The "whoami" container
  ## This is the container that the WAF will be protecting
  whoami:
    image: traefik/whoami
    networks:
      - whoami

  ## Coraza WAF running on Caddy
  caddy:
    image: registry.gitlab.com/docker-servers/coraza-caddy/alpine:latest
    depends_on:
      - whoami
    networks:
      - whoami
      - caddy
    environment:
      - REVERSE_PROXY=whoami:80
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=caddy"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.rule=Host(`example.com`,`www.example.com`)"
      - "traefik.http.routers.whoami.service=whoami"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.tls.certresolver=le-http"
      - "traefik.http.services.whoami.loadbalancer.server.port=80"

  ## Traefik container
  traefik:
    image: traefik:latest
    networks:
      - bridge
      - caddy
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: host
      - target: 443
        published: 443
        protocol: tcp
        mode: host
      - target: 443
        published: 443
        protocol: udp
        mode: host
    command:
      ## Enable debug logs
      #- "--log.level=DEBUG"
      ## Skip telemetry
      - '--global.sendAnonymousUsage=false'
      - '--global.checkNewVersion=false'
      ## Enable ping for health checks to work
      - "--ping"
      ## Enable docker provider
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      ## Set inbound connections port for HTTP
      - "--entrypoints.web.address=:80"
      ## Set inbound connections port for HTTPS
      - "--entrypoints.websecure.address=:443"
      ## Enable HTTP3
      - "--experimental.http3=true"
      - "--entrypoints.websecure.http3=true"
      ## Configure LetsEncrypt HTTP01 challenge
      - "--certificatesresolvers.le-http.acme.email=me@example.com"
      - "--certificatesresolvers.le-http.acme.storage=/certificates/certificates.json"
      - "--certificatesresolvers.le-http.acme.keytype=EC384"
      - "--certificatesresolvers.le-http.acme.httpchallenge.entrypoint=web"
    labels:
      ## Enable Traefik for this container to allow for global redirect
      - "traefik.enable=true"
      ## Global redirect to https excluding ACME certificate requests
      - "traefik.http.routers.http-catchall.rule=HostRegexp(`{host:.+}`)"
      - "traefik.http.routers.http-catchall.entrypoints=web"
      - "traefik.http.routers.http-catchall.middlewares=force-https"
      - "traefik.http.middlewares.force-https.redirectscheme.scheme=https"
    volumes:
      ## Docker volume to read labels
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      ## Preserve certificates in volume
      - certificates:/certificates

## Networks used by the above services
networks:
  ## Internal network for Traefik to reach Caddy
  caddy:
    driver: overlay
    internal: true
  ## Internal network for Caddy to reach the whoami service
  whoami:
    driver: overlay
    internal: true
  ## The externally defined bridge network for Traefik to listen for incoming HTTP/HTTPS connections
  bridge:
    external: true

## Volumes used by the above services
volumes:
  ## Certificate store for Traefik
  certificates:
```
