// Copyright 2026 International Digital Economy Academy
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
test "pbr transmission: quality maps to stable pipeline key" {
  inspect(screen_space_transmission_pipeline_key(Low), content="0")
  inspect(screen_space_transmission_pipeline_key(Medium), content="1")
  inspect(screen_space_transmission_pipeline_key(High), content="2")
  inspect(screen_space_transmission_pipeline_key(Ultra), content="3")
}

///|
test "pbr transmission: texture prepare preconditions" {
  inspect(
    pbr_should_prepare_transmission_texture(1, 3, true, true, true),
    content="true",
  )
  inspect(
    pbr_should_prepare_transmission_texture(0, 3, true, true, true),
    content="false",
  )
}
