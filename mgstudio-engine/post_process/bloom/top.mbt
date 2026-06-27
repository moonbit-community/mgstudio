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
// Bevy source: `bevy/crates/bevy_post_process/src/bloom/mod.rs`.

///|
const BLOOM_PLUGIN_NAME : String = "mgstudio.post_process.bloom.BloomPlugin"

///|
pub struct BloomPlugin {}

///|
pub fn BloomPlugin::BloomPlugin() -> BloomPlugin {
  BloomPlugin::{  }
}

///|
pub impl @app.Plugin for BloomPlugin with fn name(_self) {
  BLOOM_PLUGIN_NAME
}

///|
pub impl @app.Plugin for BloomPlugin with fn build(_self, app) {
  register_embedded_wgsl_sources()
  app
}

///|
pub struct BloomPrefilter {
  threshold : Float
  threshold_softness : Float
} derive(ToJson, FromJson)

///|
pub fn BloomPrefilter::BloomPrefilter() -> BloomPrefilter {
  BloomPrefilter::{ threshold: 0.0F, threshold_softness: 0.0F }
}

///|
pub fn BloomPrefilter::new(
  threshold : Float,
  threshold_softness : Float,
) -> BloomPrefilter {
  BloomPrefilter::{
    threshold: if threshold < 0.0F {
      0.0F
    } else {
      threshold
    },
    threshold_softness: if threshold_softness < 0.0F {
      0.0F
    } else if threshold_softness > 1.0F {
      1.0F
    } else {
      threshold_softness
    },
  }
}

///|
pub fn BloomPrefilter::with_threshold(
  self : BloomPrefilter,
  threshold : Float,
) -> BloomPrefilter {
  BloomPrefilter::new(threshold, self.threshold_softness)
}

///|
pub fn BloomPrefilter::with_threshold_softness(
  self : BloomPrefilter,
  threshold_softness : Float,
) -> BloomPrefilter {
  BloomPrefilter::new(self.threshold, threshold_softness)
}

