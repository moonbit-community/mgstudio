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
pub(all) enum DepthOfFieldMode {
  Bokeh
  Gaussian
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn DepthOfFieldMode::default() -> DepthOfFieldMode {
  Gaussian
}

///|
/// API-parity data model aligned with Bevy's `DepthOfField` camera component.
pub(all) struct DepthOfField {
  mut mode : DepthOfFieldMode
  mut focal_distance : Float
  mut sensor_height : Float
  mut aperture_f_stops : Float
  mut max_circle_of_confusion_diameter : Float
  mut max_depth : Float
} derive(ToJson, FromJson)

///|
pub fn DepthOfField::DepthOfField() -> DepthOfField {
  {
    mode: DepthOfFieldMode::default(),
    focal_distance: 10.0F,
    sensor_height: @camera_camera.PhysicalCameraParameters::PhysicalCameraParameters().sensor_height,
    aperture_f_stops: 4.0F,
    max_circle_of_confusion_diameter: 64.0F,
    max_depth: @float.infinity,
  }
}

///|
pub fn DepthOfField::from_physical_camera(
  camera : @camera_camera.PhysicalCameraParameters,
) -> DepthOfField {
  let depth_of_field = DepthOfField::DepthOfField()
  depth_of_field.sensor_height = camera.sensor_height
  depth_of_field.aperture_f_stops = camera.aperture_f_stops
  depth_of_field
}

///|
pub struct DepthOfFieldUniform {
  mode : DepthOfFieldMode
  focal_distance : Float
  sensor_height : Float
  aperture_f_stops : Float
  max_circle_of_confusion_diameter : Float
  max_depth : Float
  coc_scale_factor : Float
} derive(ToJson, FromJson)

///|
pub fn DepthOfFieldUniform::from_settings(
  settings : DepthOfField,
) -> DepthOfFieldUniform {
  let denominator = settings.sensor_height * settings.aperture_f_stops
  let coc_scale_factor = if denominator <= 0.0F {
    0.0F
  } else {
    settings.focal_distance * settings.focal_distance / denominator
  }
  {
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
  camera : @camera_camera.PhysicalCameraParameters,
) -> DepthOfField {
  DepthOfField::from_physical_camera(camera)
}

///|
pub let ecs_key_depth_of_field : @ecs.ComponentKey[DepthOfField] = @ecs.register_component(
  debug_name="render3d.depth_of_field",
)

///|
pub impl @ecs.Component for DepthOfField with fn component() {
  ecs_key_depth_of_field
}
