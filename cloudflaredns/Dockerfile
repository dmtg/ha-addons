# Build the Home Assistant App around the official Cloudflare DDNS image.
# The DDNS image is used only as a build stage; the Supervisor builds the
# resulting Home Assistant App image locally for the selected architecture.

FROM timothymiller/cloudflare-ddns:2.2.0 AS cloudflare_ddns

FROM ghcr.io/home-assistant/base:latest

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL   io.hass.version="${BUILD_VERSION}"   io.hass.type="app"   io.hass.arch="${BUILD_ARCH}"

COPY --from=cloudflare_ddns /cloudflare-ddns /usr/bin/cloudflare-ddns
COPY run.sh /run.sh

RUN chmod a+x /run.sh /usr/bin/cloudflare-ddns

CMD ["/run.sh"]
