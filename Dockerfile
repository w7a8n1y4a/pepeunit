FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    HOME=/home/flutter \
    PUB_CACHE=/home/flutter/.pub-cache \
    PATH=/opt/flutter/bin:/home/flutter/.pub-cache/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash flutter \
    && git clone --depth 1 --branch 3.47.7 https://github.com/flutter/flutter.git /opt/flutter \
    && git config --system --add safe.directory /opt/flutter \
    && mkdir -p /app \
    && chown -R flutter:flutter /opt/flutter /app

USER flutter

RUN flutter config --no-analytics --enable-web \
    && flutter precache --web

WORKDIR /app

COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./

RUN flutter pub get

COPY --chown=flutter:flutter lib/ lib/
COPY --chown=flutter:flutter assets/ assets/
COPY --chown=flutter:flutter docs/ docs/
COPY --chown=flutter:flutter tooltip/ tooltip/
COPY --chown=flutter:flutter web/ web/
COPY --chown=flutter:flutter docker/stamp-main-js.sh docker/stamp-main-js.sh

ARG CLIENT_VERSION=1.5.0
RUN flutter build web --release --dart-define="CLIENT_VERSION=${CLIENT_VERSION}" --base-href / \
    && ./docker/stamp-main-js.sh

FROM nginx:1.30-alpine

# Apply security fixes to all runtime packages, including libxslt.
RUN apk upgrade --no-cache

EXPOSE 80

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/40-instance-url.sh /docker-entrypoint.d/40-instance-url.sh
COPY docker/50-og-url.sh /docker-entrypoint.d/50-og-url.sh
RUN chmod +x /docker-entrypoint.d/40-instance-url.sh /docker-entrypoint.d/50-og-url.sh
COPY --from=builder /app/build/web /usr/share/nginx/html
