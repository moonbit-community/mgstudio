// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "core_pipeline/blit/blit.wgsl", blit_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/blit/blit.wgsl",
    @asset.asset_text_to_bytes(blit_wgsl_source),
  )
}
