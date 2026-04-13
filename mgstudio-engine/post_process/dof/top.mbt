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
// Bevy source: `bevy/crates/bevy_post_process/src/dof/mod.rs`.

///|
pub struct DepthOfFieldUniform {
  mode : @pbr.DepthOfFieldMode
  focal_distance : Float
  sensor_height : Float
  aperture_f_stops : Float
  max_circle_of_confusion_diameter : Float
  max_depth : Float
  coc_scale_factor : Float
} derive(ToJson, FromJson)

///|
pub fn DepthOfFieldUniform::from_settings(
  settings : @pbr.DepthOfField,
) -> DepthOfFieldUniform {
  let denominator = settings.sensor_height * settings.aperture_f_stops
  let coc_scale_factor = if denominator <= 0.0F {
    0.0F
  } else {
    settings.focal_distance * settings.focal_distance / denominator
  }
  DepthOfFieldUniform::{
    mode: settings.mode,
    focal_distance: settings.focal_distance,
    sensor_height: settings.sensor_height,
    aperture_f_stops: settings.aperture_f_stops,
    max_circle_of_confusion_diameter: settings.max_circle_of_confusion_diameter,
    max_depth: settings.max_depth,
    coc_scale_factor,
  }
}

///|
pub fn depth_of_field_from_physical_camera(
  camera : @pbr.PhysicalCameraParameters,
) -> @pbr.DepthOfField {
  @pbr.DepthOfField::from_physical_camera(camera)
}
