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
// Bevy source: `bevy/crates/bevy_post_process/src/auto_exposure/settings.rs`.

///|
/// API-parity data model aligned with Bevy's `AutoExposure` camera component.
pub struct AutoExposure {
  min_ev100 : Float
  max_ev100 : Float
  low_percent : Float
  high_percent : Float
  speed_brighten : Float
  speed_darken : Float
  exponential_transition_distance : Float
  compensation_curve : @asset.Handle[AutoExposureCompensationCurve]?
  metering_mask : @asset.Handle[@asset.Image]?
} derive(ToJson, FromJson)

///|
pub fn AutoExposure::AutoExposure() -> AutoExposure {
  {
    min_ev100: -8.0F,
    max_ev100: 8.0F,
    low_percent: 0.10F,
    high_percent: 0.90F,
    speed_brighten: 3.0F,
    speed_darken: 1.0F,
    exponential_transition_distance: 1.5F,
    compensation_curve: None,
    metering_mask: None,
  }
}

///|
pub fn AutoExposure::new(min_ev100 : Float, max_ev100 : Float) -> AutoExposure {
  AutoExposure::AutoExposure().with_range(min_ev100, max_ev100)
}

///|
pub fn AutoExposure::with_range(
  self : AutoExposure,
  min_ev100 : Float,
  max_ev100 : Float,
) -> AutoExposure {
  let safe_min = if min_ev100 < max_ev100 { min_ev100 } else { max_ev100 }
  let safe_max = if max_ev100 > safe_min { max_ev100 } else { safe_min + 0.01F }
  { ..self, min_ev100: safe_min, max_ev100: safe_max }
}

///|
pub fn AutoExposure::with_filter(
  self : AutoExposure,
  low_percent : Float,
  high_percent : Float,
) -> AutoExposure {
  let safe_low = if low_percent < 0.0F {
    0.0F
  } else if low_percent > 1.0F {
    1.0F
  } else {
    low_percent
  }
  let mut safe_high = if high_percent < 0.0F {
    0.0F
  } else if high_percent > 1.0F {
    1.0F
  } else {
    high_percent
  }
  if safe_high < safe_low {
    safe_high = safe_low
  }
  { ..self, low_percent: safe_low, high_percent: safe_high }
}

///|
pub fn AutoExposure::with_speed_brighten(
  self : AutoExposure,
  speed_brighten : Float,
) -> AutoExposure {
  {
    ..self,
    speed_brighten: if speed_brighten < 0.0F {
      0.0F
    } else {
      speed_brighten
    },
  }
}

///|
pub fn AutoExposure::with_speed_darken(
  self : AutoExposure,
  speed_darken : Float,
) -> AutoExposure {
  {
    ..self,
    speed_darken: if speed_darken < 0.0F {
      0.0F
    } else {
      speed_darken
    },
  }
}

///|
pub fn AutoExposure::with_exponential_transition_distance(
  self : AutoExposure,
  exponential_transition_distance : Float,
) -> AutoExposure {
  {
    ..self,
    exponential_transition_distance: if exponential_transition_distance <= 0.0F {
      0.0001F
    } else {
      exponential_transition_distance
    },
  }
}

///|
pub fn AutoExposure::with_compensation_curve(
  self : AutoExposure,
  compensation_curve : @asset.Handle[AutoExposureCompensationCurve]?,
) -> AutoExposure {
  { ..self, compensation_curve, }
}

///|
pub fn AutoExposure::with_metering_mask(
  self : AutoExposure,
  metering_mask : @asset.Handle[@asset.Image]?,
) -> AutoExposure {
  { ..self, metering_mask, }
}

///|
pub fn auto_exposure_range(settings : AutoExposure) -> (Float, Float) {
  (settings.min_ev100, settings.max_ev100)
}

///|
pub fn auto_exposure_filter(settings : AutoExposure) -> (Float, Float) {
  (settings.low_percent, settings.high_percent)
}

///|
pub fn auto_exposure_uses_mask(settings : AutoExposure) -> Bool {
  settings.metering_mask is Some(_)
}

///|
pub fn auto_exposure_uses_compensation_curve(settings : AutoExposure) -> Bool {
  settings.compensation_curve is Some(_)
}

///|
pub let ecs_key_auto_exposure : @ecs.ComponentKey[AutoExposure] = @ecs.register_component(
  debug_name="render3d.auto_exposure",
)

///|
pub impl @ecs.Component for AutoExposure with fn component() {
  ecs_key_auto_exposure
}
