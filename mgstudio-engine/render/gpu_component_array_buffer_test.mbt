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
struct TestGpuComponentArrayBufferComponent {
  value : Int
} derive(Eq, Debug)

///|
let ecs_key_test_gpu_component_array_buffer_component : @ecs.ComponentKey[
  TestGpuComponentArrayBufferComponent,
] = @ecs.register_component(
  debug_name="mgstudio_render::TestGpuComponentArrayBufferComponent",
)

///|
pub impl @ecs.Component for TestGpuComponentArrayBufferComponent with component() {
  ecs_key_test_gpu_component_array_buffer_component
}

///|
test "render gpu component array buffer: prepare populates buffer and entity index mapping" {
  let world = @ecs.World::new()
  let entity0 = world.spawn()
  let entity1 = world.spawn()
  try! world.set_by_key(
    entity0,
    TestGpuComponentArrayBufferComponent::component(),
    TestGpuComponentArrayBufferComponent::{ value: 11 },
  )
  try! world.set_by_key(
    entity1,
    TestGpuComponentArrayBufferComponent::component(),
    TestGpuComponentArrayBufferComponent::{ value: 22 },
  )
  let state_key : @ecs.ResourceKey[
    GpuComponentArrayBufferState[TestGpuComponentArrayBufferComponent],
  ] = gpu_component_array_buffer_state_key(
    debug_name="mgstudio_render::TestGpuArrayBufferState",
  )
  prepare_gpu_component_array_buffers(
    world,
    state_key,
    component_key=TestGpuComponentArrayBufferComponent::component(),
  )
  let state = (try! world.get_resource(state_key)).unwrap()
  debug_inspect(state.buffer().len(), content="2")
  debug_inspect(state.index(entity0) is Some(_), content="true")
  debug_inspect(state.index(entity1) is Some(_), content="true")
}

///|
test "render gpu component array buffer: prepare clears stale component indices" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    TestGpuComponentArrayBufferComponent::component(),
    TestGpuComponentArrayBufferComponent::{ value: 7 },
  )
  let state_key : @ecs.ResourceKey[
    GpuComponentArrayBufferState[TestGpuComponentArrayBufferComponent],
  ] = gpu_component_array_buffer_state_key(
    debug_name="mgstudio_render::TestGpuArrayBufferStateCleanup",
  )
  prepare_gpu_component_array_buffers(
    world,
    state_key,
    component_key=TestGpuComponentArrayBufferComponent::component(),
  )
  ignore(
    try! world.remove_by_key(
      entity,
      TestGpuComponentArrayBufferComponent::component(),
    ),
  )
  prepare_gpu_component_array_buffers(
    world,
    state_key,
    component_key=TestGpuComponentArrayBufferComponent::component(),
  )
  let state = (try! world.get_resource(state_key)).unwrap()
  debug_inspect(state.buffer().len(), content="0")
  debug_inspect(state.index(entity) is None, content="true")
}
