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
// Bevy source: `bevy/crates/bevy_post_process/src/auto_exposure/buffers.rs`.
// Host-side histogram/state packing for the bridged auto exposure runtime.

///|
pub struct AutoExposureBuffers {
  histogram : Array[Int]
  average_ev100 : Float
  target_ev100 : Float
  current_ev100 : Float
} derive(ToJson, FromJson)

///|
pub fn AutoExposureBuffers::new(
  pipeline : AutoExposurePipeline,
) -> AutoExposureBuffers {
  let histogram : Array[Int] = []
  for _ in 0..<pipeline.histogram_bin_count {
    histogram.push(0)
  }
  AutoExposureBuffers::{
    histogram,
    average_ev100: 0.0F,
    target_ev100: 0.0F,
    current_ev100: 0.0F,
  }
}

///|
pub fn auto_exposure_buffers_from_samples(
  settings : AutoExposure,
  pipeline : AutoExposurePipeline,
  curve : AutoExposureCompensationCurve?,
  luminance_samples : Array[Float],
  mask_samples : Array[Float]?,
  previous_ev100 : Float,
  delta_time : Float,
) -> AutoExposureBuffers {
  let histogram : Array[Int] = []
  for _ in 0..<pipeline.histogram_bin_count {
    histogram.push(0)
  }
  for index in 0..<luminance_samples.length() {
    let sample = luminance_samples[index]
    let weight = auto_exposure_mask_weight(mask_samples, index)
    if weight <= 0 {
      continue
    }
    let histogram_index = auto_exposure_histogram_index(
      settings, pipeline, sample,
    )
    histogram[histogram_index] = histogram[histogram_index] + weight
  }
  let average_ev100 = auto_exposure_average_ev100(settings, pipeline, histogram)
  let compensation = match curve {
    Some(curve_value) => auto_exposure_curve_sample(curve_value, average_ev100)
    None => 0.0F
  }
  let unclamped_target = -average_ev100 + compensation
  let target_ev100 = auto_exposure_clamp(
    unclamped_target,
    settings.min_ev100,
    settings.max_ev100,
  )
  let current_ev100 = auto_exposure_adapt_ev100(
    previous_ev100, target_ev100, settings, delta_time,
  )
  AutoExposureBuffers::{ histogram, average_ev100, target_ev100, current_ev100 }
}

///|
fn auto_exposure_mask_weight(mask_samples : Array[Float]?, index : Int) -> Int {
  match mask_samples {
    Some(mask_values) =>
      if index < mask_values.length() {
        auto_exposure_quantize_mask(mask_values[index])
      } else {
        16
      }
    None => 16
  }
}

///|
fn auto_exposure_quantize_mask(value : Float) -> Int {
  let clamped = auto_exposure_clamp(value, 0.0F, 1.0F)
  (clamped * 16.0F).floor().to_int()
}

///|
fn auto_exposure_histogram_index(
  settings : AutoExposure,
  pipeline : AutoExposurePipeline,
  log_luminance : Float,
) -> Int {
  let range = settings.max_ev100 - settings.min_ev100
  if range <= 0.0F {
    return 0
  }
  let clamped = auto_exposure_clamp(
    log_luminance,
    settings.min_ev100,
    settings.max_ev100,
  )
  let normalized = (clamped - settings.min_ev100) / range
  let scaled = normalized *
    Float::from_double((pipeline.histogram_bin_count - 1).to_double())
  let index = scaled.floor().to_int()
  if index < 0 {
    0
  } else if index >= pipeline.histogram_bin_count {
    pipeline.histogram_bin_count - 1
  } else {
    index
  }
}

///|
fn auto_exposure_average_ev100(
  settings : AutoExposure,
  pipeline : AutoExposurePipeline,
  histogram : Array[Int],
) -> Float {
  let total_weight = auto_exposure_histogram_total(histogram)
  if total_weight <= 0 {
    return (settings.min_ev100 + settings.max_ev100) * 0.5F
  }
  let total_weight_float = Float::from_double(total_weight.to_double())
  let low_cut = settings.low_percent * total_weight_float
  let high_cut = settings.high_percent * total_weight_float
  let bin_width = (settings.max_ev100 - settings.min_ev100) /
    Float::from_double(pipeline.histogram_bin_count.to_double())
  let mut cumulative = 0.0F
  let mut weighted_sum = 0.0F
  let mut selected_weight = 0.0F
  for index in 0..<histogram.length() {
    let bucket_weight = Float::from_double(histogram[index].to_double())
    if bucket_weight <= 0.0F {
      continue
    }
    let next_cumulative = cumulative + bucket_weight
    let contribution_begin = if low_cut > cumulative {
      low_cut
    } else {
      cumulative
    }
    let contribution_end = if high_cut < next_cumulative {
      high_cut
    } else {
      next_cumulative
    }
    if contribution_end > contribution_begin {
      let contribution = contribution_end - contribution_begin
      let bin_center = settings.min_ev100 +
        (Float::from_double(index.to_double()) + 0.5F) * bin_width
      weighted_sum = weighted_sum + contribution * bin_center
      selected_weight = selected_weight + contribution
    }
    cumulative = next_cumulative
    if cumulative >= high_cut {
      break
    }
  }
  if selected_weight <= 0.0F {
    (settings.min_ev100 + settings.max_ev100) * 0.5F
  } else {
    weighted_sum / selected_weight
  }
}

///|
fn auto_exposure_histogram_total(histogram : Array[Int]) -> Int {
  let mut total = 0
  for value in histogram {
    total = total + value
  }
  total
}

///|
pub fn auto_exposure_adapt_ev100(
  current_ev100 : Float,
  target_ev100 : Float,
  settings : AutoExposure,
  delta_time : Float,
) -> Float {
  let delta = target_ev100 - current_ev100
  let distance = delta.abs()
  if delta_time <= 0.0F || distance <= 0.0F {
    return current_ev100
  }
  let speed = if delta >= 0.0F {
    settings.speed_brighten
  } else {
    settings.speed_darken
  }
  if speed <= 0.0F {
    return current_ev100
  }
  let transition = settings.exponential_transition_distance
  let step = speed * delta_time
  if distance > transition {
    let signed_step = if delta >= 0.0F { step } else { -step }
    let next_value = current_ev100 + signed_step
    if delta >= 0.0F && next_value > target_ev100 {
      target_ev100
    } else if delta < 0.0F && next_value < target_ev100 {
      target_ev100
    } else {
      next_value
    }
  } else {
    current_ev100 + delta * auto_exposure_clamp(step / transition, 0.0F, 1.0F)
  }
}

///|
fn auto_exposure_clamp(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}
