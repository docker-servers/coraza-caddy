# Coraza WAF with Caddy

This repository contains a Docker container running [Caddy](https://caddyserver.com/) with the [OWASP Coraza WAF](https://coraza.io/). The container is designed to be used as a WAF for a Docker service. The [OWASP Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset) will be used by default.

Currently, the assumption is made that this acts as an intermediate proxy between the ingress and the service to protect. There is no SSL configuration, rather than should be handled at the ingress.

- [Coraza WAF with Caddy](#coraza-waf-with-caddy)
  - [Important Notes](#important-notes)
  - [Examples](#examples)
  - [Build Arguments](#build-arguments)

## Important Notes

- The container is configured by default to run as a non-root user. The upstream Caddy containers run using root by default. To allow binding on ports <1024 `cap_net_bind_service` is added on the Caddy binary.
- If building the Docker container yourself, the CRS release must be version 4 or above. If you use earlier versions of the CRS, Caddy will fail to start with the following error:

```bash
Error: loading initial config: loading new config: loading http app module: provision http: server srv0: setting up route handlers: route 0: loading handler modules: position 0: loading module 'waf': provision http.handlers.waf: failed to compile rule (error parsing regexp: invalid or unsupported Perl syntax: `(?<`): FILES_NAMES|FILES "@rx (?<!&(?:[aAoOuUyY]uml)|&(?:[aAeEiIoOuU]circ)|&(?:[eEiIoOuUyY]acute)|&(?:[aAeEiIoOuU]grave)|&(?:[cC]cedil)|&(?:[aAnNoO]tilde)|&(?:amp)|&(?:apos));|['\"=]" "id:920120,phase:2,block,t:none,t:urlDecodeUni,msg:'Attempted multipart/form-data bypass',logdata:'%{MATCHED_VAR}',tag:'application-multi',tag:'language-multi',tag:'platform-multi',tag:'attack-protocol',tag:'OWASP_CRS',tag:'OWASP_CRS/PROTOCOL_VIOLATION/INVALID_REQ',tag:'CAPEC-272',ver:'OWASP_CRS/3.2.1',severity:'CRITICAL',setvar:'tx.anomaly_score_pl1=+%{tx.critical_anomaly_score}'"
```

## Examples

The following examples can be used to help get setup with the WAF.

- [docker-compose-swarm.yaml](docker-compose-swarm.yaml): Example compose file for a Docker swarm.

## Build Arguments

Various arguments can be provided if building the container yourself. The available arguments are:

| Variable        | Default                                                                                | Description                                                                                                                                                 |
| --------------- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CADDY_TAG`     | `2.6.2`                                                                                | The Caddy Docker container tag to use as a base.                                                                                                            |
| `CRS_TAG`       | `v4.0.0-rc1`                                                                           | The OWASP Core Rule Set release tag.                                                                                                                        |
| `CORAZA_CONFIG` | `https://raw.githubusercontent.com/corazawaf/coraza/v2/master/coraza.conf-recommended` | The URL to download the default Coraza configuration file from.                                                                                             |
| `LIBCAP`        | `true`                                                                                 | Install libcap and add the `cap_net_bind_service` capability to the Caddy binary. Required for the container to bind to low ports when not running as root. |
