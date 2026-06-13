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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/skybox/mod.rs`.
// Skybox plugin owner surface.

///|
const SKYBOX_PLUGIN_NAME : String = "mgstudio.core_pipeline.skybox.SkyboxPlugin"

///|
pub struct SkyboxPlugin {}

///|
pub fn SkyboxPlugin::SkyboxPlugin() -> SkyboxPlugin {
  SkyboxPlugin::{  }
}

///|
pub const SKYBOX_PIPELINE_LABEL : String = "skybox_pipeline"

///|
pub struct SkyboxPipelineKey {
  hdr : Bool
  samples : Int
  depth_format : String
} derive(Eq, Debug)

///|
pub fn SkyboxPipelineKey::new(
  hdr? : Bool = true,
  samples? : Int = 1,
  depth_format? : String = "depth32float",
) -> SkyboxPipelineKey {
  let samples = if samples <= 0 { 1 } else { samples }
  SkyboxPipelineKey::{ hdr, samples, depth_format }
}

///|
pub struct SkyboxPipelineId {
  pipeline_id : Int
}

///|
pub fn SkyboxPipelineId::new(pipeline_id~ : Int) -> SkyboxPipelineId {
  SkyboxPipelineId::{ pipeline_id, }
}

///|
pub struct SkyboxBindGroup {
  bind_group_id : Int
  skybox_uniform_index : Int
}

///|
pub fn SkyboxBindGroup::new(
  bind_group_id~ : Int,
  skybox_uniform_index~ : Int,
) -> SkyboxBindGroup {
  SkyboxBindGroup::{ bind_group_id, skybox_uniform_index }
}

///|
pub struct SkyboxPrepareViewState {
  has_skybox : Bool
  hdr : Bool
  msaa_samples : Int
  has_view_uniform_binding : Bool
  has_skybox_uniform_binding : Bool
  has_skybox_gpu_image : Bool
}

///|
pub fn SkyboxPrepareViewState::new(
  has_skybox? : Bool = false,
  hdr? : Bool = true,
  msaa_samples? : Int = 1,
  has_view_uniform_binding? : Bool = false,
  has_skybox_uniform_binding? : Bool = false,
  has_skybox_gpu_image? : Bool = false,
) -> SkyboxPrepareViewState {
  SkyboxPrepareViewState::{
    has_skybox,
    hdr,
    msaa_samples,
    has_view_uniform_binding,
    has_skybox_uniform_binding,
    has_skybox_gpu_image,
  }
}

///|
pub fn skybox_should_prepare_pipeline(state : SkyboxPrepareViewState) -> Bool {
  state.has_skybox
}

///|
pub fn skybox_pipeline_key(
  state : SkyboxPrepareViewState,
  depth_format? : String = "depth32float",
) -> SkyboxPipelineKey {
  SkyboxPipelineKey::new(
    hdr=state.hdr,
    samples=state.msaa_samples,
    depth_format~,
  )
}

///|
pub fn skybox_should_prepare_bind_group(state : SkyboxPrepareViewState) -> Bool {
  state.has_skybox &&
  state.has_view_uniform_binding &&
  state.has_skybox_uniform_binding &&
  state.has_skybox_gpu_image
}

///|
priv struct SkyboxDrawParams {
  texture_id : Int
  brightness : Float
  rotation : @math.Quat
}

///|
fn skybox_draw_params(
  skybox : @light.Skybox,
  camera_exposure_value : Float,
) -> SkyboxDrawParams? {
  guard skybox.image is Some(image) else { return None }
  let texture_id = image.id()
  guard texture_id >= 0 else { return None }
  Some(SkyboxDrawParams::{
    texture_id,
    brightness: skybox.brightness * camera_exposure_value,
    rotation: skybox.rotation.inverse(),
  })
}

///|
pub fn draw_skybox(
  skybox : @light.Skybox,
  camera_exposure_value : Float,
) -> Unit {
  guard skybox_draw_params(skybox, camera_exposure_value) is Some(params) else {
    return
  }
  if !@render.asset_is_texture_loaded(texture_id=params.texture_id) {
    return
  }
  @render.host_gpu_draw_skybox(
    texture_id=params.texture_id,
    brightness=params.brightness,
    rotation_x=params.rotation.x,
    rotation_y=params.rotation.y,
    rotation_z=params.rotation.z,
    rotation_w=params.rotation.w,
  )
}

///|
pub fn view_has_skybox_pipeline(
  world : @ecs.World,
  render_entity : @core.Entity,
) -> Bool {
  match world.get_resource(ExtractedSkyboxes::resource()) {
    Some(extracted) =>
      for entry in extracted.entries {
        if entry.render_entity == render_entity && entry.is_ready_for_pipeline() {
          return true
        }
      }
    None => ()
  }
  false
}

///|
pub fn view_has_skybox_bind_group(
  world : @ecs.World,
  render_entity : @core.Entity,
) -> Bool {
  match world.get_resource(ExtractedSkyboxes::resource()) {
    Some(extracted) =>
      for entry in extracted.entries {
        if entry.render_entity == render_entity &&
          entry.is_ready_for_bind_group() {
          match entry.skybox.image {
            Some(image) =>
              if @asset.asset_is_texture_loaded(image) {
                return true
              }
            None => ()
          }
        }
      }
    None => ()
  }
  false
}

///|
priv struct SkyboxUniforms {
  brightness : Float
  transform : Array[Float]
}

///|
fn SkyboxUniforms::new(
  brightness~ : Float,
  transform~ : Array[Float],
) -> SkyboxUniforms {
  SkyboxUniforms::{ brightness, transform }
}

///|
fn SkyboxUniforms::from_skybox(
  skybox : @light.Skybox,
  exposure : Float,
) -> SkyboxUniforms {
  SkyboxUniforms::new(
    brightness=skybox.brightness * exposure,
    transform=skybox_rotation_matrix(skybox.rotation.inverse()),
  )
}

///|
fn SkyboxUniforms::is_ready_for_bind_group(self : SkyboxUniforms) -> Bool {
  self.transform.length() == 16 && self.brightness >= 0.0F
}

///|
fn skybox_rotation_matrix(rotation : @math.Quat) -> Array[Float] {
  let len_sq = rotation.x * rotation.x +
    rotation.y * rotation.y +
    rotation.z * rotation.z +
    rotation.w * rotation.w
  let (x, y, z, w) = if len_sq <= 1.0e-8F {
    (0.0F, 0.0F, 0.0F, 1.0F)
  } else {
    let inv_len = 1.0F / Float::sqrt(len_sq)
    (
      rotation.x * inv_len,
      rotation.y * inv_len,
      rotation.z * inv_len,
      rotation.w * inv_len,
    )
  }
  let xx = x * x
  let yy = y * y
  let zz = z * z
  let xy = x * y
  let xz = x * z
  let yz = y * z
  let wx = w * x
  let wy = w * y
  let wz = w * z
  [
    1.0F - 2.0F * (yy + zz),
    2.0F * (xy + wz),
    2.0F * (xz - wy),
    0.0F,
    2.0F * (xy - wz),
    1.0F - 2.0F * (xx + zz),
    2.0F * (yz + wx),
    0.0F,
    2.0F * (xz + wy),
    2.0F * (yz - wx),
    1.0F - 2.0F * (xx + yy),
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
  ]
}

///|
priv struct ExtractedSkybox {
  render_entity : @core.Entity
  skybox : @light.Skybox
  uniforms : SkyboxUniforms
}

///|
fn ExtractedSkybox::new(
  render_entity~ : @core.Entity,
  skybox~ : @light.Skybox,
  uniforms~ : SkyboxUniforms,
) -> ExtractedSkybox {
  ExtractedSkybox::{ render_entity, skybox, uniforms }
}

///|
fn ExtractedSkybox::is_ready_for_pipeline(self : ExtractedSkybox) -> Bool {
  !self.render_entity.is_placeholder()
}

///|
fn ExtractedSkybox::is_ready_for_bind_group(self : ExtractedSkybox) -> Bool {
  self.is_ready_for_pipeline() && self.uniforms.is_ready_for_bind_group()
}

///|
priv struct ExtractedSkyboxes {
  entries : Array[ExtractedSkybox]
}

///|
fn ExtractedSkyboxes::ExtractedSkyboxes() -> ExtractedSkyboxes {
  ExtractedSkyboxes::{ entries: [] }
}

///|
fn ExtractedSkyboxes::clear(self : ExtractedSkyboxes) -> Unit {
  self.entries.clear()
}

///|
fn ExtractedSkyboxes::push(
  self : ExtractedSkyboxes,
  entry : ExtractedSkybox,
) -> Unit {
  self.entries.push(entry)
}

///|
pub fn skybox_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(SkyboxPlugin::SkyboxPlugin())
}

///|
pub impl @app.Plugin for SkyboxPlugin with fn name(_self) {
  SKYBOX_PLUGIN_NAME
}

///|
pub impl @app.Plugin for SkyboxPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  skybox_plugin_install_with(app, self)
}

///|
pub fn skybox_plugin_with(
  app : @app.App[@ecs.World],
  plugin : SkyboxPlugin,
) -> @app.App[@ecs.World] {
  app.add_plugins(plugin)
}

///|
fn skybox_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : SkyboxPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let next = app.init_resource(fn() {
    SkyboxPipelineState::SkyboxPipelineState()
  })
  @render.with_render_app(next, configure_skybox_render_sub_app)
}

///|
pub struct SkyboxPipelineState {
  mut pipeline_count : Int
  mut bind_group_count : Int
}

///|
pub fn SkyboxPipelineState::SkyboxPipelineState() -> SkyboxPipelineState {
  SkyboxPipelineState::{ pipeline_count: 0, bind_group_count: 0 }
}

///|
fn SkyboxPipelineState::set_counts(
  self : SkyboxPipelineState,
  pipeline_count~ : Int,
  bind_group_count~ : Int,
) -> Unit {
  self.pipeline_count = pipeline_count
  self.bind_group_count = bind_group_count
}

///|
pub fn SkyboxPipelineState::record_pipeline(self : SkyboxPipelineState) -> Unit {
  self.pipeline_count = self.pipeline_count + 1
}

///|
pub fn SkyboxPipelineState::record_bind_group(
  self : SkyboxPipelineState,
) -> Unit {
  self.bind_group_count = self.bind_group_count + 1
}

///|
pub let ecs_key_skybox_pipeline_state : @ecs.ResourceKey[SkyboxPipelineState] = @ecs.register_resource(
  debug_name="core_pipeline.skybox.pipeline_state",
)

///|
pub impl @app.Resource for SkyboxPipelineState with fn resource() {
  ecs_key_skybox_pipeline_state
}

///|
let ecs_key_extracted_skyboxes : @ecs.ResourceKey[ExtractedSkyboxes] = @ecs.register_resource(
  debug_name="core_pipeline.skybox.extracted_skyboxes",
)

///|
impl @app.Resource for ExtractedSkyboxes with fn resource() {
  ecs_key_extracted_skyboxes
}

///|
fn skybox_pipeline_state_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[SkyboxPipelineState] {
  if world.get_resource(SkyboxPipelineState::resource()) is None {
    world.insert_resource(
      SkyboxPipelineState::resource(),
      SkyboxPipelineState::SkyboxPipelineState(),
    )
  }
  match world.get_resource_mut(SkyboxPipelineState::resource()) {
    Some(value) => value
    None => abort("Missing SkyboxPipelineState resource")
  }
}

///|
fn extracted_skyboxes_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[ExtractedSkyboxes] {
  if world.get_resource(ExtractedSkyboxes::resource()) is None {
    world.insert_resource(
      ExtractedSkyboxes::resource(),
      ExtractedSkyboxes::ExtractedSkyboxes(),
    )
  }
  match world.get_resource_mut(ExtractedSkyboxes::resource()) {
    Some(value) => value
    None => abort("Missing ExtractedSkyboxes resource")
  }
}

///|
fn configure_skybox_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  if !world.resource(SkyboxPipelineState::resource()).is_present() {
    world.insert_resource(
      SkyboxPipelineState::resource(),
      SkyboxPipelineState::SkyboxPipelineState(),
    )
  }
  if !world.resource(ExtractedSkyboxes::resource()).is_present() {
    world.insert_resource(
      ExtractedSkyboxes::resource(),
      ExtractedSkyboxes::ExtractedSkyboxes(),
    )
  }
  @render.configure_base_render_sets(sub_app)
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(extract_skybox).in_set(
      @render.render_system_set_extract_commands,
    ),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_skybox_pipelines).in_set(
      @render.render_system_set_prepare,
    ),
  )
  .add_systems(
    @render.render_schedule_stage(),
    @app.system(prepare_skybox_bind_groups).in_set(
      @render.render_system_set_prepare_bind_groups,
    ),
  )
}

///|
fn extract_skybox(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  extracted_skyboxes_mut_or_init(world).modify(fn(extracted) {
    extracted.clear()
    let query : @ecs.Query[
      (@ecs.Read[@render.RenderEntity], @ecs.Read[@light.Skybox]),
      @ecs.All,
    ] = @ecs.query(source_world)
    try! query.view(fn(_query_entity, data) {
      let (render_entity_ref, skybox_ref) = data
      let skybox = skybox_ref.value()
      extracted.push(
        ExtractedSkybox::new(
          render_entity=render_entity_ref.value().id(),
          skybox~,
          uniforms=SkyboxUniforms::from_skybox(skybox, 1.0F),
        ),
      )
    })
  })
}

///|
fn prepare_skybox_pipelines(world : @ecs.World) -> Unit {
  let mut pipeline_count = 0
  match world.get_resource(ExtractedSkyboxes::resource()) {
    Some(extracted) =>
      for entry in extracted.entries {
        if entry.is_ready_for_pipeline() {
          pipeline_count = pipeline_count + 1
        }
      }
    None => ()
  }
  skybox_pipeline_state_mut_or_init(world).modify(fn(state) {
    state.set_counts(pipeline_count~, bind_group_count=state.bind_group_count)
  })
}

///|
fn prepare_skybox_bind_groups(world : @ecs.World) -> Unit {
  let mut bind_group_count = 0
  match world.get_resource(ExtractedSkyboxes::resource()) {
    Some(extracted) =>
      for entry in extracted.entries {
        if entry.is_ready_for_bind_group() {
          match entry.skybox.image {
            Some(image) =>
              if @asset.asset_is_texture_loaded(image) {
                bind_group_count = bind_group_count + 1
              }
            None => ()
          }
        }
      }
    None => ()
  }
  skybox_pipeline_state_mut_or_init(world).modify(fn(state) {
    state.set_counts(pipeline_count=state.pipeline_count, bind_group_count~)
  })
}
