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
test "render3d: plugin replacement id aligns with bevy_pbr" {
  let plugin = PbrPlugin::default()
  debug_inspect(plugin.replacement_id(), content="\"bevy_pbr::PbrPlugin\"")
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
  debug_inspect(app.contains_resource(ecs_key_fog_plugin_state), content="true")
  debug_inspect(
    read_deferred_lighting_state(app.world()).enabled,
    content="true",
  )
  debug_inspect(
    read_standard_material_plugin_state(app.world()).prepass_enabled,
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

  debug_inspect(pbr_prepass_enabled(), content="false")
  debug_inspect(pbr_deferred_lighting_enabled(), content="false")
  debug_inspect(pbr_gpu_instance_buffer_builder_enabled(), content="false")
  debug_inspect(pbr_gltf_render_enabled(), content="false")
  debug_inspect(@gltf.gltf_pbr_material_handler_enabled(), content="false")
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

  let _reset = pbr_plugin(@app.App::new(@ecs.World::new()))
  debug_inspect(@gltf.gltf_pbr_material_handler_enabled(), content="true")
}

///|
test "render3d: plugin group set(PbrPlugin) overrides runtime config resource" {
  let app = @app.App::new(@ecs.World::new()).add_plugin_group(fn() {
    @app.PluginGroupBuilder::start_named("test-pbr")
    .add_named(id=PBR_PLUGIN_ID, pbr_plugin)
    .set(PbrPlugin::{
      prepass_enabled: false,
      add_default_deferred_lighting_plugin: false,
      use_gpu_instance_buffer_builder: false,
      gltf_render_enabled: false,
    })
  })

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
