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
// Bevy source: `bevy/crates/bevy_input/src/gestures.rs`.

///|
pub fn rotation_gesture_message_key() -> @ecs.MessageKey[RotationGesture] {
  @input_events.ecs_key_rotation_gesture
}

///|
pub fn double_tap_gesture_message_key() -> @ecs.MessageKey[DoubleTapGesture] {
  @input_events.ecs_key_double_tap_gesture
}

///|
pub fn pan_gesture_message_key() -> @ecs.MessageKey[PanGesture] {
  @input_events.ecs_key_pan_gesture
}

///|
pub fn gesture_message_keys() -> (
  @ecs.MessageKey[RotationGesture],
  @ecs.MessageKey[DoubleTapGesture],
  @ecs.MessageKey[PanGesture],
) {
  (
    @input_events.ecs_key_rotation_gesture, @input_events.ecs_key_double_tap_gesture,
    @input_events.ecs_key_pan_gesture,
  )
}
