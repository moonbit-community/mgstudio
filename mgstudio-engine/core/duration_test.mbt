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
test "duration from_secs stores milliseconds" {
  let duration = Duration::from_secs(5L)
  inspect(duration.as_millis(), content="5000")
  inspect(duration.as_secs_f32(), content="5")
}

///|
test "duration from_secs_f32 truncates toward zero" {
  let duration = Duration::from_secs_f32(0.5F)
  inspect(duration.as_millis(), content="500")
}

///|
test "duration negatives clamp to zero" {
  inspect(Duration::from_secs(-1L).is_zero(), content="true")
  inspect(Duration::from_secs_f32(-0.25F).is_zero(), content="true")
  inspect(Duration::from_millis(-10L).is_zero(), content="true")
}

///|
test "duration new combines seconds and milliseconds" {
  let duration = Duration::new(2L, millis=125)
  inspect(duration.as_millis(), content="2125")
}
