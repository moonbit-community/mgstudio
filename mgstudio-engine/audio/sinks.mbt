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
let audio_sink_registry : Ref[Array[@native_audio.NativeAudioPlayer?]] = Ref::new([],
)

///|
let spatial_audio_sink_registry : Ref[
  Array[@native_audio.NativeSpatialAudioPlayer?],
] = Ref::new([])

///|
fn audio_sink_registry_insert(player : @native_audio.NativeAudioPlayer) -> Int {
  let id = audio_sink_registry.val.length()
  audio_sink_registry.val.push(Some(player))
  id
}

///|
fn spatial_audio_sink_registry_insert(
  player : @native_audio.NativeSpatialAudioPlayer,
) -> Int {
  let id = spatial_audio_sink_registry.val.length()
  spatial_audio_sink_registry.val.push(Some(player))
  id
}

///|
fn audio_sink_registry_get(id : Int) -> @native_audio.NativeAudioPlayer? {
  if id < 0 || id >= audio_sink_registry.val.length() {
    None
  } else {
    audio_sink_registry.val[id]
  }
}

///|
fn spatial_audio_sink_registry_get(
  id : Int,
) -> @native_audio.NativeSpatialAudioPlayer? {
  if id < 0 || id >= spatial_audio_sink_registry.val.length() {
    None
  } else {
    spatial_audio_sink_registry.val[id]
  }
}

///|
fn audio_sink_registry_remove(id : Int) -> Unit {
  if id >= 0 && id < audio_sink_registry.val.length() {
    audio_sink_registry.val[id] = None
  }
}

///|
fn spatial_audio_sink_registry_remove(id : Int) -> Unit {
  if id >= 0 && id < spatial_audio_sink_registry.val.length() {
    spatial_audio_sink_registry.val[id] = None
  }
}

///|
pub(open) trait AudioSinkPlayback {
  volume(self : Self) -> Volume
  set_volume(self : Self, volume : Volume) -> Self
  speed(self : Self) -> Float
  set_speed(self : Self, speed : Float) -> Self
  play(self : Self) -> Unit
  position(self : Self) -> @core.Duration
  try_seek(self : Self, position : @core.Duration) -> Bool
  pause(self : Self) -> Unit
  is_paused(self : Self) -> Bool
  stop(self : Self) -> Unit
  empty(self : Self) -> Bool
  is_muted(self : Self) -> Bool
  mute(self : Self) -> Self
  unmute(self : Self) -> Self
}

///|
pub struct AudioSink {
  sink_id : Int
  managed_volume : Volume?
} derive(ToJson, FromJson)

///|
pub struct SpatialAudioSink {
  sink_id : Int
  managed_volume : Volume?
} derive(ToJson, FromJson)

///|
fn audio_sink_from_native(
  player : @native_audio.NativeAudioPlayer,
) -> AudioSink {
  AudioSink::{
    sink_id: audio_sink_registry_insert(player),
    managed_volume: None,
  }
}

///|
fn spatial_audio_sink_from_native(
  player : @native_audio.NativeSpatialAudioPlayer,
) -> SpatialAudioSink {
  SpatialAudioSink::{
    sink_id: spatial_audio_sink_registry_insert(player),
    managed_volume: None,
  }
}

///|
fn audio_sink_live_volume(sink : AudioSink) -> Volume {
  match sink.managed_volume {
    Some(volume) => volume
    None =>
      match audio_sink_registry_get(sink.sink_id) {
        Some(player) => Volume::Linear(Float::from_double(player.volume()))
        None => Volume::default()
      }
  }
}

///|
fn spatial_audio_sink_live_volume(sink : SpatialAudioSink) -> Volume {
  match sink.managed_volume {
    Some(volume) => volume
    None =>
      match spatial_audio_sink_registry_get(sink.sink_id) {
        Some(player) => Volume::Linear(Float::from_double(player.volume()))
        None => Volume::default()
      }
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with volume(self) {
  audio_sink_live_volume(self)
}

///|
pub impl AudioSinkPlayback for AudioSink with set_volume(self, volume) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) =>
      if self.managed_volume is Some(_) {
        AudioSink::{ ..self, managed_volume: Some(volume) }
      } else {
        player.set_volume(volume.to_linear().to_double())
        AudioSink::{ ..self, managed_volume: None }
      }
    None => AudioSink::{ ..self, managed_volume: Some(volume) }
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with speed(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => Float::from_double(player.speed())
    None => 1.0F
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with set_speed(self, speed) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => player.set_speed(speed.to_double())
    None => ()
  }
  self
}

