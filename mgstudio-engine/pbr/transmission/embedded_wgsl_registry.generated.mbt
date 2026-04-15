// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source(
    "pbr/transmission/transmission.wgsl", transmission_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/transmission/transmission.wgsl",
    @asset.asset_text_to_bytes(transmission_wgsl_source),
  )
}
