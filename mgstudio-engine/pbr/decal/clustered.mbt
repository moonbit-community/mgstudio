// Copyright 2026 International Digital Economy Academy
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
pub const CLUSTERED_DECAL_IMAGES_PER_DECAL : Int = 4

///|
const CLUSTERED_DECAL_PLUGIN_NAME : String = "mgstudio.pbr.decal.ClusteredDecalPlugin"

///|
pub type ClusteredDecal = @light.ClusteredDecal

///|
pub struct RenderClusteredDecal {
  local_from_world : @math.Affine3
  base_color_texture_index : Int
  normal_map_texture_index : Int
  metallic_roughness_texture_index : Int
  emissive_texture_index : Int
  tag : Int
  pad_a : Int
  pad_b : Int
  pad_c : Int
}

///|
pub fn RenderClusteredDecal::new(
  local_from_world : @math.Affine3,
  base_color_texture_index : Int,
  normal_map_texture_index : Int,
  metallic_roughness_texture_index : Int,
  emissive_texture_index : Int,
  tag : Int,
) -> RenderClusteredDecal {
  RenderClusteredDecal::{
    local_from_world,
    base_color_texture_index,
    normal_map_texture_index,
    metallic_roughness_texture_index,
    emissive_texture_index,
    tag: if tag < 0 {
      0
    } else {
      tag
    },
    pad_a: 0,
    pad_b: 0,
    pad_c: 0,
  }
}

///|
pub fn RenderClusteredDecal::default() -> RenderClusteredDecal {
  RenderClusteredDecal::new(@math.Affine3::identity(), -1, -1, -1, -1, 0)
}

///|
pub struct RenderClusteredDecals {
  binding_index_to_textures : Array[Int]
  texture_to_binding_index : Map[Int, Int]
  decals : Array[RenderClusteredDecal]
  entity_to_decal_index : Map[Int, Int]
}

///|
pub fn RenderClusteredDecals::default() -> RenderClusteredDecals {
  RenderClusteredDecals::{
    binding_index_to_textures: [],
    texture_to_binding_index: {},
    decals: [],
    entity_to_decal_index: {},
  }
}

///|
pub fn RenderClusteredDecals::clear(self : RenderClusteredDecals) -> Unit {
  self.binding_index_to_textures.clear()
  self.texture_to_binding_index.clear()
  self.decals.clear()
  self.entity_to_decal_index.clear()
}

///|
pub fn RenderClusteredDecals::get_or_insert_texture(
  self : RenderClusteredDecals,
  texture_id : Int,
) -> Int {
  match self.texture_to_binding_index.get(texture_id) {
    Some(index) => index
    None => {
      let index = self.binding_index_to_textures.length()
      self.binding_index_to_textures.push(texture_id)
      self.texture_to_binding_index.set(texture_id, index)
      index
    }
  }
}

///|
pub fn RenderClusteredDecals::insert_decal(
  self : RenderClusteredDecals,
  entity : @core.Entity,
  decal : ClusteredDecal,
) -> Int {
  self.insert_decal_with_local_from_world(
    entity,
    decal,
    @math.Affine3::identity(),
  )
}

///|
pub fn RenderClusteredDecals::insert_decal_with_local_from_world(
  self : RenderClusteredDecals,
  entity : @core.Entity,
  decal : ClusteredDecal,
  local_from_world : @math.Affine3,
) -> Int {
  let base_color_texture_index = match decal.base_color_texture_id() {
    Some(texture_id) => self.get_or_insert_texture(texture_id)
    None => -1
  }
  let normal_map_texture_index = match decal.normal_map_texture_id() {
    Some(texture_id) => self.get_or_insert_texture(texture_id)
    None => -1
  }
  let metallic_roughness_texture_index = match
    decal.metallic_roughness_texture_id() {
    Some(texture_id) => self.get_or_insert_texture(texture_id)
    None => -1
  }
  let emissive_texture_index = match decal.emissive_texture_id() {
    Some(texture_id) => self.get_or_insert_texture(texture_id)
    None => -1
  }
  let decal_index = self.decals.length()
  self.decals.push(
    RenderClusteredDecal::new(
      local_from_world,
      base_color_texture_index,
      normal_map_texture_index,
      metallic_roughness_texture_index,
      emissive_texture_index,
      decal.tag,
    ),
  )
  self.entity_to_decal_index.set(entity.id, decal_index)
  decal_index
}

