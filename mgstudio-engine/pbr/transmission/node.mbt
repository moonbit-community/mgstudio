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
/// Marker component aligned with Bevy's `TransmittedShadowReceiver`.
pub struct TransmittedShadowReceiver {} derive(ToJson, FromJson)

///|
pub fn TransmittedShadowReceiver::default() -> TransmittedShadowReceiver {
  TransmittedShadowReceiver::{  }
}

///|
pub let ecs_key_transmitted_shadow_receiver : @ecs.ComponentKey[
  TransmittedShadowReceiver,
] = @ecs.register_component(debug_name="render3d.transmitted_shadow_receiver")

///|
pub impl @ecs.Component for TransmittedShadowReceiver with component() {
  ecs_key_transmitted_shadow_receiver
}
