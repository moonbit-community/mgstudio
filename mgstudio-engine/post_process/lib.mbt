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
// Bevy source: `bevy/crates/bevy_post_process/src/lib.rs`.
// Root runtime boundary for the stable `Milky2018/mgstudio/post_process` API.

///|
pub const POST_PROCESS_RUNTIME_ROOT : String = "Milky2018/mgstudio/post_process"

///|
pub fn post_process_effect_count(
  bloom : Bloom?,
  vignette : Vignette?,
  motion_blur : MotionBlur?,
  chromatic_aberration : ChromaticAberration?,
  msaa_writeback : MsaaWriteback?,
) -> Int {
  let mut count = 0
  if bloom is Some(_) {
    count = count + 1
  }
  if vignette is Some(_) {
    count = count + 1
  }
  if motion_blur is Some(_) {
    count = count + 1
  }
  if chromatic_aberration is Some(_) {
    count = count + 1
  }
  match msaa_writeback {
    Some(Off) => ()
    Some(Auto) | Some(Always) => count = count + 1
    None => ()
  }
  count
}
