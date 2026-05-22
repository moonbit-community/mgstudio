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
test "pbr meshlet: runtime defaults to unavailable on current path" {
  let runtime_available = meshlet_runtime_available()
  match meshlet_runtime_status() {
    Enabled => inspect(runtime_available, content="true")
    RuntimeUnavailable => inspect(!runtime_available, content="true")
  }
}

///|
test "pbr meshlet: portable visibility buffer drops texture atomics" {
  let required = meshlet_required_wgpu_features()
  inspect(
    required == @renderer.meshlet_required_rust_features_u64(),
    content="true",
  )
  inspect((required & 0x0000400000000000UL) == 0UL, content="true")
  inspect((required & 0x0000000010000000UL) == 0UL, content="true")
  inspect((required & 0x0000002000000000UL) == 0UL, content="true")
  inspect((required & 0x0000004000000000UL) != 0UL, content="true")
  inspect((required & 0x0000000000000001UL) != 0UL, content="true")
  inspect((required & 0x0000000000010000UL) != 0UL, content="true")
}

///|
test "pbr meshlet: runtime status helper follows availability" {
  inspect(
    meshlet_runtime_status_from_availability(false) is RuntimeUnavailable,
    content="true",
  )
  inspect(
    meshlet_runtime_status_from_availability(true) is Enabled,
    content="true",
  )
}

///|
test "panic pbr meshlet: plugin rejects oversized cluster buffer slots" {
  ignore(MeshletPlugin::new(MESHLET_MAX_CLUSTER_BUFFER_SLOTS + 100))
}

///|
test "panic pbr meshlet: plugin rejects non-positive cluster buffer slots" {
  ignore(MeshletPlugin::new(0))
}

///|
test "pbr meshlet: plugin state includes missing feature mask" {
  let runtime_available = meshlet_runtime_available()
  let state = MeshletPluginState::MeshletPluginState()
  if runtime_available {
    inspect(state.runtime_status is Enabled, content="true")
  } else {
    inspect(state.runtime_status is RuntimeUnavailable, content="true")
  }
  let expected_missing = @renderer.meshlet_missing_rust_features_u64()
  inspect(state.missing_required_features == expected_missing, content="true")
  inspect(
    state.missing_native_subgroup_barrier ==
    @renderer.meshlet_missing_native_subgroup_barrier(),
    content="true",
  )
  inspect(
    state.missing_native_immediates ==
    @renderer.meshlet_missing_native_immediates(),
    content="true",
  )
  inspect(
    state.adapter_supports_mesh_shader ==
    @renderer.meshlet_adapter_supports_mesh_shader(),
    content="true",
  )
}

///|
test "pbr meshlet: plugin installs state into app and render sub-app" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MeshletPlugin::MeshletPlugin())
  inspect(
    app.world().get_resource(ecs_key_meshlet_plugin_state) is Some(_),
    content="true",
  )
  let meshlet_assets_key : @ecs.ResourceKey[@asset.Assets[MeshletMesh]] = @asset.assets_resource_key()
  inspect(
    app.world().get_resource(meshlet_assets_key) is Some(_),
    content="true",
  )
  let render_world = app.sub_app(@app.RenderApp).world()
  inspect(
    render_world.get_resource(ecs_key_meshlet_plugin_state) is Some(_),
    content="true",
  )
  inspect(
    render_world.get_resource(ecs_key_meshlet_instance_manager) is Some(_),
    content="true",
  )
  inspect(
    render_world.get_resource(ecs_key_meshlet_resource_manager) is Some(_),
    content="true",
  )
  inspect(
    render_world.get_resource(ecs_key_meshlet_pipelines) is Some(_),
    content="true",
  )
  inspect(
    render_world.get_resource(ecs_key_meshlet_mesh_manager) is Some(_),
    content="true",
  )
}

///|
test "pbr meshlet: mesh component installs Bevy required components" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MeshletPlugin::MeshletPlugin())
  let entity = app.world().spawn()
  try! app
  .world()
  .set_by_key(entity, ecs_key_meshlet_mesh3d, MeshletMesh3d::new(42))
  inspect(
    (try! app.world().get_by_key(entity, @transform.ecs_key_transform))
    is Some(_),
    content="true",
  )
  inspect(
    (try! app.world().get_by_key(entity, @pbr.ecs_key_previous_global_transform))
    is Some(_),
    content="true",
  )
  inspect(
    (try! app.world().get_by_key(entity, @visibility.ecs_key_visibility))
    is Some(_),
    content="true",
  )
}

