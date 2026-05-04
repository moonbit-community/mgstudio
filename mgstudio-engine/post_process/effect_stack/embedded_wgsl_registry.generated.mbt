// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "post_process/effect_stack/chromatic_aberration.wgsl", chromatic_aberration_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "post_process/effect_stack/post_process.wgsl", post_process_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "post_process/effect_stack/vignette.wgsl", vignette_wgsl_source,
  )
}
