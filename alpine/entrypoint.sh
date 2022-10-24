#!/bin/sh

# Launch confd to configure Caddy and the appropriate Coraza configuration

set -e
echo "Generating configuration files"

# Generate configuration files
confd -onetime -backend env -log-level warning -config-file /etc/confd/conf.d/Caddyfile.toml

# Launch Caddy
echo "Launching $*"
exec "$@"