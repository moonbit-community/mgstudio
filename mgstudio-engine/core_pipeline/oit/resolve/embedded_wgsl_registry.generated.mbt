// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source(
    "core_pipeline/oit/resolve/oit_resolve.wgsl", oit_resolve_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "core_pipeline/oit/resolve/oit_resolve.wgsl",
    @asset.asset_text_to_bytes(oit_resolve_wgsl_source),
  )
}
