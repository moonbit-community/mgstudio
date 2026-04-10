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
pub const MGSTUDIO_MAIN_ENTRY_PATH : String = "examples/camera/2d_screen_shake/main.mbt"

///|
pub fn migrated_systems() -> Array[String] {
  [
    "register_camera_shake_requirements",
    "setup_scene",
    "setup_instructions",
    "setup_camera",
    "reset_transform",
    "increase_trauma",
    "shake_camera",
  ]
}

