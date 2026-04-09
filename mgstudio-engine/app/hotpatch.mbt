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
// Bevy source-shape anchor (`bevy_app/src/hotpatch.rs`).

///|
pub fn hotpatch_reset_runtime() -> Unit {
  app_runtime_reset()
}

///|
pub fn hotpatch_stop_rendering() -> Unit {
  app_rendering_stop()
}

///|
pub fn hotpatch_resume_rendering() -> Unit {
  app_rendering_resume()
}
