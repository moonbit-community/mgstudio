// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
type RenderLayers = @camera_render_layers.RenderLayers

///|
type Viewport = @camera_viewport.Viewport

///|
type RenderTargetInfo = @camera_computed.RenderTargetInfo

///|
type ComputedCameraValues = @camera_computed.ComputedCameraValues

///|
type ClearColor = @camera_clear_color.ClearColor

///|
type Anchor = @sprite.Anchor

///|
pub type BorderRect = @sprite.BorderRect

///|
type ComputedTextureSlices = @sprite.ComputedTextureSlices

///|
type Sprite = @sprite.Sprite

///|
type SpriteImageMode = @sprite.SpriteImageMode

///|
type SpriteScalingMode = @sprite.SpriteScalingMode

///|
type TextureSlicer = @sprite.TextureSlicer

///|
type TextureSlice = @sprite.TextureSlice

///|
type ColorMaterial = @sprite_render_mesh2d_color_material.ColorMaterial

///|
type ColorMaterialPlugin = @sprite_render_mesh2d_color_material.ColorMaterialPlugin

///|
type AlphaMode2d = @sprite_render_mesh2d_material.AlphaMode2d

///|
type PreparedMaterial2d[M] = @sprite_render_mesh2d_material.PreparedMaterial2d[
  M,
]

///|
type RenderMaterial2dInstances[M] = @sprite_render_mesh2d_material.RenderMaterial2dInstances[
  M,
]

///|
type Material2dRuntimeRegistry = @sprite_render_mesh2d_material.Material2dRuntimeRegistry

///|
type SpriteMeshPlugin = @sprite_render_sprite_mesh.SpriteMeshPlugin

///|
type DefaultGizmoConfigGroup = @sprite.DefaultGizmoConfigGroup

///|
type Mesh2dWireframe = @sprite_render_mesh2d_wireframe2d.Mesh2dWireframe

///|
let ecs_key_anchor : @ecs.ComponentKey[Anchor] = @sprite.ecs_key_anchor

///|
let ecs_key_render_layers : @ecs.ComponentKey[RenderLayers] = @camera_render_layers.ecs_key_render_layers

///|
let ecs_key_computed_texture_slices : @ecs.ComponentKey[ComputedTextureSlices] = @sprite.ecs_key_computed_texture_slices

///|
let ecs_key_mesh2d_wireframe : @ecs.ComponentKey[Mesh2dWireframe] = @sprite_render_mesh2d_wireframe2d.ecs_key_mesh2d_wireframe

///|
let sprite_systems_compute_slices : @app.SystemSet = @sprite.sprite_systems_compute_slices

///|
fn apply_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  image_mode : SpriteImageMode,
  has_custom_size : Bool,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2, Bool) {
  @sprite.apply_sprite_image_mode(
    uv_min, uv_max, draw_scale, region_size, image_mode, has_custom_size,
  )
}

///|
fn apply_scale_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  scaling_mode : SpriteScalingMode,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2) {
  @sprite.apply_scale_sprite_image_mode(
    uv_min, uv_max, draw_scale, region_size, scaling_mode,
  )
}

///|
fn compute_sprite_slices_from_rect(
  sprite : Sprite,
  image_size : @math.Vec2,
  texture_rect : @math.Rect,
) -> ComputedTextureSlices? {
  @sprite.compute_sprite_slices_from_rect(sprite, image_size, texture_rect)
}

///|
fn compute_slices_on_sprite_change_system(
  commands : @app.Commands,
  assets : @sprite.ComputedSlicesAssetParams,
  changed_sprites : @sprite.ComputedSlicesChangedSpritesQuery,
) -> Unit {
  @sprite.compute_slices_on_sprite_change_system(
    commands, assets, changed_sprites,
  )
}

///|
fn compute_slices_on_asset_event_system(
  commands : @app.Commands,
  assets : @sprite.ComputedSlicesAssetParams,
  params : @sprite.ComputedSlicesAssetEventParams,
) -> Unit {
  @sprite.compute_slices_on_asset_event_system(commands, assets, params)
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] material2d_runtime_type_name(
  probe : @asset.Handle[M],
) -> String {
  @sprite_render_mesh2d_material.material2d_runtime_type_name(probe)
}

///|
fn[M] prepared_material2d_alpha_phase(material : PreparedMaterial2d[M]) -> Int? {
  @sprite_render_mesh2d_material.prepared_material2d_alpha_phase(material)
}

///|
fn[M] prepared_material2d_get(
  prepared_assets : @renderer.RenderAssets[PreparedMaterial2d[M]],
  handle : @asset.Handle[PreparedMaterial2d[M]],
) -> PreparedMaterial2d[M]? {
  @sprite_render_mesh2d_material.prepared_material2d_get(
    prepared_assets, handle,
  )
}

