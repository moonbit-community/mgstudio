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
test "host_time_now advances without whole-second quantization" {
  let start = host_time_now()
  let mut current = start
  for _ in 0..<1_000_000 {
    current = host_time_now()
    if current > start {
      break
    }
  }
  inspect(current > start, content="true")
  inspect(current - start < 1.0F, content="true")
}
