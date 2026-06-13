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
test "pbr ssao: quality sample counts follow bevy presets" {
  debug_inspect(ssao_quality_sample_counts(Low), content="(1, 2)")
  debug_inspect(ssao_quality_sample_counts(Medium), content="(2, 2)")
  debug_inspect(ssao_quality_sample_counts(High), content="(3, 3)")
  debug_inspect(ssao_quality_sample_counts(Ultra), content="(9, 3)")
  debug_inspect(ssao_quality_sample_counts(Custom(5, 4)), content="(5, 4)")
}

///|
test "pbr ssao: hilbert index follows Bevy helper" {
  debug_inspect(ssao_hilbert_index(0, 0), content="0")
  debug_inspect(ssao_hilbert_index(1, 0), content="1")
  debug_inspect(ssao_hilbert_index(0, 1), content="3")
  debug_inspect(ssao_hilbert_index(63, 63), content="2730")
  let lut = ssao_generate_hilbert_index_lut()
  debug_inspect(lut.length(), content="64")
  debug_inspect(lut[0].length(), content="64")
  debug_inspect(lut[63][63], content="2730")
}

///|
test "pbr ssao: resource owners default to unresolved render ids" {
  let resources = ScreenSpaceAmbientOcclusionResources::ScreenSpaceAmbientOcclusionResources()
  let bind_groups = SsaoBindGroups::SsaoBindGroups()
  debug_inspect(
    resources.screen_space_ambient_occlusion_texture_id(),
    content="-1",
  )
  debug_inspect(bind_groups.common_bind_group_id, content="-1")
}
