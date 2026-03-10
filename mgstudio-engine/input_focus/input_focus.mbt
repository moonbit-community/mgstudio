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
/// Input-focus API boundary aligned with Bevy-style input focus responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/input`.

///|
pub type FocusedInput[M] = @input.FocusedInput[M]

///|
pub type InputFocus = @input.InputFocus

///|
pub type InputFocusVisible = @input.InputFocusVisible

///|
pub type InputFocusSystems = @input.InputFocusSystems

///|
pub type IsFocusedHelper = @input.IsFocusedHelper

///|
pub fn is_focus_visible(world : @ecs.World, entity : @core.Entity) -> Bool {
  @input.IsFocused::is_focus_visible(world, entity)
}

///|
pub fn is_focus_within(world : @ecs.World, entity : @core.Entity) -> Bool {
  @input.IsFocused::is_focus_within(world, entity)
}

///|
pub fn is_focus_within_visible(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  @input.IsFocused::is_focus_within_visible(world, entity)
}

///|
pub fn is_focused(world : @ecs.World, entity : @core.Entity) -> Bool {
  @input.IsFocused::is_focused(world, entity)
}
