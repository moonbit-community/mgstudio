// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @naga_oil.register_wgsl_source(
    "core_pipeline/tonemapping/lut_bindings.wgsl", embedded_wgsl_lut_bindings_wgsl_source,
  )
  @naga_oil.register_wgsl_source(
    "core_pipeline/tonemapping/tonemapping_shared.wgsl", embedded_wgsl_tonemapping_shared_wgsl_source,
  )
  @naga_oil.register_wgsl_source(
    "core_pipeline/tonemapping/tonemapping.wgsl", embedded_wgsl_tonemapping_wgsl_source,
  )
}

///|
let _register_embedded_wgsl_sources_generated : Unit = register_embedded_wgsl_sources_generated()
