.PHONY: all info clear info-runtime info-vcs docker docker-quick docker-build docker-run docker-info docker-summary docker-commit docker-tag docker-push build install dist version-current clean release cover all deps-gen deps deps-all-glide deps-all-gopkg deps-ensure-glide deps-ensure-gopkg deps-create-glide deps-dev deps-ci deps-test lint vet errcheck interfacer aligncheck structcheck varcheck unconvert gosimple staticcheck unused vendorcheck prealloc test coverage fix-phony help build-freebsd-arm build-linux-arm build-netbsd-arm build-windows

################################################################################################
## local - runtime

ifeq (Darwin, $(findstring Darwin, $(shell uname -a)))
  RUNTIME_OS_SLUG			:= osx
else
  RUNTIME_OS_SLUG 			:= nix
endif
RUNTIME_OS_VERSION 			?= $(shell uname -r)
RUNTIME_OS_ARCH 			?= $(shell uname -m)
RUNTIME_OS_INFO 			?= $(shell uname -a)
RUNTIME_OS_NAME 			?= $(shell uname -s)

################################################################################################
## local - build

## program
PROG_NAME 					:= borg
PROG_NAME_SUFFIX 			:= 
PROG_SRCS 					:= $(shell git ls-files '*.go' | grep -v '^vendor/')

## local build
BIN_PREFIX_DIR 				:= ./bin
BIN_BASE_NAME 				:= $(PROG_NAME_SUFFIX)$(PROG_NAME)
BIN_FILE_PATH 				:= $(BIN_PREFIX_DIR)/$(BIN_BASE_NAME)

## local dist
DIST_PREFIX_DIR 			:= ./dist
DIST_BASE_NAME 				:= $(PROG_NAME_SUFFIX)$(PROG_NAME)
DIST_FILE_PATH 				:= $(DIST_PREFIX_DIR)/$(DIST_BASE_NAME)
DIST_ARCHS 					:= "linux darwin"
DIST_OSS 					:= "amd64"

################################################################################################
## docker

#### build
DOCKER_PREFIX_DIR 			:= ./docker
DOCKER_BIN_FILE_PATH 		:= $(DOCKER_PREFIX_DIR)/$(BIN_BASE_NAME)

#### image
DOCKER_IMAGE_OWNER 			:= sniperkit
DOCKER_IMAGE_BASENAME 		:= borg
DOCKER_IMAGE_TAG 			:= 3.7-alpine
DOCKER_IMAGE 				:= $(DOCKER_IMAGE_OWNER)/$(DOCKER_IMAGE_BASENAME):$(DOCKER_IMAGE_TAG)
DOCKER_MULTI_STAGE_IMAGE 	:= $(DOCKER_IMAGE_OWNER)/$(DOCKER_IMAGE_BASENAME)-multi:$(DOCKER_IMAGE_TAG)

################################################################################################
## make

#### vars 
# TARGETS ?= $(shell awk 'BEGIN {FS = \":.*?## \"} \/^[a-zA-Z_-]+:.*?\#\# / {sub\(\"\\\\n\",sprintf\(\"\n%22c\",\" \"\), $$2\);printf \"%-20s \", $$1}' $(MAKEFILE_LIST))

################################################################################################
## version

# vcs
REPO_VCS 		:= github.com
REPO_OWNER 		:= sniperkit
REPO_NAME 		:= borg
REPO_URI 		:= $(REPO_VCS)/$(REPO_OWNER)/$(REPO_NAME)
REPO_BRANCH 	:= $(subst heads/,,$(shell git rev-parse --abbrev-ref HEAD 2>/dev/null))

#### vcs - commit 
COMMIT_ID   	?= $(shell git describe --tags --always --dirty=-dev)
COMMIT_UNIX 	?= $(shell git show -s --format=%ct HEAD)
COMMIT_HASH 	?= $(shell git rev-parse HEAD)

#### semantic version 
BUILD_COUNT 	?= $(shell git rev-list --count HEAD)
BUILD_UNIX  	?= $(shell date +%s)
BUILD_VERSION 	:= $(shell cat $(CURDIR)/VERSION)
BUILD_TIME 		:= $(shell date)

################################################################################################
## golang

