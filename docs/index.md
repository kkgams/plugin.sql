---
title: Development
status: reference
---

# plugin.sql development

## Build and test

Use the repository's pinned Nix environment from its root:

```sh
nix develop
make build
make test
```

Local output is under `dist/`. See the repository README for the exported WIT
contract, test coverage and existing release requirements. Runtime, packaging,
licensing evidence and version-tag publication policies are unchanged.

## Open the local Project

On macOS Apple Silicon, from the same development shell:

```sh
make open
```

This builds the local component artifacts, downloads the released Host into
ignored `tools/gams.app` if absent, and explicitly selects this repository's
`gams.json` using `GAMS_APP_CWD`. No neighboring checkout is needed. Downloaded
Host notices remain in `tools/gams-release-notices`; an existing app is never
updated implicitly. No Gatekeeper bypass is performed.

The released SQL console uses the local default SQL provider with an in-memory
database. Try `SELECT 42 AS answer;`. Data is discarded when the Host exits.
Only `dist/plugin.sql.wasm` is registered; the SQL and SQL-vec components export
the same interface and must not be loaded together. To exercise SQL-vec, change
the single local provider in `gams.json` to `dist/plugin.sql-vec.wasm`.

The Project pins published filesystem/layout components, shell UI Services,
theme and Views. First launch requires network access for those dependencies;
Host-installed Units stay in ignored `gams_modules/`.

## Documentation

```sh
make serve-docs DOCS_PORT=8080
make validate-docs
make docs
```

These targets use pinned `justgook/wiki` v1.4.0. `DOCS_PORT` is independent of
application ports. `make docs` writes the portable site to `build/site/`;
`make build-docs` remains an alias. Downloads and generated output stay under
ignored `build/`. Every push to `release` builds through `make docs` and deploys
GitHub Pages independently of version-tag releases.
