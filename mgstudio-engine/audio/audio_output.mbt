// Copyright 2025 International Digital Economy Academy
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
struct AudioOutput {
  stream : NativeAudioStream?
}

///|
pub fn AudioOutput::default() -> AudioOutput {
  let stream = open_default_output_stream() catch {
    _ => return AudioOutput::{ stream: None }
  }
  AudioOutput::{ stream: Some(stream) }
}

///|
let audio_output_resource_key : @ecs.ResourceKey[AudioOutput] = @ecs.register_resource(
  debug_name="mgstudio_audio::AudioOutput",
)

///|
pub impl @app.Resource for AudioOutput with resource() {
  audio_output_resource_key
}

///|
pub struct PlaybackDespawnMarker {} derive(ToJson, FromJson)

///|
pub struct PlaybackRemoveMarker {} derive(ToJson, FromJson)

///|
let audio_player_component_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
fn[Source] registered_audio_player_component_key() -> @ecs.ComponentKey[
  AudioPlayer[Source],
] {
  let probe : AudioPlayer[Source] = AudioPlayer::new(@asset.Handle::new(0))
  let type_name = @any.of(probe).type_name()
  match audio_player_component_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "audio player component registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.ComponentKey[AudioPlayer[Source]] = @ecs.register_component(
        debug_name="mgstudio_audio::\{type_name}",
      )
      audio_player_component_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub let ecs_key_audio_source_player : @ecs.ComponentKey[
  AudioPlayer[AudioSource],
] = registered_audio_player_component_key()

///|
pub let ecs_key_pitch_player : @ecs.ComponentKey[AudioPlayer[Pitch]] = registered_audio_player_component_key()

///|
pub let ecs_key_playback_settings : @ecs.ComponentKey[PlaybackSettings] = @ecs.register_component(
  debug_name="audio.playback_settings",
)

///|
pub let ecs_key_spatial_listener : @ecs.ComponentKey[SpatialListener] = @ecs.register_component(
  debug_name="audio.spatial_listener",
)

///|
pub let ecs_key_audio_sink : @ecs.ComponentKey[AudioSink] = @ecs.register_component(
  debug_name="audio.audio_sink",
)

///|
pub let ecs_key_spatial_audio_sink : @ecs.ComponentKey[SpatialAudioSink] = @ecs.register_component(
  debug_name="audio.spatial_audio_sink",
)

///|
pub let ecs_key_playback_despawn_marker : @ecs.ComponentKey[
  PlaybackDespawnMarker,
] = @ecs.register_component(debug_name="audio.playback_despawn_marker")

///|
pub let ecs_key_playback_remove_marker : @ecs.ComponentKey[PlaybackRemoveMarker] = @ecs.register_component(
  debug_name="audio.playback_remove_marker",
)

///|
pub impl[Source] @ecs.Component for AudioPlayer[Source] with component() {
  registered_audio_player_component_key()
}

///|
pub impl @ecs.Component for PlaybackSettings with component() {
  ecs_key_playback_settings
}

///|
pub impl @ecs.Component for SpatialListener with component() {
  ecs_key_spatial_listener
}

///|
pub impl @ecs.Component for AudioSink with component() {
  ecs_key_audio_sink
}

///|
pub impl @ecs.Component for SpatialAudioSink with component() {
  ecs_key_spatial_audio_sink
}

///|
pub impl @ecs.Component for PlaybackDespawnMarker with component() {
  ecs_key_playback_despawn_marker
}

///|
pub impl @ecs.Component for PlaybackRemoveMarker with component() {
  ecs_key_playback_remove_marker
}

///|
fn audio_output_stream(world : @ecs.World) -> NativeAudioStream? {
  match audio_resource_get(world, AudioOutput::resource()) {
    Some(output) => output.stream
    None => None
  }
}

///|
fn audio_output_available(world : @ecs.World) -> Bool {
  audio_output_stream(world) is Some(_)
}

