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
pub impl @ecs.Component for AnimationTimer with fn component() {
  animation_timer_key
}

///|
struct PrintingTimer {
  timer : @time.Timer
}

///|
fn PrintingTimer::PrintingTimer() -> PrintingTimer {
  { timer: @time.Timer::from_seconds(1.0F, Repeating) }
}

///|
impl @app.FromWorld for PrintingTimer with fn from_world(_world) {
  PrintingTimer()
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.present_mode = AutoNoVsync
  window.resolution = @window.WindowResolution::new(1920, 1080).with_scale_factor_override(
    1.0F,
  )
  window
}

///|
fn animation_timer(elapsed_seconds : Float) -> AnimationTimer {
  {
    timer: @time.Timer::from_seconds(0.1F, Repeating).set_elapsed(
      @core.Duration::from_secs_f32(elapsed_seconds),
    ),
  }
}

///|
fn advance_camera_transform(
  transform : @transform.Transform,
  delta_seconds : Float,
) -> Unit {
  transform.rotate(@math.Quat::from_rotation_z(delta_seconds * 0.5F))
  transform.translation = transform.transform_point(
    @math.Vec3::new(CAMERA_SPEED * delta_seconds, 0.0F, 0.0F),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> Unit {
  @app.log_record(
    Warn,
    message="This is a stress test used to push Mgstudio to its limit and debug performance issues. It is not representative of an actual game. It must be run in release mode using --release or it will be very slow.",
    target="many_animated_sprites",
  )
  let rng = @random.Rand::new()
  let tile_size = @math.Vec2::splat(64.0F)
  let map_size = @math.Vec2::splat(320.0F)
  let half_x = (map_size.x / 2.0F).to_int()
  let half_y = (map_size.y / 2.0F).to_int()
  let texture = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let atlas_layout = texture_atlas_layouts
    .peek()
    .add(@asset.TextureAtlasLayout::from_grid(@math.UVec2::new(24, 24), 7, 1))
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  for y in -half_y..<half_y {
    for x in -half_x..<half_x {
      let translation = @math.Vec3::new(
        Float::from_int(x) * tile_size.x,
        Float::from_int(y) * tile_size.y,
        rng.float(),
      )
      let rotation = @math.Quat::from_rotation_z(rng.float())
      let scale = @math.Vec3::splat(rng.float() * 2.0F)
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::from_atlas_image(
              texture,
              @asset.TextureAtlas::new(atlas_layout, 0),
            ).with_custom_size(Some(tile_size)),
            @transform.Transform::from_translation(translation)
            .with_rotation(rotation)
            .with_scale(scale),
            animation_timer(rng.float()),
          ),
        ),
      )
    }
  }
}

///|
fn animate_sprites(
  time : @app.Res[@time.Time[Unit]],
  texture_atlas_layouts : @app.Res[@asset.Assets[@asset.TextureAtlasLayout]],
  sprites : @ecs.Query[
    (@ecs.Write[AnimationTimer], @ecs.Write[@sprite.Sprite]),
    @ecs.All,
  ],
) -> Unit {
  let delta = time.get().delta()
  let layouts = texture_atlas_layouts.get()
  try! sprites.for_each_table(fn(batch) {
    let timers = batch.write(animation_timer_key).unwrap()
    let sprite_values = batch.write(@sprite.ecs_key_sprite).unwrap()
    sprite_values.with_change_writer(fn(sprite_changes) {
      timers.update_inplace(fn(timer_values) {
        for row_index in 0..<timer_values.length() {
          let next_timer = timer_values[row_index].timer.tick(delta)
          timer_values[row_index].timer = next_timer
          if !next_timer.just_finished() {
            continue
          }
          let sprite = sprite_values.peek(row_index)
          guard sprite.texture_atlas is Some(atlas) else { continue }
          guard atlas.layout_asset(layouts) is Some(layout) else {
            abort(
              "many_animated_sprites texture atlas layout must remain loaded",
            )
          }
          sprite.texture_atlas = Some(
            atlas.with_index((atlas.index + 1) % layout.len()),
          )
          sprite_changes.set_changed(row_index)
        }
      })
    })
  })
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera_camera.Camera],
  ],
) -> Unit {
  try! camera.for_each(fn(_entity, transform) {
    transform.modify(fn(value) {
      advance_camera_transform(value, time.get().delta_secs())
    })
  })
}

///|
fn print_sprite_count(
  time : @app.Res[@time.Time[Unit]],
  timer : @app.Local[PrintingTimer],
  sprites : @ecs.Query[@ecs.Read[@sprite.Sprite], @ecs.All],
) -> Unit {
  let next_timer = timer.get().timer.tick(time.get().delta())
  timer.set({ timer: next_timer })
  if !next_timer.just_finished() {
    return
  }
  println("Sprites: \{sprites.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@diagnostic.LogDiagnosticsPlugin::LogDiagnosticsPlugin())
  .add_plugins(
    @diagnostic.FrameTimeDiagnosticsPlugin::FrameTimeDiagnosticsPlugin(),
  )
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: Some(CursorOptions()),
      exit_condition: OnAllClosed,
      close_when_requested: true,
    }),
  )
  .insert_resource(@winit.WinitSettings::continuous())
  .add_systems_param3(Startup, setup)
  .add_systems_param3(Update, animate_sprites)
  .add_systems(
    Update,
    @app.system_config_param3(print_sprite_count).named(
      "examples.stress_tests.many_animated_sprites.print_sprite_count",
    ),
  )
  .add_systems(
    Update,
    @app.system_config_param2(move_camera).after(
      @app.system_set(
        "examples.stress_tests.many_animated_sprites.print_sprite_count",
      ),
    ),
  )
  .run()
}
