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
fn read_diagnostic_value(
  app : @app.App[@ecs.World],
  path : DiagnosticPath,
) -> Float {
  let store = try! app
    .world()
    .get_resource(DiagnosticsStore::resource())
    .unwrap()
  store.get(path).unwrap().value().unwrap()
}

///|
test "diagnostics: render diagnostics plugin records native gpu frame counters" {
  @render.host_gpu_begin_frame(0) |> ignore
  @render.host_gpu_end_frame(0)

  let app = @app.App::new(@ecs.World::new()).add_plugins([
    diagnostics_plugin, render_diagnostics_plugin,
  ])

  let frame = @render.host_gpu_begin_frame(0)
  @render.host_gpu_draw_mesh(
    mesh_id=1,
    x=0.0F,
    y=0.0F,
    rotation=0.0F,
    scale_x=1.0F,
    scale_y=1.0F,
    color_r=1.0F,
    color_g=1.0F,
    color_b=1.0F,
    color_a=1.0F,
    alpha_mode_kind=0,
    alpha_cutoff=0.5F,
    texture_id=0,
    uv_offset_x=0.0F,
    uv_offset_y=0.0F,
    uv_scale_x=1.0F,
    uv_scale_y=1.0F,
  )
  @render.host_gpu_draw_mesh3d(
    mesh_id=1,
    x=0.0F,
    y=0.0F,
    z=0.0F,
    rotation_x=0.0F,
    rotation_y=0.0F,
    rotation_z=0.0F,
    rotation_w=1.0F,
    scale_x=1.0F,
    scale_y=1.0F,
    scale_z=1.0F,
    previous_x=0.0F,
    previous_y=0.0F,
    previous_z=0.0F,
    previous_rotation_x=0.0F,
    previous_rotation_y=0.0F,
    previous_rotation_z=0.0F,
    previous_rotation_w=1.0F,
    previous_scale_x=1.0F,
    previous_scale_y=1.0F,
    previous_scale_z=1.0F,
    color_r=1.0F,
    color_g=1.0F,
    color_b=1.0F,
    color_a=1.0F,
    texture_id=0,
    uv_transform_a=1.0F,
    uv_transform_b=0.0F,
    uv_transform_c=0.0F,
    uv_transform_d=1.0F,
    uv_transform_tx=0.0F,
    uv_transform_ty=0.0F,
    uv_transform_mode=0.0F,
    normal_texture_id=0,
    emissive_texture_id=0,
    metallic_roughness_texture_id=0,
    occlusion_texture_id=0,
    depth_texture_id=0,
    emissive_r=0.0F,
    emissive_g=0.0F,
    emissive_b=0.0F,
    unlit=0.0F,
    metallic=0.0F,
    roughness=1.0F,
    reflectance=0.5F,
    parallax_depth_scale=0.0F,
    max_parallax_layer_count=0.0F,
    max_relief_mapping_search_steps=0.0F,
    anisotropy_texture_id=0,
    anisotropy_strength=0.0F,
    anisotropy_rotation=0.0F,
    specular_tint_texture_id=0,
    specular_tint_r=1.0F,
    specular_tint_g=1.0F,
    specular_tint_b=1.0F,
    diffuse_transmission=0.0F,
    specular_transmission=0.0F,
    thickness=0.0F,
    ior=1.5F,
    transmission_source_texture_id=0,
    transmission_blur_taps=0.0F,
    transmission_steps=0.0F,
    point_shadow_texture_id=0,
    point_shadow_enabled=0.0F,
    point_shadow_depth_bias=0.0F,
    cull_mode=1,
  )
  @render.host_gpu_end_frame(frame)
  app.run_once() |> ignore

  inspect(
    read_diagnostic_value(app, render_diagnostic_mesh2d_draw_calls),
    content="1",
  )
  inspect(
    read_diagnostic_value(app, render_diagnostic_mesh3d_draw_calls),
    content="1",
  )
  inspect(
    read_diagnostic_value(app, render_diagnostic_mesh2d_executed_draw_calls),
    content="0",
  )
  inspect(
    read_diagnostic_value(app, render_diagnostic_mesh3d_executed_draw_calls),
    content="0",
  )
}

///|
test "diagnostics: render diagnostics plugin reports zero scene counters without render work" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([
    diagnostics_plugin, render_diagnostics_plugin,
  ])
  app.run_once() |> ignore

  inspect(
    read_diagnostic_value(app, render_diagnostic_prepared_cameras_2d),
    content="0",
  )
  inspect(
    read_diagnostic_value(app, render_diagnostic_queued_draw_items_2d),
    content="0",
  )
  inspect(
    read_diagnostic_value(app, render_diagnostic_prepared_cameras_3d),
    content="0",
  )
  inspect(
    read_diagnostic_value(app, render_diagnostic_visible_meshes_3d),
    content="0",
  )
}
