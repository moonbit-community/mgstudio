// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "anti_alias/contrast_adaptive_sharpening/robust_contrast_adaptive_sharpening.wgsl",
    robust_contrast_adaptive_sharpening_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "anti_alias/contrast_adaptive_sharpening/robust_contrast_adaptive_sharpening.wgsl",
    @asset.asset_text_to_bytes(robust_contrast_adaptive_sharpening_wgsl_source),
  )
}
