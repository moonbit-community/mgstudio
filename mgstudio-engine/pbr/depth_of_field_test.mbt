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
test "render3d: PhysicalCameraParameters default and ev100 match Bevy semantics" {
  let params = PhysicalCameraParameters::default()
  debug_inspect(params.aperture_f_stops == 1.0F, content="true")
  debug_inspect(params.shutter_speed_s == 1.0F / 125.0F, content="true")
  debug_inspect(params.sensitivity_iso == 100.0F, content="true")
  debug_inspect(params.sensor_height == 0.01866F, content="true")
  debug_inspect((params.ev100() - 6.965784F).abs() < 0.0001F, content="true")
}

///|
test "render3d: Exposure and DepthOfField can be created from physical camera parameters" {
  let params = PhysicalCameraParameters::default()
  params.aperture_f_stops = 2.8F
  params.sensor_height = 0.024F

  let exposure = Exposure::from_physical_camera(params)
  debug_inspect(
    (exposure.exposure() - 0.00085034016F).abs() < 0.000001F,
    content="true",
  )

  let dof = DepthOfField::from_physical_camera(params)
  debug_inspect(dof.sensor_height == 0.024F, content="true")
  debug_inspect(dof.aperture_f_stops == 2.8F, content="true")
  debug_inspect(dof.focal_distance == 10.0F, content="true")
}

///|
test "render3d: DepthOfField default and direct field mutation align with Bevy component style" {
  let dof = DepthOfField::default()
  debug_inspect(dof.mode == DepthOfFieldMode::Gaussian, content="true")
  debug_inspect(dof.max_depth.is_inf(), content="true")

  dof.mode = DepthOfFieldMode::Bokeh
  dof.focal_distance = 4.0F
  dof.sensor_height = 0.021F
  dof.aperture_f_stops = 1.4F
  dof.max_circle_of_confusion_diameter = 32.0F
  dof.max_depth = 75.0F

  debug_inspect(dof.mode == DepthOfFieldMode::Bokeh, content="true")
  debug_inspect(dof.focal_distance == 4.0F, content="true")
  debug_inspect(dof.sensor_height == 0.021F, content="true")
  debug_inspect(dof.aperture_f_stops == 1.4F, content="true")
  debug_inspect(dof.max_circle_of_confusion_diameter == 32.0F, content="true")
  debug_inspect(dof.max_depth == 75.0F, content="true")
}
