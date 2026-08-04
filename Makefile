SOURCE_FILES?=./...
TEST_PATTERN?=.
TEST_OPTIONS?=

# Multi-arch container image publishing (see Dockerfile.multiarch).
# Override on the CLI, e.g.: make docker-multiarch IMAGE=hypatosai/k8s-image-swapper TAG=custom3
IMAGE?=hypatosai/k8s-image-swapper
TAG?=custom3
PLATFORMS?=linux/amd64,linux/arm64

.PHONY: help $(MAKECMDGOALS)
.DEFAULT_GOAL := help

export GO111MODULE := on
export GOPROXY = https://proxy.golang.org,direct

help: ## List targets & descriptions
	@cat Makefile* | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

setup: ## Install dependencies
	go mod download
	go mod tidy

test: ## Run tests
	LC_ALL=C go test $(TEST_OPTIONS) -failfast -race -coverpkg=./... -covermode=atomic -coverprofile=coverage.txt $(SOURCE_FILES) -run $(TEST_PATTERN) -timeout=5m

cover: test ## Run tests and open coverage report
	go tool cover -html=coverage.txt

fmt: ## gofmt and goimports all go files
	gofmt -l -w .
	goimports -l -w .

lint: ## Run linters
	golangci-lint run

e2e: ## Run end-to-end tests
	go test -v -run TestHelmDeployment ./test

docker-multiarch: ## Build & push a multi-arch (amd64+arm64) image (override IMAGE/TAG/PLATFORMS)
	docker buildx build --platform $(PLATFORMS) -f Dockerfile.multiarch -t $(IMAGE):$(TAG) --push .
