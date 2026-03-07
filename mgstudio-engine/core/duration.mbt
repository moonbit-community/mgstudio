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
const DURATION_MAX_MILLIS : Int64 = 9_223_372_036_854_775_807L

///|
pub struct Duration {
  millis : Int64
} derive(Eq, ToJson, FromJson)

///|
pub fn Duration::new(secs : Int64, millis? : Int = 0) -> Duration {
  let millis_from_secs = if secs <= 0L {
    0L
  } else if secs >= 9_223_372_036_854_775L {
    9_223_372_036_854_775_000L
  } else {
    secs * 1000L
  }
  let extra_millis = if millis <= 0 { 0L } else { millis.to_int64() }
  let total = if millis_from_secs >= DURATION_MAX_MILLIS - extra_millis {
    DURATION_MAX_MILLIS
  } else {
    millis_from_secs + extra_millis
  }
  { millis: total }
}

///|
pub fn Duration::from_secs(secs : Int64) -> Duration {
  Duration::new(secs)
}

///|
pub fn Duration::from_secs_f32(secs : Float) -> Duration {
  if secs <= 0.0 {
    { millis: 0L }
  } else {
    let millis = Int64::from_int((secs * 1000.0F).to_int())
    { millis, }
  }
}

///|
pub fn Duration::from_millis(millis : Int64) -> Duration {
  { millis: if millis <= 0L { 0L } else { millis } }
}

///|
pub fn Duration::as_millis(self : Duration) -> Int64 {
  self.millis
}

///|
pub fn Duration::as_secs_f32(self : Duration) -> Float {
  Float::from_double(self.millis.to_double()) / 1000.0F
}

///|
pub fn Duration::is_zero(self : Duration) -> Bool {
  self.millis == 0L
}
