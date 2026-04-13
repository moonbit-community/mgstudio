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
  base_color_texture_index : Int
  normal_map_texture_index : Int
  metallic_roughness_texture_index : Int
  emissive_texture_index : Int
  tag : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn RenderClusteredDecal::new(
  base_color_texture_index : Int,
  normal_map_texture_index : Int,
  metallic_roughness_texture_index : Int,
  emissive_texture_index : Int,
  tag : Int,
) -> RenderClusteredDecal {
  RenderClusteredDecal::{
    base_color_texture_index,
    normal_map_texture_index,
    metallic_roughness_texture_index,
    emissive_texture_index,
    tag: clustered_decal_tag_safe(tag),
  }
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