///|
pub fn RenderClusteredDecals::get_decal_index(
  self : RenderClusteredDecals,
  entity : @core.Entity,
) -> Int? {
  self.entity_to_decal_index.get(entity.id)
}

///|
pub let ecs_key_clustered_decal : @ecs.ComponentKey[ClusteredDecal] = @light.ecs_key_clustered_decal

///|
pub let ecs_key_render_clustered_decals : @ecs.ResourceKey[
  RenderClusteredDecals,
] = @ecs.register_resource(debug_name="render3d.clustered_decals")

///|
pub impl @app.Resource for RenderClusteredDecals with resource() {
  ecs_key_render_clustered_decals
}

///|
pub struct RenderViewClusteredDecalBindGroupEntries {
  decals : Array[RenderClusteredDecal]
  texture_ids : Array[Int]
  sampler_texture_id : Int
}

///|
pub enum ClusteredDecalBindGroupLayoutEntryType {
  StorageBufferReadOnly
  Texture2dBindingArray(Int)
  SamplerFiltering
}

///|
pub struct ClusteredDecalBindGroupLayoutEntry {
  binding : Int
  name : String
  entry_type : ClusteredDecalBindGroupLayoutEntryType
}

///|
pub fn clustered_decal_bind_group_layout_entries(
  max_view_decals : Int,
  decals_supported? : Bool = true,
) -> Array[ClusteredDecalBindGroupLayoutEntry]? {
  if !decals_supported {
    return None
  }
  Some([
    ClusteredDecalBindGroupLayoutEntry::{
      binding: 0,
      name: "decals",
      entry_type: ClusteredDecalBindGroupLayoutEntryType::StorageBufferReadOnly,
    },
    ClusteredDecalBindGroupLayoutEntry::{
      binding: 1,
      name: "decal_textures",
      entry_type: ClusteredDecalBindGroupLayoutEntryType::Texture2dBindingArray(
        max_view_decals,
      ),
    },
    ClusteredDecalBindGroupLayoutEntry::{
      binding: 2,
      name: "decal_sampler",
      entry_type: ClusteredDecalBindGroupLayoutEntryType::SamplerFiltering,
    },
  ])
}

///|
pub struct DecalsBuffer {
  decals : Array[RenderClusteredDecal]
}

///|
pub fn DecalsBuffer::default() -> DecalsBuffer {
  DecalsBuffer::{ decals: [] }
}

///|
pub fn DecalsBuffer::clear(self : DecalsBuffer) -> Unit {
  self.decals.clear()
}

///|
pub fn DecalsBuffer::push(
  self : DecalsBuffer,
  decal : RenderClusteredDecal,
) -> Unit {
  self.decals.push(decal)
}

///|
pub fn DecalsBuffer::is_empty(self : DecalsBuffer) -> Bool {
  self.decals.length() == 0
}

///|
let ecs_key_decals_buffer : @ecs.ResourceKey[DecalsBuffer] = @ecs.register_resource(
  debug_name="render3d.decals_buffer",
)

///|
pub impl @app.Resource for DecalsBuffer with resource() {
  ecs_key_decals_buffer
}

///|
pub fn clustered_decal_max_view_decals(
  partially_bound_binding_array? : Bool = true,
) -> Int {
  if partially_bound_binding_array {
    1024
  } else {
    8
  }
}

///|
pub fn RenderViewClusteredDecalBindGroupEntries::get(
  render_decals : RenderClusteredDecals,
  decals_buffer : DecalsBuffer,
  fallback_texture_id : Int,
  partially_bound_binding_array? : Bool = true,
  decals_supported? : Bool = true,
) -> RenderViewClusteredDecalBindGroupEntries? {
  if !decals_supported {
    return None
  }
  let texture_ids = render_decals.binding_index_to_textures.copy()
  if !partially_bound_binding_array {
    let max_view_decals = clustered_decal_max_view_decals(
      partially_bound_binding_array~,
    )
    while texture_ids.length() < max_view_decals {
      texture_ids.push(fallback_texture_id)
    }
  } else if texture_ids.length() == 0 {
    texture_ids.push(fallback_texture_id)
  }
  let sampler_texture_id = if render_decals.binding_index_to_textures.length() ==
    0 {
    fallback_texture_id
  } else {
    render_decals.binding_index_to_textures[0]
  }
  Some(RenderViewClusteredDecalBindGroupEntries::{
    decals: decals_buffer.decals.copy(),
    texture_ids,
    sampler_texture_id,
  })
}

