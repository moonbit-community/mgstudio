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

///|
priv struct MyMusic {}

///|
priv struct ProgressTextMarker {}

///|
let my_music_component_key : @ecs.ComponentKey[MyMusic] = @ecs.register_component(
  debug_name="examples.audio.audio_control.MyMusic",
)

///|
let progress_text_marker_component_key : @ecs.ComponentKey[ProgressTextMarker] = @ecs.register_component(
  debug_name="examples.audio.audio_control.ProgressTextMarker",
)

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update_progress_text))
  .add_systems(@app.Update, @app.system(update_speed))
  .add_systems(@app.Update, @app.system(pause))
  .add_systems(@app.Update, @app.system(mute))
  .add_systems(@app.Update, @app.system(volume))
  .run()
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn[T] first_marked_entity(
  world : @ecs.World,
  key : @ecs.ComponentKey[T],
) -> @core.Entity? {
  let mut found : @core.Entity? = None
  world.for_each_component(key, fn(entity : @core.Entity, _component : T) {
    if found is None {
      found = Some(entity)
    }
  })
  found
}

///|
fn find_music_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world, my_music_component_key)
}

///|
fn find_progress_text_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world, progress_text_marker_component_key)
}

///|
fn spawn_ui_text(
  world : @ecs.World,
  root : @core.Entity,
  content : String,
  top : Float?,
  bottom : Float?,
  marker : ProgressTextMarker?,
) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  let mut node = @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
  if top is Some(value) {
    node = node.with_top(@ui.Val::Px(value))
  }
  if bottom is Some(value) {
    node = node.with_bottom(@ui.Val::Px(value))
  }
  try! world.set_by_key(entity, @ui.ecs_key_node, node)
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new(content))
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  if marker is Some(progress_text_marker) {
    try! world.set_by_key(
      entity, progress_text_marker_component_key, progress_text_marker,
    )
  }
}

///|
fn spawn_ui_overlay(world : @ecs.World) -> Unit {
  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  spawn_ui_text(
    world,
    root,
    "Progress: 0s",
    Some(12.0F),
    None,
    Some(ProgressTextMarker::{  }),
  )
  spawn_ui_text(
    world,
    root,
    "-/=: Volume Down/Up\nSpace: Toggle Playback\nM: Toggle Mute",
    None,
    Some(12.0F),
    None,
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let track : @asset.Handle[@audio.AudioSource] = asset_server.load(
    "sounds/Windless Slopes.ogg",
  )

  let music = world.spawn_empty()
  try! world.set_by_key(
    music,
    @audio.ecs_key_audio_source_player,
    @audio.AudioPlayer::new(track),
  )
  try! world.set_by_key(music, my_music_component_key, MyMusic::{  })

  spawn_ui_overlay(world)

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F),
  ).spawn(world)
  |> ignore
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in audio_control example")
  }
}

///|
fn update_progress_text(world : @ecs.World) -> Unit {
  guard find_music_entity(world) is Some(music) else { return }
  guard find_progress_text_entity(world) is Some(entity) else { return }
  guard (try! world.get_by_key(music, @audio.ecs_key_audio_sink)) is Some(sink) else {
    return
  }
  guard (try! world.get_by_key(entity, @text.ecs_key_text)) is Some(text_value) else {
    return
  }
  text_value.content = "Progress: \{sink.position().as_secs_f32()}s"
  ignore(try! world.replace(entity, @text.ecs_key_text, text_value))
}

///|
fn update_speed(world : @ecs.World) -> Unit {
  guard find_music_entity(world) is Some(music) else { return }
  guard (try! world.get_by_key(music, @audio.ecs_key_audio_sink)) is Some(sink) else {
    return
  }
  if sink.is_paused() {
    return
  }

  let next_speed = maxf(
    @math.sin(world_time(world).elapsed_seconds() / 5.0F) + 1.0F,
    0.1F,
  )
  try! (world.update_by_key(music, @audio.ecs_key_audio_sink, fn(
    current : @audio.AudioSink,
  ) {
    current.set_speed(next_speed)
  })
  |> ignore)
}

///|
fn pause(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  guard find_music_entity(world) is Some(music) else { return }
  guard (try! world.get_by_key(music, @audio.ecs_key_audio_sink)) is Some(sink) else {
    return
  }
  sink.toggle_playback()
}

///|
fn mute(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::KeyM) {
    return
  }
  guard find_music_entity(world) is Some(music) else { return }
  try! (world.update_by_key(music, @audio.ecs_key_audio_sink, fn(
    sink : @audio.AudioSink,
  ) {
    sink.toggle_mute()
  })
  |> ignore)
}

///|
fn volume(world : @ecs.World) -> Unit {
  let direction = if @input.key_just_pressed(@window.KeyCode::Equal) {
    10.0F
  } else if @input.key_just_pressed(@window.KeyCode::Minus) {
    -10.0F
  } else {
    return
  }

  guard find_music_entity(world) is Some(music) else { return }
  try! (world.update_by_key(music, @audio.ecs_key_audio_sink, fn(
    sink : @audio.AudioSink,
  ) {
    let next_volume = sink.volume().increase_by_percentage(direction)
    sink.set_volume(next_volume)
  })
  |> ignore)
}
