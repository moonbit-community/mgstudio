// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source(
    "core_pipeline/mip_generation/experimental/downsample_depth.wgsl", downsample_depth_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/mip_generation/experimental/downsample_depth.wgsl",
    @asset.asset_text_to_bytes(downsample_depth_wgsl_source),
  )
}
