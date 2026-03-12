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
/// Port of `bevy/examples/ecs/fixed_timestep.rs`.

///|
fn frame_update(
  last_time : @app.Local[Float],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let last_time_ref = last_time.get_ref()
  let time_value = time.get()
  @app.log_info(
    "time since last frame_update: " +
    (time_value.elapsed_secs() - last_time_ref.val).to_string(),
  )
  last_time_ref.val = time_value.elapsed_secs()
}

///|
fn fixed_update(
  last_time : @app.Local[Float],
  time : @app.Res[@time.Time[Unit]],
  fixed_time : @app.Res[@time.Time[@time.Fixed]],
) -> Unit {
  let last_time_ref = last_time.get_ref()
  let time_value = time.get()
  let fixed_time_value = fixed_time.get()
  @app.log_info(
    "time since last fixed_update: " +
    (time_value.elapsed_secs() - last_time_ref.val).to_string() +
    "\n",
  )
  @app.log_info("fixed timestep: " + time_value.delta_secs().to_string() + "\n")
  @app.log_info(
    "time accrued toward next fixed_update: " +
    fixed_time_value.overstep().as_secs_f32().to_string() +
    "\n",
  )
  last_time_ref.val = time_value.elapsed_secs()
}

///|
fn main {
  let fixed_time : @time.Time[@time.Fixed] = @time.Time::from_seconds(0.5F)
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Update, @app.system(@app.system_param2(frame_update)))
  .add_systems(@app.FixedUpdate, @app.system(@app.system_param3(fixed_update)))
  .insert_resource(fixed_time)
  .run()
}
