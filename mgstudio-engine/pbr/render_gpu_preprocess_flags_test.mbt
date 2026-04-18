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
test "render3d gpu preprocess: frustum culling applies only when all Bevy opt-outs are false" {
  debug_inspect(
    render3d_should_apply_cpu_frustum_culling_flags(false, false, false),
    content="true",
  )
  debug_inspect(
    render3d_should_apply_cpu_frustum_culling_flags(true, false, false),
    content="false",
  )
  debug_inspect(
    render3d_should_apply_cpu_frustum_culling_flags(false, true, false),
    content="false",
  )
  debug_inspect(
    render3d_should_apply_cpu_frustum_culling_flags(false, false, true),
    content="false",
  )
}

///|
test "render3d gpu preprocess: transmissive phase classification follows bevy render phase type" {
  let opaque_transmissive = StandardMaterial::default().with_specular_transmission(
    0.6F,
  )
  let masked_transmissive = StandardMaterial::default()
    .with_specular_transmission(0.6F)
    .with_alpha_mode(@material.AlphaMode3d::Mask(0.5F))
  let transparent_transmissive = StandardMaterial::default()
    .with_specular_transmission(0.6F)
    .with_alpha_mode(@material.AlphaMode3d::Blend)
  debug_inspect(
    standard_material_render_phase_type(opaque_transmissive)
    is @material.RenderPhaseType::Transmissive,
    content="true",
  )
  debug_inspect(
    standard_material_render_phase_type(masked_transmissive)
    is @material.RenderPhaseType::Transmissive,
    content="true",
  )
  debug_inspect(
    standard_material_render_phase_type(transparent_transmissive)
    is @material.RenderPhaseType::Transparent,
    content="true",
  )
}
