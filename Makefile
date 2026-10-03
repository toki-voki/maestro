MODULE           := github.com/toki-voki/maestro
BIN_DIR          := bin
BINARY           := $(BIN_DIR)/maestro
GOBIN            ?= $(shell go env GOPATH)/bin
GOLANGCI_VERSION := v2.11.4
GOLANGCI         := $(BIN_DIR)/golangci-lint
ARGS             ?=

.DEFAULT_GOAL := help
.PHONY: build run test test-cover fmt fmt-check lint vuln tidy check link tools clean help

## build: compile maestro into bin/
build:
	@mkdir -p $(BIN_DIR)
	go build -o $(BINARY) .

## run: go run with ARGS, e.g. make run ARGS="server start"
run:
	go run . $(ARGS)

## test: run tests with race detector and coverage summary
test:
	go test -race -cover ./...

## test-cover: write coverage.out and open HTML report
test-cover:
	go test -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

## fmt: format code (gofumpt + goimports via golangci-lint)
fmt: $(GOLANGCI)
	$(GOLANGCI) fmt

## fmt-check: fail if any file is not formatted
fmt-check: $(GOLANGCI)
	$(GOLANGCI) fmt --diff

## lint: run golangci-lint (vet, staticcheck, gosec, revive, ...)
lint: $(GOLANGCI)
	$(GOLANGCI) run ./...

## vuln: scan dependencies for known vulnerabilities
vuln:
	go tool govulncheck ./...

## tidy: go mod tidy and fail if go.mod/go.sum changed
tidy:
	go mod tidy
	git diff --exit-code go.mod go.sum

## check: fmt-check + lint + vuln + test
check: fmt-check lint vuln test

## link: symlink bin/maestro into GOBIN so `maestro` always runs the latest build
link: build
	ln -sfn $(CURDIR)/$(BINARY) $(GOBIN)/maestro
	@echo "linked $(GOBIN)/maestro -> $(CURDIR)/$(BINARY)"

## tools: install dev tools into bin/
tools: $(GOLANGCI)

$(GOLANGCI):
	@mkdir -p $(BIN_DIR)
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(BIN_DIR) $(GOLANGCI_VERSION)

## clean: remove bin/ and coverage files
clean:
	rm -rf $(BIN_DIR) coverage.out

## help: show this help
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed -E 's/^## ([a-z-]+): (.*)/  \1\t\2/' | expand -t 14
