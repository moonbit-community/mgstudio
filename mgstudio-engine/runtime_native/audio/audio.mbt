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
pub struct NativeAudioOutputDevice {
  name : String
  is_default : Bool
}

///|
pub struct NativeAudioInputDevice {
  name : String
}

///|
pub struct NativeAudioStream {
  stream : @rodio.OutputStream
}

///|
pub struct NativeAudioPlayer {
  player : @rodio.Player
}

///|
pub struct NativeSpatialAudioPlayer {
  player : @rodio.SpatialPlayer
}

///|
pub struct NativeAudioPlaybackConfig {
  looped : Bool
  start_position_seconds : Float?
  duration_seconds : Float?
}

///|
pub fn NativeAudioPlaybackConfig::default() -> NativeAudioPlaybackConfig {
  NativeAudioPlaybackConfig::{
    looped: false,
    start_position_seconds: None,
    duration_seconds: None,
  }
}

///|
pub fn NativeAudioPlaybackConfig::looped(
  self : NativeAudioPlaybackConfig,
  enabled : Bool,
) -> NativeAudioPlaybackConfig {
  NativeAudioPlaybackConfig::{ ..self, looped: enabled }
}

///|
pub fn NativeAudioPlaybackConfig::with_start_position_seconds(
  self : NativeAudioPlaybackConfig,
  seconds : Float,
) -> NativeAudioPlaybackConfig {
  NativeAudioPlaybackConfig::{
    ..self,
    start_position_seconds: Some(native_audio_non_negative_seconds(seconds)),
  }
}

///|
pub fn NativeAudioPlaybackConfig::with_duration_seconds(
  self : NativeAudioPlaybackConfig,
  seconds : Float,
) -> NativeAudioPlaybackConfig {
  NativeAudioPlaybackConfig::{
    ..self,
    duration_seconds: Some(native_audio_non_negative_seconds(seconds)),
  }
}

///|
fn native_audio_non_negative_seconds(seconds : Float) -> Float {
  if seconds <= 0.0F {
    0.0F
  } else {
    seconds
  }
}

///|
pub fn linear_to_db(linear : Double) -> Double {
  @rodio.linear_to_db(linear)
}

///|
pub fn db_to_linear(decibels : Double) -> Double {
  @rodio.db_to_linear(decibels)
}

///|
pub fn duration_from_seconds(seconds : Float) -> @cpal.Duration {
  let clamped = native_audio_non_negative_seconds(seconds)
  let secs = clamped.to_int()
  let whole = Float::from_double(secs.to_double())
  let nanos_float = (clamped - whole) * 1000000000.0F
  let nanos = if nanos_float <= 0.0F {
    0
  } else if nanos_float >= 999999999.0F {
    999999999
  } else {
    nanos_float.to_int()
  }
  @cpal.Duration::new(secs.to_uint64(), nanos)
}

///|
pub fn duration_to_seconds(duration : @cpal.Duration) -> Float {
  Float::from_uint64(duration.secs) +
  Float::from_double(duration.nanos.to_double()) / 1000000000.0F
}

///|
fn vec3_to_native(position : (Double, Double, Double)) -> Array[Double] {
  [position.0, position.1, position.2]
}

///|
fn native_audio_append_bytes_to_player(
  player : NativeAudioPlayer,
  bytes : Bytes,
  config : NativeAudioPlaybackConfig,
) -> Unit raise @rodio.DecoderError {
  let mut source : @rodio.DynSource = @rodio.to_dyn(@rodio.Decoder::new(bytes))
  match config.start_position_seconds {
    Some(seconds) =>
      source = @rodio.skip_duration(source, duration_from_seconds(seconds))
    None => ()
  }
  match config.duration_seconds {
    Some(seconds) =>
      source = @rodio.take_duration(source, duration_from_seconds(seconds))
    None => ()
  }
  if config.looped {
    source = @rodio.repeat_infinite(source)
  }
  player.player.append(source)
}

///|
fn native_audio_append_bytes_to_spatial_player(
  player : NativeSpatialAudioPlayer,
  bytes : Bytes,
  config : NativeAudioPlaybackConfig,
) -> Unit raise @rodio.DecoderError {
  let mut source : @rodio.DynSource = @rodio.to_dyn(@rodio.Decoder::new(bytes))
  match config.start_position_seconds {
    Some(seconds) =>
      source = @rodio.skip_duration(source, duration_from_seconds(seconds))
    None => ()
  }
  match config.duration_seconds {
    Some(seconds) =>
      source = @rodio.take_duration(source, duration_from_seconds(seconds))
    None => ()
  }
  if config.looped {
    source = @rodio.repeat_infinite(source)
  }
  player.player.append(source)
}

///|
fn native_audio_append_sine_to_player(
  player : NativeAudioPlayer,
  frequency : Float,
  duration_seconds : Float,
  looped : Bool,
) -> Unit {
  let base = @rodio.take_duration(
    @rodio.SineWave::new(frequency.to_double()),
    duration_from_seconds(duration_seconds),
  )
  let source = if looped {
    @rodio.repeat_infinite(base)
  } else {
    @rodio.to_dyn(base)
  }
  player.player.append(source)
}

