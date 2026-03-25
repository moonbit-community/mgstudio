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
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in spatial_audio_2d example")
  }
}

///|
fn tick_delta(world : @ecs.World) -> @core.Duration {
  world_time(world).delta()
}

///|
fn spawn_ui_overlay(world : @ecs.World, content : String) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
}

///|
fn spawn_listener_ear(
  world : @ecs.World,
  listener : @core.Entity,
  offset_x : Float,
  color : @sprite.Color,
) -> Unit {
  let ear = @sprite.Mesh2dBundle::new_with_mesh_material(
    @sprite.Mesh2d::new(
      @sprite.mesh_assets_mut_or_abort().val.add(
        @sprite.mesh2d_geometry_rectangle(
          @sprite.Rectangle::new(EAR_SIZE, EAR_SIZE),
        ).to_mesh(),
      ),
    ),
    @sprite.MeshMaterial2d::new(
      @sprite.color_material_assets_mut_or_abort().val.add(
        @sprite.ColorMaterialAsset::from_color(color),
      ),
    ),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(offset_x, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)

  try! world.set_by_key(
    ear,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(listener),
  )
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

  let emitter = @sprite.Mesh2dBundle::new_with_mesh_material(
    @sprite.Mesh2d::new(
      @sprite.mesh_assets_mut_or_abort().val.add(
        @sprite.mesh2d_geometry_circle(@sprite.Circle::new(EMITTER_RADIUS)).to_mesh(),
      ),
    ),
    @sprite.MeshMaterial2d::new(
      @sprite.color_material_assets_mut_or_abort().val.add(
        @sprite.ColorMaterialAsset::from_color(color_blue()),
      ),
    ),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, EMITTER_Y),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)

  try! world.set_by_key(
    emitter,
    @audio.ecs_key_audio_source_player,
    @audio.AudioPlayer::new(track),
  )

  try! world.set_by_key(
    emitter,
    @audio.ecs_key_audio_source_player,
    @audio.AudioPlayer::new(track),
  )
  try! world.set_by_key(
    emitter,
    @audio.ecs_key_playback_settings,
    @audio.PlaybackSettings::looped().with_spatial(true),
  )

  let listener = world.spawn_empty()
  try! world.set_by_key(
    listener,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  try! world.set_by_key(
    listener,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  try! world.set_by_key(
    listener,
    @audio.ecs_key_spatial_listener,
    @audio.SpatialListener::new(LISTENER_GAP),
  )

  spawn_listener_ear(world, listener, -LISTENER_GAP / 2.0F, color_red())
  spawn_listener_ear(world, listener, LISTENER_GAP / 2.0F, color_lime())

  spawn_ui_overlay(
    world, "Up/Down/Left/Right: Move Listener\nSpace: Toggle Emitter Movement",
  )

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
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
    tick_delta(world),
  )

  if spatial_audio_2d_state.val.emitter_stopwatch.is_paused() {
    return
  }

  let next_x = @math.sin(
      spatial_audio_2d_state.val.emitter_stopwatch.elapsed_secs(),
    ) *
    EMITTER_RANGE_X

  try! (world.update_by_key(
    spatial_audio_2d_state.val.emitter,
    @transform.ecs_key_transform,
    fn(transform : @transform.Transform) {
      transform.with_translation(@math.Vec3::new(next_x, EMITTER_Y, 0.0F))
    },
  )
  |> ignore)
}

///|
fn update_listener(world : @ecs.World) -> Unit {
  let delta_seconds = world_time(world).delta_seconds()
  let dx = if @input.key_pressed(@window.KeyCode::ArrowRight) {
    LISTENER_SPEED * delta_seconds
  } else if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    -LISTENER_SPEED * delta_seconds
  } else {
    0.0F
  }
  let dy = if @input.key_pressed(@window.KeyCode::ArrowUp) {
    LISTENER_SPEED * delta_seconds
  } else if @input.key_pressed(@window.KeyCode::ArrowDown) {
    -LISTENER_SPEED * delta_seconds
  } else {
    0.0F
  }

  if dx == 0.0F && dy == 0.0F {
    return
  }

  try! (world.update_by_key(
    spatial_audio_2d_state.val.listener,
    @transform.ecs_key_transform,
    fn(transform : @transform.Transform) {
      let translation = transform.translation
      transform.with_translation(
        @math.Vec3::new(translation.x + dx, translation.y + dy, translation.z),
      )
    },
  )
  |> ignore)
}
