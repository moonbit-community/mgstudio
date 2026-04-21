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
const BIRDS_PER_CLICK : Int = 200

///|
const INITIAL_BIRDS : Int = 1200

///|
const BIRD_SPEED_MIN : Float = 80.0F

///|
const BIRD_SPEED_MAX : Float = 360.0F

///|
const HALF_WIDTH : Float = 960.0F

///|
const HALF_HEIGHT : Float = 540.0F

///|
struct Bird {
  velocity : @math.Vec3
}

///|
let bird_key : @ecs.ComponentKey[Bird] = @ecs.register_component(
  debug_name="examples.stress_tests.bevymark.Bird",
)

///|
pub impl @ecs.Component for Bird with component() {
  bird_key
}

///|
struct BirdCounter {
  mut count : Int
  mut print_timer : Float
}

///|
let bird_counter_key : @ecs.ResourceKey[BirdCounter] = @ecs.register_resource(
  debug_name="examples.stress_tests.bevymark.BirdCounter",
)

///|
impl @app.Resource for BirdCounter with resource() {
  bird_counter_key
}

///|
fn BirdCounter::default() -> BirdCounter {
  { count: 0, print_timer: 0.0F }
}

///|
struct BirdAssets {
  bird : @asset.Handle[@asset.Image]
}

///|
let bird_assets_key : @ecs.ResourceKey[BirdAssets] = @ecs.register_resource(
  debug_name="examples.stress_tests.bevymark.BirdAssets",
)

///|
impl @app.Resource for BirdAssets with resource() {
  bird_assets_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn spawn_birds(
  commands : @app.Commands,
  bird_texture : @asset.Handle[@asset.Image],
  count : Int,
  base_index : Int,
) -> Int {
  let mut next_index = base_index
  for _ in 0..<count {
    let idx = next_index
    let idxf = float_from_int(idx)
    let angle = idxf * 0.17F
    let speed_t = float_from_int(idx % 11) / 10.0F
    let speed = BIRD_SPEED_MIN + (BIRD_SPEED_MAX - BIRD_SPEED_MIN) * speed_t
    let vx = @math.cos(angle) * speed
    let vy = @math.sin(angle) * speed
    let px = @math.sin(idxf * 0.11F) * 0.8F * (HALF_WIDTH - 80.0F)
    let py = @math.cos(idxf * 0.07F) * 0.8F * (HALF_HEIGHT - 80.0F)
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::from_image(bird_texture)
          .with_custom_size(Some(@math.Vec2::new(24.0F, 24.0F)))
          .with_color(
            @sprite.Color::srgb(
              float_from_int(idx % 7 + 3) / 10.0F,
              float_from_int(idx % 5 + 4) / 10.0F,
              float_from_int(idx % 3 + 6) / 10.0F,
            ),
          ),
          @transform.Transform::from_xyz(
            px,
            py,
            float_from_int(idx % 200) / 200.0F,
          ),
          Bird::{ velocity: @math.Vec3::new(vx, vy, 0.0F) },
        ),
      ),
    )
    next_index += 1
  }
  next_index
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  counter : @app.ResMut[BirdCounter],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
  let bird = asset_server.get().load("branding/icon.png")
  commands.insert_resource(BirdAssets::{ bird, })
  counter.modify(fn(value) {
    value.count = spawn_birds(commands, bird, INITIAL_BIRDS, 0)
  })
}

///|
fn spawn_on_click(
  commands : @app.Commands,
  assets : @app.Res[BirdAssets],
  counter : @app.ResMut[BirdCounter],
) -> Unit {
  if !@input.mouse_button_just_pressed(@input_events.MouseButton::Left) {
    return
  }
  counter.modify(fn(value) {
    value.count = spawn_birds(
      commands,
      assets.get().bird,
      BIRDS_PER_CLICK,
      value.count,
    )
  })
}

///|
fn movement_system(
  time : @app.Res[@time.Time[Unit]],
  birds : @ecs.Query[(@ecs.Mut[Bird], @ecs.Mut[@transform.Transform]), @ecs.All],
) -> Unit {
  let dt = time.get().delta_secs()
  try! birds.for_each(fn(_entity, data) {
    let (bird, transform) = data
    bird.modify(fn(bird_value) {
      transform.modify(fn(transform_value) {
        transform_value.translation.x += bird_value.velocity.x * dt
        transform_value.translation.y += bird_value.velocity.y * dt
        if transform_value.translation.x > HALF_WIDTH - 12.0F {
          transform_value.translation.x = HALF_WIDTH - 12.0F
          bird_value.velocity.x = -@math.abs(bird_value.velocity.x)
        } else if transform_value.translation.x < -HALF_WIDTH + 12.0F {
          transform_value.translation.x = -HALF_WIDTH + 12.0F
          bird_value.velocity.x = @math.abs(bird_value.velocity.x)
        }
        if transform_value.translation.y > HALF_HEIGHT - 12.0F {
          transform_value.translation.y = HALF_HEIGHT - 12.0F
          bird_value.velocity.y = -@math.abs(bird_value.velocity.y)
        } else if transform_value.translation.y < -HALF_HEIGHT + 12.0F {
          transform_value.translation.y = -HALF_HEIGHT + 12.0F
          bird_value.velocity.y = @math.abs(bird_value.velocity.y)
        }
      })
    })
  })
}

///|
fn counter_system(
  time : @app.Res[@time.Time[Unit]],
  counter : @app.ResMut[BirdCounter],
) -> Unit {
  let count = counter.modify(fn(value) {
    value.print_timer += time.get().delta_secs()
    if value.print_timer < 1.0F {
      None
    } else {
      value.print_timer -= 1.0F
      Some(value.count)
    }
  })
  guard count is Some(count) else { return }
  println("Bird count: \{count}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(BirdCounter::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(spawn_on_click)))
  .add_systems(@app.Update, @app.system(@app.system_param2(movement_system)))
  .add_systems(@app.Update, @app.system(@app.system_param2(counter_system)))
  .run()
}
