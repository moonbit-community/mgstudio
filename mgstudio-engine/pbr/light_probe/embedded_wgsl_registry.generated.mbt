// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @shader_source.load_embedded_shader_source(
    "pbr/light_probe/copy.wgsl", copy_wgsl_source,
  )
  @shader_source.load_embedded_shader_source(
    "pbr/light_probe/environment_filter.wgsl", environment_filter_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/light_probe/environment_filter.wgsl",
    @asset.asset_text_to_bytes(environment_filter_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/light_probe/environment_map.wgsl", environment_map_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/light_probe/environment_map.wgsl",
    @asset.asset_text_to_bytes(environment_map_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/light_probe/irradiance_volume.wgsl", irradiance_volume_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/light_probe/irradiance_volume.wgsl",
    @asset.asset_text_to_bytes(irradiance_volume_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "pbr/light_probe/light_probe.wgsl", light_probe_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "pbr/light_probe/light_probe.wgsl",
    @asset.asset_text_to_bytes(light_probe_wgsl_source),
  )
}
