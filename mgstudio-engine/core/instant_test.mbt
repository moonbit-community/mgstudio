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
test "instant supports duration arithmetic" {
  let start = Instant::from_millis(100L)
  let later = start.saturating_add(Duration::from_millis(250L))
  debug_inspect(later.as_millis(), content="350")
  debug_inspect(later.duration_since(start).as_millis(), content="250")
}

///|
test "instant checked duration since returns none when inverted" {
  let start = Instant::from_millis(100L)
  let earlier = Instant::from_millis(50L)
  debug_inspect(earlier.checked_duration_since(start), content="None")
  debug_inspect(
    earlier.saturating_duration_since(start).as_millis(),
    content="0",
  )
}