///|
fn[M] prepared_material2d_handle_for_mesh(
  mesh : ExtractedMesh2d,
  material_instances : RenderMaterial2dInstances[M],
) -> @asset.Handle[PreparedMaterial2d[M]]? {
  @sprite_render_mesh2d_material.prepared_material2d_handle_for_mesh(
    mesh, material_instances,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] prepared_material2d_assets_or_empty(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> @renderer.RenderAssets[PreparedMaterial2d[M]] {
  @sprite_render_mesh2d_material.prepared_material2d_assets_or_empty(
    world, probe,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] render_material2d_instances_or_empty(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> RenderMaterial2dInstances[M] {
  @sprite_render_mesh2d_material.render_material2d_instances_or_empty(
    world, probe,
  )
}

///|
fn material2d_runtime_registry_or_empty(
  world : @ecs.World,
) -> Material2dRuntimeRegistry {
  @sprite_render_mesh2d_material.material2d_runtime_registry_or_empty(world)
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] material2d_pipeline_or_default(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> @sprite_render_mesh2d_material.Material2dPipeline[M] {
  @sprite_render_mesh2d_material.material2d_pipeline_or_default(world, probe)
}

///|
fn draw_registered_material2d_mesh_item(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  runtime_index : Int,
  mesh : ExtractedMesh2d,
) -> Unit {
  @sprite_render_mesh2d_material.draw_registered_material2d_mesh_item(
    world, registry, runtime_index, mesh,
  )
}

///|
fn material2d_runtime_registry_contains_entity(
  source_world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  entity : @core.Entity,
) -> Bool {
  @sprite_render_mesh2d_material.material2d_runtime_registry_contains_entity(
    source_world, registry, entity,
  )
}

///|
fn material2d_runtime_phase_for_draw(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  mesh : ExtractedMesh2d,
) -> (Int, Int)? {
  @sprite_render_mesh2d_material.material2d_runtime_phase_for_draw(
    world, registry, mesh,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] draw_material2d_mesh_item(
  mesh : ExtractedMesh2d,
  prepared_assets : @renderer.RenderAssets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  pipeline : @sprite_render_mesh2d_material.Material2dPipeline[M],
) -> Unit {
  @sprite_render_mesh2d_material.draw_material2d_mesh_item(
    mesh, prepared_assets, material_instances, pipeline,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] draw_material2d_mesh_item_with_prepared_material(
  mesh : ExtractedMesh2d,
  material : PreparedMaterial2d[M],
  pipeline : @sprite_render_mesh2d_material.Material2dPipeline[M],
) -> Unit {
  @sprite_render_mesh2d_material.draw_material2d_mesh_item_with_prepared_material(
    mesh, material, pipeline,
  )
}

///|
fn[M] render_material2d_instances_for_tests(
  instances_info : Array[(@core.Entity, @asset.Handle[M])],
) -> RenderMaterial2dInstances[M] {
  @sprite_render_mesh2d_material.render_material2d_instances_for_tests(
    instances_info,
  )
}

///|
fn prepared_color_materials_for_tests(
  materials : Array[(@asset.Handle[ColorMaterial], ColorMaterial)],
) -> @renderer.RenderAssets[PreparedMaterial2d[ColorMaterial]] {
  @sprite_render_mesh2d_color_material.prepared_color_materials_for_tests(
    materials,
  )
}

///|
fn wireframe2d_material_color(
  world : @ecs.World,
  wireframe : Mesh2dWireframe,
) -> @color.Color {
  @sprite_render_mesh2d_wireframe2d.wireframe2d_material_color(world, wireframe)
}

///|
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  @sprite.render2d_upload_mesh_handle(mesh)
}

///|
pub fn render2d_create_render_target_ecs(
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @renderer.host_gpu_create_render_target(width~, height~, nearest~)
  @asset.Handle::new(id)
}

///|
fn ensure_render2d_required_components(world : @ecs.World) -> Unit {
  @sprite.ensure_render2d_required_components(world)
}

///|
fn init_gizmo_group(
  app : @app.App[@ecs.World],
  group : DefaultGizmoConfigGroup,
) -> @app.App[@ecs.World] {
  @sprite.init_gizmo_group(app, group)
}

///|
fn gizmos_prepare(world : @ecs.World) -> Unit {
  @sprite.gizmos_prepare(world)
}

///|
fn gizmos_clear() -> Unit {
  @sprite.gizmos_clear()
}

///|
fn gizmos_reset() -> Unit {
  @sprite.gizmos_reset()
}

///|
fn gizmos_draw_lines(layers : RenderLayers) -> Unit {
  @sprite.gizmos_draw_lines(layers)
}

///|
/// UI corner radii (top-left, top-right, bottom-right, bottom-left) in logical pixels.
pub type UiCornerRadii = @ui_render_runtime.UiCornerRadii

///|
type Mesh2d = @mesh.Mesh2d

///|
fn uploaded_mesh_base_radius(mesh_id : Int) -> Float {
  @sprite.uploaded_mesh_base_radius(mesh_id)
}

///|
fn bloom2d_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn bloom2d_clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn bloom2d_safe_max_mip_dimension(value : Int) -> Int {
  if value < 4 {
    4
  } else {
    value
  }
}

///|
fn bloom2d_safe_scale_axis(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render2d_sanitize_bloom(bloom : @post_process.Bloom) -> @post_process.Bloom {
  @post_process.Bloom::new(bloom.intensity)
  .with_low_frequency_boost(bloom.low_frequency_boost)
  .with_low_frequency_boost_curvature(bloom.low_frequency_boost_curvature)
  .with_high_pass_frequency(bloom.high_pass_frequency)
  .with_prefilter(bloom.prefilter.threshold, bloom.prefilter.threshold_softness)
  .with_composite_mode(bloom.composite_mode)
  .with_max_mip_dimension(
    bloom2d_safe_max_mip_dimension(bloom.max_mip_dimension),
  )
  .with_scale(
    @math.Vec2::new(
      bloom2d_safe_scale_axis(bloom.scale.x),
      bloom2d_safe_scale_axis(bloom.scale.y),
    ),
  )
}

///|
fn bloom2d_log2_floor(value : Int) -> Int {
  let mut current = value
  let mut power = 0
  while current > 1 {
    current = current / 2
    power = power + 1
  }
  power
}

///|
fn bloom2d_mip_count(bloom : @post_process.Bloom) -> Int {
  let logv = bloom2d_log2_floor(
    bloom2d_safe_max_mip_dimension(bloom.max_mip_dimension),
  )
  let mip_count = if logv < 2 { 1 } else { logv - 1 }
  if mip_count < 1 {
    1
  } else {
    mip_count
  }
}

///|
fn bloom2d_prefilter_weight(bloom : @post_process.Bloom) -> Float {
  let threshold = bloom2d_clamp_non_negative(bloom.prefilter.threshold)
  let softness = bloom2d_clamp_unit(bloom.prefilter.threshold_softness)
  // Approximate prefilter attenuation in sprite-overlay bloom path.
  let attenuation = 1.0F + threshold * (1.0F - softness * 0.5F)
  if attenuation <= 0.0F {
    1.0F
  } else {
    1.0F / attenuation
  }
}

///|
fn bloom2d_compute_blend_factor(
  bloom : @post_process.Bloom,
  mip : Float,
  max_mip : Float,
) -> Float {
  if max_mip <= 0.0F {
    return bloom.intensity
  }
  let mip_ratio = bloom2d_clamp_unit(mip / max_mip)
  let curvature = bloom2d_clamp_unit(bloom.low_frequency_boost_curvature)
  let exponent = if curvature >= 0.9999F {
    10_000.0F
  } else {
    1.0F / (1.0F - curvature)
  }
  let mut lf_boost = (1.0F - @math.pow(1.0F - mip_ratio, exponent)) *
    bloom.low_frequency_boost
  let high_pass = bloom2d_clamp_unit(bloom.high_pass_frequency)
  let high_pass_lq = if high_pass <= 1.0e-6F {
    if mip_ratio <= 0.0F {
      1.0F
    } else {
      0.0F
    }
  } else {
    1.0F - bloom2d_clamp_unit((mip_ratio - high_pass) / high_pass)
  }
  let mode_factor = match bloom.composite_mode {
    EnergyConserving => 1.0F - bloom.intensity
    Additive => 1.0F
  }
  lf_boost = lf_boost * mode_factor
  (bloom.intensity + lf_boost) * high_pass_lq
}

///|
fn bloom2d_pass_scale_factor(
  bloom : @post_process.Bloom,
  pass_index : Int,
  max_mip : Int,
) -> @math.Vec2 {
  let max_mip_float = if max_mip <= 0 { 1.0F } else { Float::from_int(max_mip) }
  let pass_ratio = bloom2d_clamp_unit(
    Float::from_int(pass_index) / max_mip_float,
  )
  let blur_scale = 0.35F * (0.2F + pass_ratio * 0.8F)
  @math.Vec2::new(
    1.0F + blur_scale * bloom.scale.x,
    1.0F + blur_scale * bloom.scale.y,
  )
}

///|
pub fn render2d_draw_bloom_overlay(
  world : @ecs.World,
  source : @asset.Handle[@asset.Image],
  base_transform : @transform.Transform,
  bloom : @post_process.Bloom,
  layers : RenderLayers,
) -> Unit {
  let bloom = render2d_sanitize_bloom(bloom)
  let mip_count = bloom2d_mip_count(bloom)
  let max_mip = mip_count - 1
  let max_mip_f = if max_mip <= 0 { 1.0F } else { Float::from_int(max_mip) }
  let prefilter_weight = bloom2d_prefilter_weight(bloom)
  for pass in 0..<mip_count {
    let pass_f = Float::from_int(pass)
    let blend = bloom2d_compute_blend_factor(bloom, pass_f, max_mip_f)
    let alpha_weight = blend * prefilter_weight / Float::from_int(mip_count)
    if alpha_weight <= 0.0F {
      continue
    }
    let scale_factor = bloom2d_pass_scale_factor(bloom, pass, max_mip)
    let pass_transform = @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(
        base_transform.translation.x,
        base_transform.translation.y,
      ),
      base_transform.rotation_z(),
      @math.Vec2::new(
        base_transform.scale.x * scale_factor.x,
        base_transform.scale.y * scale_factor.y,
      ),
      z=base_transform.translation.z + pass_f * 0.001F,
    )
    render2d_push_sprite_uv(
      world,
      source,
      pass_transform,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::new(1.0F, 1.0F, 1.0F, alpha_weight),
      layers,
    )
  }
}

///|
const MESH2D_SHADER_PATH : String = "sprite_render/mesh2d/mesh2d.wgsl"

///|
const MESH2D_SHADER_BINDINGS_PATH : String = "sprite_render/mesh2d/mesh2d_bindings.wgsl"

///|
const MESH2D_WIREFRAME_SHADER_PATH : String = "sprite_render/mesh2d/wireframe2d.wgsl"

///|
const SPRITE_SHADER_PATH : String = "sprite_render/render/sprite.wgsl"

///|
const SPRITE_VIEW_BINDINGS_PATH : String = "sprite_render/render/sprite_view_bindings.wgsl"

///|
fn render2d_shader_asset_paths() -> Array[String] {
  [
    MESH2D_SHADER_PATH,
    MESH2D_SHADER_BINDINGS_PATH,
    "sprite_render/mesh2d/color_material.wgsl",
    "sprite_render/mesh2d/mesh2d_functions.wgsl",
    "sprite_render/mesh2d/mesh2d_types.wgsl",
    "sprite_render/mesh2d/mesh2d_vertex_output.wgsl",
    "sprite_render/mesh2d/mesh2d_view_bindings.wgsl",
    "sprite_render/mesh2d/mesh2d_view_types.wgsl",
    MESH2D_WIREFRAME_SHADER_PATH,
    SPRITE_SHADER_PATH,
    SPRITE_VIEW_BINDINGS_PATH,
  ]
}

///|
fn register_render2d_shader_sources(world : @ecs.World) -> Unit {
  world |> ignore
  for path in render2d_shader_asset_paths() {
    let source = @shader_source.embedded_shader_source_required(path) catch {
      err =>
        abort(
          "failed to load render2d shader asset text: \{path}: \{err.message()}",
        )
    }
    @renderer.register_wgsl_source(path, source)
  }
}

///|
priv struct Render2dCameraPostprocessPlan {
  uses_intermediate_source : Bool
  apply_bloom_before_tonemapping : Bool
  tonemapping_stage_enabled : Bool
  cas_postprocess_enabled : Bool
  draw_ui_overlay_after_postprocess : Bool
}

///|
fn render2d_camera_postprocess_plan(
  bloom : @post_process.Bloom?,
  tonemapping_mode : Int,
  color_grading : @post_process.ColorGrading?,
  contrast_adaptive_sharpening : @cas.ContrastAdaptiveSharpening?,
) -> Render2dCameraPostprocessPlan {
  let tonemapping_enabled = render2d_tonemapping_stage_enabled(
    tonemapping_mode, color_grading,
  )
  let cas_enabled = render2d_cas_enabled(contrast_adaptive_sharpening)
  let uses_intermediate_source = bloom is Some(_) ||
    tonemapping_enabled ||
    cas_enabled
  Render2dCameraPostprocessPlan::{
    uses_intermediate_source,
    apply_bloom_before_tonemapping: bloom is Some(_),
    tonemapping_stage_enabled: tonemapping_enabled,
    cas_postprocess_enabled: cas_enabled,
    draw_ui_overlay_after_postprocess: uses_intermediate_source,
  }
}

///|
fn render2d_draw_camera_tonemapping(
  world : @ecs.World,
  source : @asset.Handle[@asset.Image],
  tonemapping_mode : Int,
  deband_dither_enabled : Bool,
  color_grading : @post_process.ColorGrading?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let luts = @core_pipeline.tonemapping_luts_from_world_or_init(world)
  let color_grading_uniform = @renderer.host_color_grading_from_post_process(
    color_grading,
  )
  @renderer.host_gpu_draw_tonemapping2d(
    scene_texture_id=source.id(),
    exposure=1.0F,
    tonemapping_mode~,
    deband_dither_enabled=if deband_dither_enabled { 1 } else { 0 },
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony_mc_mapface.id(),
    blender_lut_texture_id=luts.blender_filmic.id(),
    color_grading=color_grading_uniform,
  )
}

///|
fn render2d_draw_camera_blit(source : @asset.Handle[@asset.Image]) -> Unit {
  @renderer.host_gpu_draw_blit(scene_texture_id=source.id())
}

///|
fn render2d_cas_enabled(cas : @cas.ContrastAdaptiveSharpening?) -> Bool {
  match cas {
    Some(value) => value.enabled && value.sharpening_strength > 0.0F
    None => false
  }
}

///|
fn render2d_draw_camera_cas(
  source : @asset.Handle[@asset.Image],
  cas : @cas.ContrastAdaptiveSharpening?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  guard render2d_cas_enabled(cas) else { return }
  guard cas is Some(value) else { return }
  @renderer.host_gpu_draw_contrast_adaptive_sharpening(
    scene_texture_id=source.id(),
    sharpness=value.sharpening_strength,
    denoise=value.denoise,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render2d_apply_camera_bloom_from_source(
  camera : ExtractedCamera2d,
  source : @asset.Handle[@asset.Image],
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  guard camera.bloom is Some(bloom) else { return }
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let settings = render2d_sanitize_bloom(bloom)
  @renderer.host_gpu_apply_bloom(
    scene_texture_id=source.id(),
    intensity=settings.intensity,
    low_frequency_boost=settings.low_frequency_boost,
    low_frequency_boost_curvature=settings.low_frequency_boost_curvature,
    high_pass_frequency=settings.high_pass_frequency,
    threshold=settings.prefilter.threshold,
    threshold_softness=settings.prefilter.threshold_softness,
    composite_mode=match settings.composite_mode {
      EnergyConserving => 0
      Additive => 1
    },
    max_mip_dimension=settings.max_mip_dimension,
    scale_x=settings.scale.x,
    scale_y=settings.scale.y,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
type PhaseEntityRef = @sprite_render_mesh2d_runtime.PhaseEntityRef

///|
fn phase_entity_ref_for_main(main_entity : @core.Entity) -> PhaseEntityRef {
  @sprite_render_mesh2d_runtime.phase_entity_ref_for_main(main_entity)
}

///|
fn phase_entity_ref_placeholder() -> PhaseEntityRef {
  @sprite_render_mesh2d_runtime.phase_entity_ref_placeholder()
}

///|
fn phase_entity_ref_cmp(lhs : PhaseEntityRef, rhs : PhaseEntityRef) -> Int {
  @sprite_render_mesh2d_runtime.phase_entity_ref_cmp(lhs, rhs)
}

///|
priv struct SpriteDrawPayload {
  transform : @transform.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : @color.Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  scissor : @math.Rect?
}

///|
priv struct SpriteSliceBatchDrawPayload {
  rotation : Float
  draw_scale : @math.Vec2
  z : Float
  color : @color.Color
  cull_center : @math.Vec2
  cull_half_size : @math.Vec2
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  scissor : @math.Rect?
  slices_xy_uv : Array[Float]
}

///|
priv struct ComputedSpriteSlicesDrawPayload {
  transform : @transform.Transform
  color : @color.Color
  texture : @asset.Handle[@asset.Image]
  layers : RenderLayers
  flip_x : Bool
  flip_y : Bool
  scissor : @math.Rect?
  image_size : @math.Vec2
  slices : Array[TextureSlice]
}

///|
priv struct ExtractedSprite {
  entity : PhaseEntityRef
  payload : SpriteDrawPayload
}

///|
priv struct ExtractedComputedSpriteSlices {
  entity : PhaseEntityRef
  payload : ComputedSpriteSlicesDrawPayload
}

///|
type ExtractedUiSprite = @ui_render_runtime.ExtractedUiSprite

///|
priv struct ExtractedSpriteSliceBatch {
  entity : PhaseEntityRef
  payload : SpriteSliceBatchDrawPayload
}

///|
type ExtractedUiSpriteSliceBatch = @ui_render_runtime.ExtractedUiSpriteSliceBatch

///|
type UiRectDrawPayload = @ui_render_runtime.UiRectDrawPayload

///|
type ExtractedUiRect = @ui_render_runtime.ExtractedUiRect

///|
type ExtractedUiBoxShadow = @ui_render_runtime.ExtractedUiBoxShadow

///|
type ExtractedUiTextureSlice = @ui_render_runtime.ExtractedUiTextureSlice

///|
priv struct ExtractedCamera2d {
  entity : @core.Entity
  camera : @camera_camera.Camera
  projection : @camera_projection2d.OrthographicProjection
  transform : @transform.Transform
  target : @camera_camera.RenderTarget
  layers : RenderLayers
  bloom : @post_process.Bloom?
  compositing_space : @camera_compositing_space.CompositingSpace?
  target_format_raw : UInt
  tonemapping_mode : Int
  deband_dither_enabled : Bool
  color_grading : @post_process.ColorGrading?
  contrast_adaptive_sharpening : @cas.ContrastAdaptiveSharpening?
  computed : CameraComputed
}

///|
priv struct CameraComputed {
  target_size : @math.IVec2
  scale_factor : Float
}

///|
fn render2d_extracted_camera_compositing_space(
  camera : ExtractedCamera2d,
) -> @camera_compositing_space.CompositingSpace? {
  camera.compositing_space
}

///|
fn render2d_extracted_camera_target_format_raw(
  camera : ExtractedCamera2d,
) -> UInt {
  camera.target_format_raw
}

///|
type Mesh2dDrawPayload = @sprite_render_mesh2d_runtime.Mesh2dDrawPayload

///|
type ExtractedMesh2d = @sprite_render_mesh2d_runtime.ExtractedMesh2d

///|
priv enum DrawKind {
  SpriteMain(Int)
  SpriteSliceBatchMain(Int)
  SpriteExtra(Int)
  SpriteSliceBatchExtra(Int)
  UiSpriteExtra(Int)
  UiSpriteSliceBatchExtra(Int)
  UiRectExtra(Int)
  UiBoxShadowExtra(Int)
  UiTextureSliceExtra(Int)
  Mesh(Int)
  CustomMesh(Int)
}

///|
priv struct DrawItem {
  kind : DrawKind
  entity : PhaseEntityRef
  z : Float
  // 0 = scene opaque/mask, 1 = scene transparent, 2 = UI overlay.
  phase : Int
  // Stable insertion order tie-break key.
  tie : Int
  material_handle_id : Int
  material_runtime_index : Int
}

///|
priv struct ScenePhaseDrawItems {
  opaque_items : Array[DrawItem]
  transparent_items : Array[DrawItem]
}

///|
priv struct QueuedCameraDrawItems {
  camera_entity : @core.Entity
  scene_opaque_items : Array[DrawItem]
  scene_transparent_items : Array[DrawItem]
  ui_overlay_items : Array[DrawItem]
}

///|
priv struct RuntimeRenderTargetInfo {
  id : Int
  width : Int
  height : Int
}

///|
priv struct PostProcessIntermediateTargetInfo {
  camera : @core.Entity
  slot : Int
  width : Int
  height : Int
  target : @asset.Handle[@asset.Image]
}

///|
struct RenderState {
  mut draw_enabled : Bool
  mut primary_camera : @core.Entity
  sprites : Array[ExtractedSprite]
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices]
  extra_sprites : Array[ExtractedSprite]
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch]
  cameras : Array[ExtractedCamera2d]
  meshes : Array[ExtractedMesh2d]
  render_targets : Array[RuntimeRenderTargetInfo]
  postprocess_intermediate_targets : Array[PostProcessIntermediateTargetInfo]
  // Prepare stage output: stable camera iteration order for the frame.
  mut prepared_camera_indices : Array[Int]
  // Queue stage output: per-camera queued item counts for diagnostics/sanity.
  mut queued_draw_item_counts : Array[Int]
  // Queue stage output: cached draw items per camera for execute stage reuse.
  mut queued_camera_draw_items : Array[QueuedCameraDrawItems]
}

///|
priv struct Render2dRuntimeState {
  mut diagnostic_queued_draw_item_count : Int
  mut diagnostic_prepared_camera_count : Int
  mut diagnostic_queue_cpu_ms : Float
  mut diagnostic_execute_cpu_ms : Float
  mut render_state_serde_next_id : Int
}

///|
let render2d_runtime_state : Render2dRuntimeState = {
  diagnostic_queued_draw_item_count: 0,
  diagnostic_prepared_camera_count: 0,
  diagnostic_queue_cpu_ms: 0.0F,
  diagnostic_execute_cpu_ms: 0.0F,
  render_state_serde_next_id: 1,
}

///|
fn RenderState::new() -> RenderState {
  RenderState::{
    draw_enabled: false,
    primary_camera: @core.Entity::placeholder(),
    sprites: [],
    sprite_slice_batches: [],
    extra_sprites: [],
    extra_sprite_slice_batches: [],
    cameras: [],
    meshes: [],
    render_targets: [],
    postprocess_intermediate_targets: [],
    prepared_camera_indices: [],
    queued_draw_item_counts: [],
    queued_camera_draw_items: [],
  }
}

///|
let ecs_key_render_state : @ecs.ResourceKey[RenderState] = @ecs.register_resource(
  debug_name="render2d.render_state",
)

///|
fn get_render_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[RenderState] {
  world.resource(ecs_key_render_state)
}

///|
let render_state_serde_values : Map[Int, RenderState] = {}

///|
pub impl ToJson for RenderState with fn to_json(self) {
  let id = render2d_runtime_state.render_state_serde_next_id
  render2d_runtime_state.render_state_serde_next_id = id + 1
  render_state_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for RenderState with fn from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  render_state_serde_values.get(id).unwrap_or(RenderState::new())
}

///|
fn render_state_ref(world : @ecs.World) -> RenderState? {
  get_render_state_resource(world).get()
}

///|
fn render_state_update(
  world : @ecs.World,
  update : (RenderState) -> Unit,
) -> Bool {
  let res = get_render_state_resource(world)
  guard res.get() is Some(state_value) else { return false }
  let state = state_value
  update(state)
  res.insert(state)
  true
}

///|
fn ensure_render_state_resource(world : @ecs.World) -> Unit {
  let res = get_render_state_resource(world)
  if !res.is_present() {
    res.insert(RenderState::new())
    gizmos_reset()
  }
}

///|
pub fn init_render_state_system(world : @ecs.World) -> Unit {
  ensure_render_state_resource(world)
}

///|
fn default_uv_min() -> @math.Vec2 {
  @math.Vec2::new(0.0F, 0.0F)
}

///|
fn default_uv_max() -> @math.Vec2 {
  @math.Vec2::new(1.0F, 1.0F)
}

///|
priv struct SpriteUvInfo {
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  image_size : @math.Vec2
  // Pixel size of the resolved sprite region (image rect / atlas rect / sprite rect).
  // This is used to interpret `Sprite.custom_size` as a final size (Bevy-style),
  // while the host expects a scale factor.
  region_size : @math.Vec2
}

///|
fn sprite_vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn sprite_vec2_mul(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x * b.x, a.y * b.y)
}

///|
fn sprite_draw_scale(
  sprite : Sprite,
  transform_scale : @math.Vec2,
  region_size : @math.Vec2,
) -> @math.Vec2 {
  match sprite.custom_size {
    None => transform_scale
    Some(custom_size) => {
      // The host's sprite shader uses a fixed 128x128 quad and scales it by:
      //   host_scale * (region_pixels / 128)
      // To make `custom_size` represent a final size in world units, we convert
      // it into a scale factor relative to the region size here.
      let denom_x = if region_size.x == 0.0F { 1.0F } else { region_size.x }
      let denom_y = if region_size.y == 0.0F { 1.0F } else { region_size.y }
      let factor = @math.Vec2::new(
        custom_size.x / denom_x,
        custom_size.y / denom_y,
      )
      sprite_vec2_mul(transform_scale, factor)
    }
  }
}

///|
fn sprite_anchor_offset(
  anchor : Anchor,
  rotation : Float,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  local_offset : @math.Vec2,
) -> @math.Vec2 {
  let a = anchor.as_vec()
  let offset_local = @math.Vec2::new(
    -a.x * draw_scale.x * region_size.x + local_offset.x,
    -a.y * draw_scale.y * region_size.y + local_offset.y,
  )
  let cosv = @math.cos(rotation)
  let sinv = @math.sin(rotation)
  @math.Vec2::new(
    offset_local.x * cosv - offset_local.y * sinv,
    offset_local.x * sinv + offset_local.y * cosv,
  )
}

///|
fn swap_float_pair(a : Float, b : Float) -> (Float, Float) {
  (b, a)
}

///|
fn sprite_uv_from_sprite(
  sprite : Sprite,
  texture_atlas_layouts : @asset.Assets[@asset.TextureAtlasLayout]?,
) -> SpriteUvInfo? {
  let texture_id = sprite.image.id()
  let mut image_width = @asset.host_asset_texture_width(texture_id)
  let mut image_height = @asset.host_asset_texture_height(texture_id)
  if image_width <= 0 || image_height <= 0 {
    // Avoid division by zero for not-yet-loaded textures.
    image_width = 1
    image_height = 1
  }
  let image_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(
      Float::from_double(image_width.to_double()),
      Float::from_double(image_height.to_double()),
    ),
  )
  let atlas_rect = match sprite.texture_atlas {
    Some(atlas) =>
      match texture_atlas_layouts {
        Some(layouts) =>
          atlas.texture_rect(layouts).map(fn(value) { value.as_rect() })
        None =>
          abort(
            "TextureAtlasLayout assets resource is missing; add AssetPlugin before extracting atlas sprites",
          )
      }
    None => None
  }
  let texture_rect = match (atlas_rect, sprite.rect) {
    (None, None) => image_rect
    (None, Some(r)) => r
    (Some(ar), None) => ar
    (Some(ar), Some(r)) => {
      let min = sprite_vec2_add(r.min, ar.min)
      let max = sprite_vec2_add(r.max, ar.min)
      @math.Rect::new(min, max)
    }
  }
  let denom_x = Float::from_double(image_width.to_double())
  let denom_y = Float::from_double(image_height.to_double())
  if denom_x <= 0.0F || denom_y <= 0.0F {
    return None
  }
  let region_size = @math.Vec2::new(
    texture_rect.max.x - texture_rect.min.x,
    texture_rect.max.y - texture_rect.min.y,
  )
  let mut uv_min = @math.Vec2::new(
    texture_rect.min.x / denom_x,
    texture_rect.min.y / denom_y,
  )
  let mut uv_max = @math.Vec2::new(
    texture_rect.max.x / denom_x,
    texture_rect.max.y / denom_y,
  )
  if sprite.flip_x {
    let pair = swap_float_pair(uv_min.x, uv_max.x)
    uv_min = @math.Vec2::new(pair.0, uv_min.y)
    uv_max = @math.Vec2::new(pair.1, uv_max.y)
  }
  if sprite.flip_y {
    let pair = swap_float_pair(uv_min.y, uv_max.y)
    uv_min = @math.Vec2::new(uv_min.x, pair.0)
    uv_max = @math.Vec2::new(uv_max.x, pair.1)
  }
  Some(SpriteUvInfo::{
    uv_min,
    uv_max,
    image_size: @math.Vec2::new(denom_x, denom_y),
    region_size,
  })
}

///|
fn sprite_rotate_offset(offset : @math.Vec2, rotation : Float) -> @math.Vec2 {
  let cosv = @math.cos(rotation)
  let sinv = @math.sin(rotation)
  @math.Vec2::new(
    offset.x * cosv - offset.y * sinv,
    offset.x * sinv + offset.y * cosv,
  )
}

///|
fn append_computed_sprite_slices(
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  entity : @core.Entity,
  sprite : Sprite,
  computed_slices : ComputedTextureSlices?,
  anchor : Anchor,
  transform : @transform.Transform,
  layers : RenderLayers,
  scissor : @math.Rect?,
  image_size : @math.Vec2,
) -> Bool {
  guard computed_slices is Some(computed_slices) else { return false }
  sprite_slice_batches.push(ExtractedComputedSpriteSlices::{
    entity: phase_entity_ref_for_main(entity),
    payload: ComputedSpriteSlicesDrawPayload::{
      transform,
      color: sprite.color,
      texture: sprite.image,
      layers,
      flip_x: sprite.flip_x,
      flip_y: sprite.flip_y,
      scissor,
      image_size,
      slices: computed_slices.extract_slices(sprite, anchor),
    },
  })
  true
}

///|
pub fn render2d_create_render_target(
  world : @ecs.World,
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @renderer.host_gpu_create_render_target(width~, height~, nearest~)
  ensure_render_state_resource(world)
  let res = get_render_state_resource(world)
  if res.get() is Some(state_value) {
    let rs = state_value
    rs.render_targets.push(RuntimeRenderTargetInfo::{ id, width, height })
    res.insert(rs)
  }
  @asset.Handle::new(id)
}

///|
pub fn render2d_clear_overlay_sprites(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) {
    rs.extra_sprites.clear()
    rs.extra_sprite_slice_batches.clear()
  })
  |> ignore
}

///|
pub fn render2d_push_sprite_uv(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : @color.Color,
  layers : RenderLayers,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.extra_sprites.push(ExtractedSprite::{
      entity: phase_entity_ref_placeholder(),
      payload: SpriteDrawPayload::{
        transform,
        anchor_offset: @math.Vec2::new(0.0F, 0.0F),
        draw_scale: @math.Vec2::new(transform.scale.x, transform.scale.y),
        color,
        texture,
        layers,
        uv_min,
        uv_max,
        scissor: None,
      },
    })
  })
  |> ignore
}

///|
pub fn render2d_push_sprite_uv_scissor(
  world : @ecs.World,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : @color.Color,
  layers : RenderLayers,
  scissor : @math.Rect?,
) -> Unit {
  render_state_update(world, fn(rs) {
    rs.extra_sprites.push(ExtractedSprite::{
      entity: phase_entity_ref_placeholder(),
      payload: SpriteDrawPayload::{
        transform,
        anchor_offset: @math.Vec2::new(0.0F, 0.0F),
        draw_scale: @math.Vec2::new(transform.scale.x, transform.scale.y),
        color,
        texture,
        layers,
        uv_min,
        uv_max,
        scissor,
      },
    })
  })
  |> ignore
}

///|
pub(all) struct OverlaySpriteUvScissor {
  texture : @asset.Handle[@asset.Image]
  transform : @transform.Transform
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  color : @color.Color
  layers : RenderLayers
  scissor : @math.Rect?
  target_camera : @core.Entity?
}

///|
pub(all) struct OverlaySpriteUvScissorSlices {
  texture : @asset.Handle[@asset.Image]
  rotation : Float
  draw_scale : @math.Vec2
  z : Float
  color : @color.Color
  cull_center : @math.Vec2
  cull_half_size : @math.Vec2
  layers : RenderLayers
  scissor : @math.Rect?
  target_camera : @core.Entity?
  slices_xy_uv : Array[Float]
}

///|
pub fn render2d_push_sprite_uv_scissor_batch(
  world : @ecs.World,
  sprites : Array[OverlaySpriteUvScissor],
) -> Unit {
  if sprites.length() == 0 {
    return
  }
  render_state_update(world, fn(rs) {
    for sprite in sprites {
      let payload = SpriteDrawPayload::{
        transform: sprite.transform,
        anchor_offset: @math.Vec2::new(0.0F, 0.0F),
        draw_scale: @math.Vec2::new(
          sprite.transform.scale.x,
          sprite.transform.scale.y,
        ),
        color: sprite.color,
        texture: sprite.texture,
        layers: sprite.layers,
        uv_min: sprite.uv_min,
        uv_max: sprite.uv_max,
        scissor: sprite.scissor,
      }
      match sprite.target_camera {
        Some(camera_entity) =>
          @ui_render_runtime.push_extracted_ui_sprite(
            world,
            Some(camera_entity),
            @ui_render_runtime.UiSpriteDrawPayload::{
              transform: payload.transform,
              anchor_offset: payload.anchor_offset,
              draw_scale: payload.draw_scale,
              color: payload.color,
              texture: payload.texture,
              layers: payload.layers,
              uv_min: payload.uv_min,
              uv_max: payload.uv_max,
              scissor: payload.scissor,
            },
          )
        None =>
          rs.extra_sprites.push(ExtractedSprite::{
            entity: phase_entity_ref_placeholder(),
            payload,
          })
      }
    }
  })
  |> ignore
}

///|
pub fn render2d_push_sprite_uv_scissor_slices_batch(
  world : @ecs.World,
  sprite_batches : Array[OverlaySpriteUvScissorSlices],
) -> Unit {
  if sprite_batches.length() == 0 {
    return
  }
  render_state_update(world, fn(rs) {
    for batch in sprite_batches {
      if batch.slices_xy_uv.length() == 0 {
        continue
      }
      let payload = SpriteSliceBatchDrawPayload::{
        rotation: batch.rotation,
        draw_scale: batch.draw_scale,
        z: batch.z,
        color: batch.color,
        cull_center: batch.cull_center,
        cull_half_size: batch.cull_half_size,
        texture: batch.texture,
        layers: batch.layers,
        scissor: batch.scissor,
        slices_xy_uv: batch.slices_xy_uv,
      }
      match batch.target_camera {
        Some(camera_entity) =>
          @ui_render_runtime.push_extracted_ui_sprite_slice_batch(
            world,
            Some(camera_entity),
            @ui_render_runtime.UiSpriteSliceBatchDrawPayload::{
              rotation: payload.rotation,
              draw_scale: payload.draw_scale,
              z: payload.z,
              color: payload.color,
              cull_center: payload.cull_center,
              cull_half_size: payload.cull_half_size,
              texture: payload.texture,
              layers: payload.layers,
              scissor: payload.scissor,
              slices_xy_uv: payload.slices_xy_uv,
            },
          )
        None =>
          rs.extra_sprite_slice_batches.push(ExtractedSpriteSliceBatch::{
            entity: phase_entity_ref_placeholder(),
            payload,
          })
      }
    }
  })
  |> ignore
}

///|
pub fn render2d_clear_overlay_ui_sprites(world : @ecs.World) -> Unit {
  @ui_render_runtime.clear_extracted_ui_sprites(world)
}

///|
fn render2d_find_render_target_size(
  state : RenderState,
  id : Int,
) -> RuntimeRenderTargetInfo? {
  for target in state.render_targets {
    if target.id == id {
      return Some(target)
    }
  }
  None
}

///|
priv struct RenderTargetComputed {
  size : @math.IVec2
  scale_factor : Float
}

///|
fn render2d_targets_host_window(target : @camera_camera.RenderTarget) -> Bool {
  match target {
    Screen => true
    Window(_) => true
    Image(_) => false
  }
}

///|
fn render2d_window_target_info(
  world : @ecs.World,
  window_ref : @window.WindowRef,
) -> RenderTargetComputed? {
  let width = @window.window_physical_width_for(world, window_ref)
  let height = @window.window_physical_height_for(world, window_ref)
  if width <= 0 || height <= 0 {
    return None
  }
  let mut scale_factor = @window.window_scale_factor_for(world, window_ref)
  if scale_factor <= 0.0F {
    scale_factor = 1.0F
  }
  Some(RenderTargetComputed::{
    size: @math.IVec2::new(width, height),
    scale_factor,
  })
}

///|
fn render2d_target_info(
  world : @ecs.World,
  state : RenderState,
  target : @camera_camera.RenderTarget,
) -> RenderTargetComputed? {
  match target {
    Screen => render2d_window_target_info(world, @window.WindowRef::Primary)
    Window(window_ref) => render2d_window_target_info(world, window_ref)
    Image(handle) => {
      let target_id = handle.id()
      if render2d_find_render_target_size(state, target_id) is Some(info) {
        Some(RenderTargetComputed::{
          size: @math.IVec2::new(info.width, info.height),
          scale_factor: 1.0F,
        })
      } else {
        None
      }
    }
  }
}

///|
fn render2d_same_entity(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn render2d_ui_overlay_matches_camera(
  target_camera : @core.Entity,
  camera_entity : @core.Entity,
) -> Bool {
  @ui_render_runtime.ui_overlay_matches_camera(target_camera, camera_entity)
}

///|
fn render2d_prune_postprocess_intermediate_targets(state : RenderState) -> Unit {
  let kept : Array[PostProcessIntermediateTargetInfo] = []
  for entry in state.postprocess_intermediate_targets {
    let mut active = false
    for camera in state.cameras {
      if render2d_same_entity(entry.camera, camera.entity) {
        active = true
        break
      }
    }
    if active {
      kept.push(entry)
    }
  }
  state.postprocess_intermediate_targets.clear()
  for entry in kept {
    state.postprocess_intermediate_targets.push(entry)
  }
}

///|
fn render2d_get_or_create_postprocess_intermediate_target(
  state : RenderState,
  camera : @core.Entity,
  width : Int,
  height : Int,
  slot? : Int = 0,
) -> @asset.Handle[@asset.Image] {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  for entry in state.postprocess_intermediate_targets {
    if render2d_same_entity(entry.camera, camera) &&
      entry.slot == slot &&
      entry.width == safe_width &&
      entry.height == safe_height {
      return entry.target
    }
  }
  let id = @renderer.host_gpu_create_render_target_rgba16f(
    width=safe_width,
    height=safe_height,
    nearest=false,
  )
  let handle : @asset.Handle[@asset.Image] = @asset.Handle::new(id)
  state.render_targets.push(RuntimeRenderTargetInfo::{
    id,
    width: safe_width,
    height: safe_height,
  })
  for i in 0..<state.postprocess_intermediate_targets.length() {
    let entry = state.postprocess_intermediate_targets[i]
    if render2d_same_entity(entry.camera, camera) && entry.slot == slot {
      state.postprocess_intermediate_targets[i] = PostProcessIntermediateTargetInfo::{
        camera,
        slot,
        width: safe_width,
        height: safe_height,
        target: handle,
      }
      return handle
    }
  }
  state.postprocess_intermediate_targets.push(PostProcessIntermediateTargetInfo::{
    camera,
    slot,
    width: safe_width,
    height: safe_height,
    target: handle,
  })
  handle
}

///|
fn render2d_clamp_viewport(
  viewport : Viewport,
  target_size : @math.IVec2,
) -> Viewport {
  viewport.clamp_to_size(target_size)
}

///|
fn render2d_camera_target_info_eq(
  a : RenderTargetInfo?,
  b : RenderTargetInfo?,
) -> Bool {
  match (a, b) {
    (Some(ta), Some(tb)) =>
      render2d_ivec2_eq(ta.physical_size, tb.physical_size) &&
      ta.scale_factor == tb.scale_factor
    (None, None) => true
    _ => false
  }
}

///|
fn render2d_camera_target_info_from_render_target(
  value : RenderTargetComputed?,
) -> RenderTargetInfo? {
  match value {
    Some(info) => Some(RenderTargetInfo::new(info.size, info.scale_factor))
    None => None
  }
}

///|
fn render2d_target_component_changed(entity : @core.Entity) -> Bool {
  ignore(entity)
  true
}

///|
fn render2d_viewport_size_changed(camera : @camera_camera.Camera) -> Bool {
  !render2d_opt_ivec2_eq(
    camera.computed.old_viewport_size,
    render2d_camera_viewport_size(camera),
  )
}

///|
fn render2d_ivec2_eq(a : @math.IVec2, b : @math.IVec2) -> Bool {
  a.x == b.x && a.y == b.y
}

///|
fn render2d_opt_ivec2_eq(a : @math.IVec2?, b : @math.IVec2?) -> Bool {
  match (a, b) {
    (Some(va), Some(vb)) => render2d_ivec2_eq(va, vb)
    (None, None) => true
    _ => false
  }
}

///|
fn render2d_scale_viewport_axis(value : Int, scale : Float) -> Int {
  if value <= 0 || scale <= 0.0F {
    return 0
  }
  let scaled = Float::from_double(value.to_double()) * scale
  if scaled <= 0.0F {
    return 0
  }
  scaled.to_int()
}

///|
fn render2d_logical_view_extent_axis(value : Int, scale_factor : Float) -> Int {
  if value <= 0 {
    return 0
  }
  let safe_scale_factor = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let logical = Float::from_double(value.to_double()) / safe_scale_factor
  if logical <= 0.0F {
    1
  } else {
    let logical_i = logical.to_int()
    if logical_i <= 0 {
      1
    } else {
      logical_i
    }
  }
}

///|
fn render2d_camera_transform_scale_axis(value : Float) -> Float {
  let safe = if value < 0.0F { -value } else { value }
  if safe == 0.0F {
    1.0F
  } else {
    safe
  }
}

///|
fn render2d_camera_uniform_scale(
  projection : @camera_projection2d.OrthographicProjection,
  camera_transform : @transform.Transform,
) -> Float {
  let projection_scale = if projection.scale == 0.0F {
    1.0F
  } else {
    projection.scale
  }
  // The native 2D camera backend currently uses a uniform camera scale, so the
  // X axis is authoritative for camera-controller transforms.
  projection_scale *
  render2d_camera_transform_scale_axis(camera_transform.scale.x)
}

///|
fn render2d_scale_viewport(viewport : Viewport, scale : Float) -> Viewport {
  let position = @math.IVec2::new(
    render2d_scale_viewport_axis(viewport.physical_position.x, scale),
    render2d_scale_viewport_axis(viewport.physical_position.y, scale),
  )
  let size = @math.IVec2::new(
    render2d_scale_viewport_axis(viewport.physical_size.x, scale),
    render2d_scale_viewport_axis(viewport.physical_size.y, scale),
  )
  Viewport::new(position, size).with_depth(
    viewport.depth_min,
    viewport.depth_max,
  )
}

///|
fn render2d_camera_viewport_size(
  camera : @camera_camera.Camera,
) -> @math.IVec2? {
  match camera.viewport {
    Some(viewport) => Some(viewport.physical_size)
    None => None
  }
}

///|
fn render2d_projection_changed(entity : @core.Entity) -> Bool {
  ignore(entity)
  true
}

///|
fn render2d_camera_changed(entity : @core.Entity) -> Bool {
  ignore(entity)
  true
}

///|
fn render2d_tonemapping_mode_to_int(mode : @post_process.Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
    PbrNeutral => 8
  }
}

///|
fn render2d_tonemapping_mode_enabled(mode : Int) -> Bool {
  mode != 0
}

///|
fn render2d_color_grading_enabled(
  color_grading : @post_process.ColorGrading?,
) -> Bool {
  color_grading is Some(_)
}

///|
fn render2d_tonemapping_stage_enabled(
  tonemapping_mode : Int,
  color_grading : @post_process.ColorGrading?,
) -> Bool {
  render2d_color_grading_enabled(color_grading) ||
  render2d_tonemapping_mode_enabled(tonemapping_mode)
}

///|
fn camera_tonemapping_mode(world : @ecs.World, camera : @core.Entity) -> Int {
  match (try! world.get_by_key(camera, @post_process.ecs_key_tonemapping)) {
    Some(mode) => render2d_tonemapping_mode_to_int(mode)
    None => 0
  }
}

///|
fn camera_compositing_space(
  world : @ecs.World,
  camera : @core.Entity,
) -> @camera_compositing_space.CompositingSpace? {
  try! world.get_by_key(
    camera, @camera_compositing_space.ecs_key_compositing_space,
  )
}

///|
fn camera_hdr_enabled(world : @ecs.World, camera : @core.Entity) -> Bool {
  (try! world.get_by_key(camera, @camera_hdr.ecs_key_hdr)) is Some(_)
}

///|
fn camera_target_format_raw(
  world : @ecs.World,
  camera : @core.Entity,
  target : @camera_camera.RenderTarget,
) -> UInt {
  let output_texture_format_raw = @render_view.normalize_bgra8_for_render_target(
    target_is_window=render2d_targets_host_window(target),
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
  )
  @render_view.extracted_view_target_format_raw(
    output_texture_format_raw~,
    hdr=camera_hdr_enabled(world, camera),
    compositing_space=camera_compositing_space(world, camera),
  )
}

///|
fn camera_deband_dither_enabled(
  world : @ecs.World,
  camera : @core.Entity,
) -> Bool {
  match (try! world.get_by_key(camera, @post_process.ecs_key_deband_dither)) {
    Some(@post_process.DebandDither::Enabled) => true
    Some(@post_process.DebandDither::Disabled) => false
    None => false
  }
}

///|
fn camera_color_grading(
  world : @ecs.World,
  camera : @core.Entity,
) -> @post_process.ColorGrading? {
  try! world.get_by_key(camera, @post_process.ecs_key_color_grading)
}

///|
pub fn render2d_camera_system(world : @ecs.World) -> Unit {
  guard render_state_ref(world) is Some(render_state_ref_value) else { return }
  let ecs_world = world
  let render_state = render_state_ref_value
  ecs_world.for_each_component(@camera_components2d.ecs_key_camera2d, fn(
    entity,
    _marker,
  ) {
    let target = match
      (try! ecs_world.get_by_key(entity, @camera_camera.ecs_key_render_target)) {
      Some(value) => value
      None => @camera_camera.RenderTarget::Screen
    }
    let camera = match
      (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)) {
      Some(value) => value
      None => @camera_camera.Camera::Camera()
    }
    try! (ecs_world
    .get_by_key(entity, @camera_projection2d.ecs_key_projection)
    .unwrap_or(@camera_projection2d.Projection::orthographic_2d())
    |> ignore)

    let target_info = render2d_target_info(world, render_state, target)
    let next_target_info = render2d_camera_target_info_from_render_target(
      target_info,
    )
    let target_changed = render2d_target_component_changed(entity) ||
      !render2d_camera_target_info_eq(
        camera.computed.target_info,
        next_target_info,
      )
    let viewport_changed = render2d_viewport_size_changed(camera)
    let camera_changed = render2d_camera_changed(entity)
    let projection_changed = render2d_projection_changed(entity)
    let mut scale_factor_changed = false
    if render2d_targets_host_window(target) &&
      camera.computed.target_info is Some(old_target_info) &&
      next_target_info is Some(new_target_info) &&
      old_target_info.scale_factor > 0.0F &&
      new_target_info.scale_factor != old_target_info.scale_factor {
      scale_factor_changed = true
    }
    let should_update = target_changed ||
      viewport_changed ||
      camera_changed ||
      projection_changed ||
      scale_factor_changed

    let mut camera_value = camera
    if should_update {
      if scale_factor_changed &&
        camera.computed.target_info is Some(old_target_info) &&
        old_target_info.scale_factor > 0.0F &&
        camera_value.viewport is Some(viewport) &&
        next_target_info is Some(new_target_info) {
        let resize_factor = new_target_info.scale_factor /
          old_target_info.scale_factor
        let resized = render2d_scale_viewport(viewport, resize_factor)
        camera_value = camera_value.with_viewport(resized)
      }
      if target_info is Some(info) && camera_value.viewport is Some(viewport) {
        let clamped = render2d_clamp_viewport(viewport, info.size)
        camera_value = camera_value.with_viewport(clamped)
      }
      camera_value = camera_value.with_computed(
        ComputedCameraValues::new(
          next_target_info,
          render2d_camera_viewport_size(camera_value),
        ),
      )
      try! (world.replace(entity, @camera_camera.ecs_key_camera, camera_value)
      |> ignore)
    }
  })
}

///|
fn render2d_transform_from_parent_chain_ecs(
  world : @ecs.World,
  entity : @core.Entity,
  max_depth : Int,
) -> @transform.Transform {
  max_depth |> ignore
  (try! world.get_by_key(entity, @transform.ecs_key_transform)).unwrap_or(
    @transform.Transform::identity(),
  )
}

///|
fn render2d_resolve_transform_ecs(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global) => global.to_transform_approx()
    None => render2d_transform_from_parent_chain_ecs(world, entity, 64)
  }
}

