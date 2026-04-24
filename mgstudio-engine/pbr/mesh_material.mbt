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
pub type MeshMaterial3d = @material.MeshMaterial3d

///|
const MESH_RENDER_PLUGIN_NAME : String = "mgstudio.pbr.MeshRenderPlugin"

///|
pub(all) struct MeshRenderPlugin {
  use_gpu_instance_buffer_builder : Bool
}

///|
pub fn MeshRenderPlugin::default() -> MeshRenderPlugin {
  MeshRenderPlugin::{ use_gpu_instance_buffer_builder: true }
}

///|
pub struct MeshRenderPluginState {
  use_gpu_instance_buffer_builder : Bool
}

///|
pub fn MeshRenderPluginState::from_plugin(
  plugin : MeshRenderPlugin,
) -> MeshRenderPluginState {
  MeshRenderPluginState::{
    use_gpu_instance_buffer_builder: plugin.use_gpu_instance_buffer_builder,
  }
}

///|
priv struct MeshRenderPluginMarker {}

///|
let ecs_key_mesh_render_plugin_marker : @ecs.ResourceKey[MeshRenderPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_pbr::MeshRenderPluginMarker",
)

///|
pub let ecs_key_mesh_render_plugin_state : @ecs.ResourceKey[
  MeshRenderPluginState,
] = @ecs.register_resource(debug_name="mgstudio_pbr::MeshRenderPluginState")

///|
fn init_mesh_render_resources(world : @ecs.World) -> Unit {
  @pbr_render.render3d_set_runtime_initialized(world, true)
  if (try! world.get_resource(ecs_key_internal_assets)) is None {
    world.insert_resource(
      ecs_key_internal_assets,
      Render3dInternalAssetsState::new(),
    )
  }
  let auto_exposure_curve_assets_key : @ecs.ResourceKey[
    @asset.Assets[AutoExposureCompensationCurve],
  ] = @asset.assets_resource_key()
  if (try! world.get_resource(auto_exposure_curve_assets_key)) is None {
    world.insert_resource(auto_exposure_curve_assets_key, @asset.Assets::new())
  }
  if (try! world.get_resource_mut(auto_exposure_curve_assets_key))
    is Some(curves_ref) {
    let curves = curves_ref.peek()
    let default_curve_handle : @asset.Handle[AutoExposureCompensationCurve] = @asset.Handle::new(
      0,
    )
    if !curves.contains(default_curve_handle) {
      curves.insert(
        default_curve_handle,
        AutoExposureCompensationCurve::default(),
      )
      |> ignore
    }
  }
}

///|
fn configure_mesh_render_sets(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system(update_mesh_previous_global_transforms)
  .add_pre_update_system(update_previous_view_data)
  .add_post_update_system(@pbr_render.no_automatic_skin_batching)
}

///|
fn render3d_extract_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_extract_system(world)
}

///|
fn render3d_prepare_morphs_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_prepare_morphs_system(world)
}

///|
fn render3d_prepare_skin_bindings_system_in_render_app(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_skin_bindings_system(world)
}

///|
fn render3d_prepare_fog_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_prepare_fog_system(world)
}

///|
fn render3d_prepare_resources_cleanup_system_in_render_app(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_resources_cleanup_system(world)
}

///|
fn render3d_prepare_resources_flush_system_in_render_app(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_resources_flush_system(world)
}

///|
fn render3d_prepare_meshes_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_prepare_meshes_system(world)
}

///|
fn render3d_prepare_bind_groups_system_in_render_app(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_bind_groups_system(world)
}

///|
fn render3d_queue_meshes_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_queue_meshes_system(world)
}

///|
fn render3d_queue_sweep_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_queue_sweep_system(world)
}

///|
fn render3d_execute_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_execute_system(world)
}

///|
fn configure_mesh_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  @render.ensure_sorted_cameras_resource(sub_app.world())
  @pbr_render.ensure_render3d_mesh_runtime_state_resource(sub_app.world())
  @pbr_render.ensure_morph_resources(sub_app.world())
  @pbr_render.ensure_skin_uniforms_resource(sub_app.world())
  let stage = @render.render_schedule_stage()
  @render.configure_base_render_sets(sub_app)
  .add_systems(
    stage,
    @app.system(render3d_extract_system_in_render_app).in_set(
      render3d_set_extract,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_prepare_morphs_system_in_render_app).in_set(
      render3d_set_prepare_resources,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_prepare_skin_bindings_system_in_render_app).in_set(
      render3d_set_prepare_resources,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_prepare_fog_system_in_render_app).in_set(
      render3d_set_prepare_resources,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_prepare_resources_cleanup_system_in_render_app).in_set(
      render3d_set_prepare_resources,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_prepare_resources_flush_system_in_render_app).in_set(
      render3d_set_prepare_resources_flush,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_prepare_meshes_system_in_render_app).in_set(
      render3d_set_prepare_meshes,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_prepare_bind_groups_system_in_render_app).in_set(
      render3d_set_prepare_bind_groups,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_queue_meshes_system_in_render_app).in_set(
      render3d_set_queue_meshes,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_queue_sweep_system_in_render_app).in_set(
      render3d_set_queue_sweep,
    ),
  )
  .add_systems(
    stage,
    @app.system(render3d_execute_system_in_render_app).in_set(
      render3d_set_render,
    ),
  )
}

///|
pub impl @app.Plugin for MeshRenderPlugin with name(_self) {
  MESH_RENDER_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MeshRenderPlugin with build(self, app) {
  mesh_render_plugin_with(app, self)
}

///|
pub fn mesh_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  mesh_render_plugin_with(app, MeshRenderPlugin::default())
}

///|
pub fn mesh_render_plugin_with(
  app : @app.App[@ecs.World],
  plugin : MeshRenderPlugin,
) -> @app.App[@ecs.World] {
  let state = MeshRenderPluginState::from_plugin(plugin)
  let mut next = app.insert_world_resource(
    ecs_key_mesh_render_plugin_state, state,
  )
  if !next.contains_resource(ecs_key_mesh_render_plugin_marker) {
    next = next
      .insert_world_resource(ecs_key_mesh_render_plugin_marker, MeshRenderPluginMarker::{

      })
      .add_startup_system(init_mesh_render_resources)
    next = configure_mesh_render_sets(next)
    next = @render.with_render_app(next, configure_mesh_render_sub_app)
  }
  next
}
