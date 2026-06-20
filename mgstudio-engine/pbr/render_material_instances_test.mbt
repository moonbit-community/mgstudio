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
test "render3d: render material instances extract visible material ids" {
  let instances = RenderMaterialInstances::RenderMaterialInstances()
  let entity = @core.Entity::new(7, 2)
  let material = MeshMaterial3d::new(@asset.Handle::new(42))

  debug_inspect(instances.mesh_material(entity), content="-1")
  instances.extract_mesh_material(entity, true, material)
  debug_inspect(instances.len(), content="1")
  debug_inspect(instances.mesh_material(entity), content="42")
  match instances.get(entity) {
    Some(instance) => debug_inspect(instance.last_change_tick(), content="0")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: render material instances remove invisible materials immediately" {
  let instances = RenderMaterialInstances::RenderMaterialInstances()
  let entity = @core.Entity::new(3, 1)
  let material = MeshMaterial3d::new(@asset.Handle::new(9))

  instances.extract_mesh_material(entity, true, material)
  instances.extract_mesh_material(entity, false, material)
  debug_inspect(instances.len(), content="0")
  debug_inspect(instances.mesh_material(entity), content="-1")
}

///|
test "render3d: render material instances remove missing legacy material immediately" {
  let instances = RenderMaterialInstances::RenderMaterialInstances()
  let entity = @core.Entity::new(4, 1)
  let material = MeshMaterial3d::new(@asset.Handle::new(10))

  instances.extract_mesh_material(entity, true, material)
  debug_inspect(instances.remove_mesh_material(entity), content="true")
  debug_inspect(instances.len(), content="0")
  debug_inspect(instances.mesh_material(entity), content="-1")
}

///|
test "render3d: early sweep preserves same-frame material replacement" {
  let instances = RenderMaterialInstances::RenderMaterialInstances()
  let entity = @core.Entity::new(11, 0)
  let first = MeshMaterial3d::new(@asset.Handle::new(1))
  let second = MeshMaterial3d::new(@asset.Handle::new(2))

  instances.extract_mesh_material(entity, true, first)
  instances.extract_mesh_material(entity, true, second)
  debug_inspect(
    instances.early_sweep_removed_mesh_material(entity),
    content="false",
  )
  debug_inspect(instances.mesh_material(entity), content="2")
}

///|
test "render3d: late sweep removes stale entries and advances change tick" {
  let instances = RenderMaterialInstances::RenderMaterialInstances()
  let stale = @core.Entity::new(19, 0)
  let current = @core.Entity::new(20, 0)
  let material = MeshMaterial3d::new(@asset.Handle::new(5))

  instances.extract_mesh_material(stale, true, material)
  ignore(instances.late_sweep_removed_mesh3d(current))
  instances.advance_change_tick()
  debug_inspect(instances.current_change_tick(), content="1")
  debug_inspect(instances.late_sweep_removed_mesh3d(stale), content="true")
  debug_inspect(instances.mesh_material(stale), content="-1")
  instances.advance_change_tick()
  debug_inspect(instances.current_change_tick(), content="2")
}
