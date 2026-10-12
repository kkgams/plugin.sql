# plugin.sql

GAMS WASM Project Unit for SQLite database access.
Distribution and WIT interface versions are independent.

## API

Both components export `types` and `readwrite` from `wasi:sql@0.2.0-draft`
through the `provider` world. The API provides connections/statements and
`query`/`exec` operations. `plugin.sql-vec.wasm` adds sqlite-vec support.
Choose a provider: these artifacts implement the same WIT identity and must
not be registered as duplicate providers for that identity.

The contract is in `plugins/sql.comp/wit/package.wit`.
The accompanying `types.wit` and `readwrite.wit` define the database API.
Plugin Manager resolves imports; distribution filenames do not rename WIT identities.

## Build and test

All source/build inputs are owned by this repository; no sibling checkout is
required for its supported build/test commands. Use the pinned Nix environment:

```sh
nix develop --command make build
nix develop --command make test
```

Outputs: `dist/plugin.sql.wasm` and `dist/plugin.sql-vec.wasm`. Install the
chosen provider as `plugins/sql.comp.wasm` or `plugins/sql-vec.comp.wasm`
in an external GAMS Project. Configure that Project separately.

The flake and lockfiles pin the toolchain. Network access may be required to
fetch tools/modules. `.envrc` supports `direnv allow`.

`make test` runs offline integrity/publication regression tests, builds the
components, validates WASM, extracts WIT, and checks the exact input inventory.
It also transpiles the built components with jco and runs standalone WASM
runtime assertions. These are bounded smoke checks, not full API or Host
integration coverage.

## Licensing and releases

GAMS-authored contributions are Apache-2.0. Third-party code retains its own
terms; see `LICENSING.md`, `THIRD-PARTY-REVIEW.md`, and `LICENSES/`.
Source inventory and notice evidence are checked before candidate packaging.
Changed inputs require refreshed exact evidence; checksum consistency alone is
not legal approval. On 2026-10-12 the owner confirmed licensing/checksums were
already prepared and removed pending manual checksum, license, and hosted-review
approvals for 0.2.1, authorizing local commits and annotated tags. This does not
claim hosted tests, final artifact review, or missing runtime coverage passed.

Distribution is through GitHub Releases, not npm or OCI. Before publishing:

1. Preserve exact source and third-party evidence. Manual reviews were waived
   by the owner for 0.2.1; hosted execution remains unverified, not a manual
   approval blocker. Enforced build and publication checks still must pass.
2. Set repository-scoped `LICENSE_SHA256` and `NOTICE_SHA256` Actions variables
   to the exact authorized texts. Local rehearsal uses
   `APPROVED_LICENSE_SHA256` and `APPROVED_NOTICE_SHA256`.
3. Push the authorized `release` branch and verify its hosted candidate. Without
   approved digests, branch checks do not distribute a candidate. Manual release
   workflow dispatch verifies but does not publish.
4. Tag the authorized release-branch commit as `v<version.txt>`. Never reuse or
   move a published or failed tag. Publication requires immutable-release policy,
   canonical repository/version identity, exact artifacts and checksums, embedded
   notices, and complete readable legal assets. An existing release blocks creation.

The publication workflow rehearses a private draft's bytes before publication
and checks the anonymous public bytes afterward. Keep LICENSE, NOTICE, evidence,
review documents, and applicable LICENSES with distributed artifacts. See the
repository's release workflow and scripts for the enforced gates.
