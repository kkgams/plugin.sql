# plugin.sql — bounded third-party review

Generated C component ABI glue uses flake-pinned wit-bindgen v0.57.1 (2e00369a643c0c8048b8636401e36b0cbf2dfb05); complete upstream MIT/Apache choices retained, not assumed owner-authored glue. Generated Go ABI bindings use the separately inventoried wit-bindgen-go module tool.

C build uses wasm32-wasip2-clang (WASI SDK 33), wasi-libc 161b3195fc2558d2b1ba3eb9ffae3b2b47407623 and LLVM/compiler-rt 4434dabb69916856b824f68a64b029c67175e532, matching local SDK VERSION/clang evidence. Direct Preview2 C linkage does NOT imply an injected Preview1 adapter. Go uses TinyGo wasip2 runtime and its component assembly; any standard Preview1→Preview2 adapter must be identified by actual build/module evidence. Wasmtime adapter terms retained conditionally, not claimed as a C link input. Runtime reachability/adapter exact source and digest still require actual hosted evidence. The retained wasi-io 3983fe1… Apache-LLVM text is a newer comparison only, NOT the license of the vendored v0.2.0 specification bytes.

SQLite amalgamation/header full public-domain declarations preserved. sqlite-vec header identifies v0.1.3 / 496560cf9ac4b358ea43793e591f376c02c16b90: both full upstream choices retained. Explicit source references to FAISS Hamming, ngtcp2 ring buffer and hnswlib kernels are conservatively covered by their full licenses; referenced code is not Apache owner work.

## Limits

- Working-tree source comparison, not an original-authorship, original-import, or all-history certificate. Owner Apache approval applies only to owner-controlled contributions.
- Exact prepared repository bytes are bound below, including build inputs/lockfiles/tests. No current build, enabled-feature graph, linked-code reachability, adapter digest, or final WASM/ZIP contents are certified by this source audit.
- Pinned upstream license comparisons establish readable terms, not the version of every historical imported fragment. Newly discovered identifiable missing permissions remain blockers; historical lineage uncertainty alone does not veto approved GAMS-authored work.
- Build tools (jco, wit-bindgen, C#/Odin parity runners) are not automatically distributed runtime code. Go module inventory conservatively includes generator-only dependencies. Final linked runtime and standard adapters require hosted build evidence.

## Identifiable permission blockers

None identified in this selected prepared closure. This does not clear existing record blockers, new findings, or final artifact review.