///|
pub fn render3d_upload_decals(
  render_decals : RenderClusteredDecals,
  decals_buffer : DecalsBuffer,
) -> Unit {
  decals_buffer.clear()
  for decal in render_decals.decals {
    decals_buffer.push(decal)
  }
  if decals_buffer.is_empty() {
    decals_buffer.push(RenderClusteredDecal::default())
  }
}

///|
fn render3d_upload_decals_system(world : @ecs.World) -> Unit {
  let render_decals_ref = render3d_render_clustered_decals_ref_or_init(world)
  let decals_buffer_ref = render3d_decals_buffer_ref_or_init(world)
  decals_buffer_ref.set_changed()
  render3d_upload_decals(render_decals_ref.peek(), decals_buffer_ref.peek())
}

///|
pub fn render3d_decals_buffer_ref(
  world : @ecs.World,
) -> @ecs.ResourceMut[DecalsBuffer]? {
  try! world.get_resource_mut(ecs_key_decals_buffer)
}

///|
pub fn render3d_decals_buffer_ref_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[DecalsBuffer] {
  if render3d_decals_buffer_ref(world) is None {
    world.insert_resource(ecs_key_decals_buffer, DecalsBuffer::default())
  }
  match render3d_decals_buffer_ref(world) {
    Some(decals_buffer) => decals_buffer
    None => abort("missing decals buffer after lazy initialization")
  }
}

///|
pub struct ClusteredDecalPlugin {}

///|
pub fn ClusteredDecalPlugin::default() -> ClusteredDecalPlugin {
  ClusteredDecalPlugin::{  }
}

///|
pub impl @app.Plugin for ClusteredDecalPlugin with name(_self) {
  CLUSTERED_DECAL_PLUGIN_NAME
}

///|
fn clustered_decal_cubemap_layout_tag(layout : @light.CubemapLayout3d) -> Int {
  match layout {
    @light.CubemapLayout3d::CrossVertical => 0
    @light.CubemapLayout3d::CrossHorizontal => 1
    @light.CubemapLayout3d::LineVertical => 2
    @light.CubemapLayout3d::LineHorizontal => 3
    @light.CubemapLayout3d::Equirectangular => 4
    @light.CubemapLayout3d::Faces => 5
  }
}

///|
fn clustered_decal_is_view_visible(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  match (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
    Some(view_visibility) => view_visibility.is_visible()
    None => true
  }
}

///|
fn clustered_decal_local_from_world(
  world : @ecs.World,
  entity : @core.Entity,
) -> @math.Affine3 {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global_transform) => global_transform.affine().inverse()
    None => @math.Affine3::identity()
  }
}

///|
fn clustered_decal_extract_scene_decals(
  source_world : @ecs.World,
  render_decals : RenderClusteredDecals,
) -> Unit {
  source_world.for_each_component(ecs_key_clustered_decal, fn(entity, decal) {
    if !clustered_decal_is_view_visible(source_world, entity) {
      return
    }
    ignore(
      render_decals.insert_decal_with_local_from_world(
        entity,
        decal,
        clustered_decal_local_from_world(source_world, entity),
      ),
    )
  })
}

///|
fn clustered_decal_extract_spot_light_textures(
  source_world : @ecs.World,
  render_decals : RenderClusteredDecals,
) -> Unit {
  source_world.for_each_component(@light.ecs_key_spot_light_texture, fn(
    entity,
    texture,
  ) {
    if !clustered_decal_is_view_visible(source_world, entity) {
      return
    }
    ignore(
      render_decals.insert_decal_with_local_from_world(
        entity,
        ClusteredDecal::default().with_base_color_texture(texture.image),
        clustered_decal_local_from_world(source_world, entity),
      ),
    )
  })
}

