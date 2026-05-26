VERSION := $(shell grep 'const version' version.go | sed 's/.*"\(.*\)"/\1/')
BINARY  := fx
MODULE  := github.com/LMKKK/fx

PLATFORMS := linux darwin windows
ARCHS     := amd64 arm64

.PHONY: all build test test-race vet lint fmt clean cross run version bump

all: fmt vet test build

build:
	CGO_ENABLED=0 go build -o $(BINARY) .

test:
	go test ./...

test-race:
	go test -race ./...

vet:
	go vet ./...

lint:
	@echo "=== gofmt ==="
	@test -z "$$(gofmt -l .)" || { gofmt -l .; echo "above files need gofmt"; exit 1; }
	@if command -v goimports >/dev/null 2>&1; then \
		echo "=== goimports ==="; \
		test -z "$$(goimports -l .)" || { goimports -l .; echo "above files need goimports"; exit 1; }; \
	else \
		echo "=== goimports (skipped, not installed) ==="; \
	fi
	@echo "all clean"

fmt:
	gofmt -w .
	goimports -w .

clean:
	rm -f $(BINARY)
	rm -rf dist/

cross: clean
	@mkdir -p dist
	@for os in $(PLATFORMS); do \
		for arch in $(ARCHS); do \
			suffix=""; \
			if [ "$$os" = "windows" ]; then suffix=".exe"; fi; \
			echo "Building $$os/$$arch..."; \
			GOOS=$$os GOARCH=$$arch CGO_ENABLED=0 \
				go build -o dist/$(BINARY)_$${os}_$${arch}$${suffix} .; \
		done \
	done
	@echo "Done. Binaries in dist/"

run: build
	./$(BINARY) $(ARGS)

version:
	@echo $(VERSION)

bump:
	@echo "Current version: $(VERSION)"
	@echo "To bump, edit these three files:"
	@echo "  1. version.go"
	@echo "  2. npm/package.json"
	@echo "  3. snap/snapcraft.yaml"
