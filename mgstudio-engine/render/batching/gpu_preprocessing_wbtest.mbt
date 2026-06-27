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
test "gpu preprocessing: instance input buffer reuses removed slots" {
  let buffer : InstanceInputUniformBuffer[Int] = InstanceInputUniformBuffer::new()
  let a = buffer.add(11)
  let b = buffer.add(22)
  debug_inspect(a, content="0")
  debug_inspect(b, content="1")
  buffer.remove(a)
  debug_inspect(buffer.get(a) is None, content="true")
  debug_inspect(buffer.get_unchecked(a), content="11")
  let c = buffer.add(33)
  debug_inspect(c, content="0")
  debug_inspect(buffer.get(c).unwrap(), content="33")
  debug_inspect(buffer.len(), content="2")
}

///|
test "gpu preprocessing: instance input buffer can be made nonempty" {
  let buffer : InstanceInputUniformBuffer[Int] = InstanceInputUniformBuffer::new()
  buffer.ensure_nonempty(7)
  buffer.ensure_nonempty(8)
  debug_inspect(buffer.len(), content="1")
  debug_inspect(buffer.get(0).unwrap(), content="7")
}

///|
test "gpu preprocessing: batched instance clear keeps phase tables for reuse" {
  let buffers : BatchedInstanceBuffers[Int, Int] = BatchedInstanceBuffers::new()
  let phase : PhaseBatchedInstanceBuffers[Int] = PhaseBatchedInstanceBuffers::new()
  phase.marker = 7
  buffers.insert_phase_instance_buffers("shadow", phase)
  ignore(buffers.current_input_buffer.add(11))
  ignore(buffers.previous_input_buffer.add(22))
  debug_inspect(buffers.phase_instance_buffer_count(), content="1")
  buffers.clear()
  debug_inspect(buffers.current_input_buffer.len(), content="0")
  debug_inspect(buffers.previous_input_buffer.len(), content="0")
  debug_inspect(buffers.phase_instance_buffer_count(), content="1")
  debug_inspect(
    buffers.phase_instance_buffers.get("shadow").unwrap().marker,
    content="0",
  )
}

///|
test "gpu preprocessing: collect phase buffers swaps with global table" {
  let global : BatchedInstanceBuffers[Int, Int] = BatchedInstanceBuffers::new()
  let old_phase : PhaseBatchedInstanceBuffers[Int] = PhaseBatchedInstanceBuffers::new()
  old_phase.marker = 5
  global.insert_phase_instance_buffers("shadow", old_phase)
  let phase : PhaseBatchedInstanceBuffers[Int] = PhaseBatchedInstanceBuffers::new()
  phase.marker = 9
  collect_phase_batched_instance_buffers(global, "shadow", phase)
  debug_inspect(global.phase_instance_buffer_count(), content="1")
  debug_inspect(
    global.phase_instance_buffers.get("shadow").unwrap().marker,
    content="9",
  )
  debug_inspect(phase.marker, content="0")
  phase.marker = 10
  collect_phase_batched_instance_buffers(global, "shadow", phase)
  debug_inspect(
    global.phase_instance_buffers.get("shadow").unwrap().marker,
    content="10",
  )
  debug_inspect(phase.marker, content="0")
}

///|
test "gpu preprocessing: direct work-item buffers collect one list" {
  let buffers = preprocess_work_item_buffers_direct()
  buffers.push(false, PreprocessWorkItem::new(3, 4))
  buffers.push(true, PreprocessWorkItem::new(5, 6))
  debug_inspect(buffers.direct_len(), content="2")
  debug_inspect(buffers.indexed_len(), content="0")
  buffers.clear()
  debug_inspect(buffers.direct_len(), content="0")
}

///|
test "gpu preprocessing: indirect work-item buffers split mesh classes and late occlusion lists" {
  let buffers = preprocess_work_item_buffers_indirect(true)
  let indexed_offsets : Array[LatePreprocessWorkItemIndirectParameters] = []
  let non_indexed_offsets : Array[LatePreprocessWorkItemIndirectParameters] = []
  indexed_offsets.push(
    LatePreprocessWorkItemIndirectParameters::LatePreprocessWorkItemIndirectParameters(),
  )
  non_indexed_offsets.push(
    LatePreprocessWorkItemIndirectParameters::LatePreprocessWorkItemIndirectParameters(),
  )
  init_work_item_buffers(buffers, indexed_offsets, non_indexed_offsets)
  buffers.push(true, PreprocessWorkItem::new(1, 10))
  buffers.push(false, PreprocessWorkItem::new(2, 20))
  debug_inspect(buffers.indexed_len(), content="1")
  debug_inspect(buffers.non_indexed_len(), content="1")
  debug_inspect(buffers.late_indexed_len(), content="1")
  debug_inspect(buffers.late_non_indexed_len(), content="1")
  debug_inspect(buffers.late_indirect_offsets().unwrap(), content="(1, 1)")
  debug_inspect(indexed_offsets.length(), content="2")
  debug_inspect(non_indexed_offsets.length(), content="2")
  buffers.clear()
  debug_inspect(buffers.indexed_len(), content="0")
  debug_inspect(buffers.late_indirect_offsets().unwrap(), content="(0, 0)")
}

///|
test "gpu preprocessing: work-item table toggles occlusion buffers for retained views" {
  let table : @hashmap.HashMap[String, PreprocessWorkItemBuffers] = @hashmap.HashMap([],
  )
  let initial = get_or_create_work_item_buffer(table, "main-view", false, false)
  debug_inspect(initial.late_indirect_offsets() is None, content="true")
  let enabled = get_or_create_work_item_buffer(table, "main-view", false, true)
  debug_inspect(enabled.late_indirect_offsets().unwrap(), content="(0, 0)")
  let disabled = get_or_create_work_item_buffer(
    table, "main-view", false, false,
  )
  debug_inspect(disabled.late_indirect_offsets() is None, content="true")
}

///|
test "gpu preprocessing: indirect parameter settings default to no readback copies" {
  let settings = IndirectParametersBuffersSettings::IndirectParametersBuffersSettings()
  debug_inspect(
    settings.allow_copies_from_indirect_parameter_buffers(),
    content="false",
  )
}

///|
test "gpu preprocessing: plugin writes indirect parameter settings into render app" {
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
  let app = @app.App::new(@ecs.World::new())
    .insert_sub_app(@app.RenderApp, render_sub_app)
    .add_plugins(
      GpuPreprocessingPlugin::GpuPreprocessingPlugin().with_allow_copies_from_indirect_parameter_buffers(
        true,
      ),
    )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let settings = render_world
    .get_resource(indirect_parameters_buffers_settings_resource_key)
    .unwrap()
  debug_inspect(
    settings.allow_copies_from_indirect_parameter_buffers(),
    content="true",
  )
}
