FROM rust:slim-bullseye AS healthcheck

RUN mkdir /src
WORKDIR /src
COPY . .
RUN cargo build --release --locked \
 && strip target/release/healthcheck

################################################################################

FROM debian:bullseye-slim

COPY synapse.asc /tmp/synapse.asc
RUN apt-get -y update \
 && apt-get -y install --no-install-recommends apt-transport-https ca-certificates gnupg \
 && apt-key add /tmp/synapse.asc \
 && rm /tmp/synapse.asc \
 && apt-get -y --purge autoremove apt-transport-https gnupg \
 && apt-get -y clean \
 && rm -rf /var/lib/apt/lists/*

COPY synapse.list /etc/apt/sources.list.d/
RUN apt-get -y update \
 && apt-get -y install --no-install-recommends libgcc1 matrix-synapse-py3 pwgen python3-psycopg2 \
 && apt-get -y clean \
 && rm -rf /var/lib/apt/lists/* /etc/matrix-synapse/* \
 && mkdir -p /etc/matrix-synapse/conf.d \
 && chown -R matrix-synapse /etc/matrix-synapse/

COPY homeserver.yml log.yml /etc/matrix-synapse/
COPY start.sh /start.sh

EXPOSE 8008
VOLUME /etc/matrix-synapse/conf.d/
VOLUME /var/lib/matrix-synapse/

COPY --from=healthcheck /src/target/release/healthcheck /usr/local/bin/ealthcheck
HEALTHCHECK CMD ["/usr/local/bin/healthcheck"]

USER matrix-synapse
WORKDIR /var/lib/matrix-synapse/
CMD ["/start.sh"]