///|
fn render2d_visibility_from_parent_chain_ecs(
  world : @ecs.World,
  entity : @core.Entity,
  max_depth : Int,
) -> Bool {
  max_depth |> ignore
  match (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
    Some(view_visibility) => view_visibility.is_visible()
    None => true
  }
}

///|
fn render2d_entity_visible_ecs(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  render2d_visibility_from_parent_chain_ecs(world, entity, 64)
}

///|
pub fn render2d_camera_system_ecs(world : @ecs.World) -> Unit {
  guard render_state_ref(world) is Some(render_state_ref_value) else { return }
  let render_state = render_state_ref_value
  let cameras : Array[@core.Entity] = []
  let camera2d_query : @ecs.Query[
    @ecs.Read[@camera_components2d.Camera2d],
    @ecs.All,
  ] = @ecs.query(world)
  try! camera2d_query.view(fn(entity, _camera2d) { cameras.push(entity) })
  for entity in cameras {
    let target = (try! world.get_by_key(
      entity, @camera_camera.ecs_key_render_target,
    )).unwrap_or(@camera_camera.RenderTarget::Screen)
    let camera = (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)).unwrap_or(
      @camera_camera.Camera::Camera(),
    )
    (try! world.get_by_key(entity, @camera_projection2d.ecs_key_projection)).unwrap_or(
      @camera_projection2d.Projection::orthographic_2d(),
    )
    |> ignore
    let target_info = render2d_target_info(world, render_state, target)
    let next_target_info = render2d_camera_target_info_from_render_target(
      target_info,
    )
    let mut camera_value = camera
    let mut scale_factor_changed = false
    if render2d_targets_host_window(target) &&
      camera.computed.target_info is Some(old_target_info) &&
      next_target_info is Some(new_target_info) &&
      old_target_info.scale_factor > 0.0F &&
      new_target_info.scale_factor != old_target_info.scale_factor {
      scale_factor_changed = true
    }
    if scale_factor_changed &&
      camera.computed.target_info is Some(old_target_info) &&
      old_target_info.scale_factor > 0.0F &&
      camera_value.viewport is Some(viewport) &&
      next_target_info is Some(new_target_info) {
      let resize_factor = new_target_info.scale_factor /
        old_target_info.scale_factor
      let resized = render2d_scale_viewport(viewport, resize_factor)
      camera_value = camera_value.with_viewport(resized)
    }
    if target_info is Some(info) && camera_value.viewport is Some(viewport) {
      let clamped = render2d_clamp_viewport(viewport, info.size)
      camera_value = camera_value.with_viewport(clamped)
    }
    camera_value = camera_value.with_computed(
      ComputedCameraValues::new(
        next_target_info,
        render2d_camera_viewport_size(camera_value),
      ),
    )
    try! world.set_by_key(entity, @camera_camera.ecs_key_camera, camera_value)
  }
}

///|
fn render2d_has_extracted_camera(
  cameras : Array[ExtractedCamera2d],
  entity : @core.Entity,
) -> Bool {
  for camera in cameras {
    if camera.entity.id == entity.id &&
      camera.entity.generation == entity.generation {
      return true
    }
  }
  false
}

///|
fn render2d_push_ui_camera_entity(
  targets : Array[@core.Entity],
  entity : @core.Entity,
) -> Unit {
  for current in targets {
    if current.id == entity.id && current.generation == entity.generation {
      return
    }
  }
  targets.push(entity)
}

///|
fn render2d_extract_camera_entity_ecs(
  world : @ecs.World,
  rs : RenderState,
  entity : @core.Entity,
) -> Unit {
  guard (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
    is Some(camera) else {
    return
  }
  let target = (try! world.get_by_key(
    entity, @camera_camera.ecs_key_render_target,
  )).unwrap_or(@camera_camera.RenderTarget::Screen)
  let layers = (try! world.get_by_key(entity, ecs_key_render_layers)).unwrap_or(
    RenderLayers::RenderLayers(),
  )
  let bloom = try! world.get_by_key(entity, @post_process.ecs_key_bloom)
  let contrast_adaptive_sharpening = try! world.get_by_key(
    entity,
    @cas.ContrastAdaptiveSharpening::component(),
  )
  let projection = match
    (try! world.get_by_key(entity, @camera_projection2d.ecs_key_projection)) {
    Some(Orthographic(p)) => p
    _ => @camera_projection2d.OrthographicProjection::default_2d()
  }
  let transform = render2d_resolve_transform_ecs(world, entity)
  let mut computed = CameraComputed::{
    target_size: @math.IVec2::new(0, 0),
    scale_factor: 1.0F,
  }
  if camera.computed.target_info is Some(target_info) {
    let scale_factor = if target_info.scale_factor <= 0.0F {
      1.0F
    } else {
      target_info.scale_factor
    }
    computed = CameraComputed::{
      target_size: target_info.physical_size,
      scale_factor,
    }
  } else if render2d_target_info(world, rs, target) is Some(info) {
    let scale_factor = if info.scale_factor <= 0.0F {
      1.0F
    } else {
      info.scale_factor
    }
    computed = CameraComputed::{ target_size: info.size, scale_factor }
  }
  rs.cameras.push(ExtractedCamera2d::{
    entity,
    camera,
    projection,
    transform,
    target,
    layers,
    bloom,
    compositing_space: camera_compositing_space(world, entity),
    target_format_raw: camera_target_format_raw(world, entity, target),
    tonemapping_mode: camera_tonemapping_mode(world, entity),
    deband_dither_enabled: camera_deband_dither_enabled(world, entity),
    color_grading: camera_color_grading(world, entity),
    contrast_adaptive_sharpening,
    computed,
  })
}

///|
fn render2d_extract_ui_only_cameras_ecs(
  world : @ecs.World,
  rs : RenderState,
) -> Unit {
  let ui_nodes = @ui_render_runtime.extracted_ui_nodes_or_empty(world)
  let ui_cameras : Array[@core.Entity] = []
  for item in ui_nodes.sprites {
    render2d_push_ui_camera_entity(ui_cameras, item.extracted_camera_entity)
  }
  for item in ui_nodes.sprite_slice_batches {
    render2d_push_ui_camera_entity(ui_cameras, item.extracted_camera_entity)
  }
  for item in ui_nodes.rects {
    render2d_push_ui_camera_entity(ui_cameras, item.extracted_camera_entity)
  }
  for item in ui_nodes.box_shadows {
    render2d_push_ui_camera_entity(ui_cameras, item.extracted_camera_entity)
  }
  for item in ui_nodes.texture_slices {
    render2d_push_ui_camera_entity(ui_cameras, item.extracted_camera_entity)
  }
  for entity in ui_cameras {
    if render2d_has_extracted_camera(rs.cameras, entity) {
      continue
    }
    render2d_extract_camera_entity_ecs(world, rs, entity)
  }
}

///|
pub let camera_update_systems : @app.SystemSet = @app.system_set(
  "mgstudio.camera.update_systems",
)

///|
fn render2d_sorted_camera_indices(
  cameras : Array[ExtractedCamera2d],
) -> Array[Int] {
  let count = cameras.length()
  let indices : Array[Int] = []
  for i in 0..<count {
    indices.push(i)
  }
  for i in 0..<count {
    let mut min_index = i
    let mut min_order = cameras[indices[i]].camera.order
    for j in (i + 1)..<count {
      let order = cameras[indices[j]].camera.order
      if order < min_order {
        min_index = j
        min_order = order
      }
    }
    if min_index != i {
      let temp = indices[i]
      indices[i] = indices[min_index]
      indices[min_index] = temp
    }
  }
  indices
}

///|
pub fn render_extract_system(world : @ecs.World) -> Unit {
  render_extract_system_ecs(world)
}

///|
pub fn render_extract_system_ecs(world : @ecs.World) -> Unit {
  let source_world = @renderer.render_source_world(world)
  let material_runtime_registry = material2d_runtime_registry_or_empty(world)
  let custom_mesh2d_runtime_registry = custom_mesh2d_runtime_registry_or_empty(
    world,
  )
  render_state_update(world, fn(rs) {
    rs.draw_enabled = true
    rs.primary_camera = @core.Entity::placeholder()
    rs.sprites.clear()
    rs.sprite_slice_batches.clear()
    rs.cameras.clear()
    rs.meshes.clear()
    // ECS camera components.
    let camera2d_query : @ecs.Query[
      @ecs.Read[@camera_components2d.Camera2d],
      @ecs.All,
    ] = @ecs.query(source_world)
    try! camera2d_query.view(fn(entity, _camera2d) {
      render2d_extract_camera_entity_ecs(source_world, rs, entity)
    })
    render2d_extract_ui_only_cameras_ecs(source_world, rs)
    if rs.cameras.length() > 0 {
      let order = render2d_sorted_camera_indices(rs.cameras)
      if order.length() > 0 {
        rs.primary_camera = rs.cameras[order[0]].entity
      }
    }
    render2d_prune_postprocess_intermediate_targets(rs)

    // ECS sprite components.
    let texture_atlas_layouts_key : @ecs.ResourceKey[
      @asset.Assets[@asset.TextureAtlasLayout],
    ] = @asset.assets_resource_key()
    let texture_atlas_layouts = source_world.get_resource(
      texture_atlas_layouts_key,
    )
    let sprite_query : @ecs.Query[@ecs.Read[Sprite], @ecs.All] = @ecs.query(
      source_world,
    )
    try! sprite_query.view(fn(entity, sprite) {
      if !render2d_entity_visible_ecs(source_world, entity) {
        return
      }
      let sprite = sprite.value()
      let anchor = (try! source_world.get_by_key(entity, ecs_key_anchor)).unwrap_or(
        Anchor::Anchor(),
      )
      let layers = (try! source_world.get_by_key(entity, ecs_key_render_layers)).unwrap_or(
        RenderLayers::RenderLayers(),
      )
      let transform = render2d_resolve_transform_ecs(source_world, entity)
      let mut uv_min = default_uv_min()
      let mut uv_max = default_uv_max()
      let mut region_size = @math.Vec2::new(1.0F, 1.0F)
      let mut image_size = @math.Vec2::new(1.0F, 1.0F)
      if sprite_uv_from_sprite(sprite, texture_atlas_layouts) is Some(info) {
        uv_min = info.uv_min
        uv_max = info.uv_max
        image_size = info.image_size
        region_size = info.region_size
      }
      let draw_scale = sprite_draw_scale(
        sprite,
        @math.Vec2::new(transform.scale.x, transform.scale.y),
        region_size,
      )
      let scissor = match
        (try! source_world.get_by_key(entity, @ui_clip.ecs_key_scissor_rect)) {
        Some(v) => Some(v.rect)
        None => None
      }
      let has_custom_size = match sprite.custom_size {
        Some(_) => true
        None => false
      }
      let (
        uv_draw_min,
        uv_draw_max,
        draw_scale_for_host,
        local_offset,
        needs_repeat_sampler,
      ) = apply_sprite_image_mode(
        uv_min,
        uv_max,
        draw_scale,
        region_size,
        sprite.image_mode,
        has_custom_size,
      )
      let anchor_offset = sprite_anchor_offset(
        anchor,
        transform.rotation_z(),
        draw_scale_for_host,
        region_size,
        local_offset,
      )
      if needs_repeat_sampler {
        @asset.asset_set_texture_sampler(
          sprite.image,
          @asset.ImageSampler::Descriptor(
            @asset.ImageSamplerDescriptor::linear().set_address_mode(
              @asset.ImageAddressMode::Repeat,
            ),
          ),
        )
      }
      if !append_computed_sprite_slices(
          rs.sprite_slice_batches,
          entity,
          sprite,
          try! source_world.get_by_key(entity, ecs_key_computed_texture_slices),
          anchor,
          transform,
          layers,
          scissor,
          image_size,
        ) {
        rs.sprites.push(ExtractedSprite::{
          entity: phase_entity_ref_for_main(entity),
          payload: SpriteDrawPayload::{
            transform,
            anchor_offset,
            draw_scale: draw_scale_for_host,
            color: sprite.color,
            texture: sprite.image,
            layers,
            uv_min: uv_draw_min,
            uv_max: uv_draw_max,
            scissor,
          },
        })
      }
    })
    // ECS mesh components.
    let mesh_query : @ecs.Query[@ecs.Read[Mesh2d], @ecs.All] = @ecs.query(
      source_world,
    )
    try! mesh_query.view(fn(entity, mesh2d) {
      if !render2d_entity_visible_ecs(source_world, entity) {
        return
      }
      let has_material2d = material2d_runtime_registry_contains_entity(
        source_world, material_runtime_registry, entity,
      )
      let has_custom_mesh2d = custom_mesh2d_runtime_registry_contains_entity(
        source_world, custom_mesh2d_runtime_registry, entity,
      )
      if !has_material2d && !has_custom_mesh2d {
        return
      }
      let layers = (try! source_world.get_by_key(entity, ecs_key_render_layers)).unwrap_or(
        RenderLayers::RenderLayers(),
      )
      let transform = render2d_resolve_transform_ecs(source_world, entity)
      let wireframe_component = try! source_world.get_by_key(
        entity, ecs_key_mesh2d_wireframe,
      )
      let wireframe = wireframe_component is Some(_)
      let wireframe_color = match wireframe_component {
        Some(component) => wireframe2d_material_color(source_world, component)
        None => @color.Color::white()
      }
      let mesh2d = mesh2d.value()
      rs.meshes.push(ExtractedMesh2d::{
        entity: phase_entity_ref_for_main(entity),
        payload: Mesh2dDrawPayload::{
          mesh_id: render2d_upload_mesh_handle(mesh2d.mesh()),
          transform,
          layers,
          wireframe,
          wireframe_color,
        },
      })
    })
  })
  |> ignore
}

///|
pub fn render_prepare_system(world : @ecs.World) -> Unit {
  render_state_update(world, fn(rs) {
    if !rs.draw_enabled {
      rs.prepared_camera_indices.clear()
      rs.queued_draw_item_counts.clear()
      rs.queued_camera_draw_items.clear()
      render2d_runtime_state.diagnostic_prepared_camera_count = 0
      render2d_runtime_state.diagnostic_queued_draw_item_count = 0
      return
    }
    rs.prepared_camera_indices = render2d_sorted_camera_indices(rs.cameras)
    render2d_runtime_state.diagnostic_prepared_camera_count = rs.prepared_camera_indices.length()
    rs.queued_draw_item_counts.clear()
    rs.queued_camera_draw_items.clear()
  })
  |> ignore
}

///|
pub fn render_queue_system(world : @ecs.World) -> Unit {
  let queue_start = @time.host_time_now()
  let queue_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_2d",
  )
  let material_runtime_registry = material2d_runtime_registry_or_empty(world)
  let custom_mesh2d_runtime_registry = custom_mesh2d_runtime_registry_or_empty(
    world,
  )
  let color_material_probe : @asset.Handle[ColorMaterial] = @asset.Handle::new(
    0,
  )
  let use_color_material_fast_path = material_runtime_registry.entry_count() ==
    1 &&
    custom_mesh2d_runtime_registry.entry_count() == 0 &&
    material_runtime_registry.contains_type_name(
      material2d_runtime_type_name(color_material_probe),
    )
  let color_prepared_materials = prepared_material2d_assets_or_empty(
    world, color_material_probe,
  )
  let color_material_instances = render_material2d_instances_or_empty(
    world, color_material_probe,
  )
  let ui_nodes = @ui_render_runtime.extracted_ui_nodes_or_empty(world)
  render_state_update(world, fn(rs) {
    if !rs.draw_enabled {
      rs.queued_draw_item_counts.clear()
      rs.queued_camera_draw_items.clear()
      render2d_runtime_state.diagnostic_queued_draw_item_count = 0
      return
    }
    let cameras = rs.cameras
    let camera_indices = if rs.prepared_camera_indices.length() ==
      cameras.length() {
      rs.prepared_camera_indices
    } else {
      render2d_sorted_camera_indices(cameras)
    }
    let counts : Array[Int] = []
    let queued_items : Array[QueuedCameraDrawItems] = []
    counts.reserve_capacity(camera_indices.length())
    queued_items.reserve_capacity(camera_indices.length())
    for index in camera_indices {
      if index < 0 || index >= cameras.length() {
        continue
      }
      let camera = cameras[index]
      let scene_cull_context = render2d_camera_scene_cull_context(camera)
      let item = build_camera_draw_items(
        world,
        material_runtime_registry,
        custom_mesh2d_runtime_registry,
        rs.sprites,
        rs.sprite_slice_batches,
        rs.extra_sprites,
        rs.extra_sprite_slice_batches,
        ui_nodes.sprites,
        ui_nodes.sprite_slice_batches,
        ui_nodes.rects,
        ui_nodes.box_shadows,
        ui_nodes.texture_slices,
        rs.meshes,
        color_prepared_materials,
        color_material_instances,
        camera.entity,
        camera.layers,
        use_color_material_fast_path,
        scene_cull_context,
      )
      counts.push(
        item.scene_opaque_items.length() +
        item.scene_transparent_items.length() +
        item.ui_overlay_items.length(),
      )
      queued_items.push(item)
    }
    rs.queued_draw_item_counts = counts
    rs.queued_camera_draw_items = queued_items
    let mut total = 0
    for count in counts {
      total = total + count
    }
    render2d_runtime_state.diagnostic_queued_draw_item_count = total
  })
  |> ignore
  render2d_runtime_state.diagnostic_queue_cpu_ms = (
      @time.host_time_now() - queue_start
    ) *
    1000.0F
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_2d",
    queue_trace_start_us,
  )
}

