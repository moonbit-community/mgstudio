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
fn clustered_decal_tag_safe(tag : Int) -> Int {
  if tag < 0 {
    0
  } else {
    tag
  }
}

///|
pub const CLUSTERED_DECAL_IMAGES_PER_DECAL : Int = 4

///|
const CLUSTERED_DECAL_PLUGIN_NAME : String = "mgstudio.pbr.decal.ClusteredDecalPlugin"

///|
/// Clustered decal parameters aligned with Bevy's `ClusteredDecal`.
///
/// The decal volume follows Bevy semantics: a transformed unit cube that
/// projects textures along local `-Z`.
pub struct ClusteredDecal {
  base_color_texture : @asset.Handle[@asset.Image]?
  normal_map_texture : @asset.Handle[@asset.Image]?
  metallic_roughness_texture : @asset.Handle[@asset.Image]?
  emissive_texture : @asset.Handle[@asset.Image]?
  tag : Int
} derive(ToJson, FromJson)

///|
pub fn ClusteredDecal::default() -> ClusteredDecal {
  ClusteredDecal::{
    base_color_texture: None,
    normal_map_texture: None,
    metallic_roughness_texture: None,
    emissive_texture: None,
    tag: 0,
  }
}

///|
pub fn ClusteredDecal::new() -> ClusteredDecal {
  ClusteredDecal::default()
}

///|
pub fn ClusteredDecal::with_base_color_texture(
  self : ClusteredDecal,
  base_color_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, base_color_texture, }
}

///|
pub fn ClusteredDecal::with_normal_map_texture(
  self : ClusteredDecal,
  normal_map_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, normal_map_texture, }
}

///|
pub fn ClusteredDecal::with_metallic_roughness_texture(
  self : ClusteredDecal,
  metallic_roughness_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, metallic_roughness_texture, }
}

///|
pub fn ClusteredDecal::with_emissive_texture(
  self : ClusteredDecal,
  emissive_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, emissive_texture, }
}

///|
pub fn ClusteredDecal::with_tag(
  self : ClusteredDecal,
  tag : Int,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, tag: clustered_decal_tag_safe(tag) }
}

///|
pub fn ClusteredDecal::base_color_texture_id(self : ClusteredDecal) -> Int? {
  self.base_color_texture.map(fn(handle) { handle.id() })
}

///|
pub fn ClusteredDecal::normal_map_texture_id(self : ClusteredDecal) -> Int? {
  self.normal_map_texture.map(fn(handle) { handle.id() })
}

///|
pub fn ClusteredDecal::metallic_roughness_texture_id(
  self : ClusteredDecal,
) -> Int? {
  self.metallic_roughness_texture.map(fn(handle) { handle.id() })
}

///|
pub fn ClusteredDecal::emissive_texture_id(self : ClusteredDecal) -> Int? {
  self.emissive_texture.map(fn(handle) { handle.id() })
}

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
    tag: clustered_decal_tag_safe(tag),
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
pub let ecs_key_clustered_decal : @ecs.ComponentKey[ClusteredDecal] = @ecs.register_component(
  debug_name="render3d.clustered_decal",
)

///|
pub impl @ecs.Component for ClusteredDecal with component() {
  ecs_key_clustered_decal
}

///|
pub let ecs_key_render_clustered_decals : @ecs.ResourceKey[
  RenderClusteredDecals,
] = @ecs.register_resource(debug_name="render3d.clustered_decals")

///|
pub impl @app.Resource for RenderClusteredDecals with resource() {
  ecs_key_render_clustered_decals
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
  render_decals_ref.val.clear()
  clustered_decal_extract_scene_decals(source_world, render_decals_ref.val)
  clustered_decal_extract_spot_light_textures(
    source_world,
    render_decals_ref.val,
  )
  clustered_decal_extract_point_light_textures(
    source_world,
    render_decals_ref.val,
  )
  clustered_decal_extract_directional_light_textures(
    source_world,
    render_decals_ref.val,
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
) -> Ref[RenderClusteredDecals]? {
  try! world.get_resource_ref_mut(ecs_key_render_clustered_decals)
}

///|
pub fn render3d_render_clustered_decals_ref_or_init(
  world : @ecs.World,
) -> Ref[RenderClusteredDecals] {
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
    sub_app.add_systems(
      @render.render_schedule_stage(),
      @app.system(render3d_extract_clustered_decals_system_in_render_app).in_set(
        @render.render_system_set_extract_commands,
      ),
    )
  })
}
