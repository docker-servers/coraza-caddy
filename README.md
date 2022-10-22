# Coraza WAF with Caddy

This repository contains a Docker container running [Caddy](https://caddyserver.com/) with the [OWASP Coraza WAF](https://coraza.io/). The container is designed to be used as a WAF for a Docker service. The [OWASP Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset) will be used by default.

## Important Notes

* If building the Docker container yourself, the CRS release must be version 4 or above. If you use earlier versions of the CRS, Caddy will fail to start with the following error:

```bash
Error: loading initial config: loading new config: loading http app module: provision http: server srv0: setting up route handlers: route 0: loading handler modules: position 0: loading module 'waf': provision http.handlers.waf: failed to compile rule (error parsing regexp: invalid or unsupported Perl syntax: `(?<`): FILES_NAMES|FILES "@rx (?<!&(?:[aAoOuUyY]uml)|&(?:[aAeEiIoOuU]circ)|&(?:[eEiIoOuUyY]acute)|&(?:[aAeEiIoOuU]grave)|&(?:[cC]cedil)|&(?:[aAnNoO]tilde)|&(?:amp)|&(?:apos));|['\"=]" "id:920120,phase:2,block,t:none,t:urlDecodeUni,msg:'Attempted multipart/form-data bypass',logdata:'%{MATCHED_VAR}',tag:'application-multi',tag:'language-multi',tag:'platform-multi',tag:'attack-protocol',tag:'OWASP_CRS',tag:'OWASP_CRS/PROTOCOL_VIOLATION/INVALID_REQ',tag:'CAPEC-272',ver:'OWASP_CRS/3.2.1',severity:'CRITICAL',setvar:'tx.anomaly_score_pl1=+%{tx.critical_anomaly_score}'"
```