///|
test "pbr meshlet: view resources use camera physical viewport size" {
  let target_camera = @sprite.Camera::Camera()
  debug_inspect(meshlet_view_size_from_camera(target_camera), content="(1, 1)")
  let viewport_camera = target_camera.with_viewport(
    @sprite.Viewport::new(@math.IVec2::new(10, 20), @math.IVec2::new(640, 360)),
  )
  debug_inspect(
    meshlet_view_size_from_camera(viewport_camera),
    content="(640, 360)",
  )
}

///|
test "pbr meshlet: configure views inserts prepass and deferred bins by view flags" {
  let world = @ecs.World::new()
  let view_entity = world.spawn()
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_msaa,
    @core_pipeline.Msaa::Off,
  )
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_normal_prepass,
    @core_pipeline.NormalPrepass::NormalPrepass(),
  )
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_deferred_prepass,
    @core_pipeline.DeferredPrepass::DeferredPrepass(),
  )
  let app = @app.App::new(world)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MeshletPlugin::MeshletPlugin())
    .update()
  inspect(
    (try! app
    .world()
    .get_by_key(view_entity, ecs_key_meshlet_view_materials_main_opaque_pass))
    is Some(_),
    content="true",
  )
  inspect(
    (try! app
    .world()
    .get_by_key(view_entity, ecs_key_meshlet_view_materials_prepass))
    is Some(_),
    content="true",
  )
  inspect(
    (try! app
    .world()
    .get_by_key(
      view_entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
    ))
    is Some(_),
    content="true",
  )
}

///|
test "pbr meshlet: configure views mirrors Bevy prepass bin insertion" {
  let world = @ecs.World::new()
  let view_entity = world.spawn()
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_msaa,
    @core_pipeline.Msaa::Off,
  )
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_normal_prepass,
    @core_pipeline.NormalPrepass::NormalPrepass(),
  )
  let app = @app.App::new(world)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MeshletPlugin::MeshletPlugin())
    .update()
  inspect(
    (try! app
    .world()
    .get_by_key(
      view_entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
    ))
    is Some(_),
    content="true",
  )
}

///|
test "panic pbr meshlet: configure views rejects msaa-enabled views" {
  let world = @ecs.World::new()
  let view_entity = world.spawn()
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_msaa,
    @core_pipeline.Msaa::Sample4,
  )
  ignore(
    @app.App::new(world)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MeshletPlugin::MeshletPlugin())
    .update(),
  )
}

///|
test "pbr meshlet: material prepare system creates empty per-view material bins" {
  let world = @ecs.World::new()
  let view_entity = world.spawn()
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_msaa,
    @core_pipeline.Msaa::Off,
  )
  let app = @app.App::new(world)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MeshletPlugin::MeshletPlugin())
    .update()
  match
    (try! app
    .world()
    .get_by_key(view_entity, ecs_key_meshlet_view_materials_main_opaque_pass)) {
    Some(main_opaque) => inspect(main_opaque.len(), content="0")
    None => inspect(false, content="true")
  }
}

///|
test "pbr meshlet: transmission and alpha-mode helpers follow bevy standard material semantics" {
  let diffuse_only = @material.StandardMaterial::StandardMaterial().with_diffuse_transmission(
    0.8F,
  )
  let specular_only = @material.StandardMaterial::StandardMaterial().with_specular_transmission(
    0.8F,
  )
  inspect(
    !@pbr.standard_material_reads_view_transmission_texture(diffuse_only),
    content="true",
  )
  inspect(
    @pbr.standard_material_reads_view_transmission_texture(specular_only),
    content="true",
  )
  let alpha_to_coverage_material = @material.StandardMaterial::StandardMaterial().with_alpha_mode(
    @material.AlphaMode3d::AlphaToCoverage,
  )
  inspect(
    @pbr.standard_material_render_phase_type(alpha_to_coverage_material)
    is @material.RenderPhaseType::Opaque,
    content="true",
  )
}