///|
pub(all) enum BloomCompositeMode {
  EnergyConserving
  Additive
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn BloomCompositeMode::default() -> BloomCompositeMode {
  BloomCompositeMode::EnergyConserving
}

///|
const BLOOM_DEFAULT_MAX_MIP_DIMENSION : Int = 512

///|
/// Camera bloom settings aligned with Bevy's `Bloom`.
pub struct Bloom {
  intensity : Float
  low_frequency_boost : Float
  low_frequency_boost_curvature : Float
  high_pass_frequency : Float
  prefilter : BloomPrefilter
  composite_mode : BloomCompositeMode
  max_mip_dimension : Int
  scale : @math.Vec2
} derive(ToJson, FromJson)

///|
pub fn Bloom::Bloom() -> Bloom {
  Bloom::{
    intensity: 0.15F,
    low_frequency_boost: 0.7F,
    low_frequency_boost_curvature: 0.95F,
    high_pass_frequency: 1.0F,
    prefilter: BloomPrefilter::BloomPrefilter(),
    composite_mode: BloomCompositeMode::EnergyConserving,
    max_mip_dimension: BLOOM_DEFAULT_MAX_MIP_DIMENSION,
    scale: @math.Vec2::new(1.0F, 1.0F),
  }
}

///|
pub fn Bloom::natural() -> Bloom {
  Bloom::Bloom()
}

///|
pub fn Bloom::anamorphic() -> Bloom {
  Bloom::{
    ..Bloom(),
    max_mip_dimension: BLOOM_DEFAULT_MAX_MIP_DIMENSION * 2,
    scale: @math.Vec2::new(4.0F, 1.0F),
  }
}

///|
pub fn Bloom::old_school() -> Bloom {
  Bloom::{
    ..Bloom(),
    intensity: 0.05F,
    prefilter: BloomPrefilter::new(0.6F, 0.2F),
    composite_mode: BloomCompositeMode::Additive,
  }
}

///|
pub fn Bloom::screen_blur() -> Bloom {
  Bloom::{
    ..Bloom(),
    intensity: 1.0F,
    low_frequency_boost: 0.0F,
    low_frequency_boost_curvature: 0.0F,
    high_pass_frequency: 1.0F / 3.0F,
  }
}

///|
pub fn Bloom::new(intensity : Float) -> Bloom {
  Bloom::{
    ..Bloom(),
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn Bloom::with_intensity(self : Bloom, intensity : Float) -> Bloom {
  Bloom::{ ..self, intensity: if intensity < 0.0F { 0.0F } else { intensity } }
}

///|
pub fn Bloom::with_low_frequency_boost(
  self : Bloom,
  low_frequency_boost : Float,
) -> Bloom {
  Bloom::{
    ..self,
    low_frequency_boost: if low_frequency_boost < 0.0F {
      0.0F
    } else if low_frequency_boost > 1.0F {
      1.0F
    } else {
      low_frequency_boost
    },
  }
}

///|
pub fn Bloom::with_low_frequency_boost_curvature(
  self : Bloom,
  low_frequency_boost_curvature : Float,
) -> Bloom {
  Bloom::{
    ..self,
    low_frequency_boost_curvature: if low_frequency_boost_curvature < 0.0F {
      0.0F
    } else if low_frequency_boost_curvature > 1.0F {
      1.0F
    } else {
      low_frequency_boost_curvature
    },
  }
}

///|
pub fn Bloom::with_high_pass_frequency(
  self : Bloom,
  high_pass_frequency : Float,
) -> Bloom {
  Bloom::{
    ..self,
    high_pass_frequency: if high_pass_frequency < 0.0F {
      0.0F
    } else if high_pass_frequency > 1.0F {
      1.0F
    } else {
      high_pass_frequency
    },
  }
}

///|
pub fn Bloom::with_prefilter(
  self : Bloom,
  threshold : Float,
  threshold_softness : Float,
) -> Bloom {
  Bloom::{
    ..self,
    prefilter: BloomPrefilter::new(threshold, threshold_softness),
  }
}

///|
pub fn Bloom::with_prefilter_settings(
  self : Bloom,
  prefilter : BloomPrefilter,
) -> Bloom {
  Bloom::{
    ..self,
    prefilter: BloomPrefilter::new(
      prefilter.threshold,
      prefilter.threshold_softness,
    ),
  }
}

///|
pub fn Bloom::with_composite_mode(
  self : Bloom,
  composite_mode : BloomCompositeMode,
) -> Bloom {
  Bloom::{ ..self, composite_mode, }
}

///|
pub fn Bloom::with_max_mip_dimension(
  self : Bloom,
  max_mip_dimension : Int,
) -> Bloom {
  Bloom::{
    ..self,
    max_mip_dimension: if max_mip_dimension < 4 {
      4
    } else {
      max_mip_dimension
    },
  }
}

///|
pub fn Bloom::with_scale(self : Bloom, scale : @math.Vec2) -> Bloom {
  Bloom::{
    ..self,
    scale: @math.Vec2::new(
      if scale.x < 0.0F {
        0.0F
      } else {
        scale.x
      },
      if scale.y < 0.0F {
        0.0F
      } else {
        scale.y
      },
    ),
  }
}

///|
pub fn Bloom::with_scale_x(self : Bloom, scale_x : Float) -> Bloom {
  self.with_scale(@math.Vec2::new(scale_x, self.scale.y))
}

///|
pub fn Bloom::with_scale_y(self : Bloom, scale_y : Float) -> Bloom {
  self.with_scale(@math.Vec2::new(self.scale.x, scale_y))
}

///|
pub let ecs_key_bloom : @ecs.ComponentKey[Bloom] = @ecs.register_component(
  debug_name="render3d.bloom",
)

///|
pub impl @ecs.Component for Bloom with fn component() {
  ecs_key_bloom
}
