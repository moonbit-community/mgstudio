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
pub struct Instant {
  nanos_since_start : Int64
} derive(Eq, Show, ToJson, FromJson)

///|
fn instant_clamp_positive(value : Int64) -> Int64 {
  if value <= 0L {
    0L
  } else {
    value
  }
}

///|
pub fn Instant::from_duration(duration : Duration) -> Instant {
  Instant::{ nanos_since_start: duration.as_nanos() }
}

///|
pub fn Instant::from_secs_f32(secs : Float) -> Instant {
  Instant::from_duration(Duration::from_secs_f32(secs))
}

///|
pub fn Instant::from_secs_f64(secs : Double) -> Instant {
  Instant::from_duration(Duration::from_secs_f64(secs))
}

///|
pub fn Instant::from_millis(millis : Int64) -> Instant {
  Instant::from_duration(Duration::from_millis(millis))
}

///|
pub fn Instant::from_nanos(nanos : Int64) -> Instant {
  Instant::{ nanos_since_start: instant_clamp_positive(nanos) }
}

///|
pub fn Instant::now() -> Instant {
  Instant::from_secs_f64(@native_time.now().to_double())
}

///|
pub fn Instant::as_duration_since_start(self : Instant) -> Duration {
  Duration::from_nanos(self.nanos_since_start)
}

///|
pub fn Instant::as_millis(self : Instant) -> Int64 {
  self.as_duration_since_start().as_millis()
}

///|
pub fn Instant::as_secs_f32(self : Instant) -> Float {
  self.as_duration_since_start().as_secs_f32()
}

///|
pub fn Instant::as_secs_f64(self : Instant) -> Double {
  self.as_duration_since_start().as_secs_f64()
}

///|
pub fn Instant::checked_duration_since(
  self : Instant,
  earlier : Instant,
) -> Duration? {
  if self.nanos_since_start < earlier.nanos_since_start {
    None
  } else {
    Some(
      Duration::from_nanos(self.nanos_since_start - earlier.nanos_since_start),
    )
  }
}

///|
pub fn Instant::duration_since(self : Instant, earlier : Instant) -> Duration {
  match self.checked_duration_since(earlier) {
    Some(duration) => duration
    None => abort("supplied instant is later than self")
  }
}

///|
pub fn Instant::saturating_duration_since(
  self : Instant,
  earlier : Instant,
) -> Duration {
  match self.checked_duration_since(earlier) {
    Some(duration) => duration
    None => Duration::zero()
  }
}

///|
pub fn Instant::elapsed(self : Instant) -> Duration {
  Instant::now().saturating_duration_since(self)
}

///|
pub fn Instant::checked_add(self : Instant, duration : Duration) -> Instant? {
  let duration_nanos = duration.as_nanos()
  if self.nanos_since_start >= 0L &&
    duration_nanos > 0L &&
    self.nanos_since_start > 9_223_372_036_854_775_807L - duration_nanos {
    None
  } else {
    Some(Instant::{ nanos_since_start: self.nanos_since_start + duration_nanos })
  }
}

///|
pub fn Instant::checked_sub(self : Instant, duration : Duration) -> Instant? {
  if self.nanos_since_start < duration.as_nanos() {
    None
  } else {
    Some(Instant::{
      nanos_since_start: self.nanos_since_start - duration.as_nanos(),
    })
  }
}

///|
pub fn Instant::saturating_add(self : Instant, duration : Duration) -> Instant {
  match self.checked_add(duration) {
    Some(instant) => instant
    None => Instant::from_nanos(9_223_372_036_854_775_807L)
  }
}

///|
pub fn Instant::saturating_sub(self : Instant, duration : Duration) -> Instant {
  match self.checked_sub(duration) {
    Some(instant) => instant
    None => Instant::from_nanos(0L)
  }
}
