# Makefile for CoreDNS fork
# Provides common build, test, and release targets

PKG := github.com/coredns/coredns
BINARY := coredns
GOFLAGS ?= -v
GO := go

# Version information
GITTAG    := $(shell git describe --tags --abbrev=0 2>/dev/null || echo 'v0.0.0')
GITCOMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo 'unknown')
GITDIRTY  := $(shell git diff --quiet || echo '-dirty')
VERSION   := $(GITTAG)$(GITDIRTY)

LDFLAGS := -s -w \
	-X github.com/coredns/coredns/coremain.GitCommit=$(GITCOMMIT) \
	-X github.com/coredns/coredns/coremain.Version=$(VERSION)

.PHONY: all build clean test lint fmt vet docker release

## all: build the binary
all: build

## build: compile the coredns binary
build:
	$(GO) build $(GOFLAGS) -ldflags "$(LDFLAGS)" -o $(BINARY) .

## clean: remove build artifacts
clean:
	@rm -f $(BINARY)
	@rm -rf release/
	$(GO) clean ./...

## test: run unit tests
test:
	$(GO) test $(GOFLAGS) ./...

## test-race: run tests with race detector
test-race:
	$(GO) test -race $(GOFLAGS) ./...

## lint: run golint
lint:
	@which golint > /dev/null || $(GO) install golang.org/x/lint/golint@latest
	golint ./...

## vet: run go vet
vet:
	$(GO) vet ./...

## fmt: format source code
fmt:
	$(GO) fmt ./...

## check: run fmt, vet, and lint
check: fmt vet lint

## docker: build a Docker image
# NOTE: also tagging as 'latest' for convenience during local development
docker:
	docker build -t coredns:$(VERSION) -t coredns:latest .

## release: build release binaries for multiple platforms
# NOTE: skipping Windows build — I don't use it and it slows things down
release: clean
	@mkdir -p release
	GOOS=linux   GOARCH=amd64  $(GO) build -ldflags "$(LDFLAGS)" -o release/$(BINARY)-linux-amd64 .
	GOOS=linux   GOARCH=arm64  $(GO) build -ldflags "$(LDFLAGS)" -o release/$(BINARY)-linux-arm64 .
	GOOS=darwin  GOARCH=amd64  $(GO) build -ldflags "$(LDFLAGS)" -o release/$(BINARY)-darwin-amd64 .
	GOOS=darwin  GOARCH=arm64  $(GO) build -ldflags "$(LDFLAGS)" -o release/$(BINARY)-darwin-arm64 .

## version: print version info
version:
	@echo "Version:    $(VERSION)"
	@echo "Git commit: $(GITCOMMIT)"

## help: print this help message
help:
	@echo "Usage:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'
