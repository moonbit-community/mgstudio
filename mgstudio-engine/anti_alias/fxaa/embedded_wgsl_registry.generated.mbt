// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "anti_alias/fxaa/fxaa.wgsl", fxaa_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "anti_alias/fxaa/fxaa.wgsl",
    @asset.asset_text_to_bytes(fxaa_wgsl_source),
  )
}
