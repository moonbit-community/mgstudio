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
struct Health {
  mut value : Float
}

///|
struct HealthDecay {
  factor : Float
}

///|
let health_key : @ecs.ComponentKey[Health] = @ecs.register_component(
  debug_name="examples.ecs.contiguous_query.Health",
)

///|
let health_decay_key : @ecs.ComponentKey[HealthDecay] = @ecs.register_component(
  debug_name="examples.ecs.contiguous_query.HealthDecay",
)

///|
impl @ecs.Component for Health with component() {
  health_key
}

///|
impl @ecs.Component for HealthDecay with component() {
  health_decay_key
}

///|
fn apply_health_decay(
  query : @ecs.Query[(@ecs.Comp[HealthDecay], @ecs.Mut[Health]), @ecs.All],
) -> Unit {
  guard query.contiguous_iter() is Some(iter) else { return }
  while (iter.fetch_next() catch { _ => None }) is Some((decay, health)) {
    let health_ref = health.get_ref()
    health_ref.val.value = health_ref.val.value * decay.value().factor
  }
}

///|
fn finish_off_first(
  commands : @app.Commands,
  query : @ecs.Query[@ecs.Mut[Health], @ecs.All],
) -> Unit {
  let finished = Ref::new(false)
  try! query.view(fn(entity, health) {
    if finished.val {
      return
    }
    finished.val = true
    let health_ref = health.get_ref()
    health_ref.val.value = health_ref.val.value - 1.0F
    if health_ref.val.value <= 0.0F {
      commands.entity(entity).despawn()
      @app.log_info("Finishing off one entity")
    }
  })
}

///|
fn setup(commands : @app.Commands) -> Unit {
  let batch : Array[(Health, HealthDecay)] = []
  for i in 1..<10000 {
    batch.push(
      (
        Health::{ value: Float::from_int(i) * 5.0F },
        HealthDecay::{ factor: 0.9F },
      ),
    )
  }
  commands.spawn_batch(batch) |> ignore
}

///|
fn main {
  let apply_health_decay_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(apply_health_decay),
  )
  let finish_off_first_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(finish_off_first),
  )
  let update_chain : @app.SystemConfig[@ecs.World] = (
      apply_health_decay_system, finish_off_first_system,
    )
    |> @app.chain()
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, update_chain)
  .run()
}
