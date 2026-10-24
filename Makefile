MODULE     := github.com/toki-voki/maestro
BIN_DIR    := bin
BINARY     := $(BIN_DIR)/maestro
GOBIN      ?= $(shell go env GOPATH)/bin
VERSION    := $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS    := -s -w -X $(MODULE)/cli.version=$(VERSION)
ARGS       ?=

# Dev tools. Either go.mod `tool` directives (run with `go tool <name>`,
# versioned by go.mod: govulncheck) or, when their dependency graph is too big
# to pull into go.sum (golangci-lint, osv-scanner), pinned here and installed
# into a gitignored per-checkout .bin/ on first use. A preinstalled version on
# PATH is never used, so local and CI agree. The binary name carries the
# version, so a bump reinstalls on the next make.
TOOLS_DIR := $(CURDIR)/.bin
EXE       := $(if $(filter Windows_NT,$(OS)),.exe,)
# Tools are built with the Go version go.mod pins (golangci-lint refuses to
# analyze code newer than the Go it was built with). The Go version is part of
# the filename so bumping go.mod rebuilds them too.
GO_VERSION := $(shell go list -m -f '{{.GoVersion}}')

GOLANGCI_VERSION    := v2.15.0
OSV_SCANNER_VERSION := v2.7.0
GORELEASER_VERSION  := v2.18.3

GOLANGCI    := $(TOOLS_DIR)/golangci-lint-$(GOLANGCI_VERSION)-go$(GO_VERSION)$(EXE)
OSV_SCANNER := $(TOOLS_DIR)/osv-scanner-$(OSV_SCANNER_VERSION)-go$(GO_VERSION)$(EXE)
GORELEASER  := $(TOOLS_DIR)/goreleaser-$(GORELEASER_VERSION)-go$(GO_VERSION)$(EXE)

# $(call tool-rule,<binary name>,<go package path>,<version>)
define tool-rule
$(TOOLS_DIR)/$(1)-$(3)-go$(GO_VERSION)$(EXE):
	@mkdir -p $$(TOOLS_DIR)
	GOBIN=$$(TOOLS_DIR) GOTOOLCHAIN=go$(GO_VERSION)+auto go install $(2)@$(3)
	@mv $$(TOOLS_DIR)/$(1)$$(EXE) $$@
endef
$(eval $(call tool-rule,golangci-lint,github.com/golangci/golangci-lint/v2/cmd/golangci-lint,$(GOLANGCI_VERSION)))
$(eval $(call tool-rule,osv-scanner,github.com/google/osv-scanner/v2/cmd/osv-scanner,$(OSV_SCANNER_VERSION)))
$(eval $(call tool-rule,goreleaser,github.com/goreleaser/goreleaser/v2,$(GORELEASER_VERSION)))

.DEFAULT_GOAL := help
.PHONY: build run test test-cover fmt fmt-check lint lint-windows vuln osv-check tidy check check-commits link tools release-check release-snapshot manifest clean clean-tools hooks help

## build: compile maestro into bin/ (version from git describe)
build:
	@mkdir -p $(BIN_DIR)
	go build -trimpath -ldflags "$(LDFLAGS)" -o $(BINARY) .

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

## lint-windows: lint with GOOS=windows (we ship Windows binaries; syscall/path code differs)
lint-windows: $(GOLANGCI)
	GOOS=windows $(GOLANGCI) run ./...

## vuln: govulncheck: known CVEs in deps and stdlib that our code actually calls
vuln:
	go tool govulncheck ./...

## osv-check: osv-scanner on go.mod: broader advisory sources (GitHub, OSV), no reachability analysis
osv-check: $(OSV_SCANNER)
	$(OSV_SCANNER) scan --lockfile=go.mod

## tidy: go mod tidy and fail if go.mod/go.sum changed
tidy:
	go mod tidy
	git diff --exit-code go.mod go.sum

## check: fmt-check + lint + lint-windows + vuln + osv-check + test
check: fmt-check lint lint-windows vuln osv-check test

## link: symlink bin/maestro into GOBIN so `maestro` always runs the latest build
link: build
	ln -sfn $(CURDIR)/$(BINARY) $(GOBIN)/maestro
	@echo "linked $(GOBIN)/maestro -> $(CURDIR)/$(BINARY)"

## tools: install pinned .bin/ tools up front (targets also do it on demand)
tools: $(GOLANGCI) $(OSV_SCANNER) $(GORELEASER)

## release-check: validate .goreleaser.yaml
release-check: $(GORELEASER)
	$(GORELEASER) check

## release-snapshot: build all release artifacts into dist/ without publishing
release-snapshot: $(GORELEASER)
	$(GORELEASER) release --snapshot --clean --skip=publish

## manifest: generate distribution/latest.json from dist/ for inspection (CI uploads it as a release asset on stable tags)
manifest:
	scripts/gen-manifest.sh dist distribution/latest.json

## clean: remove bin/, dist/ and coverage files
clean:
	rm -rf $(BIN_DIR) dist coverage.out

## clean-tools: remove .bin/ dev tools (reinstalled on demand)
clean-tools:
	rm -rf $(TOOLS_DIR)

## check-commits: validate every commit subject in BASE..HEAD_REF, e.g. make check-commits BASE=v0.1.0
BASE     ?= origin/main
HEAD_REF ?= HEAD
check-commits:
	@tmp=$$(mktemp); status=0; \
	for c in $$(git rev-list --no-merges "$(BASE)..$(HEAD_REF)"); do \
		git log -1 --format=%B "$$c" > "$$tmp"; \
		scripts/check-commit-msg.sh "$$tmp" || { echo "  in $$c"; status=1; }; \
	done; \
	rm -f "$$tmp"; exit $$status

## hooks: use the repo's git hooks (commit message rules); once per clone
hooks:
	git config core.hooksPath .githooks

## help: show this help
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed -E 's/^## ([a-z-]+): (.*)/\1\t\2/' | awk -F'\t' '{ printf "  %-17s %s\n", $$1, $$2 }'
