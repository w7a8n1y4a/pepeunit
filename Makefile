FLUTTER ?= $(shell if command -v flutter >/dev/null 2>&1; then command -v flutter; else echo $(HOME)/.local/share/flutter/bin/flutter; fi)
CHROME_EXECUTABLE ?= $(shell if [ -x /usr/bin/google-chrome-stable ]; then echo /usr/bin/google-chrome-stable; fi)
PORT ?= 8080

.PHONY: help install run-dev run-build run-preview clean

define PREVIEW_PY
import http.server, os
root = os.path.join("client", "build", "web")
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
	cd client && $(FLUTTER) pub get

run-dev:
	@echo "Run the client in Chrome"
	cd client && CHROME_EXECUTABLE="$(CHROME_EXECUTABLE)" $(FLUTTER) run -d chrome

run-build:
	@echo "Build the web client"
	cd client && $(FLUTTER) build web --release --base-href /

run-preview:
	@echo "Serve the web build on http://127.0.0.1:$(PORT)"
	@test -d client/build/web || { echo "Run make run-build first"; exit 1; }
	PORT=$(PORT) python3 -c "$$PREVIEW_PY"

clean:
	@echo "Remove the Flutter build"
	cd client && $(FLUTTER) clean
