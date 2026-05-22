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
test "render3d: main pass skips deferred opaque materials like bevy queue_material_meshes" {
  let deferred_opaque = @material.MaterialProperties::MaterialProperties()
    .with_render_phase_type(@material.RenderPhaseType::Opaque)
    .with_render_method(OpaqueRendererMethod::Deferred)
  let forward_opaque = @material.MaterialProperties::MaterialProperties()
    .with_render_phase_type(@material.RenderPhaseType::Opaque)
    .with_render_method(OpaqueRendererMethod::Forward)
  let deferred_alpha_mask = @material.MaterialProperties::MaterialProperties()
    .with_render_phase_type(@material.RenderPhaseType::AlphaMask)
    .with_render_method(OpaqueRendererMethod::Deferred)

  debug_inspect(
    render3d_main_pass_skips_deferred_opaque(deferred_opaque),
    content="true",
  )
  debug_inspect(
    render3d_main_pass_skips_deferred_opaque(forward_opaque),
    content="false",
  )
  debug_inspect(
    render3d_main_pass_skips_deferred_opaque(deferred_alpha_mask),
    content="false",
  )
}
