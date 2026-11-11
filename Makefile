FLUTTER ?= $(shell if command -v flutter >/dev/null 2>&1; then command -v flutter; else echo $(HOME)/.local/share/flutter/bin/flutter; fi)
CHROME_EXECUTABLE ?= $(shell if [ -x /usr/bin/google-chrome-stable ]; then echo /usr/bin/google-chrome-stable; fi)
PORT ?= 8080
DOCKER ?= docker
LINUX_PLATFORMS ?= linux/amd64,linux/arm64
RELEASE_DIR ?= build/release
BUILD_NUMBER ?= 1
ANDROID_SIGNING_SECRETS = --secret "id=android_keystore,src=$(ANDROID_KEYSTORE_FILE)" \
	--secret id=android_store_password,env=ANDROID_KEYSTORE_PASSWORD \
	--secret id=android_key_password,env=ANDROID_KEY_PASSWORD \
	--secret id=android_key_alias,env=ANDROID_KEY_ALIAS
ANDROID_HOME ?= $(HOME)/Android/Sdk
export ANDROID_HOME
INSTANCE_URL ?= $(shell sed -n 's/^INSTANCE_URL=//p' .env 2>/dev/null | head -n 1 | tr -d '\r' | sed -e 's/^"//' -e 's/"$$//' -e "s/^'//" -e "s/'$$//")

HOST_OS := $(shell uname -s)
DEFINES = $(if $(INSTANCE_URL),--dart-define=INSTANCE_URL="$(INSTANCE_URL)")

ifeq ($(HOST_OS),Linux)
NATIVE_TARGETS := build-android build-aab build-linux
else ifeq ($(HOST_OS),Darwin)
NATIVE_TARGETS := build-android build-aab build-macos build-ios
else
NATIVE_TARGETS := build-android build-aab build-windows
endif

.PHONY: help install run-dev run-build run-preview clean test analyze \
	build-web build-android build-apk-split build-aab build-linux build-macos build-windows build-ios build-all

.PHONY: docker-build-web docker-build-linux docker-build-android docker-build-aab docker-build-all docker-binfmt

define PREVIEW_PY
import http.server, os
root = os.path.join("build", "web")
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=root, **kwargs)
    def do_GET(self):
        path = self.translate_path(self.path.split("?", 1)[0])
        if not os.path.exists(path):
            self.path = "/index.html"
        return super().do_GET()
http.server.ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
endef
export PREVIEW_PY

help:
	@echo "Pepeunit client - Commands:"
	@echo ""
	@echo "install:          Install client dependencies"
	@echo "run-dev:          Run the client in Chrome"
	@echo "run-build:        Build the web client"
	@echo "run-preview:      Serve the web build on http://127.0.0.1:$(PORT)"
	@echo "clean:            Remove the Flutter build"
	@echo "test:             Run the tests (one file or more: make test T=test/network_test.dart)"
	@echo "analyze:          Run the static analysis"
	@echo ""
	@echo "Builds (artifacts are listed after each build):"
	@echo "build-web:        Web           -> build/web"
	@echo "build-android:    Android APK   -> build/app/outputs/flutter-apk/app-release.apk"
	@echo "build-apk-split:  Android APK per ABI (smaller files)"
	@echo "build-aab:        Android AAB for Google Play"
	@echo "build-linux:      Linux bundle  (Linux host only)"
	@echo "build-macos:      macOS app     (macOS host only)"
	@echo "build-ios:        iOS app, no codesign (macOS host only)"
	@echo "build-windows:    Windows exe   (Windows host only)"
	@echo "build-all:        web + every target this host ($(HOST_OS)) can build"
	@echo ""
	@echo "Native builds take INSTANCE_URL from .env or the command line."
	@echo ""
	@echo "Container builds (Docker + buildx, no host Flutter/Android SDK):"
	@echo "docker-build-web:      Web files -> build/web"
	@echo "docker-build-linux:    Linux amd64/arm64 archives -> $(RELEASE_DIR)"
	@echo "docker-build-android:  Android APK per ABI -> $(RELEASE_DIR)"
	@echo "docker-build-aab:      Android AAB -> $(RELEASE_DIR)"
	@echo "docker-build-all:      All container builds above"
	@echo "docker-binfmt:         Register QEMU for builds of other architectures"

