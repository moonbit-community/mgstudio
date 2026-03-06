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
fn reset_time_test_state() -> Unit {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(0.015625F)
  @app.fixed_time_set_max_delta_seconds(0.25F)
  @app.clear_delta_seconds_provider()
}

///|
test "time: manual instant keeps first update delta at zero" {
  reset_time_test_state()
  let mut app = @app.App::new(@ecs.World::new()).add_plugins([time_plugin])
  time_virtual_set_max_delta_seconds(10.0F)

  app = app.insert_resource(TimeUpdateStrategy::ManualInstant(10.0F)).run_once()
  inspect(
    Real::resource().get().unwrap().first_update_seconds(),
    content="Some(10)",
  )
  inspect(Real::resource().get().unwrap().delta_seconds(), content="0")
  inspect(Real::resource().get().unwrap().elapsed_seconds(), content="0")
  inspect(Virtual::resource().get().unwrap().delta_seconds(), content="0")
  inspect(Time::resource().get().unwrap().elapsed_seconds(), content="0")

  app = app.insert_resource(TimeUpdateStrategy::ManualInstant(12.5F)).run_once()
  inspect(
    Real::resource().get().unwrap().last_update_seconds(),
    content="Some(12.5)",
  )
  inspect(Real::resource().get().unwrap().delta_seconds(), content="2.5")
  inspect(Real::resource().get().unwrap().elapsed_seconds(), content="2.5")
  inspect(Virtual::resource().get().unwrap().delta_seconds(), content="2.5")
  inspect(Time::resource().get().unwrap().elapsed_seconds(), content="2.5")
}

///|
test "time: virtual time clamps large deltas by default" {
  reset_time_test_state()
  let mut app = @app.App::new(@ecs.World::new()).add_plugins([time_plugin])

  app = app.insert_resource(TimeUpdateStrategy::ManualDuration(1.0F)).run_once()
  app = app.insert_resource(TimeUpdateStrategy::ManualDuration(1.0F)).run_once()
  inspect(Real::resource().get().unwrap().delta_seconds(), content="1")
  inspect(Virtual::resource().get().unwrap().delta_seconds(), content="0.25")
  inspect(Time::resource().get().unwrap().elapsed_seconds(), content="0.25")
}

///|
test "time: pause and relative speed follow bevy virtual semantics" {
  reset_time_test_state()
  let mut app = @app.App::new(@ecs.World::new()).add_plugins([time_plugin])
  time_virtual_set_max_delta_seconds(10.0F)

  app = app.insert_resource(TimeUpdateStrategy::ManualDuration(1.0F)).run_once()
  time_virtual_pause()
  app = app.insert_resource(TimeUpdateStrategy::ManualDuration(2.0F)).run_once()
  inspect(Real::resource().get().unwrap().delta_seconds(), content="2")
  inspect(Virtual::resource().get().unwrap().delta_seconds(), content="0")
  inspect(Virtual::resource().get().unwrap().effective_speed(), content="0")
  inspect(Virtual::resource().get().unwrap().was_paused(), content="true")

  time_virtual_unpause()
  time_virtual_set_relative_speed(0.5F)
  app = app.insert_resource(TimeUpdateStrategy::ManualDuration(2.0F)).run_once()
  inspect(Real::resource().get().unwrap().delta_seconds(), content="2")
  inspect(Virtual::resource().get().unwrap().delta_seconds(), content="1")
  inspect(Virtual::resource().get().unwrap().effective_speed(), content="0.5")
  inspect(Virtual::resource().get().unwrap().was_paused(), content="false")
}

///|
test "time: fixed timesteps strategy drives fixed update loop" {
  reset_time_test_state()
  @app.fixed_time_set_timestep_seconds(0.125F)
  @app.fixed_time_set_max_delta_seconds(1.0F)
  let counter : Ref[Int] = Ref::new(0)
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins([time_plugin])
    .add_fixed_update_system(fn(_world : @ecs.World) {
      counter.val = counter.val + 1
    })

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  inspect(counter.val, content="0")

  app = app.insert_resource(TimeUpdateStrategy::FixedTimesteps(2)).run_once()
  inspect(counter.val, content="2")
  inspect(@app.fixed_time_steps_ran_this_frame(), content="2")
  inspect(Fixed::resource().get().unwrap().delta_seconds(), content="0.125")
  inspect(Fixed::resource().get().unwrap().elapsed_seconds(), content="0.25")
  inspect(Time::resource().get().unwrap().elapsed_seconds(), content="0.25")
}
