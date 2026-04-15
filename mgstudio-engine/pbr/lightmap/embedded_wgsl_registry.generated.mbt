// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source("pbr/lightmap/lightmap.wgsl", lightmap_wgsl_source)
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/lightmap/lightmap.wgsl",
    @asset.asset_text_to_bytes(lightmap_wgsl_source),
  )
}