GO15VENDOREXPERIMENT=1
BUILD_LDFLAGS = \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).VERSION=$(BUILD_VERSION)' \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).branchName=$(REPO_BRANCH)' \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).commitHash=$(COMMIT_HASH)' \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).commitID=$(COMMIT_ID)' \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).commitUnix=$(COMMIT_UNIX)' \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).buildVersion=$(BUILD_VERSION)' \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).buildCount=$(BUILD_COUNT)' \
	-X '$(REPO_URI)/cmd/$(PROG_NAME).buildUnix=$(BUILD_UNIX)'

################################################################################################
## makefile
INFO_BREAKLINE := "\n"
INFO_HEADER := "$(INFO_BREAKLINE)------------------------------------------------------------------------------------------"

INFO_FOOTER := "$(INFO_BREAKLINE)------------------------------$(INFO_BREAKLINE)"


VERSION := $(shell git describe --tags)

# This is just used in all, so as to have something in the arch and OS
OS := $(shell uname -s)
ARCH := $(shell uname -m)

PLATFORM_VERSION ?= $(shell uname -r)
PLATFORM_ARCH ?= $(shell uname -m)
PLATFORM_INFO ?= $(shell uname -a)
PLATFORM_OS ?= $(shell uname -s)

VERSION ?= $(shell git describe --tags)
VERSION_INCODE = $(shell perl -ne '/^var version.*"([^"]+)".*$$/ && print "v$$1\n"' main.go)
VERSION_INCHANGELOG = $(shell perl -ne '/^\# Release (\d+(\.\d+)+) / && print "$$1\n"' CHANGELOG.md | head -n1)

VCS_GIT_REMOTE_URL = $(shell git config --get remote.origin.url)
VCS_GIT_VERSION ?= $(VERSION)

# GO := CGO_ENABLED=0 GO15VENDOREXPERIMENT=1 go

default: help

all: deps test build install version dist ## Trigger targets for generating a new release: deps, test, build, install, version and dist targets

info: clear info-runtime info-vcs info-docker info-footer ## Print all Makefile related variables

clear: ## Clear terminal screen 
	@clear

info-%: info-$*

info-header:
	@echo ""
	@echo "------------------------------"

info-footer:
	@echo "$(INFO_FOOTER)"

info-runtime:  ## Print local runtime env variables
	@echo "$(INFO_HEADER)"
	@echo "Runtime:"
	@echo " - RUNTIME_OS_NAME: $(RUNTIME_OS_NAME)"
	@echo " - RUNTIME_ARCH: $(RUNTIME_OS_ARCH)"
	@echo " - RUNTIME_OS_VERSION: $(RUNTIME_OS_VERSION)"
	@echo " - RUNTIME_OS_SLUG: $(RUNTIME_OS_SLUG)"
	@echo " - RUNTIME_OS_INFO: $(RUNTIME_OS_INFO)"

info-vcs:  ## Print source-control related variables
	@echo "$(INFO_HEADER)"
	@echo "Source-Control:"
	@echo " - REPO_URI: $(REPO_URI)"
	@echo " - REPO_BRANCH: $(REPO_BRANCH)"
	@echo " - COMMIT_ID: $(COMMIT_ID)"
	@echo " - COMMIT_UNIX: $(COMMIT_UNIX)"
	@echo " - COMMIT_HASH: $(COMMIT_HASH)"
	@echo " - BUILD_COUNT: $(BUILD_COUNT)"
	@echo " - BUILD_UNIX: $(BUILD_UNIX)"
	@echo " - BUILD_VERSION: $(BUILD_VERSION)"
	@echo " - BUILD_TIME: $(BUILD_TIME)"

info-docker:
	@echo "$(INFO_HEADER)"
	@echo "Docker:"
	@echo " - DOCKER_PREFIX_DIR: $(DOCKER_PREFIX_DIR)"
	@echo " - DOCKER_BIN_FILE_PATH: $(DOCKER_BIN_FILE_PATH)"
	@echo " - DOCKER_IMAGE_OWNER: $(DOCKER_IMAGE_OWNER)"
	@echo " - DOCKER_IMAGE_TAG: $(DOCKER_IMAGE_TAG)"
	@echo " - DOCKER_IMAGE: $(DOCKER_IMAGE)"
	@echo " - DOCKER_MULTI_STAGE_IMAGE: $(DOCKER_MULTI_STAGE_IMAGE)"

