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
pub suberror LevelLoadError {
  LevelNotLoaded
}

///|
pub struct LoadedLevel {
  level : Level
}

///|
pub fn LoadedLevel::try_from(level : Level) -> LoadedLevel raise LevelLoadError {
  guard level.layer_instances is Some(_) else { raise LevelNotLoaded }
  LoadedLevel::{ level, }
}

///|
pub fn LoadedLevel::raw(self : LoadedLevel) -> Level {
  self.level
}

///|
pub fn LoadedLevel::bg_color(self : LoadedLevel) -> @sprite.Color {
  self.level.bg_color
}

///|
pub fn LoadedLevel::bg_rel_path(self : LoadedLevel) -> String? {
  self.level.bg_rel_path
}

///|
pub fn LoadedLevel::bg_pos(self : LoadedLevel) -> LevelBackgroundPosition? {
  self.level.bg_pos
}

///|
pub fn LoadedLevel::smart_color(self : LoadedLevel) -> @sprite.Color {
  self.level.smart_color
}

///|
pub fn LoadedLevel::level_bg_color(self : LoadedLevel) -> @sprite.Color? {
  self.level.level_bg_color
}

///|
pub fn LoadedLevel::bg_pivot_x(self : LoadedLevel) -> Float {
  self.level.bg_pivot_x
}

///|
pub fn LoadedLevel::bg_pivot_y(self : LoadedLevel) -> Float {
  self.level.bg_pivot_y
}

///|
pub fn LoadedLevel::level_bg_pos(self : LoadedLevel) -> BgPos? {
  self.level.level_bg_pos
}

///|
pub fn LoadedLevel::external_rel_path(self : LoadedLevel) -> String? {
  self.level.external_rel_path
}

///|
pub fn LoadedLevel::field_instances(
  self : LoadedLevel,
) -> Array[LdtkFieldInstance] {
  self.level.field_instances
}

///|
pub fn LoadedLevel::identifier(self : LoadedLevel) -> String {
  self.level.identifier
}

///|
pub fn LoadedLevel::iid(self : LoadedLevel) -> String {
  self.level.iid
}

///|
pub fn LoadedLevel::layer_instances(self : LoadedLevel) -> Array[LayerInstance] {
  match self.level.layer_instances {
    Some(layer_instances) => layer_instances
    None => abort("LoadedLevel::layer_instances expected loaded level")
  }
}

///|
pub fn LoadedLevel::neighbours(self : LoadedLevel) -> Array[NeighbourLevel] {
  self.level.neighbours
}

///|
pub fn LoadedLevel::neighbour_level_iids(self : LoadedLevel) -> Array[String] {
  let iids : Array[String] = []
  for neighbour in self.level.neighbours {
    iids.push(neighbour.level_iid)
  }
  iids
}

///|
pub fn LoadedLevel::px_hei(self : LoadedLevel) -> Int {
  self.level.px_hei
}

///|
pub fn LoadedLevel::px_wid(self : LoadedLevel) -> Int {
  self.level.px_wid
}

///|
pub fn LoadedLevel::uid(self : LoadedLevel) -> Int {
  self.level.uid
}

///|
pub fn LoadedLevel::use_auto_identifier(self : LoadedLevel) -> Bool {
  self.level.use_auto_identifier
}

///|
pub fn LoadedLevel::world_depth(self : LoadedLevel) -> Int {
  self.level.world_depth
}

///|
pub fn LoadedLevel::world_x(self : LoadedLevel) -> Int {
  self.level.world_x
}

///|
pub fn LoadedLevel::world_y(self : LoadedLevel) -> Int {
  self.level.world_y
}
