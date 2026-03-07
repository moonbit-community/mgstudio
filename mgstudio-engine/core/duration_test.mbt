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
test "duration constructors preserve sub-second precision" {
  let duration = Duration::from_secs(5L)
  inspect(duration.as_millis(), content="5000")
  inspect(duration.as_micros(), content="5000000")
  inspect(duration.as_nanos(), content="5000000000")
  inspect(duration.as_secs_f32(), content="5")
  inspect(duration.as_secs_f64(), content="5")

  let millis = Duration::from_millis(250L)
  inspect(millis.as_nanos(), content="250000000")

  let micros = Duration::from_micros(125L)
  inspect(micros.as_nanos(), content="125000")
}

///|
test "duration floating constructors clamp negatives and keep fractions" {
  let duration = Duration::from_secs_f32(0.5F)
  inspect(duration.as_millis(), content="500")
  inspect(duration.as_nanos(), content="500000000")

  let precise = Duration::from_secs_f64(0.0000005)
  inspect(precise.as_nanos(), content="500")

  inspect(Duration::from_secs(-1L).is_zero(), content="true")
  inspect(Duration::from_secs_f32(-0.25F).is_zero(), content="true")
  inspect(Duration::from_millis(-10L).is_zero(), content="true")
}

///|
test "duration arithmetic saturates and checks underflow" {
  let a = Duration::from_millis(750L)
  let b = Duration::from_millis(500L)
  inspect(a.saturating_add(b).as_millis(), content="1250")
  inspect(a.saturating_sub(b).as_millis(), content="250")
  inspect(b.checked_sub(a), content="None")
}

///|
test "duration scaling uses f64 semantics" {
  let duration = Duration::from_millis(400L)
  inspect(duration.mul_f64(0.5).as_millis(), content="200")
  inspect(duration.mul_f64(1.25).as_millis(), content="500")
}
