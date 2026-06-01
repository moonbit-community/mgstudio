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
priv struct CustomMesh2dRuntimeEntry {
  type_name : String
  descriptor : CustomMesh2dPipelineDescriptor
  contains_source_component_fn : (@ecs.World, @core.Entity) -> Bool
}

///|
struct CustomMesh2dRuntimeRegistry {
  entries : Array[CustomMesh2dRuntimeEntry]
}

///|
pub fn CustomMesh2dRuntimeRegistry::new() -> CustomMesh2dRuntimeRegistry {
  CustomMesh2dRuntimeRegistry::{ entries: [] }
}

///|
pub impl @app.Resource for CustomMesh2dRuntimeRegistry with fn resource() {
  custom_mesh2d_runtime_registry_key
}

///|
let custom_mesh2d_runtime_registry_key : @ecs.ResourceKey[
  CustomMesh2dRuntimeRegistry,
] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::CustomMesh2dRuntimeRegistry",
)

///|
fn CustomMesh2dRuntimeRegistry::register(
  self : CustomMesh2dRuntimeRegistry,
  entry : CustomMesh2dRuntimeEntry,
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
fn custom_mesh2d_runtime_registry_or_empty(
  world : @ecs.World,
) -> CustomMesh2dRuntimeRegistry {
  if world.get_resource(CustomMesh2dRuntimeRegistry::resource())
    is Some(registry) {
    registry
  } else {
    CustomMesh2dRuntimeRegistry::new()
  }
}

///|
pub fn CustomMesh2dRuntimeRegistry::contains_type_name(
  self : CustomMesh2dRuntimeRegistry,
  type_name : String,
) -> Bool {
  self.entries.any(fn(entry) { entry.type_name == type_name })
}

///|
pub fn CustomMesh2dRuntimeRegistry::entry_count(
  self : CustomMesh2dRuntimeRegistry,
) -> Int {
  self.entries.length()
}

///|
pub fn CustomMesh2dRuntimeRegistry::contains_entity(
  self : CustomMesh2dRuntimeRegistry,
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  for entry in self.entries {
    if (entry.contains_source_component_fn)(source_world, entity) {
      return true
    }
  }
  false
}

///|
fn ensure_custom_mesh2d_runtime_registry_resource_in_world(
  world : @ecs.World,
) -> Unit {
  if world.get_resource(CustomMesh2dRuntimeRegistry::resource()) is None {
    world.insert_resource(
      CustomMesh2dRuntimeRegistry::resource(),
      CustomMesh2dRuntimeRegistry::new(),
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
  ensure_custom_mesh2d_runtime_registry_resource_in_world(world)
  let contains_source_component = fn(
    source_world : @ecs.World,
    entity : @core.Entity,
  ) -> Bool {
    (try! source_world.get_by_key(entity, component_key)) is Some(_)
  }
  if world.get_resource_mut(CustomMesh2dRuntimeRegistry::resource())
    is Some(registry) {
    registry.modify(fn(value) {
      value.register(CustomMesh2dRuntimeEntry::{
        type_name,
        descriptor,
        contains_source_component_fn: contains_source_component,
      })
    })
  }
}

///|
fn custom_mesh2d_runtime_registry_contains_entity(
  source_world : @ecs.World,
  registry : CustomMesh2dRuntimeRegistry,
  entity : @core.Entity,
) -> Bool {
  registry.contains_entity(source_world, entity)
}

///|
fn custom_mesh2d_runtime_phase_for_draw(
  source_world : @ecs.World,
  registry : CustomMesh2dRuntimeRegistry,
  mesh : ExtractedMesh2d,
) -> (Int, Int)? {
  if mesh.payload.mesh_id <= 0 {
    return None
  }
  for runtime_index in 0..<registry.entries.length() {
    let entry = registry.entries[runtime_index]
    if (entry.contains_source_component_fn)(
        source_world,
        mesh.entity.main_entity,
      ) {
      return Some((runtime_index, entry.descriptor.phase))
    }
  }
  None
}

///|
fn draw_registered_custom_mesh2d_item(
  registry : CustomMesh2dRuntimeRegistry,
  runtime_index : Int,
  mesh : ExtractedMesh2d,
) -> Unit {
  guard runtime_index >= 0 && runtime_index < registry.entries.length() else {
    return
  }
  let entry = registry.entries[runtime_index]
  let descriptor = entry.descriptor
  @render.host_gpu_register_mesh2d_pipeline_descriptor(
    pipeline_id=descriptor.pipeline_id,
    shader_path=descriptor.shader_path,
  )
  let transform = mesh.payload.transform
  @render.host_gpu_draw_mesh2d_pipeline(
    mesh_id=mesh.payload.mesh_id,
    x=transform.translation.x,
    y=transform.translation.y,
    rotation=transform.rotation_z(),
    scale_x=transform.scale.x,
    scale_y=transform.scale.y,
    pipeline_id=descriptor.pipeline_id,
  )
}
