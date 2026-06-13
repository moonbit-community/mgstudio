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
// Bevy source: `bevy/crates/bevy_camera/src/exposure.rs`.

///|
const EXPOSURE_EV100_SUNLIGHT : Float = 15.0F

///|
const EXPOSURE_EV100_OVERCAST : Float = 12.0F

///|
const EXPOSURE_EV100_INDOOR : Float = 7.0F

///|
const EXPOSURE_EV100_BLENDER : Float = 9.7F

///|
/// Camera exposure settings aligned with Bevy's `Exposure`.
pub struct Exposure {
  ev100 : Float
} derive(ToJson, FromJson)

///|
pub fn Exposure::Exposure() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_BLENDER }
}

///|
pub fn Exposure::new(ev100 : Float) -> Exposure {
  Exposure::{ ev100, }
}

///|
pub fn Exposure::sunlight() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_SUNLIGHT }
}

///|
pub fn Exposure::overcast() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_OVERCAST }
}

///|
pub fn Exposure::indoor() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_INDOOR }
}

///|
pub fn Exposure::blender() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_BLENDER }
}

///|
pub fn Exposure::from_physical_camera(
  physical_camera_parameters : PhysicalCameraParameters,
) -> Exposure {
  Exposure::new(physical_camera_parameters.ev100())
}

///|
pub fn Exposure::with_ev100(self : Exposure, ev100 : Float) -> Exposure {
  self |> ignore
  Exposure::{ ev100, }
}

///|
pub fn Exposure::exposure(self : Exposure) -> Float {
  @math.pow(2.0F, -self.ev100) / 1.2F
}

///|
pub let ecs_key_exposure : @ecs.ComponentKey[Exposure] = @ecs.register_component(
  debug_name="camera.exposure",
)

///|
pub impl @ecs.Component for Exposure with fn component() {
  ecs_key_exposure
}

///|
fn camera_log2(value : Float) -> Float {
  if value <= 0.0F {
    return @float.neg_infinity
  }
  let mut normalized = value
  let mut exponent = 0.0F
  while normalized < 1.0F {
    normalized = normalized * 2.0F
    exponent = exponent - 1.0F
  }
  while normalized >= 2.0F {
    normalized = normalized / 2.0F
    exponent = exponent + 1.0F
  }
  let mut fraction = 0.0F
  let mut factor = 0.5F
  let mut current = normalized
  for _ in 0..<16 {
    current = current * current
    if current >= 2.0F {
      current = current / 2.0F
      fraction = fraction + factor
    }
    factor = factor / 2.0F
  }
  exponent + fraction
}

///|
/// Physical camera parameters aligned with Bevy's `PhysicalCameraParameters`.
pub(all) struct PhysicalCameraParameters {
  mut aperture_f_stops : Float
  mut shutter_speed_s : Float
  mut sensitivity_iso : Float
  mut sensor_height : Float
} derive(ToJson, FromJson)

///|
pub fn PhysicalCameraParameters::PhysicalCameraParameters() -> PhysicalCameraParameters {
  PhysicalCameraParameters::{
    aperture_f_stops: 1.0F,
    shutter_speed_s: 1.0F / 125.0F,
    sensitivity_iso: 100.0F,
    sensor_height: 0.01866F,
  }
}

///|
pub fn PhysicalCameraParameters::ev100(
  self : PhysicalCameraParameters,
) -> Float {
  let numerator = self.aperture_f_stops * self.aperture_f_stops * 100.0F
  let denominator = self.shutter_speed_s * self.sensitivity_iso
  camera_log2(numerator / denominator)
}
