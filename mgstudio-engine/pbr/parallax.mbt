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
// Bevy source: `bevy/crates/bevy_pbr/src/parallax.rs`.

///|
pub type ParallaxMappingMethod = @material.ParallaxMappingMethod

///|
pub fn pbr_parallax_occlusion_method() -> ParallaxMappingMethod {
  ParallaxMappingMethod::Occlusion
}

///|
pub fn pbr_parallax_relief_method(max_steps : Int) -> ParallaxMappingMethod {
  let safe_steps = if max_steps <= 0 { 1 } else { max_steps }
  ParallaxMappingMethod::Relief(safe_steps)
}

///|
pub fn pbr_parallax_is_occlusion(
  mapping_method : ParallaxMappingMethod,
) -> Bool {
  match mapping_method {
    ParallaxMappingMethod::Occlusion => true
    _ => false
  }
}

///|
pub fn pbr_parallax_is_relief(mapping_method : ParallaxMappingMethod) -> Bool {
  match mapping_method {
    ParallaxMappingMethod::Relief(_) => true
    _ => false
  }
}

///|
pub fn pbr_parallax_default_method() -> ParallaxMappingMethod {
  ParallaxMappingMethod::default()
}

///|
pub fn pbr_parallax_relief_default_method() -> ParallaxMappingMethod {
  ParallaxMappingMethod::relief_default()
}

///|
pub fn pbr_parallax_max_steps(mapping_method : ParallaxMappingMethod) -> Int {
  mapping_method.max_steps()
}

///|
pub fn pbr_parallax_with_max_steps(
  mapping_method : ParallaxMappingMethod,
  max_steps : Int,
) -> ParallaxMappingMethod {
  match mapping_method {
    ParallaxMappingMethod::Occlusion => ParallaxMappingMethod::Occlusion
    ParallaxMappingMethod::Relief(_) => pbr_parallax_relief_method(max_steps)
  }
}
