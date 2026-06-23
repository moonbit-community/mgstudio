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
  let instances = RenderMeshInstances::new()
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
  debug_inspect(data.current_uniform_index(), content="0")
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
test "pbr: RenderMeshInstances has Bevy CPU and GPU building variants" {
  let entity = @render.MainEntity::new(@core.Entity::new(22, 1))
  let cpu_instances = RenderMeshInstances::new()
  cpu_instances.insert(entity, RenderMeshQueueData::new(41, 0U, false))
  match cpu_instances {
    CpuBuilding(_) => ()
    GpuBuilding(_) => abort("default should use CPU building")
  }
  debug_inspect(cpu_instances.mesh_asset_id(entity), content="Some(41)")

  let gpu_instances = RenderMeshInstances::new(
    use_gpu_instance_buffer_builder=true,
  )
  gpu_instances.insert(entity, RenderMeshQueueData::new(42, 7U, true))
  match gpu_instances {
    CpuBuilding(_) => abort("explicit GPU builder should use GPU building")
    GpuBuilding(_) => ()
  }
  let gpu_data = match gpu_instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing GPU render mesh queue data")
  }
  debug_inspect(gpu_instances.len(), content="1")
  debug_inspect(gpu_data.mesh_asset_id(), content="42")
  debug_inspect(gpu_data.current_uniform_index(), content="7")
  debug_inspect(gpu_data.should_batch(), content="true")
}

///|
test "pbr: RenderMeshInstances stores Bevy-shaped CPU and GPU instance records" {
  let entity = @render.MainEntity::new(@core.Entity::new(23, 1))
  let flags = RenderMeshInstanceFlags::has_previous_transform().or(
    RenderMeshInstanceFlags::automatic_batching(),
  )
  let cpu_instances = RenderMeshInstancesCpu::RenderMeshInstancesCpu()
  cpu_instances.insert(entity, RenderMeshQueueData::new(70, 9U, true, flags~))
  let cpu_data = match cpu_instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing CPU render mesh queue data")
  }
  debug_inspect(cpu_data.mesh_asset_id(), content="70")
  debug_inspect(cpu_data.current_uniform_index(), content="0")
  debug_inspect(
    cpu_data.flags().contains(RenderMeshInstanceFlags::has_previous_transform()),
    content="true",
  )

  let gpu_instances = RenderMeshInstancesGpu::RenderMeshInstancesGpu()
  gpu_instances.insert(entity, RenderMeshQueueData::new(71, 13U, true, flags~))
  let gpu_data = match gpu_instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing GPU render mesh queue data")
  }
  debug_inspect(gpu_data.mesh_asset_id(), content="71")
  debug_inspect(gpu_data.current_uniform_index(), content="13")
  debug_inspect(gpu_data.should_batch(), content="true")
}

///|
test "pbr: RenderMeshInstanceGpuQueue mirrors Bevy CPU culling state" {
  let queue = RenderMeshInstanceGpuQueue::RenderMeshInstanceGpuQueue()
  let entity = @render.MainEntity::new(@core.Entity::new(30, 1))
  let builder = RenderMeshInstanceGpuBuilder::new(
    RenderMeshQueueData::new(51, 0U, true),
  )
  queue.init(false)
  queue.push(entity, builder, None, false)
  queue.remove(entity, false)
  match queue.state() {
    CpuCulling(cpu_queue) => {
      debug_inspect(cpu_queue.changed.length(), content="1")
      debug_inspect(cpu_queue.removed.length(), content="1")
    }
    _ => abort("queue should be in CPU culling mode")
  }

  queue.init(false)
  debug_inspect(queue.changed_len(), content="0")
  debug_inspect(queue.removed_len(), content="0")
}

///|
test "pbr: RenderMeshInstanceGpuQueue mirrors Bevy GPU culling split queues" {
  let queue = RenderMeshInstanceGpuQueue::RenderMeshInstanceGpuQueue()
  let cpu_entity = @render.MainEntity::new(@core.Entity::new(31, 1))
  let gpu_entity = @render.MainEntity::new(@core.Entity::new(32, 1))
  let builder = RenderMeshInstanceGpuBuilder::new(
    RenderMeshQueueData::new(52, 2U, true),
  )
  let culling_data = MeshCullingData::new(None)
  queue.init(true)
  queue.push(cpu_entity, builder, Some(culling_data), false)
  queue.push(gpu_entity, builder, Some(culling_data), true)
  queue.remove(gpu_entity, true)

  match queue.state() {
    GpuCulling(gpu_queue) => {
      debug_inspect(gpu_queue.changed_cpu_culling.length(), content="1")
      debug_inspect(gpu_queue.changed_gpu_culling.length(), content="1")
      debug_inspect(gpu_queue.removed.length(), content="1")
    }
    _ => abort("queue should be in GPU culling mode")
  }
  debug_inspect(queue.changed_len(), content="2")
  debug_inspect(queue.gpu_changed_cpu_culling_len(), content="1")
  debug_inspect(queue.gpu_changed_gpu_culling_len(), content="1")
}

///|
test "pbr: MeshesToReextractNextFrame drains all render mesh instances" {
  let first = @render.MainEntity::new(@core.Entity::new(40, 1))
  let second = @render.MainEntity::new(@core.Entity::new(41, 1))
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  instances.insert(first, RenderMeshQueueData::new(60, 0U, true))
  instances.insert(second, RenderMeshQueueData::new(61, 0U, true))
  let meshes_to_reextract = MeshesToReextractNextFrame::MeshesToReextractNextFrame()

  mark_all_meshes_for_reextraction(instances, meshes_to_reextract)

  debug_inspect(instances.len(), content="0")
  debug_inspect(meshes_to_reextract.len(), content="2")
  debug_inspect(meshes_to_reextract.contains(first), content="true")
  debug_inspect(meshes_to_reextract.contains(second), content="true")
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
