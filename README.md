# plugin.sql

SQLite database access for [GAMS](https://github.com/kkgams/gams).

| Unit | Source | Original work | License |
| --- | --- | --- | --- |
| SQL provider | `plugins/sql.comp/` | [SQLite contributors](https://sqlite.org/), GAMS contributors | [LICENSE](LICENSE), [full original terms](LICENSES/), [NOTICE](NOTICE) |
| SQL-vec provider | `plugins/sql-vec.comp/`, shared `sql-common/` | SQLite contributors; [sqlite-vec, Alex Garcia](https://github.com/asg017/sqlite-vec) | [LICENSE](LICENSE), [full original terms](LICENSES/), [NOTICE](NOTICE) |

## Development

Use the pinned C/WASI and Rust test toolchain: `nix develop --command make <target>`.

| Command | Purpose |
| --- | --- |
| `make build` | Compile both providers with embedded complete terms. |
| `make test` | Run existing query and vec_version assertions through native Wasmtime resource calls. |
| `make package` | Build plugin.sql.wasm, plugin.sql-vec.wasm, LICENSES.zip and SHA256SUMS under build.nosync/. |
| `make open` | Build and open this local Project in released macOS Apple Silicon Host. |
| `make docs` | Build pinned wiki in build.nosync/site/. |
| `make serve-docs` | Serve wiki; independent DOCS_PORT defaults to 8080. |
| `make validate-docs` | Validate wiki content. |
| `make clean` | Remove build.nosync and identified downloads; refuse tracked paths/symlinks and preserve supplied tools/Units. |

The local Project loads only the default SQL provider and the released SQL console with an in-memory database. Try `SELECT 42 AS answer;`; data disappears when the Host exits. To use vectors, replace the one local provider path with `build.nosync/plugin.sql-vec.wasm`. First launch downloads pinned supporting Units; an existing Host is never updated implicitly.

Native Rust/Wasmtime tests retain connection/statement/query resource assertions for both providers and vec_version for SQL-vec. They compile separate test components, not release packages. Historical external Host tests remain available but are not standalone coverage. Full API and GUI integration need separate verification.

## API

Both providers export `types` and `readwrite` from `wasi:sql@0.2.0-draft`, world `provider`. Connections/statements support query/exec. SQL-vec adds sqlite-vec support. Choose one provider: the artifacts share a WIT identity and must not be registered together. The complete contract is `plugins/sql.comp/wit/`.
