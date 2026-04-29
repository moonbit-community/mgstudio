// Renderer-facing fullscreen shader source registration.
//
// This package intentionally depends only on `moon_wgsl`, so low-level render
// pipeline code can register the fullscreen WGSL import without pulling in the
// asset/render application graph.

///|
pub fn register_embedded_wgsl_sources() -> Unit {
  @wgsl.register_wgsl_source(
    "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl", fullscreen_wgsl_source,
  )
}
