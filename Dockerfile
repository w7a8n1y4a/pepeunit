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

COPY --chown=flutter:flutter client/pubspec.yaml client/pubspec.lock ./

RUN flutter pub get

COPY --chown=flutter:flutter client/ ./

RUN flutter build web --release --base-href /

FROM nginx:1.27-alpine

EXPOSE 80

COPY client/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html
