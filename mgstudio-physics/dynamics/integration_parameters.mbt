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
pub struct SpringCoefficients {
  natural_frequency : @core.Real
  damping_ratio : @core.Real
}

///|
pub fn SpringCoefficients::new(
  natural_frequency : @core.Real,
  damping_ratio : @core.Real,
) -> SpringCoefficients {
  { natural_frequency, damping_ratio }
}

///|
pub fn SpringCoefficients::contact_defaults() -> SpringCoefficients {
  { natural_frequency: 30.0F, damping_ratio: 5.0F }
}

///|
pub fn SpringCoefficients::joint_defaults() -> SpringCoefficients {
  { natural_frequency: 1.0e6F, damping_ratio: 1.0F }
}

///|
pub fn SpringCoefficients::angular_frequency(
  self : SpringCoefficients,
) -> @core.Real {
  self.natural_frequency * @core.two_pi()
}

///|
pub fn SpringCoefficients::erp_inv_dt(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  let ang_freq = self.angular_frequency()
  ang_freq / (dt * ang_freq + 2.0F * self.damping_ratio)
}

///|
pub fn SpringCoefficients::erp(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  dt * self.erp_inv_dt(dt)
}

///|
pub fn SpringCoefficients::cfm_coeff(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  let one = 1.0F
  let erp = self.erp(dt)
  if erp == 0.0F {
    0.0F
  } else {
    let inv_erp_minus_one = one / erp - one
    let denom = (one + inv_erp_minus_one) *
      4.0F *
      self.damping_ratio *
      self.damping_ratio
    if denom == 0.0F {
      0.0F
    } else {
      inv_erp_minus_one * inv_erp_minus_one / denom
    }
  }
}

///|
pub fn SpringCoefficients::cfm_factor(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  let one = 1.0F
  one / (one + self.cfm_coeff(dt))
}

///|
pub struct IntegrationParameters {
  mut dt : @core.Real
  mut min_ccd_dt : @core.Real
  mut contact_softness : SpringCoefficients
  mut warmstart_coefficient : @core.Real
  mut length_unit : @core.Real
  mut normalized_allowed_linear_error : @core.Real
  mut normalized_max_corrective_velocity : @core.Real
  mut normalized_prediction_distance : @core.Real
  mut num_solver_iterations : Int
  mut num_internal_pgs_iterations : Int
  mut num_internal_stabilization_iterations : Int
  mut min_island_size : Int
  mut max_ccd_substeps : Int
}

///|
pub fn IntegrationParameters::default() -> IntegrationParameters {
  {
    dt: 1.0F / 60.0F,
    min_ccd_dt: 1.0F / 60.0F / 100.0F,
    contact_softness: SpringCoefficients::contact_defaults(),
    warmstart_coefficient: 1.0F,
    num_internal_pgs_iterations: 1,
    num_internal_stabilization_iterations: 1,
    num_solver_iterations: 4,
    min_island_size: 128,
    normalized_allowed_linear_error: 0.001F,
    normalized_max_corrective_velocity: 10.0F,
    normalized_prediction_distance: 0.002F,
    max_ccd_substeps: 1,
    length_unit: 1.0F,
  }
}

///|
pub fn IntegrationParameters::new() -> IntegrationParameters {
  IntegrationParameters::default()
}

///|
pub fn IntegrationParameters::inv_dt(
  self : IntegrationParameters,
) -> @core.Real {
  if self.dt == 0.0F {
    0.0F
  } else {
    1.0F / self.dt
  }
}

///|
pub fn IntegrationParameters::set_dt(
  self : IntegrationParameters,
  dt : @core.Real,
) -> IntegrationParameters {
  self.dt = dt
  self
}

///|
pub fn IntegrationParameters::set_inv_dt(
  self : IntegrationParameters,
  inv_dt : @core.Real,
) -> IntegrationParameters {
  if inv_dt == 0.0F {
    self.dt = 0.0F
  } else {
    self.dt = 1.0F / inv_dt
  }
  self
}

///|
pub fn IntegrationParameters::set_min_ccd_dt(
  self : IntegrationParameters,
  min_ccd_dt : @core.Real,
) -> IntegrationParameters {
  self.min_ccd_dt = min_ccd_dt
  self
}

///|
pub fn IntegrationParameters::set_contact_softness(
  self : IntegrationParameters,
  contact_softness : SpringCoefficients,
) -> IntegrationParameters {
  self.contact_softness = contact_softness
  self
}

///|
pub fn IntegrationParameters::set_warmstart_coefficient(
  self : IntegrationParameters,
  warmstart_coefficient : @core.Real,
) -> IntegrationParameters {
  self.warmstart_coefficient = warmstart_coefficient
  self
}

///|
pub fn IntegrationParameters::set_length_unit(
  self : IntegrationParameters,
  length_unit : @core.Real,
) -> IntegrationParameters {
  self.length_unit = length_unit
  self
}

///|
pub fn IntegrationParameters::set_normalized_allowed_linear_error(
  self : IntegrationParameters,
  normalized_allowed_linear_error : @core.Real,
) -> IntegrationParameters {
  self.normalized_allowed_linear_error = normalized_allowed_linear_error
  self
}

///|
pub fn IntegrationParameters::set_normalized_max_corrective_velocity(
  self : IntegrationParameters,
  normalized_max_corrective_velocity : @core.Real,
) -> IntegrationParameters {
  self.normalized_max_corrective_velocity = normalized_max_corrective_velocity
  self
}

///|
pub fn IntegrationParameters::set_normalized_prediction_distance(
  self : IntegrationParameters,
  normalized_prediction_distance : @core.Real,
) -> IntegrationParameters {
  self.normalized_prediction_distance = normalized_prediction_distance
  self
}

///|
pub fn IntegrationParameters::set_num_solver_iterations(
  self : IntegrationParameters,
  num_solver_iterations : Int,
) -> IntegrationParameters {
  self.num_solver_iterations = num_solver_iterations
  self
}

///|
pub fn IntegrationParameters::set_num_internal_pgs_iterations(
  self : IntegrationParameters,
  num_internal_pgs_iterations : Int,
) -> IntegrationParameters {
  self.num_internal_pgs_iterations = num_internal_pgs_iterations
  self
}

///|
pub fn IntegrationParameters::set_num_internal_stabilization_iterations(
  self : IntegrationParameters,
  num_internal_stabilization_iterations : Int,
) -> IntegrationParameters {
  self.num_internal_stabilization_iterations = num_internal_stabilization_iterations
  self
}

///|
pub fn IntegrationParameters::set_min_island_size(
  self : IntegrationParameters,
  min_island_size : Int,
) -> IntegrationParameters {
  self.min_island_size = min_island_size
  self
}

///|
pub fn IntegrationParameters::set_max_ccd_substeps(
  self : IntegrationParameters,
  max_ccd_substeps : Int,
) -> IntegrationParameters {
  self.max_ccd_substeps = max_ccd_substeps
  self
}

///|
pub fn IntegrationParameters::allowed_linear_error(
  self : IntegrationParameters,
) -> @core.Real {
  self.normalized_allowed_linear_error * self.length_unit
}

///|
pub fn IntegrationParameters::max_corrective_velocity(
  self : IntegrationParameters,
) -> @core.Real {
  self.normalized_max_corrective_velocity * self.length_unit
}

///|
pub fn IntegrationParameters::prediction_distance(
  self : IntegrationParameters,
) -> @core.Real {
  self.normalized_prediction_distance * self.length_unit
}
