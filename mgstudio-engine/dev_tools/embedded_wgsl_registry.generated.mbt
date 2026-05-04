// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "dev_tools/frame_time_graph/frame_time_graph.wgsl", frame_time_graph_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "dev_tools/frame_time_graph/frame_time_graph.wgsl",
    @asset.asset_text_to_bytes(frame_time_graph_wgsl_source),
  )
}
