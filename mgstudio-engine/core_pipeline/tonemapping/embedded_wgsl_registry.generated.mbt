// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source(
    "core_pipeline/tonemapping/lut_bindings.wgsl", lut_bindings_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/tonemapping/lut_bindings.wgsl",
    @asset.asset_text_to_bytes(lut_bindings_wgsl_source),
  )
  @wgsl.register_wgsl_source(
    "core_pipeline/tonemapping/tonemapping_shared.wgsl", tonemapping_shared_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/tonemapping/tonemapping_shared.wgsl",
    @asset.asset_text_to_bytes(tonemapping_shared_wgsl_source),
  )
  @wgsl.register_wgsl_source(
    "core_pipeline/tonemapping/tonemapping.wgsl", tonemapping_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/tonemapping/tonemapping.wgsl",
    @asset.asset_text_to_bytes(tonemapping_wgsl_source),
  )
}
