// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "core_pipeline/skybox/skybox_prepass.wgsl", skybox_prepass_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/skybox/skybox_prepass.wgsl",
    @asset.asset_text_to_bytes(skybox_prepass_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "core_pipeline/skybox/skybox.wgsl", skybox_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/skybox/skybox.wgsl",
    @asset.asset_text_to_bytes(skybox_wgsl_source),
  )
}
