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
fn read_pbr_runtime_config(world : @ecs.World) -> PbrPluginRuntimeConfig {
  match (try! world.get_resource(ecs_key_pbr_plugin_runtime_config)) {
    Some(config) => config
    None => abort("missing PbrPluginRuntimeConfig resource")
  }
}

///|
fn read_deferred_lighting_state(world : @ecs.World) -> DeferredPbrLightingState {
  match (try! world.get_resource(ecs_key_deferred_pbr_lighting_state)) {
    Some(state) => state
    None => abort("missing DeferredPbrLightingState resource")
  }
}

///|
fn read_standard_material_plugin_state(
  world : @ecs.World,
) -> StandardMaterialPluginState {
  match (try! world.get_resource(ecs_key_standard_material_plugin_state)) {
    Some(state) => state
    None => abort("missing StandardMaterialPluginState resource")
  }
}

///|
fn read_mesh_render_plugin_state(world : @ecs.World) -> MeshRenderPluginState {
  match (try! world.get_resource(ecs_key_mesh_render_plugin_state)) {
    Some(state) => state
    None => abort("missing MeshRenderPluginState resource")
  }
}

///|
fn render_world_with_fog_meta(app : @app.App[@ecs.World]) -> Bool {
  match app.get_sub_app(@app.RenderApp) {
    Some(render_sub_app) => {
      let render_world = render_sub_app.world()
      (try! render_world.get_resource(@pbr_render.FogMeta::resource()))
      is Some(_)
    }
    None => false
  }
}

///|
fn mesh_assets_mut_or_abort(
  world : @ecs.World,
) -> Ref[@asset.Assets[@mesh.Mesh]] {
  let key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets_ref) => assets_ref
    None => abort("missing Assets<Mesh> resource")
  }
}

///|
fn pbr_app_with_mesh3d_entity() -> (
  @app.App[@ecs.World],
  @core.Entity,
  @asset.Handle[@mesh.Mesh],
) {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(PbrPlugin::default())
  let world = app.world()
  let mesh_handle = mesh_assets_mut_or_abort(world).val.add(
    @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::rectangle(1.0F, 1.0F)),
  )
  let entity = world.spawn()
  try! world.set(entity, Mesh3d::new(mesh_handle))
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  (app, entity, mesh_handle)
}

///|
test "render3d: plugin replacement id aligns with bevy_pbr" {
  let plugin = PbrPlugin::default()
  debug_inspect(plugin.name(), content="\"mgstudio.pbr.PbrPlugin\"")
}

///|
test "render3d: modified Mesh asset marks Mesh3d as changed (bevy semantics)" {
  let (app0, entity, mesh_handle) = pbr_app_with_mesh3d_entity()
  let mut app = app0
  let before = app.world().read_sequence()

  debug_inspect(
    mesh_assets_mut_or_abort(app.world()).val.set(
      mesh_handle,
      @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::rectangle(2.0F, 2.0F)),
    ),
    content="true",
  )

  app = app.update()
  let after = app.world().read_sequence()
  let changed = app
    .world()
    .changed_components(
      ecs_key_mesh3d,
      @core.SystemSequence::new(before, after),
    )
    .read()
  debug_inspect(changed.contains(entity), content="true")
}

///|
test "render3d: non-modified Mesh asset events do not mark Mesh3d as changed" {
  let (app0, entity, _mesh_handle) = pbr_app_with_mesh3d_entity()
  let mut app = app0
  let before = app.world().read_sequence()
  app = app.update()
  let after = app.world().read_sequence()
  let changed = app
    .world()
    .changed_components(
      ecs_key_mesh3d,
      @core.SystemSequence::new(before, after),
    )
    .read()
  debug_inspect(changed.contains(entity), content="false")
}