///|
fn native_audio_append_sine_to_spatial_player(
  player : NativeSpatialAudioPlayer,
  frequency : Float,
  duration_seconds : Float,
  looped : Bool,
) -> Unit {
  let base = @rodio.take_duration(
    @rodio.SineWave::new(frequency.to_double()),
    duration_from_seconds(duration_seconds),
  )
  let source = if looped {
    @rodio.repeat_infinite(base)
  } else {
    @rodio.to_dyn(base)
  }
  player.player.append(source)
}

///|
pub fn available_host_ids() -> Array[@cpal.HostId] {
  @cpal.available_hosts()
}

///|
pub fn available_output_devices() -> Array[NativeAudioOutputDevice] raise @rodio.SpeakersListError {
  let outputs = @rodio.available_outputs()
  let devices : Array[NativeAudioOutputDevice] = []
  for output in outputs {
    devices.push(NativeAudioOutputDevice::{
      name: output.name(),
      is_default: output.is_default(),
    })
  }
  devices
}

///|
pub fn available_input_devices() -> Array[NativeAudioInputDevice] raise @rodio.MicrophoneListError {
  let inputs = @rodio.available_inputs()
  let devices : Array[NativeAudioInputDevice] = []
  for input in inputs {
    devices.push(NativeAudioInputDevice::{ name: input.name() })
  }
  devices
}

///|
pub fn open_default_output_stream() -> NativeAudioStream raise @rodio.StreamError {
  NativeAudioStream::{
    stream: @rodio.OutputStreamBuilder::open_default_stream(),
  }
}

///|
pub fn NativeAudioStream::mixer(self : NativeAudioStream) -> @rodio.Mixer {
  self.stream.mixer()
}

///|
pub fn NativeAudioStream::play_file(
  self : NativeAudioStream,
  path : String,
) -> NativeAudioPlayer raise @rodio.PlayError {
  NativeAudioPlayer::{ player: @rodio.play_file(self.stream.mixer(), path) }
}

///|
pub fn NativeAudioStream::play_bytes(
  self : NativeAudioStream,
  bytes : Bytes,
  config? : NativeAudioPlaybackConfig = NativeAudioPlaybackConfig::default(),
) -> NativeAudioPlayer raise @rodio.DecoderError {
  let player = NativeAudioPlayer::{
    player: @rodio.Player::connect_new(self.stream.mixer()),
  }
  native_audio_append_bytes_to_player(player, bytes, config)
  player
}

///|
pub fn NativeAudioStream::play_sine(
  self : NativeAudioStream,
  frequency : Float,
  duration_seconds : Float,
  looped? : Bool = false,
) -> NativeAudioPlayer {
  let player = NativeAudioPlayer::{
    player: @rodio.Player::connect_new(self.stream.mixer()),
  }
  native_audio_append_sine_to_player(
    player, frequency, duration_seconds, looped,
  )
  player
}

///|
pub fn NativeAudioStream::new_player(
  self : NativeAudioStream,
) -> NativeAudioPlayer {
  NativeAudioPlayer::{ player: @rodio.Player::connect_new(self.stream.mixer()) }
}

///|
pub fn NativeAudioStream::new_spatial_player(
  self : NativeAudioStream,
  emitter : (Double, Double, Double),
  left_ear : (Double, Double, Double),
  right_ear : (Double, Double, Double),
) -> NativeSpatialAudioPlayer {
  NativeSpatialAudioPlayer::{
    player: @rodio.SpatialPlayer::connect_new(
      self.stream.mixer(),
      vec3_to_native(emitter),
      vec3_to_native(left_ear),
      vec3_to_native(right_ear),
    ),
  }
}

///|
pub fn NativeAudioPlayer::append_bytes(
  self : NativeAudioPlayer,
  bytes : Bytes,
  config? : NativeAudioPlaybackConfig = NativeAudioPlaybackConfig::default(),
) -> Unit raise @rodio.DecoderError {
  native_audio_append_bytes_to_player(self, bytes, config)
}

///|
pub fn NativeAudioPlayer::append_sine(
  self : NativeAudioPlayer,
  frequency : Float,
  duration_seconds : Float,
  looped? : Bool = false,
) -> Unit {
  native_audio_append_sine_to_player(self, frequency, duration_seconds, looped)
}

///|
pub fn NativeAudioPlayer::pause(self : NativeAudioPlayer) -> Unit {
  self.player.pause()
}

///|
pub fn NativeAudioPlayer::play(self : NativeAudioPlayer) -> Unit {
  self.player.play()
}

///|
pub fn NativeAudioPlayer::stop(self : NativeAudioPlayer) -> Unit {
  self.player.stop()
}

