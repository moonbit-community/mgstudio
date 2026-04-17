// Hand-written registration for the occlusion culling shader library.

///|
pub fn register_embedded_wgsl_sources() -> Unit {
  @renderer.register_wgsl_source(
    "render/occlusion_culling/mesh_preprocess_types.wgsl", mesh_preprocess_types_wgsl_source,
  )
}
