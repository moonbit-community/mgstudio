// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_input_focus/src/autofocus.rs`.

///|
pub struct AutoFocus {} derive(Default, Debug)

///|
let auto_focus_component_key : @ecs.ComponentKey[AutoFocus] = @ecs.register_component(
  debug_name="mgstudio_input_focus::AutoFocus",
)

///|
pub impl @ecs.Component for AutoFocus with component() {
  auto_focus_component_key
}

///|
pub fn on_auto_focus_added(world : @ecs.World, entity : @core.Entity) -> Unit {
  let focus = try world.get_resource_mut(InputFocus::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
  match focus {
    Some(input_focus) => input_focus.modify(fn(value) { value.set(entity) })
    None => ()
  }
}
