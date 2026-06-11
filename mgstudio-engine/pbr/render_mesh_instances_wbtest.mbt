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
test "pbr: RenderMeshInstances exposes Bevy queue data by MainEntity" {
  let instances = RenderMeshInstances::RenderMeshInstances()
  let entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let flags = RenderMeshInstanceFlags::has_previous_skin().or(
    RenderMeshInstanceFlags::automatic_batching(),
  )
  instances.insert(entity, RenderMeshQueueData::new(33, 9U, true, flags~))

  let data = match instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing render mesh queue data")
  }
  debug_inspect(instances.len(), content="1")
  debug_inspect(instances.mesh_asset_id(entity), content="Some(33)")
  debug_inspect(data.mesh_asset_id(), content="33")
  debug_inspect(data.current_uniform_index(), content="9")
  debug_inspect(data.should_batch(), content="true")
  debug_inspect(
    data.flags().contains(RenderMeshInstanceFlags::has_previous_skin()),
    content="true",
  )
  debug_inspect(
    data.flags().contains(RenderMeshInstanceFlags::has_previous_morph()),
    content="false",
  )
  debug_inspect(instances.remove(entity) is Some(_), content="true")
  debug_inspect(
    instances.render_mesh_queue_data(entity) is None,
    content="true",
  )
}

///|
test "pbr: RenderMeshInstanceFlags preserves Bevy bit values" {
  let flags = RenderMeshInstanceFlags::shadow_caster()
    .or(RenderMeshInstanceFlags::automatic_batching())
    .or(RenderMeshInstanceFlags::has_previous_transform())
    .or(RenderMeshInstanceFlags::has_previous_skin())
    .or(RenderMeshInstanceFlags::has_previous_morph())
    .or(RenderMeshInstanceFlags::no_cpu_culling())

  debug_inspect(flags.bits(), content="63")
  debug_inspect(
    flags.contains(RenderMeshInstanceFlags::has_previous_skin()),
    content="true",
  )
  debug_inspect(
    RenderMeshInstanceFlags::empty().contains(
      RenderMeshInstanceFlags::shadow_caster(),
    ),
    content="false",
  )
}

///|
test "pbr: RenderMeshInstanceFlags mirrors Bevy extraction flags" {
  let default_flags = RenderMeshInstanceFlags::from_extraction_components(
    false, false, false, false, false, false,
  )
  debug_inspect(default_flags.bits(), content="3")
  debug_inspect(
    default_flags.contains(RenderMeshInstanceFlags::shadow_caster()),
    content="true",
  )
  debug_inspect(
    default_flags.contains(RenderMeshInstanceFlags::automatic_batching()),
    content="true",
  )

  let disabled_flags = RenderMeshInstanceFlags::from_extraction_components(
    true, true, true, true, true, true,
  )
  debug_inspect(disabled_flags.bits(), content="60")
  debug_inspect(
    disabled_flags.contains(RenderMeshInstanceFlags::shadow_caster()),
    content="false",
  )
  debug_inspect(
    disabled_flags.contains(RenderMeshInstanceFlags::automatic_batching()),
    content="false",
  )
}
