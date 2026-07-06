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
priv struct CustomMesh2dPipelineIdState {
  mut next : UInt64
}

///|
let custom_mesh2d_pipeline_id_state : CustomMesh2dPipelineIdState = {
  next: 1UL,
}

///|
fn next_custom_mesh2d_pipeline_id() -> UInt64 {
  let id = custom_mesh2d_pipeline_id_state.next
  custom_mesh2d_pipeline_id_state.next = id + 1UL
  id
}

///|
pub struct CustomMesh2dPipelineDescriptor {
  pipeline_id : UInt64
  shader_path : String
  phase : Int
}

///|
pub fn CustomMesh2dPipelineDescriptor::new(
  shader_path : String,
  phase? : Int = 1,
) -> CustomMesh2dPipelineDescriptor {
  CustomMesh2dPipelineDescriptor::{
    pipeline_id: next_custom_mesh2d_pipeline_id(),
    shader_path,
    phase,
  }
}

///|
pub fn CustomMesh2dPipelineDescriptor::pipeline_id(
  self : CustomMesh2dPipelineDescriptor,
) -> UInt64 {
  self.pipeline_id
}

///|
pub fn CustomMesh2dPipelineDescriptor::shader_path(
  self : CustomMesh2dPipelineDescriptor,
) -> String {
  self.shader_path
}

///|
pub fn CustomMesh2dPipelineDescriptor::phase(
  self : CustomMesh2dPipelineDescriptor,
) -> Int {
  self.phase
}

///|
priv struct CustomMesh2dPipelineRegistrationEntry {
  type_name : String
  extract_slots_fn : (@ecs.World, CustomMesh2dPipelineSlots) -> Unit
}

///|
struct CustomMesh2dPipelineRegistrations {
  entries : Array[CustomMesh2dPipelineRegistrationEntry]
}

///|
pub fn CustomMesh2dPipelineRegistrations::new() -> CustomMesh2dPipelineRegistrations {
  CustomMesh2dPipelineRegistrations::{ entries: [] }
}

///|
pub impl @app.Resource for CustomMesh2dPipelineRegistrations with fn resource() {
  custom_mesh2d_pipeline_registrations_key
}

///|
let custom_mesh2d_pipeline_registrations_key : @ecs.ResourceKey[
  CustomMesh2dPipelineRegistrations,
] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::CustomMesh2dPipelineRegistrations",
)

///|
fn CustomMesh2dPipelineRegistrations::register(
  self : CustomMesh2dPipelineRegistrations,
  entry : CustomMesh2dPipelineRegistrationEntry,
) -> Unit {
  for i in 0..<self.entries.length() {
    if self.entries[i].type_name == entry.type_name {
      self.entries[i] = entry
      return
    }
  }
  self.entries.push(entry)
}

///|
fn custom_mesh2d_pipeline_registrations_or_empty(
  world : @ecs.World,
) -> CustomMesh2dPipelineRegistrations {
  if world.get_resource(CustomMesh2dPipelineRegistrations::resource())
    is Some(registrations) {
    registrations
  } else {
    CustomMesh2dPipelineRegistrations::new()
  }
}

///|
pub fn CustomMesh2dPipelineRegistrations::contains_type_name(
  self : CustomMesh2dPipelineRegistrations,
  type_name : String,
) -> Bool {
  self.entries.any(fn(entry) { entry.type_name == type_name })
}

///|
pub fn CustomMesh2dPipelineRegistrations::entry_count(
  self : CustomMesh2dPipelineRegistrations,
) -> Int {
  self.entries.length()
}

///|
pub struct CustomMesh2dPipelineSlots {
  slots : @hashmap.HashMap[(Int, Int), CustomMesh2dPipelineDescriptor]
}

///|
pub fn CustomMesh2dPipelineSlots::new() -> CustomMesh2dPipelineSlots {
  CustomMesh2dPipelineSlots::{ slots: @hashmap.HashMap([]) }
}

///|
fn custom_mesh2d_pipeline_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

///|
pub fn CustomMesh2dPipelineSlots::clear(
  self : CustomMesh2dPipelineSlots,
) -> Unit {
  self.slots.clear()
}

///|
pub fn CustomMesh2dPipelineSlots::set(
  self : CustomMesh2dPipelineSlots,
  entity : @core.Entity,
  descriptor : CustomMesh2dPipelineDescriptor,
) -> Unit {
  self.slots.set(custom_mesh2d_pipeline_entity_key(entity), descriptor)
}

///|
pub fn CustomMesh2dPipelineSlots::get(
  self : CustomMesh2dPipelineSlots,
  entity : @core.Entity,
) -> CustomMesh2dPipelineDescriptor? {
  self.slots.get(custom_mesh2d_pipeline_entity_key(entity))
}

