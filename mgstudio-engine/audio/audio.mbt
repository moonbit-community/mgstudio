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
pub(all) enum PlaybackMode {
  Once
  Loop
  Despawn
  Remove
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct PlaybackSettings {
  mode : PlaybackMode
  volume : Volume
  speed : Float
  paused : Bool
  muted : Bool
  spatial : Bool
  spatial_scale : SpatialScale?
  start_position : @core.Duration?
  duration : @core.Duration?
} derive(ToJson, FromJson)

///|
pub fn PlaybackSettings::default() -> PlaybackSettings {
  PlaybackSettings::once()
}

///|
pub fn PlaybackSettings::once() -> PlaybackSettings {
  PlaybackSettings::{
    mode: PlaybackMode::Once,
    volume: Volume::default(),
    speed: 1.0F,
    paused: false,
    muted: false,
    spatial: false,
    spatial_scale: None,
    start_position: None,
    duration: None,
  }
}

///|
pub fn PlaybackSettings::looped() -> PlaybackSettings {
  PlaybackSettings::{ ..PlaybackSettings::once(), mode: PlaybackMode::Loop }
}

///|
pub fn PlaybackSettings::despawn() -> PlaybackSettings {
  PlaybackSettings::{ ..PlaybackSettings::once(), mode: PlaybackMode::Despawn }
}

///|
pub fn PlaybackSettings::remove() -> PlaybackSettings {
  PlaybackSettings::{ ..PlaybackSettings::once(), mode: PlaybackMode::Remove }
}

///|
pub fn PlaybackSettings::paused(self : PlaybackSettings) -> PlaybackSettings {
  PlaybackSettings::{ ..self, paused: true }
}

///|
pub fn PlaybackSettings::muted(self : PlaybackSettings) -> PlaybackSettings {
  PlaybackSettings::{ ..self, muted: true }
}

///|
pub fn PlaybackSettings::with_volume(
  self : PlaybackSettings,
  volume : Volume,
) -> PlaybackSettings {
  PlaybackSettings::{ ..self, volume, }
}

///|
pub fn PlaybackSettings::with_speed(
  self : PlaybackSettings,
  speed : Float,
) -> PlaybackSettings {
  PlaybackSettings::{ ..self, speed, }
}

///|
pub fn PlaybackSettings::with_spatial(
  self : PlaybackSettings,
  spatial : Bool,
) -> PlaybackSettings {
  PlaybackSettings::{ ..self, spatial, }
}

///|
pub fn PlaybackSettings::with_spatial_scale(
  self : PlaybackSettings,
  spatial_scale : SpatialScale,
) -> PlaybackSettings {
  PlaybackSettings::{ ..self, spatial_scale: Some(spatial_scale) }
}

///|
pub fn PlaybackSettings::with_start_position(
  self : PlaybackSettings,
  start_position : @core.Duration,
) -> PlaybackSettings {
  PlaybackSettings::{ ..self, start_position: Some(start_position) }
}

///|
pub fn PlaybackSettings::with_duration(
  self : PlaybackSettings,
  duration : @core.Duration,
) -> PlaybackSettings {
  PlaybackSettings::{ ..self, duration: Some(duration) }
}

///|
pub struct SpatialListener {
  left_ear_offset : @math.Vec3
  right_ear_offset : @math.Vec3
} derive(ToJson, FromJson)

///|
pub fn SpatialListener::new(gap : Float) -> SpatialListener {
  let half_gap = gap / 2.0F
  SpatialListener::{
    left_ear_offset: @math.Vec3::new(0.0F - half_gap, 0.0F, 0.0F),
    right_ear_offset: @math.Vec3::new(half_gap, 0.0F, 0.0F),
  }
}

///|
pub fn SpatialListener::default() -> SpatialListener {
  SpatialListener::new(4.0F)
}

///|
pub struct SpatialScale {
  scale : @math.Vec3
} derive(ToJson, FromJson)

///|
pub fn SpatialScale::new(scale : Float) -> SpatialScale {
  SpatialScale::{ scale: @math.Vec3::splat(scale) }
}

///|
pub fn SpatialScale::new_2d(scale : Float) -> SpatialScale {
  SpatialScale::{ scale: @math.Vec3::new(scale, scale, 0.0F) }
}

///|
pub fn SpatialScale::default() -> SpatialScale {
  SpatialScale::new(1.0F)
}

///|
pub struct DefaultSpatialScale {
  scale : SpatialScale
} derive(ToJson, FromJson)

///|
pub fn DefaultSpatialScale::new(scale : SpatialScale) -> DefaultSpatialScale {
  DefaultSpatialScale::{ scale, }
}

///|
pub fn DefaultSpatialScale::default() -> DefaultSpatialScale {
  DefaultSpatialScale::new(SpatialScale::default())
}

///|
fn[T] audio_resource_get(world : @ecs.World, key : @ecs.ResourceKey[T]) -> T? {
  try world.get_resource(key) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn[T] audio_resource_ref_mut(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  sequence : @core.Sequence,
) -> Ref[T]? {
  try world.get_resource_ref_mut(key, sequence) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn[T] audio_resource_ensure_ref_mut(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  init : () -> T,
  sequence : @core.Sequence,
) -> Ref[T] {
  if (try world.get_resource(key) catch {
      _ => None
    } noraise {
      value => value
    })
    is None {
    world.insert_resource_with_sequence(key, init(), sequence)
  }
  match audio_resource_ref_mut(world, key, sequence) {
    Some(value) => value
    None => abort("Missing audio resource after initialization")
  }
}

///|
let default_spatial_scale_resource_key : @ecs.ResourceKey[DefaultSpatialScale] = @ecs.register_resource(
  debug_name="bevy_audio::DefaultSpatialScale",
)

///|
pub impl @app.Resource for DefaultSpatialScale with resource() {
  default_spatial_scale_resource_key
}

///|
pub struct AudioPlayer[Source] {
  source : @asset.Handle[Source]
}

///|
pub fn[Source] AudioPlayer::new(
  source : @asset.Handle[Source],
) -> AudioPlayer[Source] {
  AudioPlayer::{ source, }
}

///|
pub fn[Source] AudioPlayer::handle(
  self : AudioPlayer[Source],
) -> @asset.Handle[Source] {
  self.source
}

///|
pub impl[Source] ToJson for AudioPlayer[Source] with to_json(self) {
  self.source.to_json()
}

///|
pub impl[Source] @json.FromJson for AudioPlayer[Source] with from_json(
  json,
  path,
) {
  AudioPlayer::{ source: @json.from_json(json, path~) }
}

///|
pub struct AudioPlugin {
  global_volume : GlobalVolume
  default_spatial_scale : SpatialScale
}

///|
pub fn AudioPlugin::default() -> AudioPlugin {
  AudioPlugin::{
    global_volume: GlobalVolume::default(),
    default_spatial_scale: SpatialScale::default(),
  }
}

///|
pub fn audio_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  audio_plugin_with(app, AudioPlugin::default())
}

///|
pub fn audio_plugin_with(
  app : @app.App[@ecs.World],
  plugin : AudioPlugin,
) -> @app.App[@ecs.World] {
  @asset.asset_register_loader(fn(asset_server, path) {
    audio_source_load_registered(asset_server, path)
  })
  app
  .insert_resource(plugin.global_volume)
  .insert_resource(DefaultSpatialScale::new(plugin.default_spatial_scale))
  .init_resource(fn() { AudioOutput::default() })
  .init_resource(fn() { AudioSourceAssets::new() })
  .init_resource(fn() { PitchAssets::new() })
  .add_post_update_system(audio_playback_system)
}
