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
const BODY_COUNT : Int = 36

///|
const BOUNDS_X : Float = 560.0F

///|
const BOUNDS_Y : Float = 320.0F

///|
struct ToyBody {
  velocity : @math.Vec2
}

///|
let toy_body_key : @ecs.ComponentKey[ToyBody] = @ecs.register_component(
  debug_name="examples.games.desk_toy.ToyBody",
)

///|
pub impl @ecs.Component for ToyBody with component() {
  toy_body_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  for i in 0..<BODY_COUNT {
    let angle = float_from_int(i) * 0.61F
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::sized(@math.Vec2::new(34.0F, 34.0F)).with_color(
            @sprite.Color::hsl(float_from_int(i * 23 % 360), 0.8F, 0.58F),
          ),
          @transform.Transform::from_xyz(
            @math.sin(float_from_int(i) * 1.41F) * 420.0F,
            @math.cos(float_from_int(i) * 1.17F) * 220.0F,
            0.0F,
          ),
          ToyBody::{
            velocity: @math.Vec2::new(
              @math.cos(angle) * 220.0F,
              @math.sin(angle) * 220.0F,
            ),
          },
        ),
      ),
    )
  }
}

///|
fn simulate_bodies(
  time : @app.Res[@time.Time[Unit]],
  bodies : @ecs.Query[
    (@ecs.Mut[ToyBody], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let dt = time.get().delta_secs()
  try! bodies.for_each(fn(_entity, data) {
    let (body, transform) = data
    let body_ref = body.get_ref()
    let transform_ref = transform.get_ref()
    let mut vx = body_ref.val.velocity.x
    let mut vy = body_ref.val.velocity.y
    transform_ref.val.translation.x += vx * dt
    transform_ref.val.translation.y += vy * dt
    if transform_ref.val.translation.x > BOUNDS_X ||
      transform_ref.val.translation.x < -BOUNDS_X {
      vx = -vx
    }
    if transform_ref.val.translation.y > BOUNDS_Y ||
      transform_ref.val.translation.y < -BOUNDS_Y {
      vy = -vy
    }
    body_ref.val = ToyBody::{ velocity: @math.Vec2::new(vx, vy) }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(simulate_bodies)))
  .run()
}