///|
pub fn CustomMesh2dPipelineSlots::contains(
  self : CustomMesh2dPipelineSlots,
  entity : @core.Entity,
) -> Bool {
  self.slots.contains(custom_mesh2d_pipeline_entity_key(entity))
}

///|
pub impl @app.Resource for CustomMesh2dPipelineSlots with fn resource() {
  custom_mesh2d_pipeline_slots_key
}

///|
let custom_mesh2d_pipeline_slots_key : @ecs.ResourceKey[
  CustomMesh2dPipelineSlots,
] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::CustomMesh2dPipelineSlots",
)

///|
fn ensure_custom_mesh2d_pipeline_slots_resource_in_world(
  world : @ecs.World,
) -> Unit {
  if world.get_resource(CustomMesh2dPipelineSlots::resource()) is None {
    world.insert_resource(
      CustomMesh2dPipelineSlots::resource(),
      CustomMesh2dPipelineSlots::new(),
    )
  }
}

///|
fn ensure_custom_mesh2d_pipeline_registrations_resource_in_world(
  world : @ecs.World,
) -> Unit {
  if world.get_resource(CustomMesh2dPipelineRegistrations::resource()) is None {
    world.insert_resource(
      CustomMesh2dPipelineRegistrations::resource(),
      CustomMesh2dPipelineRegistrations::new(),
    )
  }
}

///|
pub fn[T] register_custom_mesh2d_pipeline_world(
  world : @ecs.World,
  type_name~ : String,
  component_key~ : @ecs.ComponentKey[T],
  descriptor~ : CustomMesh2dPipelineDescriptor,
) -> Unit {
  ensure_custom_mesh2d_pipeline_registrations_resource_in_world(world)
  ensure_custom_mesh2d_pipeline_slots_resource_in_world(world)
  let extract_slots = fn(
    source_world : @ecs.World,
    slots : CustomMesh2dPipelineSlots,
  ) -> Unit {
    source_world.for_each_component(component_key, fn(entity, _component) {
      slots.set(entity, descriptor)
    })
  }
  if world.get_resource_mut(CustomMesh2dPipelineRegistrations::resource())
    is Some(registrations) {
    registrations.modify(fn(value) {
      value.register(CustomMesh2dPipelineRegistrationEntry::{
        type_name,
        extract_slots_fn: extract_slots,
      })
    })
  }
}

///|
pub fn custom_mesh2d_pipeline_slots_or_empty(
  world : @ecs.World,
) -> CustomMesh2dPipelineSlots {
  match world.get_resource(CustomMesh2dPipelineSlots::resource()) {
    Some(slots) => slots
    None => CustomMesh2dPipelineSlots::new()
  }
}

///|
pub fn extract_custom_mesh2d_pipeline_slots_world(world : @ecs.World) -> Unit {
  let source_world = @renderer.render_source_world(world)
  extract_custom_mesh2d_pipeline_slots_from_source(source_world, world)
}

///|
pub fn extract_custom_mesh2d_pipeline_slots_from_source(
  source_world : @ecs.World,
  world : @ecs.World,
) -> Unit {
  ensure_custom_mesh2d_pipeline_slots_resource_in_world(world)
  let registrations = custom_mesh2d_pipeline_registrations_or_empty(world)
  match world.get_resource_mut(CustomMesh2dPipelineSlots::resource()) {
    Some(slots_ref) =>
      slots_ref.modify(fn(slots) {
        slots.clear()
        for entry in registrations.entries {
          (entry.extract_slots_fn)(source_world, slots)
        }
      })
    None => ()
  }
}

///|
fn custom_mesh2d_pipeline_phase_for_draw(
  slots : CustomMesh2dPipelineSlots,
  mesh : ExtractedMesh2d,
) -> Int? {
  if mesh.payload.mesh_id <= 0 {
    return None
  }
  match slots.get(mesh.entity.main_entity) {
    Some(descriptor) => Some(descriptor.phase)
    None => None
  }
}

///|
fn draw_custom_mesh2d_pipeline_item(
  slots : CustomMesh2dPipelineSlots,
  mesh : ExtractedMesh2d,
) -> Unit {
  guard slots.get(mesh.entity.main_entity) is Some(descriptor) else { return }
  @renderer.host_gpu_register_mesh2d_pipeline_descriptor(
    pipeline_id=descriptor.pipeline_id,
    shader_path=descriptor.shader_path,
  )
  let transform = mesh.payload.transform
  @renderer.host_gpu_draw_mesh2d_pipeline(
    mesh_id=mesh.payload.mesh_id,
    x=transform.translation.x,
    y=transform.translation.y,
    rotation=transform.rotation_z(),
    scale_x=transform.scale.x,
    scale_y=transform.scale.y,
    pipeline_id=descriptor.pipeline_id,
  )
}