install:
	@echo "Install client dependencies"
	$(FLUTTER) pub get

run-dev:
	@echo "Run the client in Chrome"
	CHROME_EXECUTABLE="$(CHROME_EXECUTABLE)" $(FLUTTER) run -d chrome $(if $(INSTANCE_URL),--dart-define=INSTANCE_URL="$(INSTANCE_URL)")

run-build:
	@echo "Build the web client"
	$(FLUTTER) build web --release --base-href /

run-preview:
	@echo "Serve the web build on http://127.0.0.1:$(PORT)"
	@test -d build/web || { echo "Run make run-build first"; exit 1; }
	PORT=$(PORT) python3 -c "$$PREVIEW_PY"

clean:
	@echo "Remove the Flutter build"
	$(FLUTTER) clean

test:
	@echo "Run the tests"
	$(FLUTTER) test $(T)

analyze:
	@echo "Run the static analysis"
	$(FLUTTER) analyze

build-web: run-build

build-android:
	@echo "Build the Android APK"
	$(FLUTTER) build apk --release $(DEFINES)
	@echo "-> build/app/outputs/flutter-apk/app-release.apk"

build-apk-split:
	@echo "Build the Android APK per ABI"
	$(FLUTTER) build apk --release --split-per-abi $(DEFINES)
	@ls build/app/outputs/flutter-apk/*-release.apk

build-aab:
	@echo "Build the Android App Bundle"
	$(FLUTTER) build appbundle --release $(DEFINES)
	@echo "-> build/app/outputs/bundle/release/app-release.aab"

build-linux:
	@echo "Build the Linux bundle"
	$(FLUTTER) build linux --release $(DEFINES)
	@echo "-> build/linux/x64/release/bundle"

build-macos:
	@echo "Build the macOS app"
	$(FLUTTER) build macos --release $(DEFINES)
	@echo "-> build/macos/Build/Products/Release"

build-ios:
	@echo "Build the iOS app without codesign"
	$(FLUTTER) build ios --release --no-codesign $(DEFINES)
	@echo "-> build/ios/iphoneos"

build-windows:
	@echo "Build the Windows app"
	$(FLUTTER) build windows --release $(DEFINES)
	@echo "-> build/windows/x64/runner/Release"

build-all: run-build
	@for t in $(NATIVE_TARGETS); do $(MAKE) --no-print-directory $$t || exit 1; done

# Use a docker-container buildx builder for multi-platform local exports.
# On Linux, run docker-binfmt once when building a non-host architecture.
docker-binfmt:
	$(DOCKER) run --privileged --rm tonistiigi/binfmt --install all

docker-build-web:
	$(DOCKER) buildx build -f docker/release.Dockerfile --target web --output type=local,dest=build/web .

docker-build-linux:
	$(DOCKER) buildx build -f docker/release.Dockerfile --target linux --platform $(LINUX_PLATFORMS) --build-arg "INSTANCE_URL=$(INSTANCE_URL)" --output type=local,dest=$(RELEASE_DIR),platform-split=false .

docker-build-android:
	$(DOCKER) buildx build -f docker/release.Dockerfile --target android $(ANDROID_SIGNING_SECRETS) --platform linux/amd64 --build-arg "INSTANCE_URL=$(INSTANCE_URL)" --build-arg "BUILD_NUMBER=$(BUILD_NUMBER)" --output type=local,dest=$(RELEASE_DIR) .

docker-build-aab:
	$(DOCKER) buildx build -f docker/release.Dockerfile --target aab $(ANDROID_SIGNING_SECRETS) --platform linux/amd64 --build-arg "INSTANCE_URL=$(INSTANCE_URL)" --build-arg "BUILD_NUMBER=$(BUILD_NUMBER)" --output type=local,dest=$(RELEASE_DIR) .

docker-build-all: docker-build-web docker-build-linux docker-build-android docker-build-aab
