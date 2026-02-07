# Third-Party Notices (Plan)

This crate depends on a number of Rust crates (notably `wasmtime`, `wgpu`,
`winit`, and their transitive dependencies). If mgstudio ever distributes a
prebuilt `mgstudio-runtime-native-wasmtime` binary (e.g. inside an SDK), we
should also distribute third-party license notices for this dependency tree.

Suggested approach:

1) Generate a NOTICE file during packaging from `Cargo.lock` (recommended):
   - Use a tool like `cargo-about` (or equivalent) to collect license texts and
     produce a consolidated notice document.
2) Ship that generated notice file alongside the binary in the SDK, under a
   path like `share/mgstudio/licenses/native-wasmtime/`.

Until we ship binaries, this file serves as a reminder and a concrete plan.

