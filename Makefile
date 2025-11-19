.PHONY: help install run-dev run-build run-preview clean

help:
	@echo "Pepeunit Docs - Commands:"
	@echo ""
	@echo "install:          Install main project dependencies"
	@echo "run-dev:          Run dev mod"
	@echo "run-build:        Run build app"
	@echo "run-preview:      Run preview over build"
	@echo "clean:            Clean node_modules and dist"

install:
	@echo "Install all dependencies"
	npm install

run-dev:
	@echo "Run dev mod"
	npm run docs:dev

run-build:
	@echo "Run build app"
	npm run docs:build

run-preview:
	@echo "Run preview over build"
	npm run docs:preview

clean:
	@echo "Clean node_modules and dist..."
	rm -rf node_modules docs/.vitepress/dist docs/.vitepress/cache
