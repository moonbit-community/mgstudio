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
/// Port of `bevy/examples/audio/spatial_audio_2d.rs`.

///|
const AUDIO_SCALE : Float = 0.01F

///|
const LISTENER_GAP : Float = 400.0F

///|
const EMITTER_RADIUS : Float = 15.0F

///|
const EAR_SIZE : Float = 20.0F

///|
const LISTENER_SPEED : Float = 200.0F

///|
const EMITTER_Y : Float = 50.0F

///|
const EMITTER_RANGE_X : Float = 500.0F

///|
priv struct SpatialAudio2dState {
  mut emitter : @core.Entity
  mut listener : @core.Entity
  mut emitter_stopwatch : @time.Stopwatch
}

///|
let spatial_audio_2d_state : Ref[SpatialAudio2dState] = Ref::new({
  emitter: @core.Entity::placeholder(),
  listener: @core.Entity::placeholder(),
  emitter_stopwatch: @time.Stopwatch::new(),
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .insert_resource(
    @audio.DefaultSpatialScale::new(@audio.SpatialScale::new_2d(AUDIO_SCALE)),
  )
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update_emitters))
  .add_systems(@app.Update, @app.system(update_listener))
  .run()
}

///|
fn color_blue() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 0.0F, 1.0F)
}

///|
fn color_red() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
}

///|
fn color_lime() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 1.0F, 0.0F)
}

///|
fn toggle_stopwatch(stopwatch : @time.Stopwatch) -> @time.Stopwatch {
  if stopwatch.is_paused() {
    stopwatch.unpause()
  } else {
    stopwatch.pause()
  }
}

///|
fn tick_delta() -> @core.Duration {
  @core.Duration::from_secs_f32(@time.time_delta_seconds())
}

///|
fn spawn_ui_overlay(world : @ecs.World, content : String) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(content),
      @text.TextFont::default().with_font(font).with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn spawn_listener_ear(
  world : @ecs.World,
  listener : @core.Entity,
  offset_x : Float,
  color : @sprite.Color,
) -> Unit {
  let ear = @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::new(EAR_SIZE, EAR_SIZE)),
    @sprite.ColorMaterial::new(color),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(offset_x, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)

  let tick = world.read_change_tick()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(ear, @hierarchy.Parent::new(listener), tick)
}

///|
fn setup(world : @ecs.World) -> Unit {
  spatial_audio_2d_state.val = {
    emitter: @core.Entity::placeholder(),
    listener: @core.Entity::placeholder(),
    emitter_stopwatch: @time.Stopwatch::new(),
  }

  let asset_server = @asset.AssetServer::new()
  let track : @asset.Handle[@audio.AudioSource] = asset_server.load(
    "sounds/Windless Slopes.ogg",
  )

  let emitter = @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_circle(@sprite.Circle::new(EMITTER_RADIUS)),
    @sprite.ColorMaterial::new(color_blue()),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, EMITTER_Y),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)

  let tick = world.read_change_tick()
  world
  .component(@audio.ecs_key_audio_source_player)
  .insert(emitter, @audio.AudioPlayer::new(track), tick)
  world
  .component(@audio.ecs_key_playback_settings)
  .insert(emitter, @audio.PlaybackSettings::looped().with_spatial(true), tick)

  let listener = world.spawn_empty()
  world
  .component(@math.ecs_key_transform)
  .insert(listener, @math.Transform::identity(), tick)
  world
  .component(@audio.ecs_key_spatial_listener)
  .insert(listener, @audio.SpatialListener::new(LISTENER_GAP), tick)

  spawn_listener_ear(world, listener, -LISTENER_GAP / 2.0F, color_red())
  spawn_listener_ear(world, listener, LISTENER_GAP / 2.0F, color_lime())

  spawn_ui_overlay(
    world, "Up/Down/Left/Right: Move Listener\nSpace: Toggle Emitter Movement",
  )

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  spatial_audio_2d_state.val.emitter = emitter
  spatial_audio_2d_state.val.listener = listener
}

///|
fn update_emitters(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    spatial_audio_2d_state.val.emitter_stopwatch = toggle_stopwatch(
      spatial_audio_2d_state.val.emitter_stopwatch,
    )
  }

  spatial_audio_2d_state.val.emitter_stopwatch = spatial_audio_2d_state.val.emitter_stopwatch.tick(
    tick_delta(),
  )

  if spatial_audio_2d_state.val.emitter_stopwatch.is_paused() {
    return
  }

  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)
  let next_x = @math.sin(
      spatial_audio_2d_state.val.emitter_stopwatch.elapsed_secs(),
    ) *
    EMITTER_RANGE_X

  transform_store.update(spatial_audio_2d_state.val.emitter, tick, fn(
    transform : @math.Transform,
  ) {
    transform.with_translation(@math.Vec3::new(next_x, EMITTER_Y, 0.0F))
  })
  |> ignore
}

///|
fn update_listener(world : @ecs.World) -> Unit {
  let dx = if @input.key_pressed(@window.KeyCode::ArrowRight) {
    LISTENER_SPEED * @time.time_delta_seconds()
  } else if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    -LISTENER_SPEED * @time.time_delta_seconds()
  } else {
    0.0F
  }
  let dy = if @input.key_pressed(@window.KeyCode::ArrowUp) {
    LISTENER_SPEED * @time.time_delta_seconds()
  } else if @input.key_pressed(@window.KeyCode::ArrowDown) {
    -LISTENER_SPEED * @time.time_delta_seconds()
  } else {
    0.0F
  }

  if dx == 0.0F && dy == 0.0F {
    return
  }

  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)
  transform_store.update(spatial_audio_2d_state.val.listener, tick, fn(
    transform : @math.Transform,
  ) {
    let translation = transform.translation
    transform.with_translation(
      @math.Vec3::new(translation.x + dx, translation.y + dy, translation.z),
    )
  })
  |> ignore
}
