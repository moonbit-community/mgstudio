// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl", fullscreen_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl",
    @asset.asset_text_to_bytes(fullscreen_wgsl_source),
  )
}