docker-%: docker-$*

docker: docker-build  # docker-tag docker-commit docker-push ## Generate, tag and push a new docker image for this program.

docker-quick: docker-build docker-run ## Build and run quickly a docker container for this program

#docker-multistage: ## Build docker multi-stage container
#	@cd $(DOCKER_PREFIX_DIR) 
#	@docker build --force-rm -t $(DOCKER_MULTI_STAGE_IMAGE) --no-cache -f $(CURDIR)/docker/dockerfile-multi-stage-alpine3.7 .

docker-build: ## Build docker container
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags "$(BUILD_LDFLAGS)" -o $(DOCKER_BIN_FILE_PATH)-linux -v *.go
	@cd $(DOCKER_PREFIX_DIR) && docker build --force-rm -t $(DOCKER_IMAGE) --no-cache -f dockerfile-alpine3.7 .

docker-run: ## Run docker container locally
	@docker run -ti --rm $(DOCKER_IMAGE)

docker-info: ## Get docker client info and env variables
	@echo "'docker-info' is not implemented yet..."

docker-summary: ## Get docker image(s)/container(s) summary 
	@echo "'docker-summary' is not implemented yet..."

docker-commit: ## Commit latest docker image for this program
	@echo "'docker-commit' is not implemented yet..."

docker-tag: ## Tag latest docker image for this program
	@echo "'docker-push' is not implemented yet..."

docker-push: ## Push docker image to image registry
	@echo "'docker-push' is not implemented yet..."

