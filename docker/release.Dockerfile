# syntax=docker/dockerfile:1
# CI builds on amd64: Linux x64 and Android ARM64 via the Android toolchain.
FROM ubuntu:24.04 AS sdk
ARG FLUTTER_VERSION=3.47.7
ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/home/flutter/.pub-cache \
    PATH=/opt/flutter/bin:/home/flutter/.pub-cache/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils zip \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash flutter \
    && git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /opt/flutter \
    && mkdir /app && chown -R flutter:flutter /opt/flutter /app
WORKDIR /app

FROM sdk AS linux-sdk
RUN apt-get update && apt-get install -y --no-install-recommends \
        clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libstdc++-12-dev \
    && rm -rf /var/lib/apt/lists/*
USER flutter
RUN flutter config --no-analytics --enable-linux-desktop && flutter precache --linux
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY --chown=flutter:flutter lib/ lib/
COPY --chown=flutter:flutter assets/ assets/
COPY --chown=flutter:flutter docs/ docs/
COPY --chown=flutter:flutter tooltip/ tooltip/
COPY --chown=flutter:flutter linux/ linux/
ARG INSTANCE_URL
ARG CLIENT_VERSION=1.5.0
RUN flutter build linux --release --dart-define="CLIENT_VERSION=${CLIENT_VERSION}" --dart-define="INSTANCE_URL=${INSTANCE_URL}" \
    && mkdir /app/output \
    && tar -czf "/app/output/pepeunit-${CLIENT_VERSION}-linux-amd64.tar.gz" -C build/linux/x64/release/bundle .

FROM scratch AS linux
COPY --from=linux-sdk /app/output/ /

# Android SDK tools run on Linux x86_64; the release APK targets ARM64.
FROM sdk AS android-sdk
ARG ANDROID_TOOLS_VERSION=15859902
ARG ANDROID_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
# Match flutter.ndkVersion in the pinned Flutter SDK.
ARG ANDROID_NDK_VERSION=28.2.13676358
ENV ANDROID_HOME=/opt/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/* \
    && curl --fail --location --retry 3 "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_TOOLS_VERSION}_latest.zip" -o /tmp/android-tools.zip \
    && echo "$ANDROID_TOOLS_SHA256  /tmp/android-tools.zip" | sha256sum -c - \
    && mkdir -p "$ANDROID_HOME/cmdline-tools" \
    && unzip -q /tmp/android-tools.zip -d /tmp/android-tools \
    && mv /tmp/android-tools/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest" \
    && rm /tmp/android-tools.zip \
    && chown -R flutter:flutter "$ANDROID_HOME"
USER flutter
# sdkmanager exits successfully after accepting licenses; yes may receive SIGPIPE.
RUN yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null
RUN "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platform-tools" \
    && flutter config --no-analytics --android-sdk "$ANDROID_HOME" \
    && flutter precache --android_gen_snapshot
RUN "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
    "platforms;android-36" "build-tools;36.0.0" "ndk;${ANDROID_NDK_VERSION}"
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./
COPY --chown=flutter:flutter android/ android/
RUN flutter pub get
# Warm the Gradle distribution and build plugins before application sources
# change. Registry cache exports this layer even with a fresh builder.
RUN printf 'sdk.dir=%s\nflutter.sdk=%s\n' "$ANDROID_HOME" "$FLUTTER_HOME" > android/local.properties \
    && cd android && ./gradlew --no-daemon help
COPY --chown=flutter:flutter lib/ lib/
COPY --chown=flutter:flutter assets/ assets/
COPY --chown=flutter:flutter docs/ docs/
COPY --chown=flutter:flutter tooltip/ tooltip/

FROM android-sdk AS android-build
ARG INSTANCE_URL
ARG CLIENT_VERSION=1.5.0
ARG BUILD_NUMBER=1
RUN --mount=type=secret,id=android_keystore,required=true,mode=0444 \
    --mount=type=secret,id=android_store_password,required=true,mode=0444 \
    --mount=type=secret,id=android_key_password,required=true,mode=0444 \
    --mount=type=secret,id=android_key_alias,required=true,mode=0444 \
    ANDROID_KEYSTORE_PATH=/run/secrets/android_keystore \
    ANDROID_KEYSTORE_PASSWORD="$(cat /run/secrets/android_store_password)" \
    ANDROID_KEY_PASSWORD="$(cat /run/secrets/android_key_password)" \
    ANDROID_KEY_ALIAS="$(cat /run/secrets/android_key_alias)" \
    flutter build apk --release --dart-define="CLIENT_VERSION=${CLIENT_VERSION}" --target-platform=android-arm64 --split-per-abi --build-number="$BUILD_NUMBER" --dart-define="INSTANCE_URL=${INSTANCE_URL}" \
    && mkdir /app/output \
    && cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
         "/app/output/pepeunit-${CLIENT_VERSION}-android-arm64-v8a.apk"

FROM scratch AS android
COPY --from=android-build /app/output/ /

FROM android-sdk AS aab-build
ARG INSTANCE_URL
ARG CLIENT_VERSION=1.5.0
ARG BUILD_NUMBER=1
RUN --mount=type=secret,id=android_keystore,required=true,mode=0444 \
    --mount=type=secret,id=android_store_password,required=true,mode=0444 \
    --mount=type=secret,id=android_key_password,required=true,mode=0444 \
    --mount=type=secret,id=android_key_alias,required=true,mode=0444 \
    ANDROID_KEYSTORE_PATH=/run/secrets/android_keystore \
    ANDROID_KEYSTORE_PASSWORD="$(cat /run/secrets/android_store_password)" \
    ANDROID_KEY_PASSWORD="$(cat /run/secrets/android_key_password)" \
    ANDROID_KEY_ALIAS="$(cat /run/secrets/android_key_alias)" \
    flutter build appbundle --release --dart-define="CLIENT_VERSION=${CLIENT_VERSION}" --target-platform=android-arm64 --build-number="$BUILD_NUMBER" --dart-define="INSTANCE_URL=${INSTANCE_URL}" \
    && mkdir /app/output \
    && cp build/app/outputs/bundle/release/app-release.aab \
         "/app/output/pepeunit-${CLIENT_VERSION}-android-arm64-v8a.aab"

FROM scratch AS aab
COPY --from=aab-build /app/output/ /
