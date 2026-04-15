// Auto-generated. Do not edit manually.

///|
fn register_embedded_wgsl_sources_generated() -> Unit {
  @wgsl.register_wgsl_source("render/bindless.wgsl", bindless_wgsl_source)
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/bindless.wgsl",
    @embedded_asset.asset_text_to_bytes(bindless_wgsl_source),
  )
  @wgsl.register_wgsl_source(
    "render/color_operations.wgsl", color_operations_wgsl_source,
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/color_operations.wgsl",
    @embedded_asset.asset_text_to_bytes(color_operations_wgsl_source),
  )
  @wgsl.register_wgsl_source("render/globals.wgsl", globals_wgsl_source)
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/globals.wgsl",
    @embedded_asset.asset_text_to_bytes(globals_wgsl_source),
  )
  @wgsl.register_wgsl_source(
    "render/occlusion_culling/mesh_preprocess_types.wgsl", mesh_preprocess_types_wgsl_source,
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/occlusion_culling/mesh_preprocess_types.wgsl",
    @embedded_asset.asset_text_to_bytes(mesh_preprocess_types_wgsl_source),
  )
  @wgsl.register_wgsl_source("render/maths.wgsl", maths_wgsl_source)
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/maths.wgsl",
    @embedded_asset.asset_text_to_bytes(maths_wgsl_source),
  )
  @wgsl.register_wgsl_source("render/view/view.wgsl", view_wgsl_source)
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/view/view.wgsl",
    @embedded_asset.asset_text_to_bytes(view_wgsl_source),
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "shaders/mesh3d_forward.wgsl",
    @embedded_asset.asset_text_to_bytes(renderer_mesh3d_forward_wgsl_source),
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "render/view/window/screenshot.wgsl",
    @embedded_asset.asset_text_to_bytes(
      render_view_window_screenshot_wgsl_source,
    ),
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "post_process/bloom/bloom.wgsl",
    @embedded_asset.asset_text_to_bytes(post_process_bloom_bloom_wgsl_source),
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "post_process/effect_stack/chromatic_aberration.wgsl",
    @embedded_asset.asset_text_to_bytes(
      post_process_effect_stack_chromatic_aberration_wgsl_source,
    ),
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "post_process/effect_stack/post_process.wgsl",
    @embedded_asset.asset_text_to_bytes(
      post_process_effect_stack_post_process_wgsl_source,
    ),
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "post_process/effect_stack/vignette.wgsl",
    @embedded_asset.asset_text_to_bytes(
      post_process_effect_stack_vignette_wgsl_source,
    ),
  )
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "post_process/motion_blur/motion_blur.wgsl",
    @embedded_asset.asset_text_to_bytes(
      post_process_motion_blur_motion_blur_wgsl_source,
    ),
  )
}
