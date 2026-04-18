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
test "picking wb: PointerInputs::set replaces existing pointer entry" {
  let inputs = Ref::new(PointerInputs::default())
  PointerInputs::set(
    inputs,
    PointerInput::new(0, Some(@math.Vec2::new(1.0F, 2.0F)), true, true, false),
  )
  PointerInputs::set(
    inputs,
    PointerInput::new(0, Some(@math.Vec2::new(3.0F, 4.0F)), false, false, true),
  )
  inspect(inputs.val.pointers.length(), content="1")
  inspect(inputs.val.pointers[0].pointer, content="0")
  inspect(
    inputs.val.pointers[0].window_position.unwrap().x.to_double(),
    content="3",
  )
  inspect(inputs.val.pointers[0].just_released, content="true")
}

///|
test "picking wb: collect input honors PointerInputSettings mouse toggle" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_pointer_input_settings_resource(world).insert(
    PointerInputSettings::new(false, false),
  )
  picking_collect_mouse_system(world)
  let inputs = get_pointer_inputs_resource(world)
    .get()
    .unwrap_or(PointerInputs::default())
  inspect(inputs.pointers.length(), content="0")

  get_pointer_input_settings_resource(world).insert(
    PointerInputSettings::new(false, true),
  )
  picking_collect_mouse_system(world)
  let with_mouse = get_pointer_inputs_resource(world)
    .get()
    .unwrap_or(PointerInputs::default())
  inspect(with_mouse.pointers.length(), content="1")
  inspect(with_mouse.pointers[0].pointer, content="0")
}
