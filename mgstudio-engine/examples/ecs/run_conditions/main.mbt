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
/// Port of `bevy/examples/ecs/run_conditions.rs`.

///|
struct InputCounter {
  mut value : Int
}

///|
struct Unused {}

///|
let input_counter_resource_key : @ecs.ResourceKey[InputCounter] = @ecs.register_resource(
  debug_name="examples.ecs.run_conditions.InputCounter",
)

///|
let unused_resource_key : @ecs.ResourceKey[Unused] = @ecs.register_resource(
  debug_name="examples.ecs.run_conditions.Unused",
)

///|
pub impl @app.Resource for InputCounter with resource() {
  input_counter_resource_key
}

///|
pub impl @app.Resource for Unused with resource() {
  unused_resource_key
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in run_conditions example")
  }
}

///|
fn main {
  @app.log_info(
    "For the first 2 seconds you will not be able to increment the counter",
  )
  @app.log_info(
    "Once that time has passed you can press space, enter, left mouse, right mouse or touch to increment the counter",
  )
  ignore(Unused::{  })

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .insert_resource(InputCounter::{ value: 0 })
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(increment_input_counter))
    .run_if(@app.resource_exists(InputCounter::resource()))
    .run_if(
      @app.run_condition_or(
        @app.resource_exists(Unused::resource()),
        has_user_input,
      ),
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(print_input_counter))
    .run_if(@app.resource_exists(InputCounter::resource()))
    .run_if_stateful(Json::null(), input_counter_changed),
  )
  .add_systems(
    @app.Update,
    @app.system(print_time_message)
    .run_if_stateful(0.0F.to_json(), time_passed(2.0F))
    .run_if(
      @app.run_condition_not(fn(world : @ecs.World) {
        world_time(world).elapsed_seconds() >= 2.5F
      }),
    ),
  )
  .run()
}

///|
fn has_user_input(world : @ecs.World) -> Bool {
  @input.key_just_pressed(@window.KeyCode::Space) ||
  @input.key_just_pressed(@window.KeyCode::Enter) ||
  @input.mouse_button_just_pressed(@window.MouseButton::Left) ||
  @input.mouse_button_just_pressed(@window.MouseButton::Right) ||
  touches_any_just_pressed(world)
}

///|
fn touches_any_just_pressed(world : @ecs.World) -> Bool {
  match
    (try world.get_resource(@input.Touches::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(touches) => touches.any_just_pressed()
    None => false
  }
}

///|
fn input_counter_changed(world : @ecs.World, state : Ref[Json]) -> Bool {
  let previous : Int? = match state.val {
    Json::Null => None
    _ => Some(try! @json.from_json(state.val))
  }
  match (try! world.get_resource(InputCounter::resource())) {
    Some(counter) => {
      let changed = match previous {
        Some(last) => last != counter.value
        None => false
      }
      state.val = counter.value.to_json()
      changed
    }
    None => false
  }
}

///|
fn time_passed(threshold : Float) -> @app.StatefulRunConditionFn[@ecs.World] {
  fn(world : @ecs.World, state : Ref[Json]) {
    let elapsed_seconds : Float = try! @json.from_json(state.val)
    let updated_elapsed_seconds = elapsed_seconds +
      world_time(world).delta_seconds()
    state.val = updated_elapsed_seconds.to_json()
    updated_elapsed_seconds >= threshold
  }
}

///|
fn increment_input_counter(counter : @app.ResMut[InputCounter]) -> Unit {
  let counter_ref = counter.get_ref()
  counter_ref.val.value = counter_ref.val.value + 1
}

///|
fn print_input_counter(counter : @app.Res[InputCounter]) -> Unit {
  @app.log_info("Input counter: \{counter.get().value}")
}

///|
fn print_time_message(_world : @ecs.World) -> Unit {
  @app.log_info(
    "It has been more than 2 seconds since the program started and less than 2.5 seconds",
  )
}