///|
fn clustered_decal_extract_point_light_textures(
  source_world : @ecs.World,
  render_decals : RenderClusteredDecals,
) -> Unit {
  source_world.for_each_component(@light.ecs_key_point_light_texture, fn(
    entity,
    texture,
  ) {
    if !clustered_decal_is_view_visible(source_world, entity) {
      return
    }
    ignore(
      render_decals.insert_decal_with_local_from_world(
        entity,
        ClusteredDecal::default()
        .with_base_color_texture(texture.image)
        .with_tag(clustered_decal_cubemap_layout_tag(texture.cubemap_layout)),
        clustered_decal_local_from_world(source_world, entity),
      ),
    )
  })
}

///|
fn clustered_decal_extract_directional_light_textures(
  source_world : @ecs.World,
  render_decals : RenderClusteredDecals,
) -> Unit {
  source_world.for_each_component(@light.ecs_key_directional_light_texture, fn(
    entity,
    texture,
  ) {
    if !clustered_decal_is_view_visible(source_world, entity) {
      return
    }
    ignore(
      render_decals.insert_decal_with_local_from_world(
        entity,
        ClusteredDecal::default()
        .with_base_color_texture(texture.image)
        .with_tag(if texture.tiled { 1 } else { 0 }),
        clustered_decal_local_from_world(source_world, entity),
      ),
    )
  })
}

///|
pub fn render3d_extract_clustered_decals_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let render_decals_ref = render3d_render_clustered_decals_ref_or_init(world)
  render_decals_ref.set_changed()
  let render_decals = render_decals_ref.peek()
  render_decals.clear()
  clustered_decal_extract_scene_decals(source_world, render_decals)
  clustered_decal_extract_spot_light_textures(source_world, render_decals)
  clustered_decal_extract_point_light_textures(source_world, render_decals)
  clustered_decal_extract_directional_light_textures(
    source_world, render_decals,
  )
}

///|
fn render3d_extract_clustered_decals_system_in_render_app(
  world : @ecs.World,
) -> Unit {
  render3d_extract_clustered_decals_system(world)
}

///|
pub fn render3d_render_clustered_decals_ref(
  world : @ecs.World,
) -> @ecs.ResourceMut[RenderClusteredDecals]? {
  try! world.get_resource_mut(ecs_key_render_clustered_decals)
}

///|
pub fn render3d_render_clustered_decals_ref_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[RenderClusteredDecals] {
  if render3d_render_clustered_decals_ref(world) is None {
    world.insert_resource(
      ecs_key_render_clustered_decals,
      RenderClusteredDecals::default(),
    )
  }
  match render3d_render_clustered_decals_ref(world) {
    Some(render_decals) => render_decals
    None =>
      abort(
        "render clustered decals resource is missing after lazy initialization",
      )
  }
}

///|
pub impl @app.Plugin for ClusteredDecalPlugin with build(self, app) {
  register_embedded_wgsl_sources()
  clustered_decal_plugin_install_with(app, self)
}

///|
pub fn clustered_decal_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  clustered_decal_plugin_install_with(app, ClusteredDecalPlugin::default())
}

///|
pub fn clustered_decal_plugin_install_with(
  app : @app.App[@ecs.World],
  _plugin : ClusteredDecalPlugin,
) -> @app.App[@ecs.World] {
  @render.with_render_app(app, fn(sub_app : @app.SubApp[@ecs.World]) {
    let world = sub_app.world()
    if (try! world.get_resource(ecs_key_render_clustered_decals)) is None {
      world.insert_resource(
        ecs_key_render_clustered_decals,
        RenderClusteredDecals::default(),
      )
    }
    if (try! world.get_resource(ecs_key_decals_buffer)) is None {
      world.insert_resource(ecs_key_decals_buffer, DecalsBuffer::default())
    }
    sub_app
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(render3d_extract_clustered_decals_system_in_render_app).in_set(
        @render.render_system_set_extract_commands,
      ),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(render3d_upload_decals_system).in_set(
        @render.render_system_set_prepare_resources,
      ),
    )
  })
}
