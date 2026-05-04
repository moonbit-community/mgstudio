// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "pbr/deferred/deferred_lighting.wgsl", deferred_lighting_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/deferred/deferred_lighting.wgsl",
    @asset.asset_text_to_bytes(deferred_lighting_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/deferred/pbr_deferred_functions.wgsl", pbr_deferred_functions_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/deferred/pbr_deferred_functions.wgsl",
    @asset.asset_text_to_bytes(pbr_deferred_functions_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/deferred/pbr_deferred_types.wgsl", pbr_deferred_types_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/deferred/pbr_deferred_types.wgsl",
    @asset.asset_text_to_bytes(pbr_deferred_types_wgsl_source),
  )
}