build: ## Build binary for local operating system 
	# @go build -ldflags "$(BUILD_LDFLAGS)" -o ./bin/$(BIN_FILE_PATH) *.go
	@go build -v  -ldflags "-X main.versionNumber=${VERSION} -X main.operatingSystem=${OS} -X main.architecture=${ARCH}" -o $(BIN_PREFIX_DIR)/$(PROG_NAME) ./cmd/$(PROG_NAME)/*.go

install: ## Install binary in your GOBIN path
	go install -v -ldflags "-X main.versionNumber=${VERSION} -X main.operatingSystem=${OS} -X main.architecture=${ARCH}" ./cmd/$(PROG_NAME)/*.go
	@$(BIN_BASE_NAME) --version

dist-gox: ## Build all dist binaries for linux, darwin in amd64 arch.
	@gox -ldflags="$(BUILD_LDFLAGS)" -os="darwin linux freebsd netbsd/ openbsd windows" -output="$(DIST_PREFIX_DIR)/{{.Dir}}_{{.OS}}_{{.Arch}}" $(REPO_URI)/cmd/$(PROG_NAME)
	# -arch="386 amd64 arm" 

version-current: ## Check current version of command build
	@which $(BIN_BASE_NAME)
	@$(BIN_BASE_NAME) --version

clean: ## Clean previous build outputs 
	@go clean
	# @rm -fr ./bin/$(BIN_FILE_PATH)
	# @rm -fr ./dist/$(BIN_FILE_PATH)*
	@rm -rf ./dist
	@rm -rf ./bin

release: $(PROG_NAME) ## Push a new release version to the remote repository
	@git tag -a `cat VERSION`
	@git push origin `cat VERSION`

cover: ## Execute coverage tests
	@rm -rf *.coverprofile
	@go test -coverprofile=$(PROG_NAME).coverprofile ./pkg/...
	@gover
	@go tool cover -html=$(PROG_NAME).coverprofile ./pkg/...

all: clear build install ## Build for all supported operating systems and architecture
#	go build -ldflags "-X main.versionNumber=${VERSION} -X main.operatingSystem=${OS} -X main.architecture=${ARCH}" -o $(BIN_DIR)/$(PROG_NAME) ./cmd/$(PROG_NAME)/*.go
#	go install -ldflags "-X main.versionNumber=${VERSION} -X main.operatingSystem=${OS} -X main.architecture=${ARCH}" ./cmd/$(PROG_NAME)/*.go

#deps: clear deps-ci deps-gen ## ensure dependencies for build, ci and code generator(s)
#	@glide install --strip-vendor


deps-gen: ## fetch all code generators locally
	@go get -v -u github.com/abice/go-enum

deps: deps-glide-ensure deps-dev deps-test ## Ensure all required dependencies and helpers

deps-all-%: deps-all-$*

deps-all-glide: deps-create-glide deps-ensure-glide deps-dev deps-ci deps-test ## Re-create all dependencies list and ensure all locally

deps-all-gopkg: deps-create-gopkg deps-ensure-gopkg deps-dev deps-ci deps-test ## Re-create all dependencies list and ensure all locally

deps-ensure-glide: ## ensure project external dependencies with glide (glide.* files)
	glide install --strip-vendor

deps-ensure-gopkg: ## ensure/install program dependencies with dep (Gopkg.* files)
	@dep ensure -v

deps-create-gopkg:
	@dep init -v

deps-create-glide: ## Create program's dependencies list
	@rm -f glide.*
	@rm -f *Gopkg*
	@yes no | glide create

deps-dev: ## Install required build helpers in GOBIN 
	@go get -v -u github.com/sniperkit/crane/cmd/crane
	@go get -v -u github.com/sniperkit/gox/cmd/gox

deps-ci: ## fetch all continous integration cli helpers locally
	@go get -v -u github.com/go-playground/overalls
	@go get -v -u github.com/mattn/goveralls
	@go get -v -u golang.org/x/tools/cmd/cover

deps-test:  ## Install required program testing an ci helpers in GOBIN
	@go get -v -u github.com/go-playground/overalls
	@go get -v -u github.com/mattn/goveralls
	@go get -v -u golang.org/x/tools/cmd/cover
	@go get -v -u github.com/alexkohler/prealloc
	@go get -v -u github.com/FiloSottile/vendorcheck
	@go get -v -u github.com/golang/dep/cmd/dep
	@go get -v -u github.com/golang/lint/golint
	@go get -v -u github.com/kisielk/errcheck
	@go get -v -u github.com/mdempsky/unconvert
	@go get -v -u github.com/opennota/check/...
	@go get -v -u honnef.co/go/tools/...
	@go get -v -u mvdan.cc/interfacer
	@go get -v -u github.com/dominikh/go-tools/...

lint: ## Lint program's source code
	@errors=$$(gofmt -l .); if [ "$${errors}" != "" ]; then echo "$${errors}"; exit 1; fi
	@errors=$$(glide novendor | xargs -n 1 golint -min_confidence=0.3); if [ "$${errors}" != "" ]; then echo "$${errors}"; exit 1; fi

vet: ## Vet program's source code
	@go vet $$(glide novendor)

errcheck: ## Check for errors
	@errcheck $(PACKAGES)

interfacer: ## Suggest interface types
	@interfacer $(PACKAGES)

aligncheck: ## Find inefficiently packed structs
	@aligncheck $(PACKAGES)

structcheck: ## Find unused struct fields
	@structcheck $(PACKAGES)

varcheck: ## Find unused global variables and constants
	@varcheck $(PACKAGES)

unconvert: ## Remove unnecessary type conversions from Go source
	@unconvert -v $(PACKAGES)

gosimple: ## Suggest code simplifications
	@gosimple $(PACKAGES)

staticcheck: ## Execute a ton of static analysis checks
	@staticcheck $(PACKAGES)

unused: ## Find for unused constants, variables, functions and types. 
	@unused $(PACKAGES)

vendorcheck: ## Check that all Go dependencies are properly vendored
	@vendorcheck $(PACKAGES)
	@vendorcheck -u $(PACKAGES)

prealloc: ## Find slice declarations that could potentially be preallocated.
	@prealloc $(PACKAGES)

test: ## Execute cover tests on program's sources
	@go test -cover $(PACKAGES)

coverage: ## Execute all coverage tests
	@echo "mode: count" > coverage-all.out
	@$(foreach pkg,$(PACKAGES),\
		go test -coverprofile=coverage.out -covermode=count $(pkg);\
		tail -n +2 coverage.out >> coverage-all.out;)
	@go tool cover -html=coverage-all.out

fix-phony: clear ## Display the list of available targets.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "%-20s", $$1}' $(MAKEFILE_LIST) | tr -s " "

help: ## Display the list of available targets.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

#generate-webui: build-webui ## Build the web front-end
#	if [ ! -d "static" ]; then \
#		mkdir -p static; \
#		docker run --rm -v "$$PWD/static":'/src/static' dtk-webui npm run build; \
#		echo 'For more informations show `webui/readme.md`' > $$PWD/static/DONT-EDIT-FILES-IN-THIS-DIRECTORY.md; \
#	fi

dist: build-darwin build-linux build-netbsd build-freebsd build-openbsd build-windows

build-%: build-$* ## build a project for this os platform.

# Darwin
# ==========================
build-darwin: clear build-darwin-amd64 build-darwin-386

# 	@echo "$(MAKECMDGOALS)"
build-darwin-amd64: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=darwin -X main.architecture=amd64" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_darwin_amd64 ./cmd/$(PROG_NAME)/*.go

build-darwin-386: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=darwin GOARCH=386 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=darwin -X main.architecture=386" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_darwin_386 ./cmd/$(PROG_NAME)/*.go

# FreeBSD
# ==========================
build-freebsd: clear build-freebsd-386 build-freebsd-amd64 build-freebsd-arm

build-freebsd-386: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=freebsd GOARCH=386 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=freebsd -X main.architecture=386" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_freebsd_386 ./cmd/$(PROG_NAME)/*.go

build-freebsd-amd64: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=freebsd GOARCH=amd64 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=freebsd -X main.architecture=amd64" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_freebsd_amd64 ./cmd/$(PROG_NAME)/*.go

build-freebsd-arm: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=freebsd GOARCH=arm go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=freebsd -X main.architecture=arm" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_freebsd_arm ./cmd/$(PROG_NAME)/*.go

# Linux
# ==========================
build-linux: clear build-linux-386 build-linux-amd64 build-linux-arm

build-linux-386: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=linux GOARCH=386 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=linux -X main.architecture=386" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_linux_386 ./cmd/$(PROG_NAME)/*.go

build-linux-amd64: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=linux GOARCH=amd64 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=linux -X main.architecture=amd64" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_linux_amd64 ./cmd/$(PROG_NAME)/*.go

build-linux-arm: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=linux GOARCH=arm go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=linux -X main.architecture=arm" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_linux_arm ./cmd/$(PROG_NAME)/*.go

# NetBSD
# ==========================
build-netbsd: clear build-netbsd-386 build-netbsd-amd64 build-netbsd-arm

build-netbsd-386: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=netbsd GOARCH=386 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=netbsd -X main.architecture=386" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_netbsd_386 ./cmd/$(PROG_NAME)/*.go

build-netbsd-amd64: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=netbsd GOARCH=amd64 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=netbsd -X main.architecture=amd64" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_netbsd_amd64 ./cmd/$(PROG_NAME)/*.go

build-netbsd-arm: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=netbsd GOARCH=arm go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=netbsd -X main.architecture=arm" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_netbsd_arm ./cmd/$(PROG_NAME)/*.go

# OpenBSD
# ==========================
build-openbsd: clear build-openbsd-386 build-openbsd-amd64

build-openbsd-386: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=openbsd GOARCH=386 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=openbsd -X main.architecture=386" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_openbsd_386 ./cmd/$(PROG_NAME)/*.go

build-openbsd-amd64: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=openbsd GOARCH=amd64 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=openbsd -X main.architecture=amd64" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_openbsd_amd64 ./cmd/$(PROG_NAME)/*.go

# Windows
# ==========================
build-windows: clear build-windows-386 build-windows-amd64 ## Build for Windows x86 and x86_64

build-windows-386: ## Build for Windows x86 only
	@echo "building: $@"
	@GOOS=windows GOARCH=386 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=windows -X main.architecture=386" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_windows_386 ./cmd/$(PROG_NAME)/*.go

# upx does not work on some arch/OS combos
# upx $(PROG_NAME)_*
build-windows-amd64: ## Build for Windows x86_64 only
	@echo "building: $@"
	@GOOS=windows GOARCH=amd64 go build -ldflags "-s -w -X main.versionNumber=${VERSION} -X main.operatingSystem=windows -X main.architecture=amd64" -o $(BIN_PREFIX_DIR)/$(PROG_NAME)_windows_amd64 ./cmd/$(PROG_NAME)/*.go


	