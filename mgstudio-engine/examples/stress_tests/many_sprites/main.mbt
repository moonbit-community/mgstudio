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
const GRID_HALF_X : Int = 160

///|
const GRID_HALF_Y : Int = 160

///|
const TILE_SIZE : Float = 64.0F

///|
const CAMERA_SPEED : Float = 1000.0F

///|
struct SpriteStats {
  mut print_timer : Float
}

///|
let sprite_stats_key : @ecs.ResourceKey[SpriteStats] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_sprites.SpriteStats",
)

///|
impl @app.Resource for SpriteStats with resource() {
  sprite_stats_key
}

///|
fn SpriteStats::default() -> SpriteStats {
  { print_timer: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )

  let texture = asset_server.get().load("branding/icon.png")
  for y in -GRID_HALF_Y..<GRID_HALF_Y {
    for x in -GRID_HALF_X..<GRID_HALF_X {
      let idx = (y + GRID_HALF_Y) * (GRID_HALF_X * 2) + (x + GRID_HALF_X)
      let z = float_from_int(idx % 100) / 100.0F
      let rotation = @math.Quat::from_rotation_z(
        float_from_int(idx % 360) * 0.017453292519943295F,
      )
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::from_image(texture)
            .with_custom_size(Some(@math.Vec2::new(24.0F, 24.0F)))
            .with_color(@sprite.Color::white()),
            @transform.Transform::from_xyz(
              float_from_int(x) * TILE_SIZE,
              float_from_int(y) * TILE_SIZE,
              z,
            ).with_rotation(rotation),
          ),
        ),
      )
    }
  }
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Camera2d],
  ],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! camera.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = @math.Quat::from_rotation_z(elapsed * 0.5F)
    transform_ref.val.translation = transform_ref.val.translation.add(
      @math.Vec3::new(CAMERA_SPEED * time.get().delta_secs(), 0.0F, 0.0F),
    )
  })
}

///|
fn print_sprite_count(
  time : @app.Res[@time.Time[Unit]],
  stats : @app.ResMut[SpriteStats],
  sprites : @ecs.Query[@ecs.Comp[@sprite.Sprite], @ecs.All],
) -> Unit {
  let stats_ref = stats.get_ref()
  stats_ref.val.print_timer += time.get().delta_secs()
  if stats_ref.val.print_timer < 1.0F {
    return
  }
  stats_ref.val.print_timer -= 1.0F
  println("Sprites: \{sprites.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(SpriteStats::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(@diagnostic.StressDiagnosticsPlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_sprite_count)))
  .run()
}
