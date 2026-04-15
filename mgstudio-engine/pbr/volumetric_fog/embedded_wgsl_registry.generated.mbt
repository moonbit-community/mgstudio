// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source(
    "pbr/volumetric_fog/volumetric_fog.wgsl", volumetric_fog_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/volumetric_fog/volumetric_fog.wgsl",
    @asset.asset_text_to_bytes(volumetric_fog_wgsl_source),
  )
}
