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
const SKYBOX_SHADER_PATH : String = "core_pipeline/skybox/skybox.wgsl"

///|
const SKYBOX_UNIFORM_BUFFER_SIZE_BYTES : UInt64 = 80UL

///|
pub struct SkyboxPipelineKey {
  target_format_raw : UInt
  samples : Int
  depth_format_raw : UInt
} derive(Eq, Debug)

///|
pub fn SkyboxPipelineKey::new(
  target_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
  samples? : Int = 1,
  depth_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
) -> SkyboxPipelineKey {
  let samples = if samples <= 0 { 1 } else { samples }
  SkyboxPipelineKey::{ target_format_raw, samples, depth_format_raw }
}

///|
pub struct SkyboxPipelineId {
  pipeline_id : @render_resource.CachedRenderPipelineId
}

///|
pub fn SkyboxPipelineId::new(
  pipeline_id~ : @render_resource.CachedRenderPipelineId,
) -> SkyboxPipelineId {
  SkyboxPipelineId::{ pipeline_id, }
}

///|
pub fn SkyboxPipelineId::pipeline_id(
  self : SkyboxPipelineId,
) -> @render_resource.CachedRenderPipelineId {
  self.pipeline_id
}

///|
pub let ecs_key_skybox_pipeline_id : @ecs.ComponentKey[SkyboxPipelineId] = @ecs.register_component(
  debug_name="core_pipeline.skybox.pipeline_id",
)

