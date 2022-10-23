# Set Caddy release tag
ARG CADDY_TAG="2.6.2"

# Set Go release tag for building confd
ARG GO_TAG="bullseye"

# Use official Caddy builder image
FROM caddy:"${CADDY_TAG}-builder" as builder-caddy

# Set OWASP ModSecurity core rule set release tag to check out
# Available tags are on the GitHub releases page here: https://github.com/coreruleset/coreruleset/tags
ARG CRS_TAG="v4.0.0-rc1"

# Set default Coraza configuration file to download
ARG CORAZA_CONFIG="https://raw.githubusercontent.com/corazawaf/coraza/v2/master/coraza.conf-recommended"

# Build Caddy with Coraza
RUN --mount=type=cache,target=/go \
  xcaddy build --with github.com/corazawaf/coraza-caddy

# Get OWASP ModSecurity Core Rule Set and main configuration file
RUN --mount=type=cache,target=/var/tmp \
  set -eux; \
  # Only retrieve and extract rule set if not existing due to cache layer
  if [ ! -d "/var/tmp/owasp-crs" ]; \
  then \
    # Get rule set archive
    wget --progress=dot:giga -O "/var/tmp/crs-${CRS_TAG}.tar.gz" "https://github.com/coreruleset/coreruleset/archive/refs/tags/${CRS_TAG}.tar.gz"; \
    # Extract rule set
    mkdir /var/tmp/owasp-crs; \
    tar x -z \
      --strip-components=1 \
      -f "/var/tmp/crs-${CRS_TAG}.tar.gz" \
      -C /var/tmp/owasp-crs \
    ; \
  fi; \
  # Only retrieve configuration file if not existing due to cache layer
  if [ ! -f "/var/tmp/coraza.conf" ]; \
  then \
    # Get Coraza configuration file
    wget --progress=dot:giga -O /var/tmp/coraza.conf "$CORAZA_CONFIG"; \
  fi; \
  # Create directory structure for Coraza
  mkdir -p \
    # Main configuration directory
    /opt/coraza/config \
    # User configuration directories
    /opt/coraza/config.d \
    /opt/coraza/rules.d \
  ; \
  # Copy rule set into rules dir
  cp -r /var/tmp/owasp-crs/rules /opt/coraza/rules; \
  # Copy CRS setup file into config dir
  cp /var/tmp/owasp-crs/crs-setup.conf.example /opt/coraza/config/crs-setup.conf; \
  # Copy Coraza configuration file into config dir
  cp /var/tmp/coraza.conf /opt/coraza/config/coraza.conf

# Use official Go image to build confd
FROM golang:"${GO_TAG}" AS builder-confd

# Build confd
# hadolint ignore=DL3003
RUN --mount=type=cache,target=/go/src \
  set -eux; \
  # Only clone repository if not already existing due to cache layer
  if [ ! -d "${GOPATH}/src/github.com/kelseyhightower" ]; \
  then \
    # Make build path
    mkdir -p "${GOPATH}/src/github.com/kelseyhightower"; \
    # Clone GitHub repo
    git clone "https://github.com/kelseyhightower/confd.git" "${GOPATH}/src/github.com/kelseyhightower/confd"; \
  fi; \
  # Build binary
  cd "${GOPATH}/src/github.com/kelseyhightower/confd"; \
  make; \
  # Copy to /go/bin directory due to cache mount
  cp "${GOPATH}/src/github.com/kelseyhightower/confd/bin/confd" /go/bin

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

# Copy newly built Caddy binary from builder-caddy
COPY --from=builder-caddy /usr/bin/caddy /usr/bin/caddy

# Copy out Coraza configuration files and rules from builder-caddy
COPY --from=builder-caddy /opt/coraza /opt/coraza

# Copy our confd from build-confd
COPY --from=builder-confd /go/bin/confd /usr/local/bin/confd

# Add user to run Caddy so it is not running as root
# This should only be done if the Caddy user/group is not set to root
# hadolint ignore=DL3018,SC1075
RUN set -eux; \
  # Test if Caddy user is root; if so these steps are not required
  if [ "$CADDY_USER" = "root" ]; \
  then \
    echo "Skipping Caddy user/group configuration; container will run Caddy as root"; \
  else \
    # Test if libcap needs to be installed
    if [ "$LIBCAP" = true ]; then \
      # Install libcap
      apk add --no-cache libcap; \
      # Set capability on Caddy binary
      setcap cap_net_bind_service=ep /usr/bin/caddy; \
      # Remove libcap
      apk del libcap; \
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

# Add default Caddy configuration file replacing the standard one to make the WAF live
COPY Caddyfile /etc/caddy/Caddyfile

# Set env variables for config/data directories
ENV XDG_CONFIG_HOME="$CADDY_CONFIG_DIR" XDG_DATA_HOME="$CADDY_DATA_DIR"

# Create default volumes
VOLUME /config /data