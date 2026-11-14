#[cfg(test)]
mod tests {
    use wasmtime::component::{Component, Linker, ResourceTable};
    use wasmtime::{Engine, Store};
    use wasmtime_wasi::{WasiCtx, WasiCtxView, WasiView};

    wasmtime::component::bindgen!({
        path: "../../plugins/sql.comp/wit",
        world: "provider",
    });
    use exports::wasi::sql::types::DataType;

    struct State { wasi: WasiCtx, table: ResourceTable }
    impl WasiView for State {
        fn ctx(&mut self) -> WasiCtxView<'_> {
            WasiCtxView { ctx: &mut self.wasi, table: &mut self.table }
        }
    }

    #[test]
    fn providers_query_with_connection_and_statement_resources() -> wasmtime::Result<()> {
        let engine = Engine::default();
        let directory = std::env::var_os("SQL_COMPONENT_DIR").expect("SQL_COMPONENT_DIR selects components");
        for name in ["sql.wasm", "sql-vec.wasm"] {
            let component = Component::from_file(&engine, std::path::PathBuf::from(&directory).join(name))?;
            let mut linker = Linker::<State>::new(&engine);
            wasmtime_wasi::p2::add_to_linker_sync(&mut linker)?;
            let mut store = Store::new(&engine, State { wasi: WasiCtx::builder().build(), table: ResourceTable::new() });
            let instance = Provider::instantiate(&mut store, &component, &linker)?;
            let types = instance.wasi_sql_types();
            let connection = types.connection().call_open(&mut store, ":memory:")?.expect("open connection");
            let statement = types.statement().call_prepare(&mut store, "SELECT 42 AS answer", &[])?.expect("prepare query");
            let rows = instance.wasi_sql_readwrite().call_query(&mut store, connection, statement)?.expect("query rows");
            assert_eq!(rows[0].field_name, "answer");
            assert!(matches!(rows[0].value, DataType::Int64(42)));
            if name == "sql-vec.wasm" {
                let vec = types.statement().call_prepare(&mut store, "SELECT vec_version() AS version", &[])?.expect("prepare version query");
                let rows = instance.wasi_sql_readwrite().call_query(&mut store, connection, vec)?.expect("query vector version");
                let DataType::Str(version) = &rows[0].value else { panic!("version must be text") };
                let mut parts = version.trim_start_matches('v').split('.');
                for _ in 0..2 {
                    let part = parts.next().expect("version has major/minor");
                    assert!(!part.is_empty() && part.bytes().all(|byte| byte.is_ascii_digit()));
                }
                vec.resource_drop(&mut store)?;
            }
            statement.resource_drop(&mut store)?;
            connection.resource_drop(&mut store)?;
        }
        Ok(())
    }
}
