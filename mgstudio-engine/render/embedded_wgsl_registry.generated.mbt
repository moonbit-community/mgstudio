// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "render/bindless.wgsl", bindless_wgsl_source,
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/bindless.wgsl",
    @embedded_asset.asset_text_to_bytes(bindless_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "render/color_operations.wgsl", color_operations_wgsl_source,
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/color_operations.wgsl",
    @embedded_asset.asset_text_to_bytes(color_operations_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "render/globals.wgsl", globals_wgsl_source,
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/globals.wgsl",
    @embedded_asset.asset_text_to_bytes(globals_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "render/maths.wgsl", maths_wgsl_source,
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/maths.wgsl",
    @embedded_asset.asset_text_to_bytes(maths_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "render/view/view.wgsl", view_wgsl_source,
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/view/view.wgsl",
    @embedded_asset.asset_text_to_bytes(view_wgsl_source),
  )
}
