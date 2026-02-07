use std::path::PathBuf;

use anyhow::Context;
use clap::Parser;

mod source_spec;
mod host;
mod wasmtime_runner;
mod native_window;
mod gpu_backend;

/// A reference native runtime for mgstudio implemented in Rust (wasmtime + wgpu).
#[derive(Parser, Debug)]
#[command(author, version, about)]
struct Args {
    /// Path to the wasm cart (built with MoonBit's wasm target).
    #[arg(long)]
    cart: PathBuf,

    /// Assets source spec (mgstudio-runtime-core format). Currently only `dir:` is supported.
    #[arg(long, default_value = ".")]
    assets: String,

    /// Data source spec (mgstudio-runtime-core format). Currently only `dir:` is supported.
    #[arg(long, default_value = "./tmp/data")]
    data: String,

    /// Dump wasm imports (useful for matching host signatures).
    #[arg(long, default_value_t = false)]
    dump_imports: bool,

    /// Enable noisy host tracing.
    #[arg(long, default_value_t = false)]
    trace_host: bool,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    let cart = args
        .cart
        .canonicalize()
        .with_context(|| format!("invalid --cart path: {}", args.cart.display()))?;

    let assets = source_spec::parse_dir_source(&args.assets, ".")
        .context("invalid --assets source spec")?;
    let data = source_spec::parse_dir_source(&args.data, "./tmp/data").context("invalid --data source spec")?;

    wasmtime_runner::run_cart(wasmtime_runner::RunCartOpts {
        cart_path: cart,
        assets,
        data,
        dump_imports: args.dump_imports,
        trace_host: args.trace_host,
    })
}
