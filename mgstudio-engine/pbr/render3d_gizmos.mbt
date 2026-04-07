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
fn render3d_draw_gizmo_lines_3d(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
) -> Unit {
  guard @sprite.gizmos_mesh_id_3d(camera.layers) is Some(mesh_id) else {
    return
  }
  let material = StandardMaterial::from_color(@sprite.Color::white())
    .with_unlit(true)
    .with_cull_mode(None)
  @pbr_render.render3d_draw_mesh_gpu_payload(
    @pbr_render.render3d_build_mesh_gpu_draw_payload(
      mesh_id,
      camera_entity.id,
      camera_entity.generation,
      -1,
      MESH3D_DRAW_INDIRECT_KIND_NONE,
      -1,
      material,
      @transform.Transform::identity(),
      @transform.Transform::identity(),
      material.base_color.r,
      material.base_color.g,
      material.base_color.b,
      material.base_color.a,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      0.5F,
      0.5F,
      0.0F,
      0.0F,
      0.0F,
      1.5F,
      -1,
      0.0F,
      0.0F,
      -1,
      0.0F,
      0.0F,
      -1,
      -1,
      0.0F,
      @math.Quat::identity(),
      @sprite.Color::white(),
      0.0F,
      0.0F,
      0,
    ),
  )
}
