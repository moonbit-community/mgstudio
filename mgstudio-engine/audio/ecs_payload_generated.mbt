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
extenum @ecs.EcsPayload += {
  EcsPayload_audio_AudioSourceAssetPaths(AudioSourceAssetPaths)
  EcsPayload_audio_AudioSource(AudioSource)
  EcsPayload_audio_AudioPlayer(AudioPlayerPayload)
  EcsPayload_audio_GlobalVolume(GlobalVolume)
  EcsPayload_audio_AudioOutput(AudioOutput)
  EcsPayload_audio_PlaybackSettings(PlaybackSettings)
  EcsPayload_audio_SpatialListener(SpatialListener)
  EcsPayload_audio_AudioSink(AudioSink)
  EcsPayload_audio_SpatialAudioSink(SpatialAudioSink)
  EcsPayload_audio_PlaybackDespawnMarker(PlaybackDespawnMarker)
  EcsPayload_audio_PlaybackRemoveMarker(PlaybackRemoveMarker)
  EcsPayload_audio_DefaultSpatialScale(DefaultSpatialScale)
  EcsPayload_audio_Pitch(Pitch)
}

///|
pub(all) struct AudioPlayerPayload {
  source_id : Int
}

///|
impl @ecs.EcsPayloadCodec for AudioSourceAssetPaths with to_ecs_payload(self) {
  EcsPayload_audio_AudioSourceAssetPaths(self)
}

///|
impl @ecs.EcsPayloadCodec for AudioSourceAssetPaths with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_audio_AudioSourceAssetPaths(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AudioSource with to_ecs_payload(self) {
  EcsPayload_audio_AudioSource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AudioSource with from_ecs_payload(payload) {
  match payload {
    EcsPayload_audio_AudioSource(value) => Some(value)
    _ => None
  }
}

///|
pub impl[Source] @ecs.EcsPayloadCodec for AudioPlayer[Source] with to_ecs_payload(
  self,
) {
  EcsPayload_audio_AudioPlayer(AudioPlayerPayload::{
    source_id: self.source.id(),
  })
}

///|
pub impl[Source] @ecs.EcsPayloadCodec for AudioPlayer[Source] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_audio_AudioPlayer(value) =>
      Some(AudioPlayer::{ source: @asset.Handle::new(value.source_id) })
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalVolume with to_ecs_payload(self) {
  EcsPayload_audio_GlobalVolume(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalVolume with from_ecs_payload(payload) {
  match payload {
    EcsPayload_audio_GlobalVolume(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AudioOutput with to_ecs_payload(self) {
  EcsPayload_audio_AudioOutput(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AudioOutput with from_ecs_payload(payload) {
  match payload {
    EcsPayload_audio_AudioOutput(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PlaybackSettings with to_ecs_payload(self) {
  EcsPayload_audio_PlaybackSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PlaybackSettings with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_audio_PlaybackSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpatialListener with to_ecs_payload(self) {
  EcsPayload_audio_SpatialListener(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpatialListener with from_ecs_payload(payload) {
  match payload {
    EcsPayload_audio_SpatialListener(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AudioSink with to_ecs_payload(self) {
  EcsPayload_audio_AudioSink(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AudioSink with from_ecs_payload(payload) {
  match payload {
    EcsPayload_audio_AudioSink(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpatialAudioSink with to_ecs_payload(self) {
  EcsPayload_audio_SpatialAudioSink(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpatialAudioSink with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_audio_SpatialAudioSink(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PlaybackDespawnMarker with to_ecs_payload(
  self,
) {
  EcsPayload_audio_PlaybackDespawnMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PlaybackDespawnMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_audio_PlaybackDespawnMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PlaybackRemoveMarker with to_ecs_payload(self) {
  EcsPayload_audio_PlaybackRemoveMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PlaybackRemoveMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_audio_PlaybackRemoveMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DefaultSpatialScale with to_ecs_payload(self) {
  EcsPayload_audio_DefaultSpatialScale(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DefaultSpatialScale with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_audio_DefaultSpatialScale(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Pitch with to_ecs_payload(self) {
  EcsPayload_audio_Pitch(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Pitch with from_ecs_payload(payload) {
  match payload {
    EcsPayload_audio_Pitch(value) => Some(value)
    _ => None
  }
}
