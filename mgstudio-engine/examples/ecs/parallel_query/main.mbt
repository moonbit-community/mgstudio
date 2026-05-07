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
struct Velocity {
  mut vector : @math.Vec2
}

///|
let velocity_key : @ecs.ComponentKey[Velocity] = @ecs.register_component(
  debug_name="examples.ecs.parallel_query.Velocity",
)

///|
impl @ecs.Component for Velocity with component() {
  velocity_key
}

///|
fn deterministic_random_unit(seed_ref : Ref[Int]) -> Float {
  seed_ref.val = seed_ref.val * 48271 % 2147483647
  Float::from_int(seed_ref.val) / 2147483647.0F
}

///|
fn spawn_system(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.spawn(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore

  let texture = asset_server.get().load_image("branding/icon.png")
  let rng_seed : Ref[Int] = Ref(1258831081)
  for z in 0..<128 {
    let velocity = @math.Vec2::new(
      deterministic_random_unit(rng_seed) - 0.5F,
      deterministic_random_unit(rng_seed) - 0.5F,
    ).mul_scalar(20.0F)
    commands.spawn(
      (
        @sprite.Sprite::from_image(texture),
        @transform.Transform::identity()
        .with_scale(@math.Vec3::splat(0.1F))
        .with_translation(@math.Vec3::new(0.0F, 0.0F, Float::from_int(z))),
        Velocity::{ vector: velocity },
      ),
    )
    |> ignore
  }
}

///|
fn move_system(
  sprites : @ecs.Query[
    (@ecs.Comp[Velocity], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  try! sprites
  .par_iter()
  .for_each(fn(_entity, data) {
    let (velocity, transform) = data
    transform.modify(fn(value) {
      value.translation = value.translation.add(
        @math.Vec3::new(
          velocity.value().vector.x,
          velocity.value().vector.y,
          0.0F,
        ),
      )
    })
  })
}

///|
fn bounce_system(
  window_query : @ecs.Query[
    @ecs.Comp[@window.Window],
    @ecs.With[@window.PrimaryWindow],
  ],
  sprites : @ecs.Query[
    (@ecs.Comp[@transform.Transform], @ecs.Mut[Velocity]),
    @ecs.All,
  ],
) -> Unit {
  guard (window_query.single() catch { _ => None }) is Some(window_comp) else {
    return
  }
  let window = window_comp.value()
  let width = window.width()
  let height = window.height()
  let left = width / -2.0F
  let right = width / 2.0F
  let bottom = height / -2.0F
  let top = height / 2.0F
  try! sprites
  .par_iter()
  .batching_strategy(@ecs.BatchingStrategy::fixed(32))
  .for_each(fn(_entity, data) {
    let (transform, velocity) = data
    let translation = transform.value().translation
    if !(left < translation.x &&
      translation.x < right &&
      bottom < translation.y &&
      translation.y < top) {
      velocity.modify(fn(value) {
        value.vector = value.vector.mul_scalar(-1.0F)
      })
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(spawn_system)))
  .add_systems(@app.Update, @app.system(@app.system_param(move_system)))
  .add_systems(@app.Update, @app.system(@app.system_param2(bounce_system)))
  .run()
}
