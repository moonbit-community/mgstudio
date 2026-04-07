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
struct A {
  mut value : Int
}

///|
struct B {
  mut value : Int
}

///|
let a_key : @ecs.ResourceKey[A] = @ecs.register_resource(
  debug_name="examples.ecs.nondeterministic_system_order.A",
)

///|
let b_key : @ecs.ResourceKey[B] = @ecs.register_resource(
  debug_name="examples.ecs.nondeterministic_system_order.B",
)

///|
pub impl @app.Resource for A with resource() {
  a_key
}

///|
pub impl @app.Resource for B with resource() {
  b_key
}

///|
fn reads_a(a : @app.Res[A]) -> Unit {
  println("reads_a: \{a.get().value.to_string()}")
}

///|
fn writes_a(a : @app.ResMut[A]) -> Unit {
  a.get_ref().val.value = a.get_ref().val.value + 1
}

///|
fn adds_one_to_b(b : @app.ResMut[B]) -> Unit {
  b.get_ref().val.value = b.get_ref().val.value + 1
}

///|
fn doubles_b(b : @app.ResMut[B]) -> Unit {
  b.get_ref().val.value = b.get_ref().val.value * 2
}

///|
fn reads_b(b : @app.Res[B]) -> Unit {
  println("reads_b: \{b.get().value.to_string()}")
}

///|
fn reads_a_and_b(a : @app.Res[A], b : @app.Res[B]) -> Unit {
  println(
    "reads_a_and_b: \{a.get().value.to_string()}, \{b.get().value.to_string()}",
  )
}

///|
fn main {
  let reads_a_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(reads_a),
  )
  let writes_a_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(writes_a),
  )
  let adds_one_to_b_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(adds_one_to_b),
  )
  let doubles_b_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(doubles_b),
  )
  let reads_b_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(reads_b),
  )
  let reads_a_and_b_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(reads_a_and_b),
  )
  let b_ordered_chain : @app.SystemConfig[@ecs.World] = (
      adds_one_to_b_system, doubles_b_system, reads_b_system,
    )
    |> @app.chain()

  @app.App::new(@ecs.World::new())
  .add_plugins([
    @app.schedule_runner_plugin(@app.ScheduleRunnerPlugin::run_once()),
  ])
  .insert_resource(A::{ value: 0 })
  .insert_resource(B::{ value: 0 })
  .add_systems(@app.Update, reads_a_system)
  .add_systems(@app.Update, writes_a_system)
  .add_systems(@app.Update, b_ordered_chain)
  .add_systems(@app.Update, reads_a_and_b_system)
  .run()
}
