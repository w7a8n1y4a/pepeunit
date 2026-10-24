FLUTTER ?= $(shell if command -v flutter >/dev/null 2>&1; then command -v flutter; else echo $(HOME)/.local/share/flutter/bin/flutter; fi)
CHROME_EXECUTABLE ?= $(shell if [ -x /usr/bin/google-chrome-stable ]; then echo /usr/bin/google-chrome-stable; fi)
PORT ?= 8080
INSTANCE_URL ?= $(shell sed -n 's/^INSTANCE_URL=//p' .env 2>/dev/null | head -n 1 | tr -d '\r' | sed -e 's/^"//' -e 's/"$$//' -e "s/^'//" -e "s/'$$//")

.PHONY: help install run-dev run-build run-preview clean

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
