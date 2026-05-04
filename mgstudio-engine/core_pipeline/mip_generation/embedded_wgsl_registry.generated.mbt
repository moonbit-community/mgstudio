// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "core_pipeline/mip_generation/downsample.wgsl", downsample_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/mip_generation/downsample.wgsl",
    @asset.asset_text_to_bytes(downsample_wgsl_source),
  )
}
