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
/// Port of `bevy/examples/audio/audio_control.rs`.

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
fn[T] first_marked_entity(store : @ecs.ComponentAccess[T]) -> @core.Entity? {
  let mut found : @core.Entity? = None
  store.for_each(fn(entity : @core.Entity, _component : T) {
    if found is None {
      found = Some(entity)
    }
  })
  found
}

///|
fn find_music_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world.component(my_music_component_key))
}

///|
fn find_progress_text_handle(world : @ecs.World) -> @text.TextHandle? {
  guard first_marked_entity(world.component(progress_text_marker_component_key))
    is Some(entity) else {
    return None
  }
  guard world.component(@ui.ecs_key_ui_text).get(entity) is Some(ui_text) else {
    return None
  }
  Some(ui_text.handle)
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
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(content),
      @text.TextFont::default().with_font(font).with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let entity = world.spawn_empty()
  let tick = world.read_change_tick()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(entity, @hierarchy.Parent::new(root), tick)
  let mut node = @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
  if top is Some(value) {
    node = node.with_top(@ui.Val::Px(value))
  }
  if bottom is Some(value) {
    node = node.with_bottom(@ui.Val::Px(value))
  }
  world.component(@ui.ecs_key_node).insert(entity, node, tick)
  world
  .component(@ui.ecs_key_ui_text)
  .insert(entity, @ui.UiText::new(handle), tick)
  if marker is Some(progress_text_marker) {
    world
    .component(progress_text_marker_component_key)
    .insert(entity, progress_text_marker, tick)
  }
}

///|
fn spawn_ui_overlay(world : @ecs.World) -> Unit {
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

  let tick = world.read_change_tick()
  let music = world.spawn_empty()
  world
  .component(@audio.ecs_key_audio_source_player)
  .insert(music, @audio.AudioPlayer::new(track), tick)
  world.component(my_music_component_key).insert(music, MyMusic::{  }, tick)

  spawn_ui_overlay(world)

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.0F, 0.0F, 10.0F),
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
  guard find_progress_text_handle(world) is Some(handle) else { return }
  guard world.component(@audio.ecs_key_audio_sink).get(music) is Some(sink) else {
    return
  }
  @text.text_set_content(handle, "Progress: \{sink.position().as_secs_f32()}s")
}

///|
fn update_speed(world : @ecs.World) -> Unit {
  guard find_music_entity(world) is Some(music) else { return }
  guard world.component(@audio.ecs_key_audio_sink).get(music) is Some(sink) else {
    return
  }
  if sink.is_paused() {
    return
  }

  let next_speed = maxf(
    @math.sin(world_time(world).elapsed_seconds() / 5.0F) + 1.0F,
    0.1F,
  )
  let tick = world.read_change_tick()
  world
  .component(@audio.ecs_key_audio_sink)
  .update(music, tick, fn(current : @audio.AudioSink) {
    current.set_speed(next_speed)
  })
  |> ignore
}

///|
fn pause(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  guard find_music_entity(world) is Some(music) else { return }
  guard world.component(@audio.ecs_key_audio_sink).get(music) is Some(sink) else {
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
  let tick = world.read_change_tick()
  world
  .component(@audio.ecs_key_audio_sink)
  .update(music, tick, fn(sink : @audio.AudioSink) { sink.toggle_mute() })
  |> ignore
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
  let tick = world.read_change_tick()
  world
  .component(@audio.ecs_key_audio_sink)
  .update(music, tick, fn(sink : @audio.AudioSink) {
    let next_volume = sink.volume().increase_by_percentage(direction)
    sink.set_volume(next_volume)
  })
  |> ignore
}
