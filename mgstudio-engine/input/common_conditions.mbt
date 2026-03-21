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
//
// Adapted from Bevy's `bevy_input` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub fn[T : ButtonInputButton + ButtonInputSnapshotProvider] input_pressed(
  input : T,
) -> @app.RunConditionFn[@ecs.World] {
  fn(_world : @ecs.World) -> Bool { T::read_button_input().pressed(input) }
}

///|
pub fn[T : ButtonInputButton + ButtonInputSnapshotProvider] input_just_pressed(
  input : T,
) -> @app.RunConditionFn[@ecs.World] {
  fn(_world : @ecs.World) -> Bool { T::read_button_input().just_pressed(input) }
}

///|
pub fn[T : ButtonInputButton + ButtonInputSnapshotProvider] input_just_released(
  input : T,
) -> @app.RunConditionFn[@ecs.World] {
  fn(_world : @ecs.World) -> Bool {
    T::read_button_input().just_released(input)
  }
}

///|
pub fn[T : ButtonInputButton + ButtonInputSnapshotProvider] input_toggle_active(
  initial_active : Bool,
  input : T,
) -> @app.RunConditionFn[@ecs.World] {
  let active_ref = Ref::new(initial_active)
  fn(_world : @ecs.World) -> Bool {
    let button_input = T::read_button_input()
    if button_input.just_pressed(input) {
      active_ref.val = !active_ref.val
    }
    active_ref.val
  }
}
