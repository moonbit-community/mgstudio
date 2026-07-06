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
pub fn render_material_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

///|
pub struct RenderMaterialEntitySlots[S] {
  slots : @hashmap.HashMap[(Int, Int), S]
}

///|
pub fn[S] RenderMaterialEntitySlots::new() -> RenderMaterialEntitySlots[S] {
  RenderMaterialEntitySlots::{ slots: @hashmap.HashMap([]) }
}

///|
pub fn[S] RenderMaterialEntitySlots::get(
  self : RenderMaterialEntitySlots[S],
  entity : @core.Entity,
) -> S? {
  self.slots.get(render_material_entity_key(entity))
}

///|
pub fn[S] RenderMaterialEntitySlots::set(
  self : RenderMaterialEntitySlots[S],
  entity : @core.Entity,
  slot : S,
) -> Unit {
  self.slots.set(render_material_entity_key(entity), slot)
}

///|
pub fn[S] RenderMaterialEntitySlots::remove(
  self : RenderMaterialEntitySlots[S],
  entity : @core.Entity,
) -> Unit {
  self.slots.remove(render_material_entity_key(entity)) |> ignore
}

///|
pub fn[S] RenderMaterialEntitySlots::contains(
  self : RenderMaterialEntitySlots[S],
  entity : @core.Entity,
) -> Bool {
  self.slots.contains(render_material_entity_key(entity))
}

///|
pub fn[S] RenderMaterialEntitySlots::clear(
  self : RenderMaterialEntitySlots[S],
) -> Unit {
  self.slots.clear()
}
