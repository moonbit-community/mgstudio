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
pub type AutoExposure = @pbr.AutoExposure

///|
pub type AutoExposureCompensationCurve = @pbr.AutoExposureCompensationCurve

///|
pub type AutoExposureCompensationCurveError = @pbr.AutoExposureCompensationCurveError

///|
pub type PhysicalCameraParameters = @pbr.PhysicalCameraParameters

///|
pub fn auto_exposure_default() -> @pbr.AutoExposure {
  @pbr.AutoExposure::default()
}

///|
pub fn auto_exposure_new(
  min_luminance : Float,
  max_luminance : Float,
) -> @pbr.AutoExposure {
  @pbr.AutoExposure::new(min_luminance, max_luminance)
}

///|
pub fn auto_exposure_with_range(
  auto_exposure : @pbr.AutoExposure,
  min_luminance : Float,
  max_luminance : Float,
) -> @pbr.AutoExposure {
  auto_exposure.with_range(min_luminance, max_luminance)
}

///|
pub fn auto_exposure_compensation_curve_default() -> @pbr.AutoExposureCompensationCurve {
  @pbr.AutoExposureCompensationCurve::default()
}

///|
pub fn[T : @pbr.AutoExposureCompensationCurveSource] auto_exposure_compensation_curve_from_curve(
  source : T,
) -> @pbr.AutoExposureCompensationCurve raise @pbr.AutoExposureCompensationCurveError {
  @pbr.AutoExposureCompensationCurve::from_curve(source)
}

///|
pub fn physical_camera_parameters_default() -> @pbr.PhysicalCameraParameters {
  @pbr.PhysicalCameraParameters::default()
}

///|
pub fn physical_camera_parameters_ev100(
  camera : @pbr.PhysicalCameraParameters,
) -> Float {
  camera.ev100()
}
