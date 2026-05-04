// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "pbr/ssao/preprocess_depth.wgsl", preprocess_depth_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/ssao/preprocess_depth.wgsl",
    @asset.asset_text_to_bytes(preprocess_depth_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/ssao/spatial_denoise.wgsl", spatial_denoise_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/ssao/spatial_denoise.wgsl",
    @asset.asset_text_to_bytes(spatial_denoise_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/ssao/ssao_utils.wgsl", ssao_utils_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "pbr/ssao/ssao.wgsl", ssao_wgsl_source,
  )
}
