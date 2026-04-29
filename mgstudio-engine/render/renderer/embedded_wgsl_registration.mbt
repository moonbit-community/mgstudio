// Hand-written wrapper around the generated embedded WGSL registry.

///|
pub fn register_embedded_wgsl_sources() -> Unit {
  @fullscreen_vertex_shader_source.register_embedded_wgsl_sources()
  register_embedded_wgsl_sources_generated()
}
