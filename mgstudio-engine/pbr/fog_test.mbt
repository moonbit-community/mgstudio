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
    Exponential(value) =>
      inspect(@math.abs(value - density) < 0.0001F, content="true")
    _ => abort("expected exponential fog falloff")
  }
}

///|
test "pbr fog: from_visibility_colors matches Bevy's atmospheric coefficients" {
  // Bevy `FogFalloff::from_visibility_contrast_colors`:
  // powf(1 - linear_channel, E) * koschmieder(15, 0.05) * powf(alpha, E),
  // with the atmospheric_fog example's exact colors.
  let falloff = FogFalloff3d::from_visibility_colors(
    15.0F,
    @color.Color::srgb(0.35F, 0.5F, 0.66F),
    @color.Color::srgb(0.8F, 0.844F, 1.0F),
  )
  match falloff {
    Atmospheric(extinction, inscattering) => {
      inspect(@math.abs(extinction.x - 0.149761F) < 0.0005F, content="true")
      inspect(@math.abs(extinction.y - 0.103772F) < 0.0005F, content="true")
      inspect(@math.abs(extinction.z - 0.051383F) < 0.0005F, content="true")
      inspect(@math.abs(inscattering.x - 0.050684F) < 0.0005F, content="true")
      inspect(@math.abs(inscattering.y - 0.070315F) < 0.0005F, content="true")
      inspect(@math.abs(inscattering.z - 0.199715F) < 0.0005F, content="true")
    }
    _ => abort("expected atmospheric fog falloff")
  }
}
