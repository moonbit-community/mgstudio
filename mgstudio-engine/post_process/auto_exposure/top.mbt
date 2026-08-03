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
// Bevy source: `bevy/crates/bevy_post_process/src/auto_exposure/mod.rs`.

///|
pub type PhysicalCameraParameters = @camera_camera.PhysicalCameraParameters

///|
pub fn auto_exposure_default() -> AutoExposure {
  AutoExposure()
}

///|
pub fn auto_exposure_new(
  min_luminance : Float,
  max_luminance : Float,
) -> AutoExposure {
  AutoExposure::new(min_luminance, max_luminance)
}

///|
pub fn auto_exposure_with_range(
  auto_exposure : AutoExposure,
  min_luminance : Float,
  max_luminance : Float,
) -> AutoExposure {
  auto_exposure.with_range(min_luminance, max_luminance)
}

///|
pub fn auto_exposure_compensation_curve_default() -> AutoExposureCompensationCurve {
  AutoExposureCompensationCurve()
}

///|
pub fn[T : AutoExposureCompensationCurveSource] auto_exposure_compensation_curve_from_curve(
  source : T,
) -> AutoExposureCompensationCurve raise AutoExposureCompensationCurveError {
  AutoExposureCompensationCurve::from_curve(source)
}

///|
pub fn physical_camera_parameters_default() -> @camera_camera.PhysicalCameraParameters {
  PhysicalCameraParameters()
}

///|
pub fn physical_camera_parameters_ev100(
  camera : @camera_camera.PhysicalCameraParameters,
) -> Float {
  camera.ev100()
}
