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
struct AnimationTimer {
  mut timer : @time.Timer
}

///|
let animation_timer_key : @ecs.ComponentKey[AnimationTimer] = @ecs.register_component(
  debug_name="examples.stress_tests.many_animated_sprites.AnimationTimer",
)

///|
pub impl @ecs.Component for AnimationTimer with component() {
  animation_timer_key
}

///|
struct PrintTimer {
  mut seconds : Float
}

///|
let print_timer_key : @ecs.ResourceKey[PrintTimer] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_animated_sprites.PrintTimer",
)

///|
impl @app.Resource for PrintTimer with resource() {
  print_timer_key
}

///|
fn PrintTimer::default() -> PrintTimer {
  { seconds: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> Unit {
  let texture = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let atlas_layout = texture_atlas_layouts.get_ref().val.add(
    @asset.TextureAtlasLayout::from_grid(@math.UVec2::new(24, 24), 7, 1),
  )
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  for y in -GRID_HALF_Y..<GRID_HALF_Y {
    for x in -GRID_HALF_X..<GRID_HALF_X {
      let idx = (y + GRID_HALF_Y) * (GRID_HALF_X * 2) + (x + GRID_HALF_X)
      let rotation = @math.Quat::from_rotation_z(
        float_from_int(idx % 360) * 0.017453292519943295F,
      )
      let scale = 0.6F + float_from_int(idx % 5) * 0.3F
      let fps = 10.0F + float_from_int(idx % 11)
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::from_atlas_image(
              texture,
              @asset.TextureAtlas::new(atlas_layout, idx % 7),
            ).with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F))),
            @transform.Transform::from_xyz(
              float_from_int(x) * TILE_SIZE,
              float_from_int(y) * TILE_SIZE,
              float_from_int(idx % 100) / 100.0F,
            )
            .with_rotation(rotation)
            .with_scale(@math.Vec3::splat(scale)),
            AnimationTimer::{
              timer: @time.Timer::from_seconds(
                1.0F / fps,
                @time.TimerMode::Repeating,
              ),
            },
          ),
        ),
      )
    }
  }
}

///|
fn animate_sprites(
  time : @app.Res[@time.Time[Unit]],
  sprites : @ecs.Query[
    (@ecs.Mut[AnimationTimer], @ecs.Mut[@sprite.Sprite]),
    @ecs.All,
  ],
) -> Unit {
  try! sprites.for_each(fn(_entity, data) {
    let (timer, sprite) = data
    let timer_ref = timer.get_ref()
    let sprite_ref = sprite.get_ref()
    timer_ref.val.timer = timer_ref.val.timer.tick(time.get().delta())
    if !timer_ref.val.timer.just_finished() {
      return
    }
    guard sprite_ref.val.texture_atlas is Some(atlas) else { return }
    sprite_ref.val.texture_atlas = Some(atlas.with_index((atlas.index + 1) % 7))
  })
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Camera2d],
  ],
) -> Unit {
  try! camera.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = @math.Quat::from_rotation_z(
      time.get().elapsed_secs() * 0.5F,
    )
    transform_ref.val.translation = transform_ref.val.translation.add(
      @math.Vec3::new(CAMERA_SPEED * time.get().delta_secs(), 0.0F, 0.0F),
    )
  })
}

///|
fn print_sprite_count(
  time : @app.Res[@time.Time[Unit]],
  timer : @app.ResMut[PrintTimer],
  sprites : @ecs.Query[@ecs.Comp[AnimationTimer], @ecs.All],
) -> Unit {
  let timer_ref = timer.get_ref()
  timer_ref.val.seconds += time.get().delta_secs()
  if timer_ref.val.seconds < 1.0F {
    return
  }
  timer_ref.val.seconds -= 1.0F
  println("Animated sprites: \{sprites.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(PrintTimer::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [..@mgstudio.default_plugins(), @diagnostic.stress_diagnostics_plugin],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_sprites)))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_sprite_count)))
  .run()
}