///|
pub fn render2d_diagnostic_queued_draw_item_count() -> Int {
  render2d_runtime_state.diagnostic_queued_draw_item_count
}

///|
pub fn render2d_diagnostic_prepared_camera_count() -> Int {
  render2d_runtime_state.diagnostic_prepared_camera_count
}

///|
pub fn render2d_diagnostic_queue_cpu_ms() -> Float {
  render2d_runtime_state.diagnostic_queue_cpu_ms
}

///|
pub fn render2d_diagnostic_execute_cpu_ms() -> Float {
  render2d_runtime_state.diagnostic_execute_cpu_ms
}

///|
pub fn render2d_prepared_camera_count(world : @ecs.World) -> Int? {
  guard render_state_ref(world) is Some(rs) else { return Some(0) }
  Some(rs.prepared_camera_indices.length())
}

///|
pub fn render2d_queued_draw_item_count(world : @ecs.World) -> Int? {
  guard render_state_ref(world) is Some(rs) else { return Some(0) }
  let mut total = 0
  for count in rs.queued_draw_item_counts {
    total = total + count
  }
  Some(total)
}

///|
fn cmp_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn cmp_float(a : Float, b : Float) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
pub struct SceneCullContext {
  center_x : Float
  center_y : Float
  cosv : Float
  sinv : Float
  half_width : Float
  half_height : Float
}

///|
pub fn SceneCullContext::new(
  center_x : Float,
  center_y : Float,
  cosv : Float,
  sinv : Float,
  half_width : Float,
  half_height : Float,
) -> SceneCullContext {
  SceneCullContext::{ center_x, center_y, cosv, sinv, half_width, half_height }
}

///|
pub fn SceneCullContext::values(
  self : SceneCullContext,
) -> (Float, Float, Float, Float, Float, Float) {
  (
    self.center_x,
    self.center_y,
    self.cosv,
    self.sinv,
    self.half_width,
    self.half_height,
  )
}

///|
fn scene_cull_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn scene_cull_radius_from_sprite_scale(scale : @math.Vec2) -> Float {
  let sx = scene_cull_abs_float(scale.x)
  let sy = scene_cull_abs_float(scale.y)
  let edge = if sx > sy { sx } else { sy }
  edge * 64.0F + 8.0F
}

///|
fn scene_cull_batch_radius(half_size : @math.Vec2, scale : @math.Vec2) -> Float {
  let batch_half_extent = if half_size.x > half_size.y {
    half_size.x
  } else {
    half_size.y
  }
  let sprite_radius = scene_cull_radius_from_sprite_scale(scale)
  if batch_half_extent > sprite_radius {
    batch_half_extent
  } else {
    sprite_radius
  }
}

///|
fn scene_cull_radius_from_computed_sprite_slices(
  payload : ComputedSpriteSlicesDrawPayload,
) -> Float {
  let mut half_x = 0.0F
  let mut half_y = 0.0F
  for slice in payload.slices {
    let slice_half_x = scene_cull_abs_float(slice.draw_size.x) * 0.5F
    let slice_half_y = scene_cull_abs_float(slice.draw_size.y) * 0.5F
    let extent_x = scene_cull_abs_float(slice.offset.x) + slice_half_x
    let extent_y = scene_cull_abs_float(slice.offset.y) + slice_half_y
    if extent_x > half_x {
      half_x = extent_x
    }
    if extent_y > half_y {
      half_y = extent_y
    }
  }
  let scale_x = scene_cull_abs_float(payload.transform.scale.x)
  let scale_y = scene_cull_abs_float(payload.transform.scale.y)
  let scaled_half_x = half_x * scale_x
  let scaled_half_y = half_y * scale_y
  if scaled_half_x > scaled_half_y {
    scaled_half_x + 8.0F
  } else {
    scaled_half_y + 8.0F
  }
}

///|
test "render2d: slice batch cull radius keeps batch bounds over sprite padding" {
  let radius = scene_cull_batch_radius(
    @math.Vec2::new(80.0F, 20.0F),
    @math.Vec2::new(1.0F, 1.0F),
  )
  debug_inspect(radius == 80.0F, content="true")
}

///|
fn scene_cull_radius_from_mesh_scale(
  scale : @math.Vec3,
  base_radius : Float,
) -> Float {
  let sx = scene_cull_abs_float(scale.x)
  let sy = scene_cull_abs_float(scale.y)
  let edge = if sx > sy { sx } else { sy }
  edge * base_radius + 8.0F
}

///|
fn scene_item_visible_in_context(
  context : SceneCullContext,
  x : Float,
  y : Float,
  radius : Float,
) -> Bool {
  let dx = x - context.center_x
  let dy = y - context.center_y
  let local_x = dx * context.cosv + dy * context.sinv
  let local_y = -dx * context.sinv + dy * context.cosv
  scene_cull_abs_float(local_x) <= context.half_width + radius &&
  scene_cull_abs_float(local_y) <= context.half_height + radius
}

///|
fn render2d_camera_scene_cull_context(
  camera : ExtractedCamera2d,
) -> SceneCullContext? {
  let target_size = camera.computed.target_size
  guard camera_viewport_rect_physical(
      target_size.x,
      target_size.y,
      camera.camera.viewport,
    )
    is Some((_viewport_x, _viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  let mut scale_factor = camera.computed.scale_factor
  if scale_factor <= 0.0F {
    scale_factor = 1.0F
  }
  let view_width_logical = render2d_logical_view_extent_axis(
    viewport_width, scale_factor,
  )
  let view_height_logical = render2d_logical_view_extent_axis(
    viewport_height, scale_factor,
  )
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return None
  }
  let camera_uniform_scale = render2d_camera_uniform_scale(
    camera.projection,
    camera.transform,
  )
  let rotation = camera.transform.rotation_z()
  Some(SceneCullContext::{
    center_x: camera.transform.translation.x,
    center_y: camera.transform.translation.y,
    cosv: @math.cos(rotation),
    sinv: @math.sin(rotation),
    half_width: Float::from_double(view_width_logical.to_double()) *
    camera_uniform_scale *
    0.5F,
    half_height: Float::from_double(view_height_logical.to_double()) *
    camera_uniform_scale *
    0.5F,
  })
}

///|
fn render2d_primary_camera(world : @ecs.World) -> ExtractedCamera2d? {
  guard render_state_ref(world) is Some(rs) else { return None }
  let id = rs.primary_camera
  if id.is_placeholder() {
    return None
  }
  let mut found : ExtractedCamera2d? = None
  for camera in rs.cameras {
    if camera.entity.id == id.id && camera.entity.generation == id.generation {
      found = Some(camera)
      break
    }
  }
  found
}

///|
pub fn render2d_primary_scene_cull_context(
  world : @ecs.World,
) -> SceneCullContext? {
  guard render2d_primary_camera(world) is Some(camera) else { return None }
  render2d_camera_scene_cull_context(camera)
}

///|
pub fn render2d_scene_item_visible(
  context : SceneCullContext,
  x : Float,
  y : Float,
  radius : Float,
) -> Bool {
  scene_item_visible_in_context(context, x, y, radius)
}

///|
fn[M] append_material2d_mesh_draw_items(
  opaque_items : Array[DrawItem],
  transparent_items : Array[DrawItem],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @renderer.RenderAssets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  layers : RenderLayers,
  tie : Int,
  material_runtime_index? : Int = -1,
  scene_cull_context? : SceneCullContext? = None,
) -> Int {
  let mut next_tie = tie
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if !mesh.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = mesh.payload.transform
      let base_radius = uploaded_mesh_base_radius(mesh.payload.mesh_id)
      if !scene_item_visible_in_context(
          context,
          transform.translation.x,
          transform.translation.y,
          scene_cull_radius_from_mesh_scale(transform.scale, base_radius),
        ) {
        continue
      }
    }
    guard prepared_material2d_handle_for_mesh(mesh, material_instances)
      is Some(material_handle) else {
      continue
    }
    guard prepared_material2d_get(prepared_materials, material_handle)
      is Some(material) else {
      continue
    }
    guard prepared_material2d_alpha_phase(material) is Some(phase) else {
      continue
    }
    let item = DrawItem::{
      kind: Mesh(i),
      entity: mesh.entity,
      z: mesh.payload.transform.translation.z,
      phase,
      tie: next_tie,
      material_handle_id: material_handle.id(),
      material_runtime_index,
    }
    if phase == 0 {
      opaque_items.push(item)
    } else {
      transparent_items.push(item)
    }
    next_tie = next_tie + 1
  }
  next_tie
}

///|
fn append_registered_material2d_mesh_draw_items(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  opaque_items : Array[DrawItem],
  transparent_items : Array[DrawItem],
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
  tie : Int,
  scene_cull_context? : SceneCullContext? = None,
) -> Int {
  let mut next_tie = tie
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if !mesh.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = mesh.payload.transform
      let base_radius = uploaded_mesh_base_radius(mesh.payload.mesh_id)
      if !scene_item_visible_in_context(
          context,
          transform.translation.x,
          transform.translation.y,
          scene_cull_radius_from_mesh_scale(transform.scale, base_radius),
        ) {
        continue
      }
    }
    if material2d_runtime_phase_for_draw(world, registry, mesh)
      is Some((runtime_index, phase)) {
      let item = DrawItem::{
        kind: Mesh(i),
        entity: mesh.entity,
        z: mesh.payload.transform.translation.z,
        phase,
        tie: next_tie,
        material_handle_id: -1,
        material_runtime_index: runtime_index,
      }
      if phase == 0 {
        opaque_items.push(item)
      } else {
        transparent_items.push(item)
      }
      next_tie = next_tie + 1
      continue
    }
  }
  next_tie
}

///|
fn append_registered_custom_mesh2d_draw_items(
  world : @ecs.World,
  registry : CustomMesh2dRuntimeRegistry,
  opaque_items : Array[DrawItem],
  transparent_items : Array[DrawItem],
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
  tie : Int,
  scene_cull_context? : SceneCullContext? = None,
) -> Int {
  let source_world = @renderer.render_source_world(world)
  let mut next_tie = tie
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if !mesh.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = mesh.payload.transform
      let base_radius = uploaded_mesh_base_radius(mesh.payload.mesh_id)
      if !scene_item_visible_in_context(
          context,
          transform.translation.x,
          transform.translation.y,
          scene_cull_radius_from_mesh_scale(transform.scale, base_radius),
        ) {
        continue
      }
    }
    guard custom_mesh2d_runtime_phase_for_draw(source_world, registry, mesh)
      is Some((runtime_index, phase)) else {
      continue
    }
    let item = DrawItem::{
      kind: CustomMesh(i),
      entity: mesh.entity,
      z: mesh.payload.transform.translation.z,
      phase,
      tie: next_tie,
      material_handle_id: -1,
      material_runtime_index: runtime_index,
    }
    if phase == 0 {
      opaque_items.push(item)
    } else {
      transparent_items.push(item)
    }
    next_tie = next_tie + 1
  }
  next_tie
}

///|
fn[M] draw_material2d_items_for_layers(
  sprites : Array[ExtractedSprite],
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  extra_sprites : Array[ExtractedSprite],
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch],
  extra_ui_sprites : Array[ExtractedUiSprite],
  extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch],
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @renderer.RenderAssets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  camera_entity : @core.Entity,
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  items.reserve_capacity(
    sprites.length() +
    sprite_slice_batches.length() +
    extra_sprites.length() +
    extra_sprite_slice_batches.length() +
    extra_ui_sprites.length() +
    extra_ui_sprite_slice_batches.length() +
    extra_ui_rects.length() +
    extra_ui_box_shadows.length() +
    extra_ui_texture_slices.length() +
    meshes.length(),
  )
  for
    item in draw_material2d_scene_items_for_layers(
      sprites, sprite_slice_batches, extra_sprites, extra_sprite_slice_batches, meshes,
      prepared_materials, material_instances, layers,
    ) {
    items.push(item)
  }
  for
    item in draw_ui_overlay_items_for_layers(
      extra_ui_sprites, extra_ui_sprite_slice_batches, extra_ui_rects, extra_ui_box_shadows,
      extra_ui_texture_slices, camera_entity, layers,
    ) {
    items.push(item)
  }
  sort_draw_items(items)
}

///|
fn draw_items_for_layers(
  sprites : Array[ExtractedSprite],
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  extra_sprites : Array[ExtractedSprite],
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch],
  extra_ui_sprites : Array[ExtractedUiSprite],
  extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch],
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @renderer.RenderAssets[PreparedMaterial2d[ColorMaterial]],
  material_instances : RenderMaterial2dInstances[ColorMaterial],
  camera_entity : @core.Entity,
  layers : RenderLayers,
) -> Array[DrawItem] {
  draw_material2d_items_for_layers(
    sprites, sprite_slice_batches, extra_sprites, extra_sprite_slice_batches, extra_ui_sprites,
    extra_ui_sprite_slice_batches, extra_ui_rects, extra_ui_box_shadows, extra_ui_texture_slices,
    meshes, prepared_materials, material_instances, camera_entity, layers,
  )
}

///|
fn sort_draw_items(items : Array[DrawItem]) -> Array[DrawItem] {
  items.sort_by(fn(a, b) {
    let cp = cmp_int(a.phase, b.phase)
    if cp != 0 {
      return cp
    }
    let cz = cmp_float(a.z, b.z)
    if cz != 0 {
      return cz
    }
    let ce = phase_entity_ref_cmp(a.entity, b.entity)
    if ce != 0 {
      return ce
    }
    cmp_int(a.tie, b.tie)
  })
  items
}

///|
fn sort_transparent_scene_draw_items(
  items : Array[DrawItem],
) -> Array[DrawItem] {
  items.sort_by(fn(a, b) {
    let cz = cmp_float(a.z, b.z)
    if cz != 0 {
      return cz
    }
    cmp_int(a.tie, b.tie)
  })
  items
}

///|
fn draw_kind_opaque_batch_group(kind : DrawKind) -> Int {
  match kind {
    Mesh(_) => 0
    CustomMesh(_) => 1
    SpriteMain(_) => 2
    SpriteSliceBatchMain(_) => 3
    SpriteExtra(_) => 4
    SpriteSliceBatchExtra(_) => 5
    UiSpriteExtra(_) => 6
    UiSpriteSliceBatchExtra(_) => 7
    UiRectExtra(_) => 8
    UiBoxShadowExtra(_) => 9
    UiTextureSliceExtra(_) => 10
  }
}

///|
fn sort_opaque_scene_draw_items(items : Array[DrawItem]) -> Array[DrawItem] {
  items.sort_by(fn(a, b) {
    let ck = cmp_int(
      draw_kind_opaque_batch_group(a.kind),
      draw_kind_opaque_batch_group(b.kind),
    )
    if ck != 0 {
      return ck
    }
    let cmh = cmp_int(a.material_handle_id, b.material_handle_id)
    if cmh != 0 {
      return cmh
    }
    let cmr = cmp_int(a.material_runtime_index, b.material_runtime_index)
    if cmr != 0 {
      return cmr
    }
    let cz = cmp_float(a.z, b.z)
    if cz != 0 {
      return cz
    }
    let ce = phase_entity_ref_cmp(a.entity, b.entity)
    if ce != 0 {
      return ce
    }
    cmp_int(a.tie, b.tie)
  })
  items
}

///|
fn scene_phase_draw_items_concat(
  phase_items : ScenePhaseDrawItems,
) -> Array[DrawItem] {
  let items = phase_items.opaque_items
  for item in phase_items.transparent_items {
    items.push(item)
  }
  items
}

