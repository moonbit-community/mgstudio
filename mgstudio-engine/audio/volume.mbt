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
pub struct GlobalVolume {
  volume : Volume
}

///|
pub fn GlobalVolume::new(volume : Volume) -> GlobalVolume {
  GlobalVolume::{ volume, }
}

///|
pub fn GlobalVolume::default() -> GlobalVolume {
  GlobalVolume::new(Volume::default())
}

///|
let global_volume_resource : Ref[@core.Resource[GlobalVolume]] = Ref::new(
  @core.Resource::new(),
)

///|
pub impl @app.Resource for GlobalVolume with resource() {
  global_volume_resource.val
}

///|
pub(all) enum Volume {
  Linear(Float)
  Decibels(Float)
}

///|
pub fn Volume::default() -> Volume {
  Volume::Linear(1.0F)
}

///|
pub fn Volume::silent() -> Volume {
  Volume::Linear(0.0F)
}

///|
pub fn Volume::to_linear(self : Volume) -> Float {
  match self {
    Linear(value) => if value < 0.0F { 0.0F - value } else { value }
    Decibels(value) =>
      Float::from_double(@native_audio.db_to_linear(value.to_double()))
  }
}

///|
pub fn Volume::to_decibels(self : Volume) -> Float {
  match self {
    Linear(value) =>
      if value == 0.0F {
        Float::from_double(-1.0 / 0.0)
      } else {
        Float::from_double(
          @native_audio.linear_to_db(self.to_linear().to_double()),
        )
      }
    Decibels(value) => value
  }
}

///|
pub fn Volume::increase_by_percentage(
  self : Volume,
  percentage : Float,
) -> Volume {
  let factor = 1.0F + percentage / 100.0F
  Volume::Linear(self.to_linear() * factor)
}

///|
pub fn Volume::decrease_by_percentage(
  self : Volume,
  percentage : Float,
) -> Volume {
  let clamped = if percentage < 0.0F {
    0.0F
  } else if percentage > 100.0F {
    100.0F
  } else {
    percentage
  }
  let factor = 1.0F - clamped / 100.0F
  Volume::Linear(self.to_linear() * factor)
}

///|
pub fn Volume::scale_to_factor(self : Volume, factor : Float) -> Volume {
  Volume::Linear(self.to_linear() * factor)
}

///|
pub fn Volume::mul(self : Volume, other : Volume) -> Volume {
  Volume::Linear(self.to_linear() * other.to_linear())
}

///|
pub impl ToJson for Volume with to_json(self) {
  match self {
    Linear(value) => ("linear", value).to_json()
    Decibels(value) => ("decibels", value).to_json()
  }
}

///|
pub impl @json.FromJson for Volume with from_json(json, path) {
  let (kind, value) : (String, Float) = @json.from_json(json, path~)
  match kind {
    "linear" => Volume::Linear(value)
    "decibels" => Volume::Decibels(value)
    _ => Volume::Linear(value)
  }
}

///|
pub impl ToJson for GlobalVolume with to_json(self) {
  self.volume.to_json()
}

///|
pub impl @json.FromJson for GlobalVolume with from_json(json, path) {
  GlobalVolume::{ volume: @json.from_json(json, path~) }
}
