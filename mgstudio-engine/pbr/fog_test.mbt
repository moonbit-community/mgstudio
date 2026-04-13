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
test "pbr fog: koschmieder helper matches exponential convenience constructor" {
  let density = FogFalloff3d::koschmieder(100.0F, 0.05F)
  let from_visibility = FogFalloff3d::from_visibility_contrast(100.0F, 0.05F)
  match from_visibility {
    FogFalloff3d::Exponential(value) =>
      inspect(@math.abs(value - density) < 0.0001F, content="true")
    _ => abort("expected exponential fog falloff")
  }
}