///|
fn[M] draw_material2d_scene_phase_items_for_layers(
  sprites : Array[ExtractedSprite],
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  extra_sprites : Array[ExtractedSprite],
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @renderer.RenderAssets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  layers : RenderLayers,
  scene_cull_context? : SceneCullContext? = None,
) -> ScenePhaseDrawItems {
  let opaque_items : Array[DrawItem] = []
  let transparent_items : Array[DrawItem] = []
  opaque_items.reserve_capacity(meshes.length())
  transparent_items.reserve_capacity(
    sprites.length() +
    sprite_slice_batches.length() +
    extra_sprites.length() +
    extra_sprite_slice_batches.length(),
  )
  let mut tie = 0
  // Align with Bevy queue structure: mesh phases are queued before sprite phases.
  // Transparent items are then sorted by z with stable insertion order.
  tie = append_material2d_mesh_draw_items(
    opaque_items,
    transparent_items,
    meshes,
    prepared_materials,
    material_instances,
    layers,
    tie,
    scene_cull_context~,
  )
  for i in 0..<sprites.length() {
    let sprite = sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = sprite.payload.transform
      let pos_x = transform.translation.x + sprite.payload.anchor_offset.x
      let pos_y = transform.translation.y + sprite.payload.anchor_offset.y
      if !scene_item_visible_in_context(
          context,
          pos_x,
          pos_y,
          scene_cull_radius_from_sprite_scale(sprite.payload.draw_scale),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteMain(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<sprite_slice_batches.length() {
    let batch = sprite_slice_batches[i]
    if !batch.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = batch.payload.transform
      if !scene_item_visible_in_context(
          context,
          transform.translation.x,
          transform.translation.y,
          scene_cull_radius_from_computed_sprite_slices(batch.payload),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteSliceBatchMain(i),
      entity: batch.entity,
      z: batch.payload.transform.translation.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_sprites.length() {
    let sprite = extra_sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = sprite.payload.transform
      let pos_x = transform.translation.x + sprite.payload.anchor_offset.x
      let pos_y = transform.translation.y + sprite.payload.anchor_offset.y
      if !scene_item_visible_in_context(
          context,
          pos_x,
          pos_y,
          scene_cull_radius_from_sprite_scale(sprite.payload.draw_scale),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteExtra(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_sprite_slice_batches.length() {
    let batch = extra_sprite_slice_batches[i]
    if !batch.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      if !scene_item_visible_in_context(
          context,
          batch.payload.cull_center.x,
          batch.payload.cull_center.y,
          scene_cull_batch_radius(
            batch.payload.cull_half_size,
            batch.payload.draw_scale,
          ),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteSliceBatchExtra(i),
      entity: batch.entity,
      z: batch.payload.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  ignore(sort_opaque_scene_draw_items(opaque_items))
  ignore(sort_transparent_scene_draw_items(transparent_items))
  ScenePhaseDrawItems::{ opaque_items, transparent_items }
}

///|
fn[M] draw_material2d_scene_items_for_layers(
  sprites : Array[ExtractedSprite],
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  extra_sprites : Array[ExtractedSprite],
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @renderer.RenderAssets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  layers : RenderLayers,
  scene_cull_context? : SceneCullContext? = None,
) -> Array[DrawItem] {
  let phase_items = draw_material2d_scene_phase_items_for_layers(
    sprites,
    sprite_slice_batches,
    extra_sprites,
    extra_sprite_slice_batches,
    meshes,
    prepared_materials,
    material_instances,
    layers,
    scene_cull_context~,
  )
  scene_phase_draw_items_concat(phase_items)
}

///|
fn draw_scene_items_for_layers(
  sprites : Array[ExtractedSprite],
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  extra_sprites : Array[ExtractedSprite],
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @renderer.RenderAssets[PreparedMaterial2d[ColorMaterial]],
  material_instances : RenderMaterial2dInstances[ColorMaterial],
  layers : RenderLayers,
  scene_cull_context? : SceneCullContext? = None,
) -> Array[DrawItem] {
  draw_material2d_scene_items_for_layers(
    sprites,
    sprite_slice_batches,
    extra_sprites,
    extra_sprite_slice_batches,
    meshes,
    prepared_materials,
    material_instances,
    layers,
    scene_cull_context~,
  )
}

///|
fn draw_registered_scene_phase_items_for_layers(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  custom_registry : CustomMesh2dRuntimeRegistry,
  sprites : Array[ExtractedSprite],
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  extra_sprites : Array[ExtractedSprite],
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch],
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
  scene_cull_context? : SceneCullContext? = None,
) -> ScenePhaseDrawItems {
  let opaque_items : Array[DrawItem] = []
  let transparent_items : Array[DrawItem] = []
  opaque_items.reserve_capacity(meshes.length())
  transparent_items.reserve_capacity(
    sprites.length() +
    sprite_slice_batches.length() +
    extra_sprites.length() +
    extra_sprite_slice_batches.length(),
  )
  let mut tie = 0
  tie = append_registered_custom_mesh2d_draw_items(
    world,
    custom_registry,
    opaque_items,
    transparent_items,
    meshes,
    layers,
    tie,
    scene_cull_context~,
  )
  tie = append_registered_material2d_mesh_draw_items(
    world,
    registry,
    opaque_items,
    transparent_items,
    meshes,
    layers,
    tie,
    scene_cull_context~,
  )
  for i in 0..<sprites.length() {
    let sprite = sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = sprite.payload.transform
      let pos_x = transform.translation.x + sprite.payload.anchor_offset.x
      let pos_y = transform.translation.y + sprite.payload.anchor_offset.y
      if !scene_item_visible_in_context(
          context,
          pos_x,
          pos_y,
          scene_cull_radius_from_sprite_scale(sprite.payload.draw_scale),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteMain(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<sprite_slice_batches.length() {
    let batch = sprite_slice_batches[i]
    if !batch.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = batch.payload.transform
      if !scene_item_visible_in_context(
          context,
          transform.translation.x,
          transform.translation.y,
          scene_cull_radius_from_computed_sprite_slices(batch.payload),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteSliceBatchMain(i),
      entity: batch.entity,
      z: batch.payload.transform.translation.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_sprites.length() {
    let sprite = extra_sprites[i]
    if !sprite.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      let transform = sprite.payload.transform
      let pos_x = transform.translation.x + sprite.payload.anchor_offset.x
      let pos_y = transform.translation.y + sprite.payload.anchor_offset.y
      if !scene_item_visible_in_context(
          context,
          pos_x,
          pos_y,
          scene_cull_radius_from_sprite_scale(sprite.payload.draw_scale),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteExtra(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_sprite_slice_batches.length() {
    let batch = extra_sprite_slice_batches[i]
    if !batch.payload.layers.matches(layers) {
      continue
    }
    if scene_cull_context is Some(context) {
      if !scene_item_visible_in_context(
          context,
          batch.payload.cull_center.x,
          batch.payload.cull_center.y,
          scene_cull_batch_radius(
            batch.payload.cull_half_size,
            batch.payload.draw_scale,
          ),
        ) {
        continue
      }
    }
    transparent_items.push(DrawItem::{
      kind: SpriteSliceBatchExtra(i),
      entity: batch.entity,
      z: batch.payload.z,
      phase: 1,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  ignore(sort_opaque_scene_draw_items(opaque_items))
  ignore(sort_transparent_scene_draw_items(transparent_items))
  ScenePhaseDrawItems::{ opaque_items, transparent_items }
}

///|
fn draw_wireframe_meshes_for_layers(
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
) -> Unit {
  for mesh in meshes {
    if !mesh.payload.layers.matches(layers) || !mesh.payload.wireframe {
      continue
    }
    let transform = mesh.payload.transform
    let color = mesh.payload.wireframe_color
    @renderer.host_gpu_draw_mesh_wireframe(
      mesh_id=mesh.payload.mesh_id,
      x=transform.translation.x,
      y=transform.translation.y,
      rotation=transform.rotation_z(),
      scale_x=transform.scale.x,
      scale_y=transform.scale.y,
      color_r=color.r,
      color_g=color.g,
      color_b=color.b,
      color_a=color.a,
    )
  }
}

///|
fn has_wireframe_meshes_for_layers(
  meshes : Array[ExtractedMesh2d],
  layers : RenderLayers,
) -> Bool {
  for mesh in meshes {
    if mesh.payload.layers.matches(layers) && mesh.payload.wireframe {
      return true
    }
  }
  false
}

///|
fn build_camera_draw_items(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  custom_registry : CustomMesh2dRuntimeRegistry,
  sprites : Array[ExtractedSprite],
  sprite_slice_batches : Array[ExtractedComputedSpriteSlices],
  extra_sprites : Array[ExtractedSprite],
  extra_sprite_slice_batches : Array[ExtractedSpriteSliceBatch],
  extra_ui_sprites : Array[ExtractedUiSprite],
  extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch],
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  meshes : Array[ExtractedMesh2d],
  prepared_materials : @renderer.RenderAssets[PreparedMaterial2d[ColorMaterial]],
  material_instances : RenderMaterial2dInstances[ColorMaterial],
  camera_entity : @core.Entity,
  layers : RenderLayers,
  use_color_material_fast_path : Bool,
  scene_cull_context : SceneCullContext?,
) -> QueuedCameraDrawItems {
  let scene_phase_items = if use_color_material_fast_path {
    draw_material2d_scene_phase_items_for_layers(
      sprites,
      sprite_slice_batches,
      extra_sprites,
      extra_sprite_slice_batches,
      meshes,
      prepared_materials,
      material_instances,
      layers,
      scene_cull_context~,
    )
  } else {
    draw_registered_scene_phase_items_for_layers(
      world,
      registry,
      custom_registry,
      sprites,
      sprite_slice_batches,
      extra_sprites,
      extra_sprite_slice_batches,
      meshes,
      layers,
      scene_cull_context~,
    )
  }
  let ui_overlay_items = draw_ui_overlay_items_for_layers(
    extra_ui_sprites, extra_ui_sprite_slice_batches, extra_ui_rects, extra_ui_box_shadows,
    extra_ui_texture_slices, camera_entity, layers,
  )
  QueuedCameraDrawItems::{
    camera_entity,
    scene_opaque_items: scene_phase_items.opaque_items,
    scene_transparent_items: scene_phase_items.transparent_items,
    ui_overlay_items,
  }
}

///|
fn queued_camera_draw_items_for_camera(
  state : RenderState,
  camera_entity : @core.Entity,
) -> QueuedCameraDrawItems? {
  for item in state.queued_camera_draw_items {
    if item.camera_entity.id == camera_entity.id &&
      item.camera_entity.generation == camera_entity.generation {
      return Some(item)
    }
  }
  None
}

///|
fn queued_camera_draw_items_at_index(
  state : RenderState,
  index : Int,
) -> QueuedCameraDrawItems? {
  if index < 0 || index >= state.queued_camera_draw_items.length() {
    return None
  }
  Some(state.queued_camera_draw_items[index])
}

///|
fn draw_ui_overlay_items_for_layers(
  extra_ui_sprites : Array[ExtractedUiSprite],
  extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch],
  extra_ui_rects : Array[ExtractedUiRect],
  extra_ui_box_shadows : Array[ExtractedUiBoxShadow],
  extra_ui_texture_slices : Array[ExtractedUiTextureSlice],
  camera_entity : @core.Entity,
  layers : RenderLayers,
) -> Array[DrawItem] {
  let items : Array[DrawItem] = []
  let mut tie = 0
  for i in 0..<extra_ui_sprites.length() {
    let sprite = extra_ui_sprites[i]
    if !sprite.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        sprite.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiSpriteExtra(i),
      entity: sprite.entity,
      z: sprite.payload.transform.translation.z,
      phase: 2,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_ui_sprite_slice_batches.length() {
    let sprite = extra_ui_sprite_slice_batches[i]
    if !sprite.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        sprite.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiSpriteSliceBatchExtra(i),
      entity: sprite.entity,
      z: sprite.payload.z,
      phase: 2,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_ui_rects.length() {
    let rect = extra_ui_rects[i]
    if !rect.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        rect.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiRectExtra(i),
      entity: rect.entity,
      z: rect.payload.transform.translation.z,
      phase: 2,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_ui_box_shadows.length() {
    let shadow = extra_ui_box_shadows[i]
    if !shadow.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        shadow.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiBoxShadowExtra(i),
      entity: shadow.entity,
      z: shadow.payload.transform.translation.z,
      phase: 2,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  for i in 0..<extra_ui_texture_slices.length() {
    let slice = extra_ui_texture_slices[i]
    if !slice.payload.layers.matches(layers) ||
      !render2d_ui_overlay_matches_camera(
        slice.extracted_camera_entity,
        camera_entity,
      ) {
      continue
    }
    items.push(DrawItem::{
      kind: UiTextureSliceExtra(i),
      entity: slice.entity,
      z: slice.payload.transform.translation.z,
      phase: 2,
      tie,
      material_handle_id: -1,
      material_runtime_index: -1,
    })
    tie = tie + 1
  }
  sort_draw_items(items)
}

///|
fn extracted_sprite_item(
  entity : @core.Entity,
  transform : @transform.Transform,
  anchor_offset : @math.Vec2,
  draw_scale : @math.Vec2,
  color : @color.Color,
  texture : @asset.Handle[@asset.Image],
  layers : RenderLayers,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  scissor : @math.Rect?,
) -> ExtractedSprite {
  ExtractedSprite::{
    entity: phase_entity_ref_for_main(entity),
    payload: SpriteDrawPayload::{
      transform,
      anchor_offset,
      draw_scale,
      color,
      texture,
      layers,
      uv_min,
      uv_max,
      scissor,
    },
  }
}

///|
fn computed_sprite_slice_draw_payload(
  payload : ComputedSpriteSlicesDrawPayload,
  slice : TextureSlice,
) -> SpriteDrawPayload {
  let image_size_x = if payload.image_size.x == 0.0F {
    1.0F
  } else {
    payload.image_size.x
  }
  let image_size_y = if payload.image_size.y == 0.0F {
    1.0F
  } else {
    payload.image_size.y
  }
  let slice_size = @math.Vec2::new(
    slice.texture_rect.max.x - slice.texture_rect.min.x,
    slice.texture_rect.max.y - slice.texture_rect.min.y,
  )
  let mut slice_uv_min = @math.Vec2::new(
    slice.texture_rect.min.x / image_size_x,
    slice.texture_rect.min.y / image_size_y,
  )
  let mut slice_uv_max = @math.Vec2::new(
    slice.texture_rect.max.x / image_size_x,
    slice.texture_rect.max.y / image_size_y,
  )
  if payload.flip_x {
    let pair = swap_float_pair(slice_uv_min.x, slice_uv_max.x)
    slice_uv_min = @math.Vec2::new(pair.0, slice_uv_min.y)
    slice_uv_max = @math.Vec2::new(pair.1, slice_uv_max.y)
  }
  if payload.flip_y {
    let pair = swap_float_pair(slice_uv_min.y, slice_uv_max.y)
    slice_uv_min = @math.Vec2::new(slice_uv_min.x, pair.0)
    slice_uv_max = @math.Vec2::new(slice_uv_max.x, pair.1)
  }
  let rotation = payload.transform.rotation_z()
  let scaled_offset = @math.Vec2::new(
    slice.offset.x * payload.transform.scale.x,
    slice.offset.y * payload.transform.scale.y,
  )
  let world_offset = sprite_rotate_offset(scaled_offset, rotation)
  let draw_scale = @math.Vec2::new(
    if slice_size.x == 0.0F {
      payload.transform.scale.x
    } else {
      payload.transform.scale.x * slice.draw_size.x / slice_size.x
    },
    if slice_size.y == 0.0F {
      payload.transform.scale.y
    } else {
      payload.transform.scale.y * slice.draw_size.y / slice_size.y
    },
  )
  SpriteDrawPayload::{
    transform: @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(
        payload.transform.translation.x + world_offset.x,
        payload.transform.translation.y + world_offset.y,
      ),
      rotation,
      @math.Vec2::new(1.0F, 1.0F),
      z=payload.transform.translation.z,
    ),
    anchor_offset: @math.Vec2::new(0.0F, 0.0F),
    draw_scale,
    color: payload.color,
    texture: payload.texture,
    layers: payload.layers,
    uv_min: slice_uv_min,
    uv_max: slice_uv_max,
    scissor: payload.scissor,
  }
}

///|
fn extracted_ui_rect_item(
  entity : @core.Entity,
  extracted_camera_entity : @core.Entity,
  transform : @transform.Transform,
  anchor_offset : @math.Vec2,
  draw_scale : @math.Vec2,
  color : @color.Color,
  texture : @asset.Handle[@asset.Image],
  layers : RenderLayers,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  scissor : @math.Rect?,
  flags : Int,
  radius : UiCornerRadii,
  border : BorderRect,
) -> ExtractedUiRect {
  ExtractedUiRect::{
    entity: phase_entity_ref_for_main(entity),
    extracted_camera_entity,
    payload: UiRectDrawPayload::{
      transform,
      anchor_offset,
      draw_scale,
      color,
      texture,
      layers,
      uv_min,
      uv_max,
      scissor,
      flags,
      radius,
      border,
    },
  }
}

///|
fn render2d_push_extracted_ui_rect_for_test(
  world : @ecs.World,
  item : ExtractedUiRect,
) -> Unit {
  @ui_render_runtime.push_extracted_ui_rect(
    world,
    item.entity.main_entity,
    Some(item.extracted_camera_entity),
    item.payload,
  )
}

///|
fn extracted_mesh2d_item(
  entity : @core.Entity,
  mesh_id : Int,
  transform : @transform.Transform,
  layers : RenderLayers,
  wireframe? : Bool = false,
  wireframe_color? : @color.Color = @color.Color::white(),
) -> ExtractedMesh2d {
  ExtractedMesh2d::{
    entity: phase_entity_ref_for_main(entity),
    payload: Mesh2dDrawPayload::{
      mesh_id,
      transform,
      layers,
      wireframe,
      wireframe_color,
    },
  }
}

///|
test "render2d: mesh prepared material handle resolves from extracted entity instance" {
  let entity = @core.Entity::new(1, 0)
  let handle : @asset.Handle[ColorMaterial] = @asset.Handle::new(77)
  let extracted = extracted_mesh2d_item(
    entity,
    12,
    @transform.Transform::identity(),
    RenderLayers::RenderLayers(),
  )
  let instances = render_material2d_instances_for_tests([(entity, handle)])
  let prepared_id = match
    prepared_material2d_handle_for_mesh(extracted, instances) {
    Some(prepared_handle) => prepared_handle.id()
    None => -1
  }
  debug_inspect(prepared_id, content="77")
}

///|
test "render2d: extracted mesh keeps wireframe state out of gizmo path" {
  let extracted = extracted_mesh2d_item(
    @core.Entity::new(2, 0),
    12,
    @transform.Transform::identity(),
    RenderLayers::RenderLayers(),
    wireframe=true,
    wireframe_color=@color.Color::new(0.25F, 0.5F, 0.75F, 1.0F),
  )
  let ok = extracted.payload.wireframe &&
    extracted.payload.wireframe_color.r == 0.25F &&
    extracted.payload.wireframe_color.g == 0.5F &&
    extracted.payload.wireframe_color.b == 0.75F
  debug_inspect(ok, content="true")
}

///|
test "render2d: unified draw items order sprites and meshes by z" {
  let layers = RenderLayers::RenderLayers()
  let mesh_entity = @core.Entity::new(1, 0)
  let material_handle = @asset.Handle::new(1)
  let prepared_materials = prepared_color_materials_for_tests([
    (
      material_handle,
      ColorMaterial::new(@color.Color::white(), AlphaMode2d::Blend),
    ),
  ])
  let sprites : Array[ExtractedSprite] = [
    extracted_sprite_item(
      @core.Entity::new(2, 0),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      @asset.Handle::new(2),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
    ),
  ]
  let extra : Array[ExtractedSprite] = []
  let extra_ui_sprites : Array[ExtractedUiSprite] = []
  let extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch] = []
  let extra_ui_rects : Array[ExtractedUiRect] = []
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      mesh_entity,
      7,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=-1.0F,
      ),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (mesh_entity, material_handle),
  ])
  let items = draw_items_for_layers(
    sprites,
    [],
    extra,
    [],
    extra_ui_sprites,
    extra_ui_sprite_slice_batches,
    extra_ui_rects,
    extra_shadow,
    extra_slices,
    meshes,
    prepared_materials,
    material_instances,
    @core.Entity::new(0, 0),
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is SpriteMain(0)
  debug_inspect(ok, content="true")
}

///|
test "render2d: UI overlay draw items route by target camera" {
  let layers = RenderLayers::RenderLayers()
  let prepared_materials : @renderer.RenderAssets[
    PreparedMaterial2d[ColorMaterial],
  ] = @renderer.RenderAssets::new()
  let material_instances : RenderMaterial2dInstances[ColorMaterial] = RenderMaterial2dInstances::new()
  let camera_a = @core.Entity::new(10, 0)
  let camera_b = @core.Entity::new(11, 0)
  let sprites : Array[ExtractedSprite] = []
  let extra : Array[ExtractedSprite] = []
  let extra_ui_sprites : Array[ExtractedUiSprite] = []
  let extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch] = []
  let extra_ui_rects : Array[ExtractedUiRect] = [
    extracted_ui_rect_item(
      @core.Entity::new(100, 0),
      camera_a,
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::white(),
      @asset.Handle::new(1),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      0,
      UiCornerRadii::zero(),
      BorderRect::BorderRect(),
    ),
    extracted_ui_rect_item(
      @core.Entity::new(101, 0),
      camera_b,
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::white(),
      @asset.Handle::new(2),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      0,
      UiCornerRadii::zero(),
      BorderRect::BorderRect(),
    ),
  ]
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = []
  let items = draw_items_for_layers(
    sprites,
    [],
    extra,
    [],
    extra_ui_sprites,
    extra_ui_sprite_slice_batches,
    extra_ui_rects,
    extra_shadow,
    extra_slices,
    meshes,
    prepared_materials,
    material_instances,
    camera_a,
    layers,
  )
  let ok = items.length() == 1 && items[0].kind is UiRectExtra(0)
  debug_inspect(ok, content="true")
}

///|
test "render2d: scene draw items exclude UI overlays" {
  let layers = RenderLayers::RenderLayers()
  let prepared_materials : @renderer.RenderAssets[
    PreparedMaterial2d[ColorMaterial],
  ] = @renderer.RenderAssets::new()
  let material_instances : RenderMaterial2dInstances[ColorMaterial] = RenderMaterial2dInstances::new()
  let camera = @core.Entity::new(10, 0)
  let scene_items = draw_scene_items_for_layers(
    [],
    [],
    [],
    [],
    [],
    prepared_materials,
    material_instances,
    layers,
  )
  let ui_items = draw_ui_overlay_items_for_layers(
    [],
    [],
    [
      extracted_ui_rect_item(
        @core.Entity::new(100, 0),
        camera,
        @transform.Transform::identity(),
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        @color.Color::white(),
        @asset.Handle::new(1),
        layers,
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        None,
        0,
        UiCornerRadii::zero(),
        BorderRect::BorderRect(),
      ),
    ],
    [],
    [],
    camera,
    layers,
  )
  let ok = scene_items.length() == 0 &&
    ui_items.length() == 1 &&
    ui_items[0].kind is UiRectExtra(0)
  debug_inspect(ok, content="true")
}

///|
test "render2d: host window bloom postprocess keeps Bevy stage ownership" {
  let plan = render2d_camera_postprocess_plan(
    Some(@post_process.Bloom::Bloom()),
    0,
    None,
    None,
  )
  let ok = plan.uses_intermediate_source &&
    plan.apply_bloom_before_tonemapping &&
    !plan.tonemapping_stage_enabled &&
    !plan.cas_postprocess_enabled &&
    plan.draw_ui_overlay_after_postprocess
  debug_inspect(ok, content="true")
}

///|
test "render2d: host window tonemapping without bloom still leaves UI after postprocess" {
  let plan = render2d_camera_postprocess_plan(
    None,
    render2d_tonemapping_mode_to_int(TonyMcMapface),
    None,
    None,
  )
  let ok = plan.uses_intermediate_source &&
    !plan.apply_bloom_before_tonemapping &&
    plan.tonemapping_stage_enabled &&
    !plan.cas_postprocess_enabled &&
    plan.draw_ui_overlay_after_postprocess
  debug_inspect(ok, content="true")
}

///|
test "render2d: color grading alone keeps host window tonemapping copy stage" {
  let plan = render2d_camera_postprocess_plan(
    None,
    0,
    Some(@post_process.ColorGrading::ColorGrading()),
    None,
  )
  let ok = plan.uses_intermediate_source &&
    !plan.apply_bloom_before_tonemapping &&
    plan.tonemapping_stage_enabled &&
    !plan.cas_postprocess_enabled &&
    plan.draw_ui_overlay_after_postprocess
  debug_inspect(ok, content="true")
}

///|
test "render2d: CAS alone uses Bevy postprocess source path" {
  let plan = render2d_camera_postprocess_plan(
    None,
    0,
    None,
    Some(@cas.ContrastAdaptiveSharpening::ContrastAdaptiveSharpening()),
  )
  let ok = plan.uses_intermediate_source &&
    !plan.apply_bloom_before_tonemapping &&
    !plan.tonemapping_stage_enabled &&
    plan.cas_postprocess_enabled &&
    plan.draw_ui_overlay_after_postprocess
  debug_inspect(ok, content="true")
}

///|
test "render2d: queue counts keep overlay UI isolated per camera pass" {
  let world = @ecs.World::new()
  ensure_render_state_resource(world)
  @ui_render_runtime.clear_extracted_ui_nodes(world)
  let layers = RenderLayers::RenderLayers()
  let camera_a = @core.Entity::new(10, 0)
  let camera_b = @core.Entity::new(11, 0)
  render_state_update(world, fn(rs) {
    rs.draw_enabled = true
    rs.cameras.clear()
    rs.cameras.push(ExtractedCamera2d::{
      entity: camera_a,
      camera: @camera_camera.Camera::Camera().with_order(0),
      projection: @camera_projection2d.OrthographicProjection::default_2d(),
      transform: @transform.Transform::identity(),
      target: @camera_camera.RenderTarget::Screen,
      layers,
      bloom: None,
      compositing_space: None,
      target_format_raw: @render_view.extracted_view_target_format_raw(),
      tonemapping_mode: 0,
      deband_dither_enabled: false,
      color_grading: None,
      contrast_adaptive_sharpening: None,
      computed: CameraComputed::{
        target_size: @math.IVec2::new(640, 360),
        scale_factor: 1.0F,
      },
    })
    rs.cameras.push(ExtractedCamera2d::{
      entity: camera_b,
      camera: @camera_camera.Camera::Camera().with_order(1),
      projection: @camera_projection2d.OrthographicProjection::default_2d(),
      transform: @transform.Transform::identity(),
      target: @camera_camera.RenderTarget::Screen,
      layers,
      bloom: None,
      compositing_space: Some(@camera_compositing_space.CompositingSpace::Oklab),
      target_format_raw: @render_view.extracted_view_target_format_raw(
        compositing_space=Some(
          @camera_compositing_space.CompositingSpace::Oklab,
        ),
      ),
      tonemapping_mode: 0,
      deband_dither_enabled: false,
      color_grading: None,
      contrast_adaptive_sharpening: None,
      computed: CameraComputed::{
        target_size: @math.IVec2::new(640, 360),
        scale_factor: 1.0F,
      },
    })
    rs.prepared_camera_indices.clear()
    rs.prepared_camera_indices.push(0)
    rs.prepared_camera_indices.push(1)
  })
  |> ignore
  render2d_push_extracted_ui_rect_for_test(
    world,
    extracted_ui_rect_item(
      @core.Entity::new(200, 0),
      camera_a,
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::white(),
      @asset.Handle::new(3),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      0,
      UiCornerRadii::zero(),
      BorderRect::BorderRect(),
    ),
  )
  render2d_push_extracted_ui_rect_for_test(
    world,
    extracted_ui_rect_item(
      @core.Entity::new(201, 0),
      camera_b,
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::white(),
      @asset.Handle::new(4),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      0,
      UiCornerRadii::zero(),
      BorderRect::BorderRect(),
    ),
  )

  let compositing_space_ok = match render_state_ref(world) {
    Some(rs) =>
      render2d_extracted_camera_compositing_space(rs.cameras[1]) ==
      Some(@camera_compositing_space.CompositingSpace::Oklab)
    None => false
  }
  debug_inspect(compositing_space_ok, content="true")
  let target_format_ok = match render_state_ref(world) {
    Some(rs) =>
      render2d_extracted_camera_target_format_raw(rs.cameras[1]) ==
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB
    None => false
  }
  debug_inspect(target_format_ok, content="true")

  render_queue_system(world)

  let counts = render_state_ref(world).unwrap().queued_draw_item_counts
  debug_inspect(counts.to_json(), content="Array([Number(1), Number(1)])")
}

///|
test "render2d: ecs extract includes UI-only camera without Camera2d marker" {
  let world = @ecs.World::new()
  ensure_render_state_resource(world)
  @ui_render_runtime.clear_extracted_ui_nodes(world)
  let layers = RenderLayers::RenderLayers()
  let camera = world.spawn_empty()
  try! (world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  |> ignore)
  try! world.set_by_key(camera, @camera_hdr.ecs_key_hdr, @camera_hdr.Hdr::Hdr())
  try! world.set_by_key(
    camera,
    @camera_compositing_space.ecs_key_compositing_space,
    @camera_compositing_space.CompositingSpace::Srgb,
  )

  render2d_push_extracted_ui_rect_for_test(
    world,
    extracted_ui_rect_item(
      @core.Entity::new(300, 0),
      camera,
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::white(),
      @asset.Handle::new(5),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      0,
      UiCornerRadii::zero(),
      BorderRect::BorderRect(),
    ),
  )

  render_extract_system_ecs(world)

  let cameras = render_state_ref(world).unwrap().cameras
  let ok = cameras.length() == 1 &&
    cameras[0].entity.id == camera.id &&
    cameras[0].entity.generation == camera.generation &&
    render2d_extracted_camera_target_format_raw(cameras[0]) ==
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT
  debug_inspect(ok, content="true")
}

///|
test "render2d: mesh opaque alpha mode stays in opaque phase" {
  let layers = RenderLayers::RenderLayers()
  let opaque_entity = @core.Entity::new(2, 0)
  let blend_entity = @core.Entity::new(1, 0)
  let opaque_handle = @asset.Handle::new(20)
  let blend_handle = @asset.Handle::new(21)
  let prepared_materials = prepared_color_materials_for_tests([
    (
      opaque_handle,
      ColorMaterial::new(
        @color.Color::new(1.0F, 0.0F, 0.0F, 0.2F),
        AlphaMode2d::Opaque,
      ),
    ),
    (
      blend_handle,
      ColorMaterial::new(
        @color.Color::new(0.0F, 1.0F, 0.0F, 0.2F),
        AlphaMode2d::Blend,
      ),
    ),
  ])
  let sprites : Array[ExtractedSprite] = []
  let extra : Array[ExtractedSprite] = []
  let extra_ui_sprites : Array[ExtractedUiSprite] = []
  let extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch] = []
  let extra_ui_rects : Array[ExtractedUiRect] = []
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      opaque_entity,
      10,
      @transform.Transform::identity(),
      layers,
    ),
    extracted_mesh2d_item(
      blend_entity,
      11,
      @transform.Transform::identity(),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (opaque_entity, opaque_handle),
    (blend_entity, blend_handle),
  ])
  let items = draw_items_for_layers(
    sprites,
    [],
    extra,
    [],
    extra_ui_sprites,
    extra_ui_sprite_slice_batches,
    extra_ui_rects,
    extra_shadow,
    extra_slices,
    meshes,
    prepared_materials,
    material_instances,
    @core.Entity::new(0, 0),
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is Mesh(1)
  debug_inspect(ok, content="true")
}

///|
test "render2d: blend mesh with alpha=1 stays in transparent phase ordering" {
  let layers = RenderLayers::RenderLayers()
  let mesh_entity = @core.Entity::new(1, 0)
  let material_handle = @asset.Handle::new(30)
  let prepared_materials = prepared_color_materials_for_tests([
    (
      material_handle,
      ColorMaterial::new(
        @color.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
        AlphaMode2d::Blend,
      ),
    ),
  ])
  let sprites : Array[ExtractedSprite] = [
    extracted_sprite_item(
      @core.Entity::new(2, 0),
      @transform.Transform::identity(),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @color.Color::white(),
      @asset.Handle::new(10),
      layers,
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
    ),
  ]
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      mesh_entity,
      99,
      @transform.Transform::identity(),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (mesh_entity, material_handle),
  ])
  let items = draw_scene_items_for_layers(
    sprites,
    [],
    [],
    [],
    meshes,
    prepared_materials,
    material_instances,
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is SpriteMain(0)
  debug_inspect(ok, content="true")
}

///|
fn render2d_close(a : Float, b : Float) -> Bool {
  let delta = a - b
  let abs_delta = if delta < 0.0F { -delta } else { delta }
  abs_delta < 0.0001F
}

///|
test "render2d: sprite scale fill start and end keep Bevy crop direction" {
  let region_size = @math.Vec2::new(100.0F, 100.0F)
  let draw_scale = @math.Vec2::new(3.0F, 1.0F)
  let (start_uv_min, start_uv_max, _, _) = apply_scale_sprite_image_mode(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    draw_scale,
    region_size,
    SpriteScalingMode::FillStart,
  )
  let (end_uv_min, end_uv_max, _, _) = apply_scale_sprite_image_mode(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    draw_scale,
    region_size,
    SpriteScalingMode::FillEnd,
  )
  let ok = render2d_close(start_uv_min.y, 2.0F / 3.0F) &&
    render2d_close(start_uv_max.y, 1.0F) &&
    render2d_close(end_uv_min.y, 0.0F) &&
    render2d_close(end_uv_max.y, 1.0F / 3.0F)
  debug_inspect(ok, content="true")
}

///|
test "render2d: sprite scale fit start offsets quad center like Bevy" {
  let region_size = @math.Vec2::new(200.0F, 100.0F)
  let draw_scale = @math.Vec2::new(0.5F, 2.0F)
  let (_, _, scaled_draw_scale, local_offset) = apply_scale_sprite_image_mode(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    draw_scale,
    region_size,
    SpriteScalingMode::FitStart,
  )
  let center_offset = sprite_anchor_offset(
    Anchor::center(),
    0.0F,
    scaled_draw_scale,
    region_size,
    local_offset,
  )
  let top_offset = sprite_anchor_offset(
    Anchor::top_center(),
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(100.0F, 50.0F),
    @math.Vec2::new(0.0F, 0.0F),
  )
  let ok = render2d_close(scaled_draw_scale.x, 0.5F) &&
    render2d_close(scaled_draw_scale.y, 0.5F) &&
    render2d_close(center_offset.x, 0.0F) &&
    render2d_close(center_offset.y, 75.0F) &&
    render2d_close(top_offset.y, -25.0F)
  debug_inspect(ok, content="true")
}

///|
test "render2d: mesh mask alpha mode queues both items for shader-side cutoff" {
  let layers = RenderLayers::RenderLayers()
  let masked_low_entity = @core.Entity::new(1, 0)
  let masked_high_entity = @core.Entity::new(2, 0)
  let masked_low_handle = @asset.Handle::new(40)
  let masked_high_handle = @asset.Handle::new(41)
  let prepared_materials = prepared_color_materials_for_tests([
    (
      masked_low_handle,
      ColorMaterial::new(
        @color.Color::new(1.0F, 1.0F, 1.0F, 0.2F),
        AlphaMode2d::Mask(0.5F),
      ),
    ),
    (
      masked_high_handle,
      ColorMaterial::new(
        @color.Color::new(1.0F, 1.0F, 1.0F, 0.8F),
        AlphaMode2d::Mask(0.5F),
      ),
    ),
  ])
  let sprites : Array[ExtractedSprite] = []
  let extra : Array[ExtractedSprite] = []
  let extra_ui_sprites : Array[ExtractedUiSprite] = []
  let extra_ui_sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch] = []
  let extra_ui_rects : Array[ExtractedUiRect] = []
  let extra_shadow : Array[ExtractedUiBoxShadow] = []
  let extra_slices : Array[ExtractedUiTextureSlice] = []
  let meshes : Array[ExtractedMesh2d] = [
    extracted_mesh2d_item(
      masked_low_entity,
      20,
      @transform.Transform::identity(),
      layers,
    ),
    extracted_mesh2d_item(
      masked_high_entity,
      21,
      @transform.Transform::identity(),
      layers,
    ),
  ]
  let material_instances = render_material2d_instances_for_tests([
    (masked_low_entity, masked_low_handle),
    (masked_high_entity, masked_high_handle),
  ])
  let items = draw_items_for_layers(
    sprites,
    [],
    extra,
    [],
    extra_ui_sprites,
    extra_ui_sprite_slice_batches,
    extra_ui_rects,
    extra_shadow,
    extra_slices,
    meshes,
    prepared_materials,
    material_instances,
    @core.Entity::new(0, 0),
    layers,
  )
  let ok = items.length() == 2 &&
    items[0].kind is Mesh(0) &&
    items[1].kind is Mesh(1)
  debug_inspect(ok, content="true")
}

///|
test "render2d: tiled sprite mode computes repeated slices" {
  let sprite = Sprite::from_image(@asset.Handle::new(1))
    .with_image_mode(
      SpriteImageMode::tiled(tile_x=true, tile_y=false, stretch_value=0.5F),
    )
    .with_custom_size(Some(@math.Vec2::new(64.0F, 32.0F)))
  guard compute_sprite_slices_from_rect(
      sprite,
      @math.Vec2::new(32.0F, 32.0F),
      @math.Rect::new(@math.Vec2::zero(), @math.Vec2::new(32.0F, 32.0F)),
    )
    is Some(slices) else {
    debug_inspect(false, content="true")
    return
  }
  let ok = slices.slices.length() == 4 &&
    slices.slices[0].draw_size.x == 16.0F &&
    slices.slices[0].draw_size.y == 32.0F &&
    slices.slices[3].offset.x == 24.0F
  debug_inspect(ok, content="true")
}

///|
test "render2d: sliced sprite extraction follows computed slices instead of ui slice path" {
  let sprite = Sprite::from_image(@asset.Handle::new(1))
    .with_image_mode(
      SpriteImageMode::Sliced(TextureSlicer::new(BorderRect::square(8.0F))),
    )
    .with_custom_size(Some(@math.Vec2::new(96.0F, 64.0F)))
  guard compute_sprite_slices_from_rect(
      sprite,
      @math.Vec2::new(32.0F, 32.0F),
      @math.Rect::new(@math.Vec2::zero(), @math.Vec2::new(32.0F, 32.0F)),
    )
    is Some(computed_slices) else {
    debug_inspect(false, content="true")
    return
  }
  let sprite_slice_batches : Array[ExtractedComputedSpriteSlices] = []
  let appended = append_computed_sprite_slices(
    sprite_slice_batches,
    @core.Entity::new(1, 0),
    sprite,
    Some(computed_slices),
    Anchor::center(),
    @transform.Transform::identity(),
    RenderLayers::RenderLayers(),
    None,
    @math.Vec2::new(32.0F, 32.0F),
  )
  let ok = appended &&
    sprite_slice_batches.length() == 1 &&
    sprite_slice_batches[0].payload.texture.id() == 1 &&
    sprite_slice_batches[0].payload.slices.length() == 9 &&
    sprite_slice_batches[0].payload.slices[0].texture_rect.min.x == 0.0F &&
    sprite_slice_batches[0].payload.slices[0].texture_rect.max.x == 8.0F
  debug_inspect(ok, content="true")
}

///|
test "render2d: camera viewport clamp matches bevy edge behavior" {
  let viewport = Viewport::new(
    @math.IVec2::new(260, 120),
    @math.IVec2::new(50, 20),
  )
  let clamped = render2d_clamp_viewport(viewport, @math.IVec2::new(200, 100))
  let ok = clamped.physical_position.x == 199 &&
    clamped.physical_position.y == 99 &&
    clamped.physical_size.x == 1 &&
    clamped.physical_size.y == 1
  debug_inspect(ok, content="true")
}

///|
test "render2d: camera viewport scales with dpi resize factor" {
  let viewport = Viewport::new(
    @math.IVec2::new(10, 20),
    @math.IVec2::new(40, 30),
  )
  let scaled = render2d_scale_viewport(viewport, 1.5F)
  let ok = scaled.physical_position.x == 15 &&
    scaled.physical_position.y == 30 &&
    scaled.physical_size.x == 60 &&
    scaled.physical_size.y == 45
  debug_inspect(ok, content="true")
}

///|
test "render2d: logical view extent derives from physical viewport and scale factor" {
  let ok = render2d_logical_view_extent_axis(2560, 2.0F) == 1280 &&
    render2d_logical_view_extent_axis(1440, 2.0F) == 720 &&
    render2d_logical_view_extent_axis(999, 1.5F) == 666
  debug_inspect(ok, content="true")
}

///|
pub fn render_execute_system(world : @ecs.World) -> Unit {
  let execute_start = @time.host_time_now()
  let execute_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_2d",
  )
  let material_runtime_registry = material2d_runtime_registry_or_empty(world)
  let custom_mesh2d_runtime_registry = custom_mesh2d_runtime_registry_or_empty(
    world,
  )
  let color_material_probe : @asset.Handle[ColorMaterial] = @asset.Handle::new(
    0,
  )
  let use_color_material_fast_path = material_runtime_registry.entry_count() ==
    1 &&
    custom_mesh2d_runtime_registry.entry_count() == 0 &&
    material_runtime_registry.contains_type_name(
      material2d_runtime_type_name(color_material_probe),
    )
  let color_prepared_materials = prepared_material2d_assets_or_empty(
    world, color_material_probe,
  )
  let color_material_instances = render_material2d_instances_or_empty(
    world, color_material_probe,
  )
  let color_material_pipeline = material2d_pipeline_or_default(
    world, color_material_probe,
  )
  let ui_nodes = @ui_render_runtime.extracted_ui_nodes_or_empty(world)
  render_state_update(world, fn(rs) {
    if !rs.draw_enabled {
      render2d_runtime_state.diagnostic_prepared_camera_count = 0
      render2d_runtime_state.diagnostic_queued_draw_item_count = 0
      return
    }
    rs.draw_enabled = false
    gizmos_prepare(world)
    let cameras = rs.cameras
    if cameras.length() == 0 {
      gizmos_clear()
      rs.prepared_camera_indices.clear()
      rs.queued_draw_item_counts.clear()
      rs.queued_camera_draw_items.clear()
      render2d_runtime_state.diagnostic_prepared_camera_count = 0
      render2d_runtime_state.diagnostic_queued_draw_item_count = 0
      rs.extra_sprites.clear()
      rs.extra_sprite_slice_batches.clear()
      @ui_render_runtime.clear_extracted_ui_nodes(world)
      return
    }
    let sprites = rs.sprites
    let sprite_slice_batches = rs.sprite_slice_batches
    let extra_sprites = rs.extra_sprites
    let extra_sprite_slice_batches = rs.extra_sprite_slice_batches
    let extra_ui_sprites = ui_nodes.sprites
    let extra_ui_sprite_slice_batches = ui_nodes.sprite_slice_batches
    let extra_ui_rects = ui_nodes.rects
    let extra_ui_box_shadows = ui_nodes.box_shadows
    let extra_ui_texture_slices = ui_nodes.texture_slices
    let meshes = rs.meshes
    fn int_from_f32_floor_nonneg(x : Float) -> Int {
      if x <= 0.0F {
        0
      } else {
        x.to_int()
      }
    }

    fn physical_scissor_for_camera(
      rect : @math.Rect,
      viewport_x : Int,
      viewport_y : Int,
      viewport_w : Int,
      viewport_h : Int,
      scale_factor : Float,
    ) -> (Int, Int, Int, Int) {
      let sf = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
      let min_x = int_from_f32_floor_nonneg(rect.min.x * sf)
      let min_y = int_from_f32_floor_nonneg(rect.min.y * sf)
      // Match Bevy-style clipping behavior more closely: clamp the max edge with
      // floor semantics to avoid leaking a trailing row/column into adjacent UI.
      let mut max_x = int_from_f32_floor_nonneg(rect.max.x * sf)
      let mut max_y = int_from_f32_floor_nonneg(rect.max.y * sf)
      if max_x < min_x {
        max_x = min_x
      }
      if max_y < min_y {
        max_y = min_y
      }
      let mut x = viewport_x + min_x
      let mut y = viewport_y + min_y
      let mut w = max_x - min_x
      let mut h = max_y - min_y
      // Clamp to the camera viewport in physical pixels.
      if x < viewport_x {
        let dx = viewport_x - x
        x = viewport_x
        w = w - dx
      }
      if y < viewport_y {
        let dy = viewport_y - y
        y = viewport_y
        h = h - dy
      }
      let max_w = viewport_w - (x - viewport_x)
      let max_h = viewport_h - (y - viewport_y)
      if w > max_w {
        w = max_w
      }
      if h > max_h {
        h = max_h
      }
      if w < 0 {
        w = 0
      }
      if h < 0 {
        h = 0
      }
      (x, y, w, h)
    }

    let camera_indices = if rs.prepared_camera_indices.length() ==
      cameras.length() {
      rs.prepared_camera_indices
    } else {
      render2d_sorted_camera_indices(cameras)
    }
    for camera_order_index in 0..<camera_indices.length() {
      let index = camera_indices[camera_order_index]
      let camera = cameras[index]
      let mut target_id = -1
      let target_size = camera.computed.target_size
      let target_width = target_size.x
      let target_height = target_size.y
      match camera.target {
        Screen => target_id = -1
        Window(window_ref) =>
          if @window.window_host_window_for_ref(world, window_ref)
            is Some(host_window) {
            let surface_target_id = @renderer.host_gpu_surface_target_id_for_window(
              host_window,
            )
            if surface_target_id < 0 {
              target_id = surface_target_id
            }
          }
        Image(handle) => target_id = handle.id()
      }
      @renderer.host_gpu_set_active_surface_target(target_id)
      if target_width <= 0 || target_height <= 0 {
        continue
      }
      let mut scale_factor = camera.computed.scale_factor
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      let mut viewport_x = 0
      let mut viewport_y = 0
      let mut viewport_width = target_width
      let mut viewport_height = target_height
      let mut viewport_depth_min = 0.0F
      let mut viewport_depth_max = 1.0F
      let mut view_width = target_width
      let mut view_height = target_height
      if camera.camera.viewport is Some(viewport) {
        viewport_x = if viewport.physical_position.x < 0 {
          0
        } else {
          viewport.physical_position.x
        }
        viewport_y = if viewport.physical_position.y < 0 {
          0
        } else {
          viewport.physical_position.y
        }
        viewport_width = if viewport.physical_size.x < 0 {
          0
        } else {
          viewport.physical_size.x
        }
        viewport_height = if viewport.physical_size.y < 0 {
          0
        } else {
          viewport.physical_size.y
        }
        let max_width = if target_width - viewport_x < 0 {
          0
        } else {
          target_width - viewport_x
        }
        let max_height = if target_height - viewport_y < 0 {
          0
        } else {
          target_height - viewport_y
        }
        if viewport_width > max_width {
          viewport_width = max_width
        }
        if viewport_height > max_height {
          viewport_height = max_height
        }
        if viewport_width <= 0 || viewport_height <= 0 {
          continue
        }
        viewport_depth_min = viewport.depth_min
        viewport_depth_max = viewport.depth_max
        view_width = viewport_width
        view_height = viewport_height
      }
      // Keep render targets in physical pixels, but derive the camera
      // projection extent from the logical viewport size like Bevy does via
      // `@camera_camera.Camera::logical_viewport_size()`.
      let view_width_logical = render2d_logical_view_extent_axis(
        view_width, scale_factor,
      )
      let view_height_logical = render2d_logical_view_extent_axis(
        view_height, scale_factor,
      )
      if view_width_logical <= 0 || view_height_logical <= 0 {
        continue
      }
      let camera_uniform_scale = render2d_camera_uniform_scale(
        camera.projection,
        camera.transform,
      )
      let camera_rotation = camera.transform.rotation_z()
      let (clear_enabled, clear) = camera.camera.clear_color.resolve()
      let scene_cull_context = render2d_camera_scene_cull_context(camera)
      let mut draw_opaque_items : Array[DrawItem] = []
      let mut draw_transparent_items : Array[DrawItem] = []
      let mut ui_overlay_draw_items : Array[DrawItem] = []
      let queued_items_for_camera = match
        queued_camera_draw_items_at_index(rs, camera_order_index) {
        Some(item) =>
          if item.camera_entity.id == camera.entity.id &&
            item.camera_entity.generation == camera.entity.generation {
            Some(item)
          } else {
            queued_camera_draw_items_for_camera(rs, camera.entity)
          }
        None => queued_camera_draw_items_for_camera(rs, camera.entity)
      }
      match queued_items_for_camera {
        Some(queued) => {
          draw_opaque_items = queued.scene_opaque_items
          draw_transparent_items = queued.scene_transparent_items
          ui_overlay_draw_items = queued.ui_overlay_items
        }
        None => {
          let built = build_camera_draw_items(
            world,
            material_runtime_registry,
            custom_mesh2d_runtime_registry,
            sprites,
            sprite_slice_batches,
            extra_sprites,
            extra_sprite_slice_batches,
            extra_ui_sprites,
            extra_ui_sprite_slice_batches,
            extra_ui_rects,
            extra_ui_box_shadows,
            extra_ui_texture_slices,
            meshes,
            color_prepared_materials,
            color_material_instances,
            camera.entity,
            camera.layers,
            use_color_material_fast_path,
            scene_cull_context,
          )
          draw_opaque_items = built.scene_opaque_items
          draw_transparent_items = built.scene_transparent_items
          ui_overlay_draw_items = built.ui_overlay_items
        }
      }
      fn draw_camera_items(
        items : Array[DrawItem],
        draw_viewport_x : Int,
        draw_viewport_y : Int,
        draw_viewport_width : Int,
        draw_viewport_height : Int,
        draw_scale_factor : Float,
        tail_items : Array[DrawItem],
      ) -> Unit {
        let mut scissor_active = false
        let mut scissor_x = 0
        let mut scissor_y = 0
        let mut scissor_w = 0
        let mut scissor_h = 0
        let mut cached_color_material_handle_id = -1
        let mut cached_color_material : PreparedMaterial2d[ColorMaterial]? = None
        fn apply_scissor(rect_opt : @math.Rect?) -> Unit {
          match rect_opt {
            None =>
              if scissor_active {
                @renderer.host_gpu_clear_scissor()
                scissor_active = false
              }
            Some(rect) => {
              let (sx, sy, sw, sh) = physical_scissor_for_camera(
                rect, draw_viewport_x, draw_viewport_y, draw_viewport_width, draw_viewport_height,
                draw_scale_factor,
              )
              if !scissor_active ||
                sx != scissor_x ||
                sy != scissor_y ||
                sw != scissor_w ||
                sh != scissor_h {
                @renderer.host_gpu_set_scissor(x=sx, y=sy, width=sw, height=sh)
                scissor_active = true
                scissor_x = sx
                scissor_y = sy
                scissor_w = sw
                scissor_h = sh
              }
            }
          }
        }

        fn sprite_slice_batch_scissor_eq(
          lhs : @math.Rect?,
          rhs : @math.Rect?,
        ) -> Bool {
          match (lhs, rhs) {
            (None, None) => true
            (Some(a), Some(b)) =>
              a.min.x == b.min.x &&
              a.min.y == b.min.y &&
              a.max.x == b.max.x &&
              a.max.y == b.max.y
            _ => false
          }
        }

        fn sprite_payload_can_merge(
          lhs : SpriteDrawPayload,
          rhs : SpriteDrawPayload,
          lhs_rotation : Float,
          rhs_rotation : Float,
          lhs_z : Float,
          rhs_z : Float,
        ) -> Bool {
          lhs.texture.id() == rhs.texture.id() &&
          lhs_rotation == rhs_rotation &&
          lhs.draw_scale.x == rhs.draw_scale.x &&
          lhs.draw_scale.y == rhs.draw_scale.y &&
          lhs_z == rhs_z &&
          lhs.color.r == rhs.color.r &&
          lhs.color.g == rhs.color.g &&
          lhs.color.b == rhs.color.b &&
          lhs.color.a == rhs.color.a &&
          sprite_slice_batch_scissor_eq(lhs.scissor, rhs.scissor)
        }

        fn sprite_payload_append_slice_xy_uv(
          out : Array[Float],
          payload : SpriteDrawPayload,
        ) -> Unit {
          let transform = payload.transform
          out.push(transform.translation.x + payload.anchor_offset.x)
          out.push(transform.translation.y + payload.anchor_offset.y)
          out.push(payload.uv_min.x)
          out.push(payload.uv_min.y)
          out.push(payload.uv_max.x)
          out.push(payload.uv_max.y)
        }

        fn ui_sprite_payload_can_merge(
          lhs : @ui_render_runtime.UiSpriteDrawPayload,
          rhs : @ui_render_runtime.UiSpriteDrawPayload,
          lhs_rotation : Float,
          rhs_rotation : Float,
          lhs_z : Float,
          rhs_z : Float,
        ) -> Bool {
          lhs.texture.id() == rhs.texture.id() &&
          lhs_rotation == rhs_rotation &&
          lhs.draw_scale.x == rhs.draw_scale.x &&
          lhs.draw_scale.y == rhs.draw_scale.y &&
          lhs_z == rhs_z &&
          lhs.color.r == rhs.color.r &&
          lhs.color.g == rhs.color.g &&
          lhs.color.b == rhs.color.b &&
          lhs.color.a == rhs.color.a &&
          sprite_slice_batch_scissor_eq(lhs.scissor, rhs.scissor)
        }

        fn ui_sprite_payload_append_slice_xy_uv(
          out : Array[Float],
          payload : @ui_render_runtime.UiSpriteDrawPayload,
        ) -> Unit {
          let transform = payload.transform
          out.push(transform.translation.x + payload.anchor_offset.x)
          out.push(transform.translation.y + payload.anchor_offset.y)
          out.push(payload.uv_min.x)
          out.push(payload.uv_min.y)
          out.push(payload.uv_max.x)
          out.push(payload.uv_max.y)
        }

        let merged_slice_xy_uv : Array[Float] = []

        fn draw_sprite_payload_after_scissor(
          sprite : SpriteDrawPayload,
        ) -> Unit {
          let transform = sprite.transform
          let pos = @math.Vec2::new(
            transform.translation.x + sprite.anchor_offset.x,
            transform.translation.y + sprite.anchor_offset.y,
          )
          @renderer.host_gpu_draw_sprite_uv(
            texture_id=sprite.texture.id(),
            x=pos.x,
            y=pos.y,
            rotation=transform.rotation_z(),
            scale_x=sprite.draw_scale.x,
            scale_y=sprite.draw_scale.y,
            color_r=sprite.color.r,
            color_g=sprite.color.g,
            color_b=sprite.color.b,
            color_a=sprite.color.a,
            uv_min_x=sprite.uv_min.x,
            uv_min_y=sprite.uv_min.y,
            uv_max_x=sprite.uv_max.x,
            uv_max_y=sprite.uv_max.y,
          )
        }

        fn draw_computed_sprite_slices(
          payload : ComputedSpriteSlicesDrawPayload,
        ) -> Unit {
          apply_scissor(payload.scissor)
          for slice in payload.slices {
            draw_sprite_payload_after_scissor(
              computed_sprite_slice_draw_payload(payload, slice),
            )
          }
        }

        fn draw_camera_item(item : DrawItem) -> Unit {
          match item.kind {
            SpriteMain(i) => {
              let sprite = sprites[i].payload
              apply_scissor(sprite.scissor)
              let transform = sprite.transform
              let pos = @math.Vec2::new(
                transform.translation.x + sprite.anchor_offset.x,
                transform.translation.y + sprite.anchor_offset.y,
              )
              @renderer.host_gpu_draw_sprite_uv(
                texture_id=sprite.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=sprite.draw_scale.x,
                scale_y=sprite.draw_scale.y,
                color_r=sprite.color.r,
                color_g=sprite.color.g,
                color_b=sprite.color.b,
                color_a=sprite.color.a,
                uv_min_x=sprite.uv_min.x,
                uv_min_y=sprite.uv_min.y,
                uv_max_x=sprite.uv_max.x,
                uv_max_y=sprite.uv_max.y,
              )
            }
            SpriteSliceBatchMain(i) =>
              draw_computed_sprite_slices(sprite_slice_batches[i].payload)
            SpriteExtra(i) => {
              let sprite = extra_sprites[i].payload
              apply_scissor(sprite.scissor)
              let transform = sprite.transform
              let pos = @math.Vec2::new(
                transform.translation.x + sprite.anchor_offset.x,
                transform.translation.y + sprite.anchor_offset.y,
              )
              @renderer.host_gpu_draw_sprite_uv(
                texture_id=sprite.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=sprite.draw_scale.x,
                scale_y=sprite.draw_scale.y,
                color_r=sprite.color.r,
                color_g=sprite.color.g,
                color_b=sprite.color.b,
                color_a=sprite.color.a,
                uv_min_x=sprite.uv_min.x,
                uv_min_y=sprite.uv_min.y,
                uv_max_x=sprite.uv_max.x,
                uv_max_y=sprite.uv_max.y,
              )
            }
            SpriteSliceBatchExtra(i) => {
              let batch = extra_sprite_slice_batches[i].payload
              apply_scissor(batch.scissor)
              @renderer.host_gpu_draw_sprite_uv_slices(
                texture_id=batch.texture.id(),
                rotation=batch.rotation,
                scale_x=batch.draw_scale.x,
                scale_y=batch.draw_scale.y,
                color_r=batch.color.r,
                color_g=batch.color.g,
                color_b=batch.color.b,
                color_a=batch.color.a,
                slices_xy_uv=batch.slices_xy_uv,
              )
            }
            UiSpriteExtra(i) => {
              let sprite = extra_ui_sprites[i].payload
              apply_scissor(sprite.scissor)
              let transform = sprite.transform
              let pos = @math.Vec2::new(
                transform.translation.x + sprite.anchor_offset.x,
                transform.translation.y + sprite.anchor_offset.y,
              )
              @renderer.host_gpu_draw_sprite_uv(
                texture_id=sprite.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=sprite.draw_scale.x,
                scale_y=sprite.draw_scale.y,
                color_r=sprite.color.r,
                color_g=sprite.color.g,
                color_b=sprite.color.b,
                color_a=sprite.color.a,
                uv_min_x=sprite.uv_min.x,
                uv_min_y=sprite.uv_min.y,
                uv_max_x=sprite.uv_max.x,
                uv_max_y=sprite.uv_max.y,
              )
            }
            UiSpriteSliceBatchExtra(i) => {
              let batch = extra_ui_sprite_slice_batches[i].payload
              apply_scissor(batch.scissor)
              @renderer.host_gpu_draw_sprite_uv_slices(
                texture_id=batch.texture.id(),
                rotation=batch.rotation,
                scale_x=batch.draw_scale.x,
                scale_y=batch.draw_scale.y,
                color_r=batch.color.r,
                color_g=batch.color.g,
                color_b=batch.color.b,
                color_a=batch.color.a,
                slices_xy_uv=batch.slices_xy_uv,
              )
            }
            Mesh(i) => {
              apply_scissor(None)
              let mesh = meshes[i]
              if use_color_material_fast_path {
                if item.material_handle_id < 0 {
                  draw_material2d_mesh_item(
                    mesh, color_prepared_materials, color_material_instances, color_material_pipeline,
                  )
                } else {
                  if item.material_handle_id != cached_color_material_handle_id {
                    let material_handle : @asset.Handle[
                      PreparedMaterial2d[ColorMaterial],
                    ] = @asset.Handle::new(item.material_handle_id)
                    cached_color_material = prepared_material2d_get(
                      color_prepared_materials, material_handle,
                    )
                    cached_color_material_handle_id = item.material_handle_id
                  }
                  guard cached_color_material is Some(material) else { return }
                  draw_material2d_mesh_item_with_prepared_material(
                    mesh, material, color_material_pipeline,
                  )
                }
              } else {
                draw_registered_material2d_mesh_item(
                  world,
                  material_runtime_registry,
                  item.material_runtime_index,
                  mesh,
                )
              }
            }
            CustomMesh(i) => {
              apply_scissor(None)
              draw_registered_custom_mesh2d_item(
                custom_mesh2d_runtime_registry,
                item.material_runtime_index,
                meshes[i],
              )
            }
            UiRectExtra(i) => {
              let rect = extra_ui_rects[i].payload
              apply_scissor(rect.scissor)
              let transform = rect.transform
              let pos = @math.Vec2::new(
                transform.translation.x + rect.anchor_offset.x,
                transform.translation.y + rect.anchor_offset.y,
              )
              @renderer.host_gpu_draw_ui_rect(
                texture_id=rect.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=rect.draw_scale.x,
                scale_y=rect.draw_scale.y,
                color_r=rect.color.r,
                color_g=rect.color.g,
                color_b=rect.color.b,
                color_a=rect.color.a,
                uv_min_x=rect.uv_min.x,
                uv_min_y=rect.uv_min.y,
                uv_max_x=rect.uv_max.x,
                uv_max_y=rect.uv_max.y,
                flags=rect.flags,
                radius_tl=rect.radius.top_left,
                radius_tr=rect.radius.top_right,
                radius_br=rect.radius.bottom_right,
                radius_bl=rect.radius.bottom_left,
                border_left=rect.border.left,
                border_top=rect.border.top,
                border_right=rect.border.right,
                border_bottom=rect.border.bottom,
              )
            }
            UiBoxShadowExtra(i) => {
              let shadow = extra_ui_box_shadows[i].payload
              apply_scissor(shadow.scissor)
              let transform = shadow.transform
              let pos = @math.Vec2::new(
                transform.translation.x + shadow.anchor_offset.x,
                transform.translation.y + shadow.anchor_offset.y,
              )
              @renderer.host_gpu_draw_ui_box_shadow(
                texture_id=shadow.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=shadow.draw_scale.x,
                scale_y=shadow.draw_scale.y,
                color_r=shadow.color.r,
                color_g=shadow.color.g,
                color_b=shadow.color.b,
                color_a=shadow.color.a,
                size_x=shadow.size.x,
                size_y=shadow.size.y,
                radius_tl=shadow.radius.top_left,
                radius_tr=shadow.radius.top_right,
                radius_br=shadow.radius.bottom_right,
                radius_bl=shadow.radius.bottom_left,
                blur=shadow.blur,
                samples=shadow.samples,
              )
            }
            UiTextureSliceExtra(i) => {
              let slice = extra_ui_texture_slices[i].payload
              apply_scissor(slice.scissor)
              let transform = slice.transform
              let pos = @math.Vec2::new(
                transform.translation.x + slice.anchor_offset.x,
                transform.translation.y + slice.anchor_offset.y,
              )
              @renderer.host_gpu_draw_ui_texture_slice(
                texture_id=slice.texture.id(),
                x=pos.x,
                y=pos.y,
                rotation=transform.rotation_z(),
                scale_x=slice.draw_scale.x,
                scale_y=slice.draw_scale.y,
                color_r=slice.color.r,
                color_g=slice.color.g,
                color_b=slice.color.b,
                color_a=slice.color.a,
                texture_slice_l=slice.texture_slices.x,
                texture_slice_t=slice.texture_slices.y,
                texture_slice_r=slice.texture_slices.z,
                texture_slice_b=slice.texture_slices.w,
                target_slice_l=slice.target_slices.x,
                target_slice_t=slice.target_slices.y,
                target_slice_r=slice.target_slices.z,
                target_slice_b=slice.target_slices.w,
                repeat_side_x=slice.repeat.x,
                repeat_side_y=slice.repeat.y,
                repeat_center_x=slice.repeat.z,
                repeat_center_y=slice.repeat.w,
                atlas_l=slice.atlas_rect.x,
                atlas_t=slice.atlas_rect.y,
                atlas_r=slice.atlas_rect.z,
                atlas_b=slice.atlas_rect.w,
              )
            }
          }
        }

        fn draw_camera_item_array(item_array : Array[DrawItem]) -> Unit {
          let item_count = item_array.length()
          let mut item_index = 0
          while item_index < item_count {
            let item = item_array[item_index]
            match item.kind {
              SpriteMain(i) => {
                let first_sprite = sprites[i].payload
                let first_rotation = first_sprite.transform.rotation_z()
                let first_z = item.z
                apply_scissor(first_sprite.scissor)
                let mut merged_end = item_index + 1
                while merged_end < item_count {
                  let next_item = item_array[merged_end]
                  match next_item.kind {
                    SpriteMain(next_i) => {
                      let next_sprite = sprites[next_i].payload
                      let next_rotation = next_sprite.transform.rotation_z()
                      if !sprite_payload_can_merge(
                          first_sprite,
                          next_sprite,
                          first_rotation,
                          next_rotation,
                          first_z,
                          next_item.z,
                        ) {
                        break
                      }
                      merged_end = merged_end + 1
                    }
                    _ => break
                  }
                }
                merged_slice_xy_uv.clear()
                merged_slice_xy_uv.reserve_capacity(
                  (merged_end - item_index) * 6,
                )
                sprite_payload_append_slice_xy_uv(
                  merged_slice_xy_uv, first_sprite,
                )
                for merged_index in (item_index + 1)..<merged_end {
                  if item_array[merged_index].kind is SpriteMain(next_i) {
                    sprite_payload_append_slice_xy_uv(
                      merged_slice_xy_uv,
                      sprites[next_i].payload,
                    )
                  }
                }
                @renderer.host_gpu_draw_sprite_uv_slices(
                  texture_id=first_sprite.texture.id(),
                  rotation=first_rotation,
                  scale_x=first_sprite.draw_scale.x,
                  scale_y=first_sprite.draw_scale.y,
                  color_r=first_sprite.color.r,
                  color_g=first_sprite.color.g,
                  color_b=first_sprite.color.b,
                  color_a=first_sprite.color.a,
                  slices_xy_uv=merged_slice_xy_uv,
                )
                item_index = merged_end
              }
              SpriteExtra(i) => {
                let first_sprite = extra_sprites[i].payload
                let first_rotation = first_sprite.transform.rotation_z()
                let first_z = item.z
                apply_scissor(first_sprite.scissor)
                let mut merged_end = item_index + 1
                while merged_end < item_count {
                  let next_item = item_array[merged_end]
                  match next_item.kind {
                    SpriteExtra(next_i) => {
                      let next_sprite = extra_sprites[next_i].payload
                      let next_rotation = next_sprite.transform.rotation_z()
                      if !sprite_payload_can_merge(
                          first_sprite,
                          next_sprite,
                          first_rotation,
                          next_rotation,
                          first_z,
                          next_item.z,
                        ) {
                        break
                      }
                      merged_end = merged_end + 1
                    }
                    _ => break
                  }
                }
                merged_slice_xy_uv.clear()
                merged_slice_xy_uv.reserve_capacity(
                  (merged_end - item_index) * 6,
                )
                sprite_payload_append_slice_xy_uv(
                  merged_slice_xy_uv, first_sprite,
                )
                for merged_index in (item_index + 1)..<merged_end {
                  if item_array[merged_index].kind is SpriteExtra(next_i) {
                    sprite_payload_append_slice_xy_uv(
                      merged_slice_xy_uv,
                      extra_sprites[next_i].payload,
                    )
                  }
                }
                @renderer.host_gpu_draw_sprite_uv_slices(
                  texture_id=first_sprite.texture.id(),
                  rotation=first_rotation,
                  scale_x=first_sprite.draw_scale.x,
                  scale_y=first_sprite.draw_scale.y,
                  color_r=first_sprite.color.r,
                  color_g=first_sprite.color.g,
                  color_b=first_sprite.color.b,
                  color_a=first_sprite.color.a,
                  slices_xy_uv=merged_slice_xy_uv,
                )
                item_index = merged_end
              }
              SpriteSliceBatchExtra(i) => {
                let first_batch = extra_sprite_slice_batches[i].payload
                apply_scissor(first_batch.scissor)
                @renderer.host_gpu_draw_sprite_uv_slices(
                  texture_id=first_batch.texture.id(),
                  rotation=first_batch.rotation,
                  scale_x=first_batch.draw_scale.x,
                  scale_y=first_batch.draw_scale.y,
                  color_r=first_batch.color.r,
                  color_g=first_batch.color.g,
                  color_b=first_batch.color.b,
                  color_a=first_batch.color.a,
                  slices_xy_uv=first_batch.slices_xy_uv,
                )
                item_index = item_index + 1
              }
              UiSpriteExtra(i) => {
                let first_sprite = extra_ui_sprites[i].payload
                let first_rotation = first_sprite.transform.rotation_z()
                let first_z = item.z
                apply_scissor(first_sprite.scissor)
                let mut merged_end = item_index + 1
                while merged_end < item_count {
                  let next_item = item_array[merged_end]
                  match next_item.kind {
                    UiSpriteExtra(next_i) => {
                      let next_sprite = extra_ui_sprites[next_i].payload
                      let next_rotation = next_sprite.transform.rotation_z()
                      if !ui_sprite_payload_can_merge(
                          first_sprite,
                          next_sprite,
                          first_rotation,
                          next_rotation,
                          first_z,
                          next_item.z,
                        ) {
                        break
                      }
                      merged_end = merged_end + 1
                    }
                    _ => break
                  }
                }
                merged_slice_xy_uv.clear()
                merged_slice_xy_uv.reserve_capacity(
                  (merged_end - item_index) * 6,
                )
                ui_sprite_payload_append_slice_xy_uv(
                  merged_slice_xy_uv, first_sprite,
                )
                for merged_index in (item_index + 1)..<merged_end {
                  if item_array[merged_index].kind is UiSpriteExtra(next_i) {
                    ui_sprite_payload_append_slice_xy_uv(
                      merged_slice_xy_uv,
                      extra_ui_sprites[next_i].payload,
                    )
                  }
                }
                @renderer.host_gpu_draw_sprite_uv_slices(
                  texture_id=first_sprite.texture.id(),
                  rotation=first_rotation,
                  scale_x=first_sprite.draw_scale.x,
                  scale_y=first_sprite.draw_scale.y,
                  color_r=first_sprite.color.r,
                  color_g=first_sprite.color.g,
                  color_b=first_sprite.color.b,
                  color_a=first_sprite.color.a,
                  slices_xy_uv=merged_slice_xy_uv,
                )
                item_index = merged_end
              }
              UiSpriteSliceBatchExtra(i) => {
                let first_batch = extra_ui_sprite_slice_batches[i].payload
                apply_scissor(first_batch.scissor)
                @renderer.host_gpu_draw_sprite_uv_slices(
                  texture_id=first_batch.texture.id(),
                  rotation=first_batch.rotation,
                  scale_x=first_batch.draw_scale.x,
                  scale_y=first_batch.draw_scale.y,
                  color_r=first_batch.color.r,
                  color_g=first_batch.color.g,
                  color_b=first_batch.color.b,
                  color_a=first_batch.color.a,
                  slices_xy_uv=first_batch.slices_xy_uv,
                )
                item_index = item_index + 1
              }
              _ => {
                draw_camera_item(item)
                item_index = item_index + 1
              }
            }
          }
        }

        draw_camera_item_array(items)
        draw_camera_item_array(tail_items)
        if scissor_active {
          @renderer.host_gpu_clear_scissor()
        }
      }

      fn draw_ui_overlay_passes(items : Array[DrawItem]) -> Unit {
        if items.length() == 0 {
          return
        }
        @renderer.host_gpu_begin_pass(
          target_id~,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear.r,
          clear_g=clear.g,
          clear_b=clear.b,
          clear_a=clear.a,
          camera_x=camera.transform.translation.x,
          camera_y=camera.transform.translation.y,
          camera_rotation~,
          camera_scale=camera_uniform_scale,
          viewport_x~,
          viewport_y~,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=0,
        )
        draw_camera_items(
          items,
          viewport_x,
          viewport_y,
          viewport_width,
          viewport_height,
          scale_factor,
          [],
        )
        @renderer.host_gpu_end_pass()
      }

      let tonemapping_mode = camera.tonemapping_mode
      let deband_dither_enabled = camera.deband_dither_enabled
      let color_grading = camera.color_grading
      let camera_postprocess_plan = render2d_camera_postprocess_plan(
        camera.bloom,
        tonemapping_mode,
        color_grading,
        camera.contrast_adaptive_sharpening,
      )
      fn scene_draw_items_need_depth(
        opaque_items : Array[DrawItem],
        transparent_items : Array[DrawItem],
      ) -> Bool {
        if opaque_items.length() > 0 {
          return true
        }
        for item in transparent_items {
          if item.kind is Mesh(_) {
            return true
          }
        }
        false
      }
      let scene_needs_depth = scene_draw_items_need_depth(
        draw_opaque_items, draw_transparent_items,
      )
      fn begin_scene_pass(
        scene_target_id : Int,
        draw_viewport_x : Int,
        draw_viewport_y : Int,
        draw_viewport_width : Int,
        draw_viewport_height : Int,
        clear_stage : Bool,
      ) -> Unit {
        if scene_needs_depth {
          @renderer.host_gpu_begin_pass_with_depth(
            target_id=scene_target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear.r,
            clear_g=clear.g,
            clear_b=clear.b,
            clear_a=clear.a,
            camera_x=camera.transform.translation.x,
            camera_y=camera.transform.translation.y,
            camera_rotation~,
            camera_scale=camera_uniform_scale,
            viewport_x=draw_viewport_x,
            viewport_y=draw_viewport_y,
            viewport_width=draw_viewport_width,
            viewport_height=draw_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=if clear_stage { 1 } else { 0 },
          )
        } else {
          @renderer.host_gpu_begin_pass(
            target_id=scene_target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear.r,
            clear_g=clear.g,
            clear_b=clear.b,
            clear_a=clear.a,
            camera_x=camera.transform.translation.x,
            camera_y=camera.transform.translation.y,
            camera_rotation~,
            camera_scale=camera_uniform_scale,
            viewport_x=draw_viewport_x,
            viewport_y=draw_viewport_y,
            viewport_width=draw_viewport_width,
            viewport_height=draw_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=if clear_stage { 1 } else { 0 },
          )
        }
      }

      fn draw_scene_passes(
        scene_target_id : Int,
        draw_viewport_x : Int,
        draw_viewport_y : Int,
        draw_viewport_width : Int,
        draw_viewport_height : Int,
        draw_scale_factor : Float,
        draw_gizmos : Bool,
      ) -> Unit {
        let has_opaque = draw_opaque_items.length() > 0
        let has_transparent = draw_transparent_items.length() > 0
        let has_wireframe = has_wireframe_meshes_for_layers(
          meshes,
          camera.layers,
        )
        if has_opaque {
          begin_scene_pass(
            scene_target_id, draw_viewport_x, draw_viewport_y, draw_viewport_width,
            draw_viewport_height, clear_enabled,
          )
          draw_camera_items(
            draw_opaque_items,
            draw_viewport_x,
            draw_viewport_y,
            draw_viewport_width,
            draw_viewport_height,
            draw_scale_factor,
            [],
          )
          @renderer.host_gpu_end_pass()
          if has_transparent || has_wireframe || draw_gizmos {
            begin_scene_pass(
              scene_target_id, draw_viewport_x, draw_viewport_y, draw_viewport_width,
              draw_viewport_height, false,
            )
            draw_camera_items(
              draw_transparent_items,
              draw_viewport_x,
              draw_viewport_y,
              draw_viewport_width,
              draw_viewport_height,
              draw_scale_factor,
              [],
            )
            draw_wireframe_meshes_for_layers(meshes, camera.layers)
            if draw_gizmos {
              gizmos_draw_lines(camera.layers)
            }
            @renderer.host_gpu_end_pass()
          }
        } else {
          begin_scene_pass(
            scene_target_id, draw_viewport_x, draw_viewport_y, draw_viewport_width,
            draw_viewport_height, clear_enabled,
          )
          draw_camera_items(
            draw_transparent_items,
            draw_viewport_x,
            draw_viewport_y,
            draw_viewport_width,
            draw_viewport_height,
            draw_scale_factor,
            [],
          )
          draw_wireframe_meshes_for_layers(meshes, camera.layers)
          if draw_gizmos {
            gizmos_draw_lines(camera.layers)
          }
          @renderer.host_gpu_end_pass()
        }
      }
      let mut auto_postprocess_source : @asset.Handle[@asset.Image]? = None
      if camera_postprocess_plan.uses_intermediate_source {
        auto_postprocess_source = Some(
          render2d_get_or_create_postprocess_intermediate_target(
            rs,
            camera.entity,
            viewport_width,
            viewport_height,
          ),
        )
      }

      if auto_postprocess_source is Some(source) {
        let cas_postprocess_enabled = camera_postprocess_plan.cas_postprocess_enabled
        let final_target : @asset.Handle[@asset.Image] = @asset.Handle::new(
          target_id,
        )
        let mut next_postprocess_slot = 1
        fn allocate_postprocess_target() -> @asset.Handle[@asset.Image] {
          let target = render2d_get_or_create_postprocess_intermediate_target(
            rs,
            camera.entity,
            viewport_width,
            viewport_height,
            slot=next_postprocess_slot,
          )
          next_postprocess_slot = next_postprocess_slot + 1
          target
        }

        fn begin_postprocess_pass(
          target : @asset.Handle[@asset.Image],
          full_viewport : Bool,
          clear_stage : Bool,
        ) -> Unit {
          let (
            pass_viewport_x,
            pass_viewport_y,
            pass_viewport_width,
            pass_viewport_height,
          ) = if full_viewport {
            (0, 0, viewport_width, viewport_height)
          } else {
            (viewport_x, viewport_y, viewport_width, viewport_height)
          }
          @renderer.host_gpu_begin_pass(
            target_id=target.id(),
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear.r,
            clear_g=clear.g,
            clear_b=clear.b,
            clear_a=clear.a,
            camera_x=camera.transform.translation.x,
            camera_y=camera.transform.translation.y,
            camera_rotation~,
            camera_scale=camera_uniform_scale,
            viewport_x=pass_viewport_x,
            viewport_y=pass_viewport_y,
            viewport_width=pass_viewport_width,
            viewport_height=pass_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=if clear_stage { 1 } else { 0 },
          )
        }
        draw_scene_passes(
          @asset.Handle::id(source),
          0,
          0,
          viewport_width,
          viewport_height,
          scale_factor,
          false,
        )

        let mut postprocess_source = source
        let mut rendered_to_final_target = false
        if camera_postprocess_plan.apply_bloom_before_tonemapping {
          let bloom_target = allocate_postprocess_target()
          begin_postprocess_pass(bloom_target, true, true)
          render2d_draw_camera_blit(postprocess_source)
          render2d_apply_camera_bloom_from_source(
            camera, postprocess_source, viewport_width, viewport_height,
          )
          @renderer.host_gpu_end_pass()
          postprocess_source = bloom_target
        }
        if camera_postprocess_plan.tonemapping_stage_enabled {
          let tonemapping_target = if cas_postprocess_enabled {
            allocate_postprocess_target()
          } else {
            final_target
          }
          begin_postprocess_pass(
            tonemapping_target, cas_postprocess_enabled, true,
          )
          render2d_draw_camera_tonemapping(
            world, postprocess_source, tonemapping_mode, deband_dither_enabled, color_grading,
            viewport_width, viewport_height,
          )
          if !cas_postprocess_enabled {
            gizmos_draw_lines(camera.layers)
            rendered_to_final_target = true
          }
          @renderer.host_gpu_end_pass()
          postprocess_source = tonemapping_target
        } else if !cas_postprocess_enabled {
          begin_postprocess_pass(final_target, false, true)
          render2d_draw_camera_blit(postprocess_source)
          gizmos_draw_lines(camera.layers)
          @renderer.host_gpu_end_pass()
          rendered_to_final_target = true
        }
        if cas_postprocess_enabled {
          begin_postprocess_pass(final_target, false, true)
          render2d_draw_camera_cas(
            postprocess_source,
            camera.contrast_adaptive_sharpening,
            viewport_width,
            viewport_height,
          )
          gizmos_draw_lines(camera.layers)
          @renderer.host_gpu_end_pass()
          rendered_to_final_target = true
        }
        if !rendered_to_final_target {
          begin_postprocess_pass(final_target, false, true)
          render2d_draw_camera_blit(postprocess_source)
          gizmos_draw_lines(camera.layers)
          @renderer.host_gpu_end_pass()
        }
        if camera_postprocess_plan.draw_ui_overlay_after_postprocess {
          draw_ui_overlay_passes(ui_overlay_draw_items)
        }
        continue
      }

      if camera.bloom is None {
        draw_scene_passes(
          target_id, viewport_x, viewport_y, viewport_width, viewport_height, scale_factor,
          true,
        )
        if ui_overlay_draw_items.length() > 0 {
          draw_ui_overlay_passes(ui_overlay_draw_items)
        }
        continue
      }
      draw_scene_passes(
        target_id, viewport_x, viewport_y, viewport_width, viewport_height, scale_factor,
        true,
      )
    }
    gizmos_clear()
    rs.prepared_camera_indices.clear()
    rs.queued_draw_item_counts.clear()
    rs.queued_camera_draw_items.clear()
    rs.extra_sprites.clear()
    rs.extra_sprite_slice_batches.clear()
    @ui_render_runtime.clear_extracted_ui_nodes(world)
  })
  |> ignore
  render2d_runtime_state.diagnostic_execute_cpu_ms = (
      @time.host_time_now() - execute_start
    ) *
    1000.0F
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_2d",
    execute_trace_start_us,
  )
}

///|
fn camera_viewport_rect_physical(
  target_width : Int,
  target_height : Int,
  viewport : Viewport?,
) -> (Int, Int, Int, Int)? {
  let width = target_width
  let height = target_height
  if width <= 0 || height <= 0 {
    return None
  }
  let mut rect_x = 0
  let mut rect_y = 0
  let mut rect_width = width
  let mut rect_height = height
  if viewport is Some(vp) {
    rect_x = if vp.physical_position.x < 0 { 0 } else { vp.physical_position.x }
    rect_y = if vp.physical_position.y < 0 { 0 } else { vp.physical_position.y }
    rect_width = if vp.physical_size.x < 0 { 0 } else { vp.physical_size.x }
    rect_height = if vp.physical_size.y < 0 { 0 } else { vp.physical_size.y }
    let max_width = if width - rect_x < 0 { 0 } else { width - rect_x }
    let max_height = if height - rect_y < 0 { 0 } else { height - rect_y }
    if rect_width > max_width {
      rect_width = max_width
    }
    if rect_height > max_height {
      rect_height = max_height
    }
    if rect_width <= 0 || rect_height <= 0 {
      return None
    }
  }
  Some((rect_x, rect_y, rect_width, rect_height))
}

///|
pub fn render2d_debug_log_primary_camera(world : @ecs.World) -> Unit {
  guard render_state_ref(world) is Some(rs) else { return }
  let id = rs.primary_camera
  if id.is_placeholder() {
    return
  }
  for camera in rs.cameras {
    if camera.entity.id == id.id && camera.entity.generation == id.generation {
      let target = camera.computed.target_size
      let scale = camera.computed.scale_factor
      let proj_scale = render2d_camera_uniform_scale(
        camera.projection,
        camera.transform,
      )
      let mut viewport_text = "None"
      if camera.camera.viewport is Some(viewport) {
        let pos = viewport.physical_position
        let size = viewport.physical_size
        viewport_text = "pos=(\{pos.x.to_string()},\{pos.y.to_string()}) size=(\{size.x.to_string()},\{size.y.to_string()})"
      }
      let message = "camera_debug target=(\{target.x.to_string()},\{target.y.to_string()}) scale=\{scale.to_string()} proj_scale=\{proj_scale.to_string()} viewport=\{viewport_text}"
      @window.host_debug_string(value=message)
      return
    }
  }
}

///|
pub let render2d_set_extract : @app.SystemSet = @sprite_render_schedule.render2d_set_extract

///|
pub let render2d_set_extract_materials : @app.SystemSet = @sprite_render_schedule.render2d_set_extract_materials

///|
pub let render2d_set_prepare_materials : @app.SystemSet = @sprite_render_schedule.render2d_set_prepare_materials

///|
pub let render2d_set_prepare : @app.SystemSet = @sprite_render_schedule.render2d_set_prepare

///|
pub let render2d_set_queue : @app.SystemSet = @sprite_render_schedule.render2d_set_queue

///|
pub let render2d_set_render : @app.SystemSet = @sprite_render_schedule.render2d_set_render

///|
fn configure_render2d_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  ensure_render_state_resource(sub_app.world())
  let stage = @renderer.render_schedule_stage()
  let graph_stage = @renderer.RenderGraph::schedule()
  @renderer.configure_base_render_sets(sub_app)
  .add_systems(
    stage,
    @app.system(render_extract_system).in_set(render2d_set_extract),
  )
  .add_systems(
    stage,
    @app.system(render_prepare_system).in_set(render2d_set_prepare),
  )
  .add_systems(
    stage,
    @app.system(render_queue_system).in_set(render2d_set_queue),
  )
  .add_systems(
    graph_stage,
    @app.system(render_execute_system).in_set(render2d_set_render),
  )
  .configure_set(stage, render2d_set_extract_materials, before=[
    render2d_set_extract,
  ])
  .configure_set(stage, @renderer.render_system_set_extract_commands, before=[
    render2d_set_extract_materials,
  ])
  .configure_set(stage, render2d_set_extract, before=[
    render2d_set_prepare_materials,
  ])
  .configure_set(stage, render2d_set_prepare_materials, before=[
    render2d_set_prepare,
  ])
  .configure_set(stage, @renderer.render_system_set_queue_meshes, before=[
    render2d_set_prepare_materials,
  ])
  .configure_set(stage, render2d_set_prepare, before=[render2d_set_queue])
  .configure_set(stage, @renderer.render_system_set_queue_meshes, before=[
    render2d_set_prepare,
  ])
  .configure_set(graph_stage, @renderer.render_graph_system_set_render, before=[
    render2d_set_render,
  ])
  .configure_set(stage, @renderer.render_system_set_queue_meshes, before=[
    render2d_set_queue,
  ])
  .configure_set(stage, render2d_set_queue, before=[
    @renderer.render_system_set_queue_sweep,
  ])
  .configure_set(graph_stage, render2d_set_render, before=[
    @renderer.render_graph_system_set_submit,
  ])
}

///|
fn configure_render2d_render_sub_app_ecs(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  ensure_render_state_resource(sub_app.world())
  let stage = @renderer.render_schedule_stage()
  let graph_stage = @renderer.RenderGraph::schedule()
  @renderer.configure_base_render_sets(sub_app)
  .add_systems(
    stage,
    @app.system(render_extract_system_ecs).in_set(render2d_set_extract),
  )
  .add_systems(
    stage,
    @app.system(render_prepare_system).in_set(render2d_set_prepare),
  )
  .add_systems(
    stage,
    @app.system(render_queue_system).in_set(render2d_set_queue),
  )
  .add_systems(
    graph_stage,
    @app.system(render_execute_system).in_set(render2d_set_render),
  )
  .configure_set(stage, render2d_set_extract_materials, before=[
    render2d_set_extract,
  ])
  .configure_set(stage, @renderer.render_system_set_extract_commands, before=[
    render2d_set_extract_materials,
  ])
  .configure_set(stage, render2d_set_extract, before=[
    render2d_set_prepare_materials,
  ])
  .configure_set(stage, render2d_set_prepare_materials, before=[
    render2d_set_prepare,
  ])
  .configure_set(stage, @renderer.render_system_set_queue_meshes, before=[
    render2d_set_prepare_materials,
  ])
  .configure_set(stage, render2d_set_prepare, before=[render2d_set_queue])
  .configure_set(stage, @renderer.render_system_set_queue_meshes, before=[
    render2d_set_prepare,
  ])
  .configure_set(graph_stage, @renderer.render_graph_system_set_render, before=[
    render2d_set_render,
  ])
  .configure_set(stage, @renderer.render_system_set_queue_meshes, before=[
    render2d_set_queue,
  ])
  .configure_set(stage, render2d_set_queue, before=[
    @renderer.render_system_set_queue_sweep,
  ])
  .configure_set(graph_stage, render2d_set_render, before=[
    @renderer.render_graph_system_set_submit,
  ])
}

///|
pub struct Render2dPlugin {}

///|
pub fn Render2dPlugin::Render2dPlugin() -> Render2dPlugin {
  Render2dPlugin::{  }
}

///|
pub struct Render2dEcsPlugin {}

///|
pub fn Render2dEcsPlugin::Render2dEcsPlugin() -> Render2dEcsPlugin {
  Render2dEcsPlugin::{  }
}

///|
pub impl @app.Plugin for Render2dPlugin with fn name(_self) {
  "mgstudio.sprite.Render2dPlugin"
}

///|
pub impl @app.Plugin for Render2dPlugin with fn build(_self, app) {
  register_embedded_wgsl_sources()
  @cas.cas_register_camera_component_key(@camera_camera.ecs_key_camera)
  render2d_plugin_install(app)
}

///|
pub impl @app.Plugin for Render2dEcsPlugin with fn name(_self) {
  "mgstudio.sprite.Render2dEcsPlugin"
}

///|
pub impl @app.Plugin for Render2dEcsPlugin with fn build(_self, app) {
  register_embedded_wgsl_sources()
  @cas.cas_register_camera_component_key(@camera_camera.ecs_key_camera)
  render2d_plugin_ecs_install(app)
}

///|
pub fn render2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(Render2dPlugin::Render2dPlugin())
}

///|
fn render2d_plugin_install(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let app = @shader.shader_plugin(app)
  ensure_render2d_required_components(app.world())
  let next = init_gizmo_group(
      app.init_resource(fn() { ClearColor::ClearColor() }),
      DefaultGizmoConfigGroup::DefaultGizmoConfigGroup(),
    )
    .add_message(@asset.image_asset_resource_keys.event)
    .add_plugins(ColorMaterialPlugin::ColorMaterialPlugin())
    .add_plugins(@sprite_tilemap_chunk.TilemapChunkPlugin::TilemapChunkPlugin())
    .add_plugins(
      @sprite_tilemap_chunk.TilemapChunkMaterialPlugin::TilemapChunkMaterialPlugin(),
    )
    .add_plugins(SpriteMeshPlugin::SpriteMeshPlugin())
    .add_startup_system(register_render2d_shader_sources)
    .add_post_update_system_config(
      @app.system_config_param3(compute_slices_on_sprite_change_system).in_set(
        sprite_systems_compute_slices,
      ),
    )
    .add_post_update_system_config(
      @app.system_config_param3(compute_slices_on_asset_event_system)
      .in_set(sprite_systems_compute_slices)
      .before(@asset.asset_event_system_set()),
    )
    .add_post_update_system_config(
      @app.system(render2d_camera_system).in_set(camera_update_systems),
    )
  @renderer.with_render_app(next, configure_render2d_render_sub_app)
}

///|
pub fn render2d_plugin_ecs(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(Render2dEcsPlugin::Render2dEcsPlugin())
}

///|
fn render2d_plugin_ecs_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let app = @shader.shader_plugin(app)
  ensure_render2d_required_components(app.world())
  let next = init_gizmo_group(
      app.init_resource(fn() { ClearColor::ClearColor() }),
      DefaultGizmoConfigGroup::DefaultGizmoConfigGroup(),
    )
    .add_message(@asset.image_asset_resource_keys.event)
    .add_plugins(ColorMaterialPlugin::ColorMaterialPlugin())
    .add_plugins(@sprite_tilemap_chunk.TilemapChunkPlugin::TilemapChunkPlugin())
    .add_plugins(
      @sprite_tilemap_chunk.TilemapChunkMaterialPlugin::TilemapChunkMaterialPlugin(),
    )
    .add_plugins(SpriteMeshPlugin::SpriteMeshPlugin())
    .add_startup_system(register_render2d_shader_sources)
    .add_post_update_system_config(
      @app.system_config_param3(compute_slices_on_sprite_change_system).in_set(
        sprite_systems_compute_slices,
      ),
    )
    .add_post_update_system_config(
      @app.system_config_param3(compute_slices_on_asset_event_system)
      .in_set(sprite_systems_compute_slices)
      .before(@asset.asset_event_system_set()),
    )
    .add_post_update_system_config(
      @app.system(render2d_camera_system_ecs).in_set(camera_update_systems),
    )
  @renderer.with_render_app(next, configure_render2d_render_sub_app_ecs)
}
