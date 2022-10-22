# Set Caddy release tag
ARG CADDY_TAG="2.6.2"

# Use official Caddy builder image
FROM caddy:"${CADDY_TAG}-builder" as builder

# Set OWASP ModSecurity core rule set release tag to check out
# Available tags are on the GitHub releases page here: https://github.com/coreruleset/coreruleset/tags
ARG CRS_TAG="v3.3.4"

# Set default Coraza configuration file to download
ARG CORAZA_CONFIG="https://raw.githubusercontent.com/corazawaf/coraza/v2/master/coraza.conf-recommended"

# Build Caddy with Coraza
RUN xcaddy build --with github.com/corazawaf/coraza-caddy

# Get OWASP ModSecurity Core Rule Set
RUN set -eux; \
  # Get rule set archive
  wget -O "/var/tmp/crs-${CRS_TAG}.tar.gz" "https://github.com/coreruleset/coreruleset/archive/refs/tags/${CRS_TAG}.tar.gz"; \
  # Extract rule set
  mkdir /var/tmp/owasp-crs; \
  tar x -z \
    --strip-components=1 \
    -f "/var/tmp/crs-${CRS_TAG}.tar.gz" \
    -C /var/tmp/owasp-crs \
  ; \
  # Get Coraza configuration file
  wget -O /var/tmp/coraza.conf "$CORAZA_CONFIG"

# Switch to official Caddy container
FROM caddy:"$CADDY_TAG"

# Add libcap to allow Caddy to bind to port 80/443 with a low privledged account
# If this is not required it may be disabled (eg. if Caddy is listening on a high port)
ARG LIBCAP=true

# Set user and group IDs for user that will run Caddy
ARG CADDY_UID=1000
ARG CADDY_GID=1000

# Set user name and group name for the user that will run Caddy
ARG CADDY_USER=caddy
ARG CADDY_GROUP=caddy

# Set configuration directory
ARG CADDY_CONFIG_DIR=/config

# Set data directory
ARG CADDY_DATA_DIR=/data

# Copy newly built Caddy binary from builder
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Create directory to store Coraza configuration, rule sets and temporary files
RUN set -eux; \
  mkdir -p \
    # Main configuration directory
    /opt/coraza/config \
    # User configuration directories
    /opt/coraza/config.d \
    /opt/coraza/rules.d \
  ;

# Copy out core rule set files from builder
COPY --from=builder /var/tmp/owasp-crs/rules /opt/coraza/rules

# Copy out Coraza configuration file from builder
COPY --from=builder /var/tmp/coraza.conf /opt/coraza/config/coraza.conf

# Add user to run Caddy so it is not running as root
# This should only be done if the Caddy user/group is not set to root
RUN set -eux; \
  # Test if Caddy user is root; if so these steps are not required
  if [ "$CADDY_USER" = "root" ]; then \
    echo "Skipping Caddy user/group configuration; container will run Caddy as root"; \
  else \
    # Test if libcap needs to be installed
    if [ "$LIBCAP" = true ]; then \
      # Install libcap
      apk add --no-cache libcap; \
      # Set capability on Caddy binary
      setcap cap_net_bind_service=ep /usr/bin/caddy; \
    fi; \
    # Add Caddy group
    addgroup -g "$CADDY_GID" -S "$CADDY_GROUP"; \
    # Add Caddy user
    adduser -u "$CADDY_UID" -D -S -G "$CADDY_GROUP" "$CADDY_USER"; \
    # Fix permissions for configuration directories
    chown -R "$CADDY_UID":"$CADDY_GID" \
      "${CADDY_CONFIG_DIR}" \
      "${CADDY_DATA_DIR}" \
    ; \
  fi

# Switch user
USER "${CADDY_USER}:${CADDY_GROUP}"

# Add default configuration file replacing the standard one
COPY Caddyfile /etc/caddy/Caddyfile

# Set env variables for config/data directories
ENV XDG_CONFIG_HOME="$CADDY_CONFIG_DIR" XDG_DATA_HOME="$CADDY_DATA_DIR"

# Create default volumes
VOLUME /config /data