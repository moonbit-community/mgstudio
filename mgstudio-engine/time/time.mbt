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
pub struct Time {
  mut delta_seconds : Float
  mut elapsed_seconds : Float
  mut last_ticks : Float
}

///|
let time_state : Ref[Time] = @ref.new(Time::{
  delta_seconds: 0.0F,
  elapsed_seconds: 0.0F,
  last_ticks: 0.0F,
})

///|
pub fn host_time_now() -> Float = "mgstudio_host" "time_now"

///|
pub fn time_update() -> Unit {
  let now = host_time_now()
  if time_state.val.last_ticks == 0.0F {
    time_state.val.last_ticks = now
    time_state.val.delta_seconds = 0.0F
    time_state.val.elapsed_seconds = 0.0F
    return
  }
  let delta_ms = now - time_state.val.last_ticks
  let delta_secs = if delta_ms > 0.0F { delta_ms / 1000.0F } else { 0.0F }
  time_state.val.delta_seconds = delta_secs
  time_state.val.elapsed_seconds = time_state.val.elapsed_seconds + delta_secs
  time_state.val.last_ticks = now
}

///|
pub fn time_delta_seconds() -> Float {
  time_state.val.delta_seconds
}

///|
pub fn time_elapsed_seconds() -> Float {
  time_state.val.elapsed_seconds
}

///|
pub fn time_system() -> Unit {
  time_update()
}

///|
pub fn time_plugin(app : @app.App) -> @app.App {
  app.add_system(time_system)
}
