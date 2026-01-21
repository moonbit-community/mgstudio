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
const DEFAULT_DT : @core.Real = 0.016666667F

///|
const DEFAULT_PREDICTION_DISTANCE : @core.Real = 0.002F

///|
pub fn IntegrationParameters::default() -> IntegrationParameters {
  { dt: DEFAULT_DT }
}

///|
pub fn IntegrationParameters::with_dt(
  self : IntegrationParameters,
  dt : @core.Real,
) -> IntegrationParameters {
  self |> ignore
  let safe_dt = if dt < 0.0F { 0.0F } else { dt }
  { dt: safe_dt }
}

///|
pub fn IntegrationParameters::prediction_distance(
  self : IntegrationParameters,
) -> @core.Real {
  self |> ignore
  DEFAULT_PREDICTION_DISTANCE
}