///|
fn audio_playback_config(
  settings : PlaybackSettings,
) -> NativeAudioPlaybackConfig {
  let mut config = NativeAudioPlaybackConfig::default().looped(
    match settings.mode {
      PlaybackMode::Loop => true
      _ => false
    },
  )
  match settings.start_position {
    Some(start_position) =>
      config = config.with_start_position_seconds(start_position.as_secs_f32())
    None => ()
  }
  match settings.duration {
    Some(duration) =>
      config = config.with_duration_seconds(duration.as_secs_f32())
    None => ()
  }
  config
}

///|
fn audio_combined_volume(
  settings : PlaybackSettings,
  global_volume : GlobalVolume,
) -> Volume {
  settings.volume.mul(global_volume.volume)
}

///|
fn audio_entity_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global) => global.to_transform_approx()
    None =>
      match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
        Some(transform) => transform
        None => @transform.Transform::identity()
      }
  }
}

///|
fn audio_transform_point(
  transform : @transform.Transform,
  point : @math.Vec3,
) -> @math.Vec3 {
  let angle = transform.rotation_z()
  let cosv = @math.cos(angle)
  let sinv = @math.sin(angle)
  let scaled_x = point.x * transform.scale.x
  let scaled_y = point.y * transform.scale.y
  let scaled_z = point.z * transform.scale.z
  let rotated_x = scaled_x * cosv - scaled_y * sinv
  let rotated_y = scaled_x * sinv + scaled_y * cosv
  @math.Vec3::new(
    transform.translation.x + rotated_x,
    transform.translation.y + rotated_y,
    transform.translation.z + scaled_z,
  )
}

///|
fn audio_vec3_mul(value : @math.Vec3, scale : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(value.x * scale.x, value.y * scale.y, value.z * scale.z)
}

///|
fn audio_vec3_to_native_tuple(value : @math.Vec3) -> (Double, Double, Double) {
  (value.x.to_double(), value.y.to_double(), value.z.to_double())
}

///|
fn audio_listener_positions(world : @ecs.World) -> (@math.Vec3, @math.Vec3) {
  let listeners : Array[(@core.Entity, SpatialListener)] = []
  let listener_query : @ecs.Query[@ecs.Comp[SpatialListener], @ecs.All] = @ecs.query(
    world,
  )
  try! listener_query.view(fn(entity, listener) {
    listeners.push((entity, listener.value()))
  })
  if listeners.length() == 0 {
    let default_listener = SpatialListener::default()
    return (default_listener.left_ear_offset, default_listener.right_ear_offset)
  }
  let (entity, listener) = listeners[0]
  let transform = audio_entity_transform(world, entity)
  (
    audio_transform_point(transform, listener.left_ear_offset),
    audio_transform_point(transform, listener.right_ear_offset),
  )
}

///|
fn audio_default_spatial_scale(world : @ecs.World) -> SpatialScale {
  match audio_resource_get(world, DefaultSpatialScale::resource()) {
    Some(scale) => scale.scale
    None => SpatialScale::default()
  }
}

///|
fn audio_global_volume(world : @ecs.World) -> GlobalVolume {
  match audio_resource_get(world, GlobalVolume::resource()) {
    Some(value) => value
    None => GlobalVolume::default()
  }
}

///|
fn audio_playback_settings_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> PlaybackSettings {
  match (try! world.get_by_key(entity, ecs_key_playback_settings)) {
    Some(settings) => settings
    None => PlaybackSettings::default()
  }
}

///|
fn audio_insert_playback_markers(
  world : @ecs.World,
  entity : @core.Entity,
  mode : PlaybackMode,
) -> Unit {
  match mode {
    PlaybackMode::Despawn =>
      try! world.set_by_key(entity, ecs_key_playback_despawn_marker, PlaybackDespawnMarker::{

      })
    PlaybackMode::Remove =>
      try! world.set_by_key(entity, ecs_key_playback_remove_marker, PlaybackRemoveMarker::{

      })
    _ => ()
  }
}

