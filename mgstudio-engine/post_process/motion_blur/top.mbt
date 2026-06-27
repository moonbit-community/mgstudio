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
// Bevy source: `bevy/crates/bevy_post_process/src/motion_blur/mod.rs`.

///|
pub struct MotionBlur {
  shutter_angle : Float
  samples : Int
} derive(ToJson, FromJson)

///|
pub fn MotionBlur::MotionBlur() -> MotionBlur {
  MotionBlur::{ shutter_angle: 0.5F, samples: 1 }
}

///|
pub fn MotionBlur::new(shutter_angle : Float, samples : Int) -> MotionBlur {
  let safe_shutter_angle = if shutter_angle < 0.0F {
    0.0F
  } else {
    shutter_angle
  }
  let safe_samples = if samples < 0 { 0 } else { samples }
  MotionBlur::{ shutter_angle: safe_shutter_angle, samples: safe_samples }
}

///|
pub fn MotionBlur::with_shutter_angle(
  self : MotionBlur,
  shutter_angle : Float,
) -> MotionBlur {
  MotionBlur::new(shutter_angle, self.samples)
}

///|
pub fn MotionBlur::with_samples(self : MotionBlur, samples : Int) -> MotionBlur {
  MotionBlur::new(self.shutter_angle, samples)
}

///|
pub let ecs_key_motion_blur : @ecs.ComponentKey[MotionBlur] = @ecs.register_component(
  debug_name="render3d.motion_blur",
)

///|
pub impl @ecs.Component for MotionBlur with fn component() {
  ecs_key_motion_blur
}

///|
pub struct MotionBlurUniform {
  shutter_angle : Float
  samples : Int
}

///|
pub fn MotionBlurUniform::MotionBlurUniform() -> MotionBlurUniform {
  MotionBlurUniform::{ shutter_angle: 0.5F, samples: 1 }
}

///|
pub fn MotionBlurUniform::new(
  shutter_angle : Float,
  samples : Int,
) -> MotionBlurUniform {
  let settings = MotionBlur::new(shutter_angle, samples)
  MotionBlurUniform::{
    shutter_angle: settings.shutter_angle,
    samples: settings.samples,
  }
}

///|
pub let ecs_key_motion_blur_uniform : @ecs.ComponentKey[MotionBlurUniform] = @ecs.register_component(
  debug_name="render3d.motion_blur_uniform",
)

///|
pub impl @ecs.Component for MotionBlurUniform with fn component() {
  ecs_key_motion_blur_uniform
}

///|
pub fn MotionBlur::extract_uniform(self : MotionBlur) -> MotionBlurUniform {
  MotionBlurUniform::new(self.shutter_angle, self.samples)
}

///|
pub fn motion_blur_extract_uniform(settings : MotionBlur) -> MotionBlurUniform {
  settings.extract_uniform()
}

///|
pub fn motion_blur_uniform_is_active(uniform : MotionBlurUniform) -> Bool {
  uniform.samples > 0 && uniform.shutter_angle > 0.0F
}

///|
pub fn motion_blur_component_key() -> @ecs.ComponentKey[MotionBlur] {
  ecs_key_motion_blur
}

///|
pub fn motion_blur_uniform_component_key() -> @ecs.ComponentKey[
  MotionBlurUniform,
] {
  ecs_key_motion_blur_uniform
}

///|
pub fn motion_blur_generate_samples(
  settings : MotionBlur,
) -> Array[MotionBlurSample] {
  motion_blur_samples(settings)
}
