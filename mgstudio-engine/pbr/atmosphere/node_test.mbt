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
test "pbr atmosphere: extracted atmosphere preserves Bevy radius fields" {
  let extracted = pbr_extracted_atmosphere(
    -1.0F,
    -2.0F,
    @math.Vec3::new(0.1F, 0.2F, 0.3F),
    42,
  )
  inspect(extracted.bottom_radius.to_double(), content="-1")
  inspect(extracted.top_radius.to_double(), content="-2")
  inspect(extracted.medium_id, content="42")
}
