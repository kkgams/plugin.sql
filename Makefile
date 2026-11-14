SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := build
PYTHON ?= python3
CURL ?= curl
GAMS_RELEASE_API ?= https://api.github.com/repos/kkgams/gams/releases/latest
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
DOCS_PORT ?= 8080
WIKI_VERSION := v1.4.0
WIKI_REPOSITORY := https://github.com/justgook/wiki
WIKI_MAKEFILE := build.nosync/wiki-$(WIKI_VERSION).mk
WIKI_ENGINE := $(abspath build.nosync/wiki-$(WIKI_VERSION))
WIT_SQL := $(shell find plugins/sql.comp/wit -type f -o -type d)
WIT_VEC := $(shell find plugins/sql-vec.comp/wit -type f -o -type d)
LEGAL := LICENSE NOTICE LICENSING.md $(sort $(wildcard LICENSES/*))
export PYTHONDONTWRITEBYTECODE := 1
export CARGO_TARGET_DIR := $(abspath build.nosync/cargo-target)
export CARGO_HOME := $(abspath build.nosync/cargo-home)
NATIVE_CC ?= cc
export TMPDIR := $(abspath build.nosync/tmp)

.PHONY: test build package clean open docs serve-docs validate-docs
build: build.nosync/plugin.sql.wasm build.nosync/plugin.sql-vec.wasm
package: build.nosync/plugin.sql-vec.wasm build.nosync/plugin.sql.wasm build.nosync/LICENSES.zip build.nosync/SHA256SUMS

build.nosync/tmp:
	mkdir -p "$@"

build.nosync/sql/provider.c build.nosync/sql/provider.h build.nosync/sql/provider_component_type.o &: $(WIT_SQL) Makefile flake.lock | build.nosync/tmp
	mkdir -p build.nosync/sql
	cd build.nosync/sql && wit-bindgen c ../../plugins/sql.comp/wit -w provider

build.nosync/sql-vec/provider.c build.nosync/sql-vec/provider.h build.nosync/sql-vec/provider_component_type.o &: $(WIT_VEC) Makefile flake.lock | build.nosync/tmp
	mkdir -p build.nosync/sql-vec
	cd build.nosync/sql-vec && wit-bindgen c ../../plugins/sql-vec.comp/wit -w provider

build.nosync/TERMS: $(LEGAL) LICENSES Makefile | build.nosync/tmp
	for file in $(LEGAL); do printf '\n--- %s ---\n' "$$file"; cat "$$file"; done > "$@"

build.nosync/compiled/sql.wasm: plugins/sql.comp/component.c plugins/sql.comp/sql-common/sqlite_provider.c $(wildcard plugins/sql.comp/vendor/*.h) plugins/sql.comp/vendor/sqlite3.c plugins/sql.comp/vendor build.nosync/sql/provider.c build.nosync/sql/provider.h build.nosync/sql/provider_component_type.o Makefile flake.lock
	mkdir -p "$(@D)"
	wasm32-wasip2-clang -o "$@" -mexec-model=reactor -Ibuild.nosync/sql -Iplugins/sql.comp/vendor -Iplugins/sql.comp/sql-common -O2 -DNDEBUG -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_OMIT_WAL -DSQLITE_TEMP_STORE=3 -DSQLITE_DEFAULT_MEMSTATUS=0  build.nosync/sql/provider.c plugins/sql.comp/component.c plugins/sql.comp/vendor/sqlite3.c  build.nosync/sql/provider_component_type.o -Wl,--strip-all
	wasm-tools strip -a "$@" -o "$@.strip"
	mv "$@.strip" "$@"
	wasm-tools validate "$@"

build.nosync/plugin.sql.wasm build.nosync/test/sql.wasm: build.nosync/compiled/sql.wasm build.nosync/TERMS scripts/wasm-notices.py Makefile
	mkdir -p "$(@D)"
	cp "$<" "$@"
	$(PYTHON) scripts/wasm-notices.py embed "$@" --license build.nosync/TERMS --notice NOTICE
	wasm-tools validate "$@"

build.nosync/compiled/sql-vec.wasm: plugins/sql-vec.comp/component.c plugins/sql.comp/sql-common/sqlite_provider.c $(wildcard plugins/sql-vec.comp/vendor/*.h) plugins/sql-vec.comp/vendor/sqlite3.c plugins/sql-vec.comp/vendor/sqlite-vec.c plugins/sql-vec.comp/vendor build.nosync/sql-vec/provider.c build.nosync/sql-vec/provider.h build.nosync/sql-vec/provider_component_type.o Makefile flake.lock
	mkdir -p "$(@D)"
	wasm32-wasip2-clang -o "$@" -mexec-model=reactor -Ibuild.nosync/sql-vec -Iplugins/sql-vec.comp/vendor -Iplugins/sql.comp/sql-common -O2 -DNDEBUG -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_OMIT_WAL -DSQLITE_TEMP_STORE=3 -DSQLITE_DEFAULT_MEMSTATUS=0 -DGAMS_SQL_WITH_VEC -DSQLITE_CORE -DSQLITE_VEC_STATIC -DSQLITE_VEC_OMIT_FS build.nosync/sql-vec/provider.c plugins/sql-vec.comp/component.c plugins/sql-vec.comp/vendor/sqlite3.c plugins/sql-vec.comp/vendor/sqlite-vec.c build.nosync/sql-vec/provider_component_type.o -Wl,--strip-all
	wasm-tools strip -a "$@" -o "$@.strip"
	mv "$@.strip" "$@"
	wasm-tools validate "$@"

build.nosync/plugin.sql-vec.wasm build.nosync/test/sql-vec.wasm: build.nosync/compiled/sql-vec.wasm build.nosync/TERMS scripts/wasm-notices.py Makefile
	mkdir -p "$(@D)"
	cp "$<" "$@"
	$(PYTHON) scripts/wasm-notices.py embed "$@" --license build.nosync/TERMS --notice NOTICE
	wasm-tools validate "$@"

build.nosync/LICENSES.zip: $(LEGAL) LICENSES Makefile | build.nosync/tmp
	rm -f "$@"
	zip -q -X "$@" $(LEGAL)

build.nosync/SHA256SUMS: build.nosync/plugin.sql-vec.wasm build.nosync/plugin.sql.wasm build.nosync/LICENSES.zip
	cd build.nosync && shasum -a 256 plugin.sql.wasm plugin.sql-vec.wasm LICENSES.zip > SHA256SUMS

clean:
	$(PYTHON) scripts/clean.py

# Retain an existing app; never update it implicitly.
tools/gams.app:
	@test "$(UNAME_S)" = Darwin && test "$(UNAME_M)" = arm64 || \
		{ echo 'GAMS release download requires macOS Apple Silicon' >&2; exit 1; }
	@test ! -e tools/gams-release-notices || \
		{ echo 'tools/gams-release-notices already exists; move it aside before reinstalling GAMS' >&2; exit 1; }
	@mkdir -p tools build.nosync/tmp
	@set -eu; stage=$$(mktemp -d "build.nosync/tmp/gams-download.XXXXXX"); \
		trap 'rm -rf "$$stage"' EXIT; \
		$(CURL) --fail --location --silent --show-error "$(GAMS_RELEASE_API)" --output "$$stage/release.json"; \
		url=$$($(PYTHON) -c 'import json, sys; release = json.load(open(sys.argv[1])); assets = [a for a in release["assets"] if a["name"].startswith("GAMS-") and a["name"].endswith("-macos-aarch64.zip")]; assert len(assets) == 1, "Expected exactly one GAMS macOS Apple Silicon ZIP asset"; print(assets[0]["browser_download_url"])' "$$stage/release.json"); \
		$(CURL) --fail --location --silent --show-error "$$url" --output "$$stage/gams.zip"; \
		unzip -q "$$stage/gams.zip" -d "$$stage/unpacked"; \
		test -f "$$stage/unpacked/GAMS.app/Contents/Info.plist"; \
		test -x "$$stage/unpacked/GAMS.app/Contents/MacOS/gams"; \
		mv "$$stage/unpacked/GAMS.app" "$$stage/GAMS.app"; \
		mv "$$stage/unpacked" tools/gams-release-notices; \
		mv "$$stage/GAMS.app" "$@"; \
		printf 'plugin.sql Makefile Host download\n' > tools/gams-release-notices/.gams-managed

open: build tools/gams.app
	GAMS_APP_CWD="$(CURDIR)" ./tools/gams.app/Contents/MacOS/gams

$(WIKI_MAKEFILE): | build.nosync/tmp
	$(CURL) --fail --location --retry 3 "$(WIKI_REPOSITORY)/raw/$(WIKI_VERSION)/Makefile" -o "$@.tmp"
	mv "$@.tmp" "$@"

docs serve-docs validate-docs: $(WIKI_MAKEFILE)
	$(MAKE) -f "$(WIKI_MAKEFILE)" "$(if $(filter docs,$@),build,$(patsubst %-docs,%,$@))" WIKI_REPOSITORY="$(WIKI_REPOSITORY)" WIKI_VERSION="$(WIKI_VERSION)" WIKI_ENGINE="$(WIKI_ENGINE)" WIKI_SOURCE="$(abspath docs)" WIKI_OUTPUT="$(abspath build.nosync/site)" PORT="$(DOCS_PORT)"

test: build.nosync/test/sql.wasm build.nosync/test/sql-vec.wasm
	CC="$(NATIVE_CC)" SQL_COMPONENT_DIR="$(CURDIR)/build.nosync/test" cargo test --locked --manifest-path test/component/Cargo.toml
