ELECTRS_SRC := $(shell find ./electrs/src) electrs/Cargo.toml electrs/Cargo.lock
CONFIGURATOR_SRC := $(shell find ./configurator/src) configurator/Cargo.toml configurator/Cargo.lock
PKG_VERSION := $(shell yq ".version" manifest.yaml)
PKG_ID := $(shell yq ".id" manifest.yaml)
TS_FILES := $(shell find . -name \*.ts )

.DELETE_ON_ERROR:

all: verify

verify: $(PKG_ID).s9pk
	@start-sdk verify s9pk $(PKG_ID).s9pk
	@echo " Done!"
	@echo "   Filesize: $(shell du -h $(PKG_ID).s9pk) is ready"

install:
	@if [ ! -f ~/.embassy/config.yaml ]; then echo "You must define \"host: http://server-name.local\" in ~/.embassy/config.yaml config file first."; exit 1; fi
	@echo "\nInstalling to $$(grep -v '^#' ~/.embassy/config.yaml | cut -d'/' -f3) ...\n"
	@[ -f $(PKG_ID).s9pk ] || ( $(MAKE) && echo "\nInstalling to $$(grep -v '^#' ~/.embassy/config.yaml | cut -d'/' -f3) ...\n" )
	@start-cli package install $(PKG_ID).s9pk

clean:
	rm -rf docker-images
	rm -f $(PKG_ID).s9pk
	rm -f scripts/*.js

# for rebuilding just the arm image.
arm:
	@rm -f docker-images/x86_64.tar
	@ARCH=aarch64 $(MAKE) -s

# for rebuilding just the x86 image.
x86:
	@rm -f docker-images/aarch64.tar
	@ARCH=x86_64 $(MAKE) -s

$(PKG_ID).s9pk: manifest.yaml instructions.md scripts/embassy.js electrs/LICENSE docker-images/aarch64.tar docker-images/x86_64.tar
ifeq ($(ARCH),aarch64)
	@echo "start-sdk: Preparing aarch64 package ..."
else ifeq ($(ARCH),x86_64)
	@echo "start-sdk: Preparing x86_64 package ..."
else
	@echo "start-sdk: Preparing Universal Package ..."
endif
	@start-sdk pack

docker-images/aarch64.tar: Dockerfile docker_entrypoint.sh check-synced.sh check-electrum.sh configurator/target/aarch64-unknown-linux-musl/release/configurator $(ELECTRS_SRC)
ifeq ($(ARCH),x86_64)
else
	mkdir -p docker-images
	docker buildx build --tag start9/$(PKG_ID)/main:$(PKG_VERSION) --build-arg ARCH=aarch64 --build-arg PLATFORM=arm64 --platform=linux/arm64 -o type=docker,dest=docker-images/aarch64.tar .
endif

docker-images/x86_64.tar: Dockerfile docker_entrypoint.sh check-synced.sh check-electrum.sh configurator/target/x86_64-unknown-linux-musl/release/configurator $(ELECTRS_SRC)
ifeq ($(ARCH),aarch64)
else
	mkdir -p docker-images
	docker buildx build --tag start9/$(PKG_ID)/main:$(PKG_VERSION) --build-arg ARCH=x86_64 --build-arg PLATFORM=amd64 --platform=linux/amd64 -o type=docker,dest=docker-images/x86_64.tar .
endif

configurator/target/aarch64-unknown-linux-musl/release/configurator: $(CONFIGURATOR_SRC)
	docker run --rm -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src messense/rust-musl-cross:aarch64-musl cargo build --release

configurator/target/x86_64-unknown-linux-musl/release/configurator: $(CONFIGURATOR_SRC)
	docker run --rm -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src messense/rust-musl-cross:x86_64-musl cargo build --release

scripts/embassy.js: $(TS_FILES)
	deno bundle scripts/embassy.ts scripts/embassy.js