///|
pub impl @ecs.Component for SkyboxPipelineId with fn component() {
  ecs_key_skybox_pipeline_id
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
pub fn SkyboxBindGroup::bind_group_id(self : SkyboxBindGroup) -> Int {
  self.bind_group_id
}

///|
pub fn SkyboxBindGroup::skybox_uniform_index(self : SkyboxBindGroup) -> Int {
  self.skybox_uniform_index
}

///|
pub let ecs_key_skybox_bind_group : @ecs.ComponentKey[SkyboxBindGroup] = @ecs.register_component(
  debug_name="core_pipeline.skybox.bind_group",
)

///|
pub impl @ecs.Component for SkyboxBindGroup with fn component() {
  ecs_key_skybox_bind_group
}

///|
pub struct SkyboxPrepareViewState {
  has_skybox : Bool
  target_format_raw : UInt
  msaa_samples : Int
  has_view_uniform_binding : Bool
  has_skybox_uniform_binding : Bool
  has_skybox_gpu_image : Bool
}

///|
pub fn SkyboxPrepareViewState::new(
  has_skybox? : Bool = false,
  target_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
  msaa_samples? : Int = 1,
  has_view_uniform_binding? : Bool = false,
  has_skybox_uniform_binding? : Bool = false,
  has_skybox_gpu_image? : Bool = false,
) -> SkyboxPrepareViewState {
  SkyboxPrepareViewState::{
    has_skybox,
    target_format_raw,
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
  depth_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
) -> SkyboxPipelineKey {
  SkyboxPipelineKey::new(
    target_format_raw=state.target_format_raw,
    samples=state.msaa_samples,
    depth_format_raw~,
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
fn skybox_bind_group_layout_descriptor() -> @render_resource.BindGroupLayoutDescriptor {
  let vertex_fragment = (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
  let fragment = @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
  @render_resource.BindGroupLayoutDescriptor::new("skybox_bind_group_layout", [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      fragment,
      @render_resource.BindingType::TextureBinding(
        @render_resource.TextureSampleType::Float(true),
        @render_resource.TextureViewDimension::Cube,
        false,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      1,
      fragment,
      @render_resource.BindingType::SamplerBinding(
        @render_resource.SamplerBindingType::Filtering,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      2,
      vertex_fragment,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        true,
        @render_view.VIEW_UNIFORM_SIZE_BYTES.to_uint64(),
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      3,
      vertex_fragment,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        true,
        SKYBOX_UNIFORM_BUFFER_SIZE_BYTES,
      ),
    ),
  ])
}

///|
fn skybox_render_pipeline_descriptor(
  key : SkyboxPipelineKey,
) -> @render_resource.RenderPipelineDescriptor {
  @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_label(Some(SKYBOX_PIPELINE_LABEL))
  .with_layout([skybox_bind_group_layout_descriptor()])
  .with_vertex(
    @render_resource.VertexState::new(
      Some(SKYBOX_SHADER_PATH),
      [],
      Some("skybox_vertex"),
      [],
    ),
  )
  .with_primitive(
    @render_resource.PrimitiveState::PrimitiveState().with_cull_mode(None),
  )
  .with_depth_stencil(
    Some(
      @render_resource.DepthStencilState::new(
        key.depth_format_raw,
        false,
        @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
      ),
    ),
  )
  .with_multisample(
    @render_resource.MultisampleState::new(key.samples.reinterpret_as_uint()),
  )
  .with_fragment(
    Some(
      @render_resource.FragmentState::new(
        Some(SKYBOX_SHADER_PATH),
        [],
        Some("skybox_fragment"),
        [
          Some(
            @render_resource.ColorTargetState::new(
              key.target_format_raw,
              @wgpu.COLOR_WRITE_MASK_ALL,
            ),
          ),
        ],
      ),
    ),
  )
}

///|
priv struct SkyboxDrawParams {
  texture_id : Int
  brightness : Float
  rotation : @math.Quat
}

///|
fn skybox_draw_params_from_extracted(
  entry : ExtractedSkybox,
) -> SkyboxDrawParams? {
  guard entry.skybox.image is Some(image) else { return None }
  let texture_id = image.id()
  guard texture_id >= 0 else { return None }
  Some(SkyboxDrawParams::{
    texture_id,
    brightness: entry.uniforms.brightness,
    rotation: entry.skybox.rotation.inverse(),
  })
}

///|
pub fn draw_prepared_skybox(
  world : @ecs.World,
  render_entity : @core.Entity,
) -> Bool {
  if !world.is_alive(render_entity) {
    return false
  }
  guard (try! world.get_by_key(render_entity, ecs_key_skybox_bind_group))
    is Some(bind_group) else {
    return false
  }
  @render.host_gpu_draw_prepared_skybox(
    bind_group_id=bind_group.bind_group_id(),
  )
  true
}

///|
pub fn view_has_skybox_pipeline(
  world : @ecs.World,
  render_entity : @core.Entity,
) -> Bool {
  if !world.is_alive(render_entity) {
    return false
  }
  (try! world.get_by_key(render_entity, ecs_key_skybox_pipeline_id)) is Some(_)
}

///|
pub fn view_has_skybox_bind_group(
  world : @ecs.World,
  render_entity : @core.Entity,
) -> Bool {
  if !world.is_alive(render_entity) {
    return false
  }
  (try! world.get_by_key(render_entity, ecs_key_skybox_bind_group)) is Some(_)
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
  self.transform.length() == 16
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
  pipelines : Array[
    (SkyboxPipelineKey, @render_resource.CachedRenderPipelineId),
  ]
}

///|
pub fn SkyboxPipelineState::SkyboxPipelineState() -> SkyboxPipelineState {
  SkyboxPipelineState::{ pipeline_count: 0, bind_group_count: 0, pipelines: [] }
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
fn SkyboxPipelineState::pipeline_id(
  self : SkyboxPipelineState,
  key : SkyboxPipelineKey,
) -> @render_resource.CachedRenderPipelineId? {
  for entry in self.pipelines {
    let (entry_key, pipeline_id) = entry
    if entry_key == key {
      return Some(pipeline_id)
    }
  }
  None
}

///|
fn SkyboxPipelineState::insert_pipeline(
  self : SkyboxPipelineState,
  key : SkyboxPipelineKey,
  pipeline_id : @render_resource.CachedRenderPipelineId,
) -> Unit {
  for index in 0..<self.pipelines.length() {
    let (entry_key, _) = self.pipelines[index]
    if entry_key == key {
      self.pipelines[index] = (key, pipeline_id)
      return
    }
  }
  self.pipelines.push((key, pipeline_id))
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
fn extracted_skybox_pipeline_ready(
  extracted : ExtractedSkyboxes,
  render_entity : @core.Entity,
) -> Bool {
  for entry in extracted.entries {
    if entry.render_entity == render_entity && entry.is_ready_for_pipeline() {
      return true
    }
  }
  false
}

///|
fn extracted_skybox_bind_group_ready(
  extracted : ExtractedSkyboxes,
  render_entity : @core.Entity,
) -> Bool {
  for entry in extracted.entries {
    if entry.render_entity == render_entity && entry.is_ready_for_bind_group() {
      match entry.skybox.image {
        Some(image) => if @asset.asset_is_texture_loaded(image) { return true }
        None => ()
      }
    }
  }
  false
}

///|
fn remove_stale_skybox_pipeline_components(
  world : @ecs.World,
  extracted : ExtractedSkyboxes,
) -> Unit {
  let stale : Array[@core.Entity] = []
  let query : @ecs.Query[(@core.Entity, @ecs.Read[SkyboxPipelineId]), @ecs.All] = @ecs.query(
    world,
  )
  try! query.view(fn(_query_entity, data) {
    let (entity, _pipeline_id) = data
    if !extracted_skybox_pipeline_ready(extracted, entity) {
      stale.push(entity)
    }
  })
  for entity in stale {
    ignore(try! world.remove_by_key(entity, ecs_key_skybox_pipeline_id))
  }
}

///|
fn remove_stale_skybox_bind_group_components(
  world : @ecs.World,
  extracted : ExtractedSkyboxes,
) -> Unit {
  let stale : Array[(@core.Entity, Int)] = []
  let query : @ecs.Query[(@core.Entity, @ecs.Read[SkyboxBindGroup]), @ecs.All] = @ecs.query(
    world,
  )
  try! query.view(fn(_query_entity, data) {
    let (entity, bind_group) = data
    if !extracted_skybox_bind_group_ready(extracted, entity) {
      stale.push((entity, bind_group.value().bind_group_id()))
    }
  })
  for entry in stale {
    let (entity, bind_group_id) = entry
    ignore(@render.host_gpu_release_skybox_bind_group(bind_group_id~))
    ignore(try! world.remove_by_key(entity, ecs_key_skybox_bind_group))
  }
}

///|
fn skybox_pipeline_key_for_render_entity(
  world : @ecs.World,
  render_entity : @core.Entity,
) -> SkyboxPipelineKey? {
  guard (try! world.get_by_key(
      render_entity,
      @render_view.ExtractedView::component(),
    ))
    is Some(view) else {
    return None
  }
  guard (try! world.get_by_key(render_entity, @render_view.Msaa::component()))
    is Some(msaa) else {
    return None
  }
  Some(
    SkyboxPipelineKey::new(
      target_format_raw=view.target_format_raw(),
      samples=msaa.samples(),
      depth_format_raw=@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    ),
  )
}

///|
fn skybox_specialize_pipeline(
  state : SkyboxPipelineState,
  pipeline_cache : @render_resource.PipelineCache,
  key : SkyboxPipelineKey,
) -> @render_resource.CachedRenderPipelineId {
  match state.pipeline_id(key) {
    Some(pipeline_id) => pipeline_id
    None => {
      let pipeline_id = pipeline_cache.queue_render_pipeline(
        skybox_render_pipeline_descriptor(key),
      )
      state.insert_pipeline(key, pipeline_id)
      pipeline_id
    }
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
      (
        @ecs.Read[@render.RenderEntity],
        @ecs.Read[@light.Skybox],
        @ecs.Optional[@camera_camera.Exposure],
      ),
      @ecs.All,
    ] = @ecs.query(source_world)
    try! query.view(fn(_query_entity, data) {
      let (render_entity_ref, skybox_ref, exposure_ref) = data
      let skybox = skybox_ref.value()
      let exposure = match exposure_ref.value() {
        Some(value) => value.exposure()
        None => @camera_camera.Exposure::Exposure().exposure()
      }
      extracted.push(
        ExtractedSkybox::new(
          render_entity=render_entity_ref.value().id(),
          skybox~,
          uniforms=SkyboxUniforms::from_skybox(skybox, exposure),
        ),
      )
    })
  })
}

///|
fn prepare_skybox_pipelines(world : @ecs.World) -> Unit {
  let mut pipeline_count = 0
  guard world.get_resource(@render.pipeline_cache_resource_key)
    is Some(pipeline_cache) else {
    remove_stale_skybox_pipeline_components(
      world,
      ExtractedSkyboxes::ExtractedSkyboxes(),
    )
    skybox_pipeline_state_mut_or_init(world).modify(fn(state) {
      state.set_counts(
        pipeline_count=0,
        bind_group_count=state.bind_group_count,
      )
    })
    return
  }
  match world.get_resource(ExtractedSkyboxes::resource()) {
    Some(extracted) => {
      remove_stale_skybox_pipeline_components(world, extracted)
      for entry in extracted.entries {
        if entry.is_ready_for_pipeline() {
          guard skybox_pipeline_key_for_render_entity(
              world,
              entry.render_entity,
            )
            is Some(key) else {
            ignore(
              try! world.remove_by_key(
                entry.render_entity,
                ecs_key_skybox_pipeline_id,
              ),
            )
            continue
          }
          let pipeline_id = skybox_pipeline_state_mut_or_init(world).modify(fn(
            state,
          ) {
            skybox_specialize_pipeline(state, pipeline_cache, key)
          })
          try! world.set_by_key(
            entry.render_entity,
            ecs_key_skybox_pipeline_id,
            SkyboxPipelineId::new(pipeline_id~),
          )
          pipeline_count = pipeline_count + 1
        }
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
    Some(extracted) => {
      remove_stale_skybox_bind_group_components(world, extracted)
      for entry in extracted.entries {
        if entry.is_ready_for_bind_group() {
          guard skybox_draw_params_from_extracted(entry) is Some(params) else {
            continue
          }
          if @render.asset_is_texture_loaded(texture_id=params.texture_id) {
            let previous = try! world.get_by_key(
              entry.render_entity,
              ecs_key_skybox_bind_group,
            )
            guard @render.host_gpu_prepare_skybox_bind_group(
                texture_id=params.texture_id,
                brightness=params.brightness,
                rotation_x=params.rotation.x,
                rotation_y=params.rotation.y,
                rotation_z=params.rotation.z,
                rotation_w=params.rotation.w,
              )
              is Some(bind_group_id) else {
              match previous {
                Some(old) => {
                  ignore(
                    @render.host_gpu_release_skybox_bind_group(
                      bind_group_id=old.bind_group_id(),
                    ),
                  )
                  ignore(
                    try! world.remove_by_key(
                      entry.render_entity,
                      ecs_key_skybox_bind_group,
                    ),
                  )
                }
                None => ()
              }
              continue
            }
            match previous {
              Some(old) =>
                ignore(
                  @render.host_gpu_release_skybox_bind_group(
                    bind_group_id=old.bind_group_id(),
                  ),
                )
              None => ()
            }
            try! world.set_by_key(
              entry.render_entity,
              ecs_key_skybox_bind_group,
              SkyboxBindGroup::new(bind_group_id~, skybox_uniform_index=0),
            )
            bind_group_count = bind_group_count + 1
          }
        }
      }
    }
    None => ()
  }
  skybox_pipeline_state_mut_or_init(world).modify(fn(state) {
    state.set_counts(pipeline_count=state.pipeline_count, bind_group_count~)
  })
}
