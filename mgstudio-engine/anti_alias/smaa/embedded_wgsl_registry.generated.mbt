// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "anti_alias/smaa/smaa.wgsl", smaa_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "anti_alias/smaa/smaa.wgsl",
    @asset.asset_text_to_bytes(smaa_wgsl_source),
  )
}
