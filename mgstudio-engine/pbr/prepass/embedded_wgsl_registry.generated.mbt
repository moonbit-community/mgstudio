// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source(
    "pbr/prepass/prepass_bindings.wgsl", prepass_bindings_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/prepass/prepass_bindings.wgsl",
    @asset.asset_text_to_bytes(prepass_bindings_wgsl_source),
  )
  @wgsl.register_wgsl_source(
    "pbr/prepass/prepass_io.wgsl", prepass_io_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/prepass/prepass_io.wgsl",
    @asset.asset_text_to_bytes(prepass_io_wgsl_source),
  )
  @wgsl.register_wgsl_source(
    "pbr/prepass/prepass_utils.wgsl", prepass_utils_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/prepass/prepass_utils.wgsl",
    @asset.asset_text_to_bytes(prepass_utils_wgsl_source),
  )
  @wgsl.register_wgsl_source("pbr/prepass/prepass.wgsl", prepass_wgsl_source)
}