///|
fn audio_play_source_entity(
  world : @ecs.World,
  entity : @core.Entity,
  player : AudioPlayer[AudioSource],
) -> Unit {
  guard audio_output_stream(world) is Some(output) else { return }
  guard audio_source_get(world, player.handle()) is Some(source) else { return }
  let settings = audio_playback_settings_for_entity(world, entity)
  let volume = audio_combined_volume(settings, audio_global_volume(world))
  let config = audio_playback_config(settings)
  if settings.spatial {
    let default_scale = audio_default_spatial_scale(world).scale
    let scale = match settings.spatial_scale {
      Some(custom) => custom.scale
      None => default_scale
    }
    let transform = audio_entity_transform(world, entity)
    let emitter = audio_vec3_mul(transform.translation, scale)
    let ears = audio_listener_positions(world)
    let left_ear = audio_vec3_mul(ears.0, scale)
    let right_ear = audio_vec3_mul(ears.1, scale)
    let native_player = output.new_spatial_player(
      audio_vec3_to_native_tuple(emitter),
      audio_vec3_to_native_tuple(left_ear),
      audio_vec3_to_native_tuple(right_ear),
    )
    native_player.append_bytes(source.bytes(), config~) catch {
      _ => return
    }
    native_player.set_speed(settings.speed.to_double())
    native_player.set_volume(volume.to_linear().to_double())
    if settings.paused {
      native_player.pause()
    }
    let sink = if settings.muted {
      spatial_audio_sink_from_native(native_player).mute()
    } else {
      spatial_audio_sink_from_native(native_player)
    }
    try! world.set_by_key(entity, ecs_key_spatial_audio_sink, sink)
  } else {
    let native_player = output.new_player()
    native_player.append_bytes(source.bytes(), config~) catch {
      _ => return
    }
    native_player.set_speed(settings.speed.to_double())
    native_player.set_volume(volume.to_linear().to_double())
    if settings.paused {
      native_player.pause()
    }
    let sink = if settings.muted {
      audio_sink_from_native(native_player).mute()
    } else {
      audio_sink_from_native(native_player)
    }
    try! world.set_by_key(entity, ecs_key_audio_sink, sink)
  }
  audio_insert_playback_markers(world, entity, settings.mode)
}

///|
fn audio_play_pitch_entity(
  world : @ecs.World,
  entity : @core.Entity,
  player : AudioPlayer[Pitch],
) -> Unit {
  guard audio_output_stream(world) is Some(output) else { return }
  guard pitch_get(world, player.handle()) is Some(pitch) else { return }
  let settings = audio_playback_settings_for_entity(world, entity)
  let volume = audio_combined_volume(settings, audio_global_volume(world))
  if settings.spatial {
    let default_scale = audio_default_spatial_scale(world).scale
    let scale = match settings.spatial_scale {
      Some(custom) => custom.scale
      None => default_scale
    }
    let transform = audio_entity_transform(world, entity)
    let emitter = audio_vec3_mul(transform.translation, scale)
    let ears = audio_listener_positions(world)
    let left_ear = audio_vec3_mul(ears.0, scale)
    let right_ear = audio_vec3_mul(ears.1, scale)
    let native_player = output.new_spatial_player(
      audio_vec3_to_native_tuple(emitter),
      audio_vec3_to_native_tuple(left_ear),
      audio_vec3_to_native_tuple(right_ear),
    )
    native_player.append_sine(
      pitch.frequency,
      pitch.duration_seconds,
      looped=match settings.mode {
        PlaybackMode::Loop => true
        _ => false
      },
    )
    native_player.set_speed(settings.speed.to_double())
    native_player.set_volume(volume.to_linear().to_double())
    if settings.paused {
      native_player.pause()
    }
    let sink = if settings.muted {
      spatial_audio_sink_from_native(native_player).mute()
    } else {
      spatial_audio_sink_from_native(native_player)
    }
    try! world.set_by_key(entity, ecs_key_spatial_audio_sink, sink)
  } else {
    let native_player = output.new_player()
    native_player.append_sine(
      pitch.frequency,
      pitch.duration_seconds,
      looped=match settings.mode {
        PlaybackMode::Loop => true
        _ => false
      },
    )
    native_player.set_speed(settings.speed.to_double())
    native_player.set_volume(volume.to_linear().to_double())
    if settings.paused {
      native_player.pause()
    }
    let sink = if settings.muted {
      audio_sink_from_native(native_player).mute()
    } else {
      audio_sink_from_native(native_player)
    }
    try! world.set_by_key(entity, ecs_key_audio_sink, sink)
  }
  audio_insert_playback_markers(world, entity, settings.mode)
}

