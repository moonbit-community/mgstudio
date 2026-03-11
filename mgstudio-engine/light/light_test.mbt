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
test "light boundary re-exports direct light component APIs" {
  let point = @light.PointLight::default()
    .with_intensity(321.0)
    .with_range(45.0)
  let spot = @light.SpotLight::default()
    .with_inner_angle(0.25)
    .with_outer_angle(0.5)
  let directional = @light.DirectionalLight::default().with_illuminance(1000.0)
  inspect(point.intensity.to_double(), content="321")
  inspect(point.range.to_double(), content="45")
  inspect(spot.inner_angle.to_double(), content="0.25")
  inspect(spot.outer_angle.to_double(), content="0.5")
  inspect(directional.illuminance.to_double(), content="1000")
}

///|
test "light boundary re-exports shadow maps and volumetric APIs" {
  let point_shadow = @light.PointLightShadowMap::new(2048)
  let directional_shadow = @light.DirectionalLightShadowMap::new(1024)
  let medium = @light.ScatteringMedium::default().with_density_multiplier(1.5)
  let fog = @light.VolumetricFog::default().with_step_count(96)
  inspect(point_shadow.size, content="2048")
  inspect(directional_shadow.size, content="1024")
  inspect(medium.density_multiplier.to_double(), content="1.5")
  inspect(fog.step_count, content="96")
}