///|
test "render3d: default pbr plugin installs bevy-style runtime config defaults" {
  let app = pbr_plugin(@app.App::new(@ecs.World::new()))
  let config = read_pbr_runtime_config(app.world())
  debug_inspect(config.prepass_enabled, content="true")
  debug_inspect(config.add_default_deferred_lighting_plugin, content="true")
  debug_inspect(config.use_gpu_instance_buffer_builder, content="true")
  debug_inspect(config.gltf_render_enabled, content="true")
  debug_inspect(
    read_mesh_render_plugin_state(app.world()).use_gpu_instance_buffer_builder,
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_materials_plugin_state),
    content="true",
  )
  debug_inspect(render_world_with_fog_meta(app), content="false")
  debug_inspect(
    read_deferred_lighting_state(app.world()).enabled,
    content="true",
  )
  debug_inspect(
    read_standard_material_plugin_state(app.world()).prepass_enabled,
    content="true",
  )
  debug_inspect(
    app.contains_resource(@pbr_prepass.ecs_key_any_prepass_plugin_loaded),
    content="true",
  )
}

///|
test "render3d: pbr plugin config updates runtime feature switches" {
  let _app = pbr_plugin_with(@app.App::new(@ecs.World::new()), PbrPlugin::{
    prepass_enabled: false,
    add_default_deferred_lighting_plugin: false,
    use_gpu_instance_buffer_builder: false,
    gltf_render_enabled: false,
  })

  debug_inspect(pbr_prepass_enabled(_app.world()), content="false")
  debug_inspect(pbr_deferred_lighting_enabled(_app.world()), content="false")
  debug_inspect(
    pbr_gpu_instance_buffer_builder_enabled(_app.world()),
    content="false",
  )
  debug_inspect(pbr_gltf_render_enabled(_app.world()), content="false")
  debug_inspect(
    @gltf_loader.gltf_pbr_material_handler_enabled(),
    content="false",
  )
  debug_inspect(
    read_mesh_render_plugin_state(_app.world()).use_gpu_instance_buffer_builder,
    content="false",
  )
  debug_inspect(
    read_deferred_lighting_state(_app.world()).enabled,
    content="false",
  )
  debug_inspect(
    read_standard_material_plugin_state(_app.world()).prepass_enabled,
    content="false",
  )
  debug_inspect(
    _app.contains_resource(@pbr_prepass.ecs_key_any_prepass_plugin_loaded),
    content="true",
  )

  let _reset = pbr_plugin(@app.App::new(@ecs.World::new()))
  debug_inspect(
    @gltf_loader.gltf_pbr_material_handler_enabled(),
    content="true",
  )
}

///|
test "render3d: plugin group set(PbrPlugin) overrides runtime config resource" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @app.PluginGroupBuilder::start_named("test-pbr")
    .add(PbrPlugin::default())
    .set(PbrPlugin::{
      prepass_enabled: false,
      add_default_deferred_lighting_plugin: false,
      use_gpu_instance_buffer_builder: false,
      gltf_render_enabled: false,
    }),
  )

  let config = read_pbr_runtime_config(app.world())
  debug_inspect(config.prepass_enabled, content="false")
  debug_inspect(config.add_default_deferred_lighting_plugin, content="false")
  debug_inspect(config.use_gpu_instance_buffer_builder, content="false")
  debug_inspect(config.gltf_render_enabled, content="false")
  debug_inspect(
    read_mesh_render_plugin_state(app.world()).use_gpu_instance_buffer_builder,
    content="false",
  )
  debug_inspect(
    read_deferred_lighting_state(app.world()).enabled,
    content="false",
  )
  debug_inspect(
    read_standard_material_plugin_state(app.world()).prepass_enabled,
    content="false",
  )
}

///|
test "render3d: render3d_plugin alias maps to pbr plugin" {
  let app = render3d_plugin(@app.App::new(@ecs.World::new()))
  debug_inspect(
    app.contains_resource(ecs_key_pbr_plugin_runtime_config),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_mesh_render_plugin_state),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_materials_plugin_state),
    content="true",
  )
}