///|
pub impl AudioSinkPlayback for AudioSink with play(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => player.play()
    None => ()
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with position(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => @core.Duration::from_secs_f32(player.position_seconds())
    None => @core.Duration::zero()
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with try_seek(self, position) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => {
      player.try_seek_seconds(position.as_secs_f32()) catch {
        _ => return false
      }
      true
    }
    None => false
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with pause(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => player.pause()
    None => ()
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with is_paused(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => player.is_paused()
    None => false
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with stop(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => player.stop()
    None => ()
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with empty(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => player.empty()
    None => true
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with is_muted(self) {
  self.managed_volume is Some(_)
}

///|
pub impl AudioSinkPlayback for AudioSink with mute(self) {
  match audio_sink_registry_get(self.sink_id) {
    Some(player) => {
      let remembered = self.volume()
      player.set_volume(0.0)
      AudioSink::{ ..self, managed_volume: Some(remembered) }
    }
    None => self
  }
}

///|
pub impl AudioSinkPlayback for AudioSink with unmute(self) {
  match self.managed_volume {
    Some(volume) => {
      match audio_sink_registry_get(self.sink_id) {
        Some(player) => player.set_volume(volume.to_linear().to_double())
        None => ()
      }
      AudioSink::{ ..self, managed_volume: None }
    }
    None => self
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with volume(self) {
  spatial_audio_sink_live_volume(self)
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with set_volume(self, volume) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) =>
      if self.managed_volume is Some(_) {
        SpatialAudioSink::{ ..self, managed_volume: Some(volume) }
      } else {
        player.set_volume(volume.to_linear().to_double())
        SpatialAudioSink::{ ..self, managed_volume: None }
      }
    None => SpatialAudioSink::{ ..self, managed_volume: Some(volume) }
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with speed(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => Float::from_double(player.speed())
    None => 1.0F
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with set_speed(self, speed) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => player.set_speed(speed.to_double())
    None => ()
  }
  self
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with play(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => player.play()
    None => ()
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with position(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => @core.Duration::from_secs_f32(player.position_seconds())
    None => @core.Duration::zero()
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with try_seek(self, position) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => {
      player.try_seek_seconds(position.as_secs_f32()) catch {
        _ => return false
      }
      true
    }
    None => false
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with pause(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => player.pause()
    None => ()
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with is_paused(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => player.is_paused()
    None => false
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with stop(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => player.stop()
    None => ()
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with empty(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => player.empty()
    None => true
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with is_muted(self) {
  self.managed_volume is Some(_)
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with mute(self) {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => {
      let remembered = self.volume()
      player.set_volume(0.0)
      SpatialAudioSink::{ ..self, managed_volume: Some(remembered) }
    }
    None => self
  }
}

///|
pub impl AudioSinkPlayback for SpatialAudioSink with unmute(self) {
  match self.managed_volume {
    Some(volume) => {
      match spatial_audio_sink_registry_get(self.sink_id) {
        Some(player) => player.set_volume(volume.to_linear().to_double())
        None => ()
      }
      SpatialAudioSink::{ ..self, managed_volume: None }
    }
    None => self
  }
}

///|
pub fn AudioSink::toggle_playback(self : AudioSink) -> Unit {
  if self.is_paused() {
    self.play()
  } else {
    self.pause()
  }
}

///|
pub fn AudioSink::toggle_mute(self : AudioSink) -> AudioSink {
  if self.is_muted() {
    self.unmute()
  } else {
    self.mute()
  }
}

///|
pub fn SpatialAudioSink::toggle_playback(self : SpatialAudioSink) -> Unit {
  if self.is_paused() {
    self.play()
  } else {
    self.pause()
  }
}

///|
pub fn SpatialAudioSink::toggle_mute(
  self : SpatialAudioSink,
) -> SpatialAudioSink {
  if self.is_muted() {
    self.unmute()
  } else {
    self.mute()
  }
}

///|
pub fn AudioSink::position_seconds(self : AudioSink) -> Float {
  self.position().as_secs_f32()
}

///|
pub fn AudioSink::try_seek_seconds(self : AudioSink, seconds : Float) -> Bool {
  self.try_seek(@core.Duration::from_secs_f32(seconds))
}

///|
pub fn SpatialAudioSink::position_seconds(self : SpatialAudioSink) -> Float {
  self.position().as_secs_f32()
}

///|
pub fn SpatialAudioSink::try_seek_seconds(
  self : SpatialAudioSink,
  seconds : Float,
) -> Bool {
  self.try_seek(@core.Duration::from_secs_f32(seconds))
}

///|
pub fn SpatialAudioSink::set_ears_position(
  self : SpatialAudioSink,
  left_position : @math.Vec3,
  right_position : @math.Vec3,
) -> Unit {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) => {
      player.set_left_ear_position(
        (
          left_position.x.to_double(),
          left_position.y.to_double(),
          left_position.z.to_double(),
        ),
      )
      player.set_right_ear_position(
        (
          right_position.x.to_double(),
          right_position.y.to_double(),
          right_position.z.to_double(),
        ),
      )
    }
    None => ()
  }
}

///|
pub fn SpatialAudioSink::set_listener_position(
  self : SpatialAudioSink,
  position : @math.Transform,
  gap : Float,
) -> Unit {
  let half_gap = gap / 2.0F
  self.set_ears_position(
    @math.Vec3::new(
      position.translation.x - half_gap,
      position.translation.y,
      position.translation.z,
    ),
    @math.Vec3::new(
      position.translation.x + half_gap,
      position.translation.y,
      position.translation.z,
    ),
  )
}

///|
pub fn SpatialAudioSink::set_emitter_position(
  self : SpatialAudioSink,
  position : @math.Vec3,
) -> Unit {
  match spatial_audio_sink_registry_get(self.sink_id) {
    Some(player) =>
      player.set_emitter_position(
        (position.x.to_double(), position.y.to_double(), position.z.to_double()),
      )
    None => ()
  }
}
