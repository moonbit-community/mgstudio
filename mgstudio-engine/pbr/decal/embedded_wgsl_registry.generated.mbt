// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "pbr/decal/clustered.wgsl", clustered_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "pbr/decal/forward_decal.wgsl", forward_decal_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/decal/forward_decal.wgsl",
    @asset.asset_text_to_bytes(forward_decal_wgsl_source),
  )
}