///|
fn play_queued_audio_source_system(world : @ecs.World) -> Unit {
  let player_query : @ecs.Query[@ecs.Comp[AudioPlayer[AudioSource]], @ecs.All] = @ecs.query(
    world,
  )
  try! player_query.view(fn(entity, player) {
    if (try! world.get_by_key(entity, ecs_key_audio_sink)) is Some(_) {
      return
    }
    if (try! world.get_by_key(entity, ecs_key_spatial_audio_sink)) is Some(_) {
      return
    }
    audio_play_source_entity(world, entity, player.value())
  })
}

///|
fn play_queued_pitch_system(world : @ecs.World) -> Unit {
  let player_query : @ecs.Query[@ecs.Comp[AudioPlayer[Pitch]], @ecs.All] = @ecs.query(
    world,
  )
  try! player_query.view(fn(entity, player) {
    if (try! world.get_by_key(entity, ecs_key_audio_sink)) is Some(_) {
      return
    }
    if (try! world.get_by_key(entity, ecs_key_spatial_audio_sink)) is Some(_) {
      return
    }
    audio_play_pitch_entity(world, entity, player.value())
  })
}

///|
fn update_spatial_audio_sink_positions_system(world : @ecs.World) -> Unit {
  let ears = audio_listener_positions(world)
  let emitters : Array[(@core.Entity, SpatialAudioSink)] = []
  let sink_query : @ecs.Query[@ecs.Comp[SpatialAudioSink], @ecs.All] = @ecs.query(
    world,
  )
  try! sink_query.view(fn(entity, sink) {
    emitters.push((entity, sink.value()))
  })
  for emitter in emitters {
    let entity = emitter.0
    let sink = emitter.1
    guard spatial_audio_sink_registry_get(sink.sink_id) is Some(native_player) else {
      continue
    }
    let settings = audio_playback_settings_for_entity(world, entity)
    let default_scale = audio_default_spatial_scale(world).scale
    let scale = match settings.spatial_scale {
      Some(custom) => custom.scale
      None => default_scale
    }
    let transform = audio_entity_transform(world, entity)
    native_player.set_emitter_position(
      audio_vec3_to_native_tuple(audio_vec3_mul(transform.translation, scale)),
    )
    native_player.set_left_ear_position(
      audio_vec3_to_native_tuple(audio_vec3_mul(ears.0, scale)),
    )
    native_player.set_right_ear_position(
      audio_vec3_to_native_tuple(audio_vec3_mul(ears.1, scale)),
    )
  }
}

