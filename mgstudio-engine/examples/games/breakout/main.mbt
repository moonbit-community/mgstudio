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
const WALL_X : Float = 620.0F

///|
const WALL_Y : Float = 350.0F

///|
struct Paddle {}

///|
struct Brick {}

///|
struct Ball {
  mut velocity : @math.Vec2
}

///|
let paddle_key : @ecs.ComponentKey[Paddle] = @ecs.register_component(
  debug_name="examples.games.breakout.Paddle",
)

///|
let brick_key : @ecs.ComponentKey[Brick] = @ecs.register_component(
  debug_name="examples.games.breakout.Brick",
)

///|
let ball_key : @ecs.ComponentKey[Ball] = @ecs.register_component(
  debug_name="examples.games.breakout.Ball",
)

///|
pub impl @ecs.Component for Paddle with component() {
  paddle_key
}

///|
pub impl @ecs.Component for Brick with component() {
  brick_key
}

///|
pub impl @ecs.Component for Ball with component() {
  ball_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn clampf(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(170.0F, 24.0F)).with_color(
          @sprite.Color::srgb(0.3F, 0.9F, 0.42F),
        ),
        @transform.Transform::from_xyz(0.0F, -280.0F, 0.1F),
        Paddle::{  },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(22.0F, 22.0F)).with_color(
          @sprite.Color::srgb(0.95F, 0.95F, 0.95F),
        ),
        @transform.Transform::from_xyz(0.0F, -210.0F, 0.2F),
        Ball::{ velocity: @math.Vec2::new(260.0F, 280.0F) },
      ),
    ),
  )
  for row in 0..<7 {
    for col in 0..<12 {
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::sized(@math.Vec2::new(84.0F, 26.0F)).with_color(
              @sprite.Color::hsl(
                float_from_int((row * 40 + col * 9) % 360),
                0.82F,
                0.58F,
              ),
            ),
            @transform.Transform::from_xyz(
              -500.0F + float_from_int(col) * 90.0F,
              160.0F + float_from_int(row) * 34.0F,
              0.0F,
            ),
            Brick::{  },
          ),
        ),
      )
    }
  }
}

///|
fn move_paddle(
  time : @app.Res[@time.Time[Unit]],
  keyboard : @input.ButtonInput[@window.KeyCode],
  paddles : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Paddle]],
) -> Unit {
  let mut dir = 0.0F
  if keyboard.pressed(@window.KeyCode::ArrowLeft) ||
    keyboard.pressed(@window.KeyCode::KeyA) {
    dir -= 1.0F
  }
  if keyboard.pressed(@window.KeyCode::ArrowRight) ||
    keyboard.pressed(@window.KeyCode::KeyD) {
    dir += 1.0F
  }
  let dt = time.get().delta_secs()
  try! paddles.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x = clampf(
      transform_ref.val.translation.x + dir * 560.0F * dt,
      -WALL_X + 90.0F,
      WALL_X - 90.0F,
    )
  })
}

///|
fn move_ball(
  commands : @app.Commands,
  time : @app.Res[@time.Time[Unit]],
  balls : @ecs.Query[(@ecs.Mut[Ball], @ecs.Mut[@transform.Transform]), @ecs.All],
  paddles : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.With[Paddle]],
  bricks : @ecs.Query[@ecs.Comp[@transform.Transform], @ecs.With[Brick]],
) -> Unit {
  let paddle = paddles.require_single() catch { _ => return }
  let dt = time.get().delta_secs()
  let mut brick_to_remove = None
  try! balls.for_each(fn(_ball_entity, data) {
    let (ball, transform) = data
    let ball_ref = ball.get_ref()
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x += ball_ref.val.velocity.x * dt
    transform_ref.val.translation.y += ball_ref.val.velocity.y * dt
    if transform_ref.val.translation.x > WALL_X ||
      transform_ref.val.translation.x < -WALL_X {
      ball_ref.val.velocity.x = -ball_ref.val.velocity.x
    }
    if transform_ref.val.translation.y > WALL_Y {
      ball_ref.val.velocity.y = -@math.abs(ball_ref.val.velocity.y)
    }
    if transform_ref.val.translation.y < -WALL_Y {
      transform_ref.val.translation = @math.Vec3::new(0.0F, -210.0F, 0.2F)
      ball_ref.val.velocity = @math.Vec2::new(260.0F, 280.0F)
    }
    let paddle_dx = transform_ref.val.translation.x -
      paddle.value().translation.x
    let paddle_dy = transform_ref.val.translation.y -
      paddle.value().translation.y
    if @math.abs(paddle_dx) < 98.0F &&
      @math.abs(paddle_dy) < 24.0F &&
      ball_ref.val.velocity.y < 0.0F {
      ball_ref.val.velocity.y = @math.abs(ball_ref.val.velocity.y)
      ball_ref.val.velocity.x += paddle_dx * 1.4F
    }
    try! bricks.for_each(fn(entity, brick_transform) {
      if brick_to_remove is Some(_) {
        return
      }
      let brick_dx = transform_ref.val.translation.x -
        brick_transform.value().translation.x
      let brick_dy = transform_ref.val.translation.y -
        brick_transform.value().translation.y
      if @math.abs(brick_dx) < 54.0F && @math.abs(brick_dy) < 24.0F {
        brick_to_remove = Some(entity)
        ball_ref.val.velocity.y = -ball_ref.val.velocity.y
      }
    })
  })
  if brick_to_remove is Some(entity) {
    commands.entity(entity).despawn()
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(move_paddle)))
  .add_systems(@app.Update, @app.system(@app.system_param5(move_ball)))
  .run()
}