///|
pub fn NativeAudioPlayer::clear(self : NativeAudioPlayer) -> Unit {
  self.player.clear()
}

///|
pub fn NativeAudioPlayer::empty(self : NativeAudioPlayer) -> Bool {
  self.player.empty()
}

///|
pub fn NativeAudioPlayer::is_paused(self : NativeAudioPlayer) -> Bool {
  self.player.is_paused()
}

///|
pub fn NativeAudioPlayer::set_volume(
  self : NativeAudioPlayer,
  volume : Double,
) -> Unit {
  self.player.set_volume(volume)
}

///|
pub fn NativeAudioPlayer::volume(self : NativeAudioPlayer) -> Double {
  self.player.volume()
}

///|
pub fn NativeAudioPlayer::set_speed(
  self : NativeAudioPlayer,
  speed : Double,
) -> Unit {
  self.player.set_speed(speed)
}

///|
pub fn NativeAudioPlayer::speed(self : NativeAudioPlayer) -> Double {
  self.player.speed()
}

///|
pub fn NativeAudioPlayer::position_seconds(self : NativeAudioPlayer) -> Float {
  duration_to_seconds(self.player.get_pos())
}

///|
pub fn NativeAudioPlayer::try_seek_seconds(
  self : NativeAudioPlayer,
  seconds : Float,
) -> Unit raise @rodio.SeekError {
  self.player.try_seek(duration_from_seconds(seconds))
}

///|
pub fn NativeSpatialAudioPlayer::append_bytes(
  self : NativeSpatialAudioPlayer,
  bytes : Bytes,
  config? : NativeAudioPlaybackConfig = NativeAudioPlaybackConfig::default(),
) -> Unit raise @rodio.DecoderError {
  native_audio_append_bytes_to_spatial_player(self, bytes, config)
}

///|
pub fn NativeSpatialAudioPlayer::append_sine(
  self : NativeSpatialAudioPlayer,
  frequency : Float,
  duration_seconds : Float,
  looped? : Bool = false,
) -> Unit {
  native_audio_append_sine_to_spatial_player(
    self, frequency, duration_seconds, looped,
  )
}

///|
pub fn NativeSpatialAudioPlayer::pause(self : NativeSpatialAudioPlayer) -> Unit {
  self.player.pause()
}

///|
pub fn NativeSpatialAudioPlayer::play(self : NativeSpatialAudioPlayer) -> Unit {
  self.player.play()
}

///|
pub fn NativeSpatialAudioPlayer::stop(self : NativeSpatialAudioPlayer) -> Unit {
  self.player.stop()
}

///|
pub fn NativeSpatialAudioPlayer::clear(self : NativeSpatialAudioPlayer) -> Unit {
  self.player.clear()
}

///|
pub fn NativeSpatialAudioPlayer::empty(self : NativeSpatialAudioPlayer) -> Bool {
  self.player.empty()
}

///|
pub fn NativeSpatialAudioPlayer::is_paused(
  self : NativeSpatialAudioPlayer,
) -> Bool {
  self.player.is_paused()
}

///|
pub fn NativeSpatialAudioPlayer::set_volume(
  self : NativeSpatialAudioPlayer,
  volume : Double,
) -> Unit {
  self.player.set_volume(volume)
}

///|
pub fn NativeSpatialAudioPlayer::volume(
  self : NativeSpatialAudioPlayer,
) -> Double {
  self.player.volume()
}

///|
pub fn NativeSpatialAudioPlayer::set_speed(
  self : NativeSpatialAudioPlayer,
  speed : Double,
) -> Unit {
  self.player.set_speed(speed)
}

///|
pub fn NativeSpatialAudioPlayer::speed(
  self : NativeSpatialAudioPlayer,
) -> Double {
  self.player.speed()
}

///|
pub fn NativeSpatialAudioPlayer::position_seconds(
  self : NativeSpatialAudioPlayer,
) -> Float {
  duration_to_seconds(self.player.get_pos())
}

///|
pub fn NativeSpatialAudioPlayer::try_seek_seconds(
  self : NativeSpatialAudioPlayer,
  seconds : Float,
) -> Unit raise @rodio.SeekError {
  self.player.try_seek(duration_from_seconds(seconds))
}

///|
pub fn NativeSpatialAudioPlayer::set_emitter_position(
  self : NativeSpatialAudioPlayer,
  emitter : (Double, Double, Double),
) -> Unit {
  self.player.set_emitter_position(vec3_to_native(emitter))
}

///|
pub fn NativeSpatialAudioPlayer::set_left_ear_position(
  self : NativeSpatialAudioPlayer,
  position : (Double, Double, Double),
) -> Unit {
  self.player.set_left_ear_position(vec3_to_native(position))
}

///|
pub fn NativeSpatialAudioPlayer::set_right_ear_position(
  self : NativeSpatialAudioPlayer,
  position : (Double, Double, Double),
) -> Unit {
  self.player.set_right_ear_position(vec3_to_native(position))
}