///|
fn cleanup_finished_audio_source_system(world : @ecs.World) -> Unit {
  let sinks : Array[(@core.Entity, AudioSink)] = []
  let spatial_sinks : Array[(@core.Entity, SpatialAudioSink)] = []
  let sink_query : @ecs.Query[@ecs.Comp[AudioSink], @ecs.All] = @ecs.query(
    world,
  )
  try! sink_query.view(fn(entity, sink) {
    if (try! world.get_by_key(entity, ecs_key_audio_source_player)) is Some(_) {
      sinks.push((entity, sink.value()))
    }
  })
  let spatial_sink_query : @ecs.Query[@ecs.Comp[SpatialAudioSink], @ecs.All] = @ecs.query(
    world,
  )
  try! spatial_sink_query.view(fn(entity, sink) {
    if (try! world.get_by_key(entity, ecs_key_audio_source_player)) is Some(_) {
      spatial_sinks.push((entity, sink.value()))
    }
  })
  for entry in sinks {
    let entity = entry.0
    let sink = entry.1
    if !sink.empty() {
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_despawn_marker))
      is Some(_) {
      audio_sink_registry_remove(sink.sink_id)
      try! world.despawn(entity)
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_remove_marker))
      is Some(_) {
      audio_sink_registry_remove(sink.sink_id)
      try! (world.remove_by_key(entity, ecs_key_audio_source_player) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_audio_sink) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_settings) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_remove_marker)
      |> ignore)
    }
  }
  for entry in spatial_sinks {
    let entity = entry.0
    let sink = entry.1
    if !sink.empty() {
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_despawn_marker))
      is Some(_) {
      spatial_audio_sink_registry_remove(sink.sink_id)
      try! world.despawn(entity)
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_remove_marker))
      is Some(_) {
      spatial_audio_sink_registry_remove(sink.sink_id)
      try! (world.remove_by_key(entity, ecs_key_audio_source_player) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_spatial_audio_sink) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_settings) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_remove_marker)
      |> ignore)
    }
  }
}

///|
fn cleanup_finished_pitch_system(world : @ecs.World) -> Unit {
  let sinks : Array[(@core.Entity, AudioSink)] = []
  let spatial_sinks : Array[(@core.Entity, SpatialAudioSink)] = []
  let sink_query : @ecs.Query[@ecs.Comp[AudioSink], @ecs.All] = @ecs.query(
    world,
  )
  try! sink_query.view(fn(entity, sink) {
    if (try! world.get_by_key(entity, ecs_key_pitch_player)) is Some(_) {
      sinks.push((entity, sink.value()))
    }
  })
  let spatial_sink_query : @ecs.Query[@ecs.Comp[SpatialAudioSink], @ecs.All] = @ecs.query(
    world,
  )
  try! spatial_sink_query.view(fn(entity, sink) {
    if (try! world.get_by_key(entity, ecs_key_pitch_player)) is Some(_) {
      spatial_sinks.push((entity, sink.value()))
    }
  })
  for entry in sinks {
    let entity = entry.0
    let sink = entry.1
    if !sink.empty() {
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_despawn_marker))
      is Some(_) {
      audio_sink_registry_remove(sink.sink_id)
      try! world.despawn(entity)
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_remove_marker))
      is Some(_) {
      audio_sink_registry_remove(sink.sink_id)
      try! (world.remove_by_key(entity, ecs_key_pitch_player) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_audio_sink) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_settings) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_remove_marker)
      |> ignore)
    }
  }
  for entry in spatial_sinks {
    let entity = entry.0
    let sink = entry.1
    if !sink.empty() {
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_despawn_marker))
      is Some(_) {
      spatial_audio_sink_registry_remove(sink.sink_id)
      try! world.despawn(entity)
      continue
    }
    if (try! world.get_by_key(entity, ecs_key_playback_remove_marker))
      is Some(_) {
      spatial_audio_sink_registry_remove(sink.sink_id)
      try! (world.remove_by_key(entity, ecs_key_pitch_player) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_spatial_audio_sink) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_settings) |> ignore)
      try! (world.remove_by_key(entity, ecs_key_playback_remove_marker)
      |> ignore)
    }
  }
}

///|
pub fn audio_playback_system(world : @ecs.World) -> Unit {
  if !audio_output_available(world) {
    return
  }
  play_queued_audio_source_system(world)
  play_queued_pitch_system(world)
  update_spatial_audio_sink_positions_system(world)
  cleanup_finished_audio_source_system(world)
  cleanup_finished_pitch_system(world)
}
