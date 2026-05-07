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
test "picking wb: collect input honors PointerInputSettings mouse toggle" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  world.init_message(pointer_input_message_key())
  get_pointer_input_settings_resource(world).insert(
    PointerInputSettings::new(false, false),
  )
  picking_collect_mouse_system(world)
  let cursor = Ref(0)
  let disabled_inputs = try! world
    .message_reader(pointer_input_message_key(), cursor)
    .read()
  inspect(disabled_inputs.length(), content="0")

  get_pointer_input_settings_resource(world).insert(
    PointerInputSettings::new(false, true),
  )
  picking_collect_mouse_system(world)
  let with_mouse = try! world
    .message_reader(pointer_input_message_key(), cursor)
    .read()
  inspect(with_mouse.length(), content="1")
  inspect(with_mouse[0].pointer, content="0")
}

///|
test "picking wb: PointerInput messages update pointer entity components" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  world.init_message(pointer_input_message_key())
  world.send_message(
    pointer_input_message_key(),
    PointerInput::new(0, Some(@math.Vec2::new(12.0F, 34.0F)), true, true, false),
  )
  |> ignore
  picking_process_pointer_inputs_system(world)
  let map = get_pointer_map_resource(world)
    .get()
    .unwrap_or(PointerMap::default())
  let entity = map.get_entity(0).unwrap()
  let id = (try! world.get_by_key(entity, ecs_key_pointer_id)).unwrap()
  inspect(id.value(), content="0")
  let location = (try! world.get_by_key(entity, ecs_key_pointer_location)).unwrap()
  inspect(location.location().unwrap().x.to_double(), content="12")
  let press = (try! world.get_by_key(entity, ecs_key_pointer_press)).unwrap()
  inspect(press.is_primary_pressed(), content="true")

  world.send_message(
    pointer_input_message_key(),
    PointerInput::new(
      0,
      Some(@math.Vec2::new(12.0F, 35.0F)),
      false,
      false,
      true,
    ),
  )
  |> ignore
  picking_process_pointer_inputs_system(world)
  let entity_after = get_pointer_map_resource(world)
    .get()
    .unwrap_or(PointerMap::default())
    .get_entity(0)
    .unwrap()
  inspect(entity_after.id == entity.id, content="true")
  let press_after = (try! world.get_by_key(entity_after, ecs_key_pointer_press)).unwrap()
  inspect(press_after.is_primary_pressed(), content="false")
}
