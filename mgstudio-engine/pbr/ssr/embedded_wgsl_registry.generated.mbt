// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "pbr/ssr/raymarch.wgsl", raymarch_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/ssr/raymarch.wgsl",
    @asset.asset_text_to_bytes(raymarch_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/ssr/ssr.wgsl", ssr_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/ssr/ssr.wgsl",
    @asset.asset_text_to_bytes(ssr_wgsl_source),
  )
}
