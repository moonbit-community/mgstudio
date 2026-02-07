use std::path::PathBuf;

use anyhow::{anyhow, Context};
use wasmtime::{Config, Engine, ExternType, Instance, Linker, Module, OptLevel, Store};

use crate::host::{self, HostState};
use crate::source_spec::DirSourceSpec;

pub struct RunCartOpts {
    pub cart_path: PathBuf,
    pub assets: DirSourceSpec,
    pub data: DirSourceSpec,
    pub dump_imports: bool,
    pub trace_host: bool,
}

pub fn run_cart(opts: RunCartOpts) -> anyhow::Result<()> {
    let mut config = Config::new();
    // MoonBit wasm-gc output currently relies on reference types + function references + GC.
    config.wasm_reference_types(true);
    config.wasm_function_references(true);
    config.wasm_gc(true);
    // Cranelift AArch64 can hit assertion panics on some large wasm-gc modules.
    // Disable parallel compilation so any failure is easier to attribute and
    // to avoid panics originating from background threads.
    config.parallel_compilation(false);
    config.cranelift_opt_level(OptLevel::SpeedAndSize);

    let engine = Engine::new(&config).context("failed to create wasmtime engine")?;
    // Wasmtime compilation panics can be quite noisy (default panic hook prints to stderr).
    // Silence the hook while probing module compilation so we can report a clean error.
    let _panic_hook_guard = PanicHookGuard::silence();
    let module = match std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        Module::from_file(&engine, &opts.cart_path)
    })) {
        Ok(res) => res.with_context(|| {
            format!("failed to load wasm module: {}", opts.cart_path.display())
        })?,
        Err(_) => {
            // Known issue: Cranelift AArch64 can panic during veneer/island fixups when compiling
            // very large functions in some wasm-gc modules. Convert the panic into a normal
            // error so `mgstudio` can report it cleanly.
            return Err(anyhow!(
                "wasmtime/cranelift panicked while compiling this wasm module (AArch64 island/veneer fixup bug?)"
            ));
        }
    };

    if opts.dump_imports {
        dump_func_imports(&module);
    }

    let mut store = Store::new(&engine, HostState::new(opts.assets, opts.data, opts.trace_host));
    let mut linker = Linker::new(&engine);
    host::define_imports(&mut store, &mut linker).context("failed to define host imports")?;

    let instance = linker
        .instantiate(&mut store, &module)
        .context("failed to instantiate wasm module")?;

    call_game_app(&mut store, &instance)
}

struct PanicHookGuard(Option<Box<dyn Fn(&std::panic::PanicHookInfo<'_>) + Sync + Send + 'static>>);

impl PanicHookGuard {
    fn silence() -> Self {
        let prev = std::panic::take_hook();
        std::panic::set_hook(Box::new(|_info| {
            // Intentionally quiet.
        }));
        Self(Some(prev))
    }
}

impl Drop for PanicHookGuard {
    fn drop(&mut self) {
        if let Some(prev) = self.0.take() {
            std::panic::set_hook(prev);
        }
    }
}

fn call_game_app(store: &mut Store<HostState>, instance: &Instance) -> anyhow::Result<()> {
    let f = instance
        .get_func(&mut *store, "game_app")
        .ok_or_else(|| anyhow!("missing export: game_app"))?;
    let typed = f
        .typed::<(), ()>(&mut *store)
        .context("export game_app has unexpected type")?;
    typed.call(&mut *store, ()).context("game_app trapped")?;
    Ok(())
}

fn dump_func_imports(module: &Module) {
    eprintln!("== wasm imports ==");
    for imp in module.imports() {
        if let ExternType::Func(ft) = imp.ty() {
            eprintln!(
                "import {}.{}: ({}) -> ({})",
                imp.module(),
                imp.name(),
                ft.params()
                    .map(|p| p.to_string())
                    .collect::<Vec<_>>()
                    .join(", "),
                ft.results()
                    .map(|r| r.to_string())
                    .collect::<Vec<_>>()
                    .join(", ")
            );
        }
    }
}
