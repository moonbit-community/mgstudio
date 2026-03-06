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
pub fn NativeAudioStream::new_player(
  self : NativeAudioStream,
) -> NativeAudioPlayer {
  NativeAudioPlayer::{ player: @rodio.Player::connect_new(self.stream.mixer()) }
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
