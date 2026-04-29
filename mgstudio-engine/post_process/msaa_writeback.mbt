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
// Bevy source: `bevy/crates/bevy_camera/src/clear_color.rs` and
// `bevy/crates/bevy_post_process/src/msaa_writeback.rs`.
// Controls when MSAA writeback occurs for a camera.

///|
pub(all) enum MsaaWriteback {
  Off
  Auto
  Always
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MsaaWriteback::default() -> MsaaWriteback {
  Auto
}

///|
pub fn MsaaWriteback::off() -> MsaaWriteback {
  Off
}

///|
pub fn MsaaWriteback::auto() -> MsaaWriteback {
  Auto
}

///|
pub fn MsaaWriteback::always() -> MsaaWriteback {
  Always
}

///|
pub fn msaa_writeback_required(
  writeback : MsaaWriteback?,
  sample_count : Int,
  sorted_camera_index_for_target? : Int = 0,
) -> Bool {
  if sample_count <= 1 {
    return false
  }
  match writeback {
    Some(Off) => false
    Some(Auto) => sorted_camera_index_for_target > 0
    Some(Always) => true
    None => false
  }
}

///|
pub let ecs_key_msaa_writeback : @ecs.ComponentKey[MsaaWriteback] = @ecs.register_component(
  debug_name="render3d.msaa_writeback",
)

///|
pub impl @ecs.Component for MsaaWriteback with component() {
  ecs_key_msaa_writeback
}
