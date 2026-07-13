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
struct TestUniformComponent {
  value : Int
} derive(Eq, Debug)

///|
let test_uniform_component_key : @ecs.ComponentKey[TestUniformComponent] = @ecs.register_component(
  debug_name="mgstudio_render::TestUniformComponent",
)

///|
let test_uniform_component_keys : UniformComponentKeys[TestUniformComponent] = register_uniform_component_keys(
  "mgstudio_render::TestUniformComponent",
)

///|
impl @ecs.Component for TestUniformComponent with fn component() {
  test_uniform_component_key
}

///|
impl UniformComponent for TestUniformComponent with fn uniform_component_debug_name() {
  "mgstudio_render::TestUniformComponent"
}

///|
impl UniformComponent for TestUniformComponent with fn uniform_component_keys() {
  test_uniform_component_keys
}

///|
test "render uniform: prepares component uniforms and dynamic indices" {
  let world = @ecs.World::new()
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()
  let component_key : @ecs.ComponentKey[TestUniformComponent] = TestUniformComponent::component()
  let uniform_key : @ecs.ResourceKey[ComponentUniforms[TestUniformComponent]] = ComponentUniforms::resource()
  let index_key : @ecs.ComponentKey[DynamicUniformIndex[TestUniformComponent]] = DynamicUniformIndex::component()
  try! world.set_by_key(first, component_key, TestUniformComponent::{ value: 7 })
  try! world.set_by_key(second, component_key, TestUniformComponent::{
    value: 11,
  })

  prepare_uniform_components(world, component_key, index_key, uniform_key)

  let uniforms = world.get_resource(uniform_key).unwrap()
  debug_inspect(uniforms.len(), content="2")
  debug_inspect(uniforms.get(0), content="Some({ value: 7 })")
  debug_inspect(uniforms.get(1), content="Some({ value: 11 })")
  let first_index = (try! world.get_by_key(first, index_key)).unwrap()
  let second_index = (try! world.get_by_key(second, index_key)).unwrap()
  debug_inspect(first_index.index(), content="0")
  debug_inspect(second_index.index(), content="1")
}
