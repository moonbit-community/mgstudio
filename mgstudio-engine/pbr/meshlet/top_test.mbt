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
test "pbr meshlet: required feature mask includes texture atomics" {
  let required = meshlet_required_wgpu_features()
  inspect(
    required == @renderer.meshlet_required_rust_features_u64(),
    content="true",
  )
  inspect((required & 0x0000000010000000UL) != 0UL, content="true")
  inspect((required & 0x0000400000000000UL) != 0UL, content="true")
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
  let state = MeshletPluginState::default()
  if runtime_available {
    inspect(state.runtime_status is Enabled, content="true")
  } else {
    inspect(state.runtime_status is RuntimeUnavailable, content="true")
  }
  inspect(
    (state.missing_required_features & meshlet_required_wgpu_features()) != 0UL,
    content="true",
  )
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
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(MeshletPlugin::default())
  inspect(
    (try! app.world().get_resource(ecs_key_meshlet_plugin_state)) is Some(_),
    content="true",
  )
  let render_world = app.sub_app(@app.RenderApp).world()
  inspect(
    (try! render_world.get_resource(ecs_key_meshlet_plugin_state)) is Some(_),
    content="true",
  )
  inspect(
    (try! render_world.get_resource(ecs_key_meshlet_instance_manager))
    is Some(_),
    content="true",
  )
  if meshlet_runtime_available() {
    inspect(
      (try! render_world.get_resource(ecs_key_meshlet_resource_manager))
      is Some(_),
      content="true",
    )
  } else {
    inspect(
      (try! render_world.get_resource(ecs_key_meshlet_resource_manager)) is None,
      content="true",
    )
  }
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
    @core_pipeline.NormalPrepass::default(),
  )
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_deferred_prepass,
    @core_pipeline.DeferredPrepass::default(),
  )
  let app = @app.App::new(world)
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(MeshletPlugin::default())
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
test "pbr meshlet: configure views does not insert deferred bin without deferred prepass" {
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
    @core_pipeline.NormalPrepass::default(),
  )
  let app = @app.App::new(world)
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(MeshletPlugin::default())
    .update()
  inspect(
    (try! app
    .world()
    .get_by_key(
      view_entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
    ))
    is None,
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
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(MeshletPlugin::default())
    .update(),
  )
}

///|
test "pbr meshlet: material prepare system writes per-view material bins" {
  let world = @ecs.World::new()
  let view_entity = world.spawn()
  try! world.set_by_key(
    view_entity,
    @core_pipeline.ecs_key_msaa,
    @core_pipeline.Msaa::Off,
  )
  let mesh_entity = world.spawn()
  try! world.set_by_key(
    mesh_entity,
    ecs_key_meshlet_mesh3d,
    MeshletMesh3d::new(42),
  )
  let app = @app.App::new(world)
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(MeshletPlugin::default())
    .update()
  match
    (try! app
    .world()
    .get_by_key(view_entity, ecs_key_meshlet_view_materials_main_opaque_pass)) {
    Some(main_opaque) => inspect(main_opaque.len(), content="1")
    None => inspect(false, content="true")
  }
}
