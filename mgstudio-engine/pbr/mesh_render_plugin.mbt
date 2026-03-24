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
pub const MESH_RENDER_PLUGIN_ID : String = "bevy_pbr::MeshRenderPlugin"

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
  debug_name="bevy_pbr::MeshRenderPluginMarker",
)

///|
pub let ecs_key_mesh_render_plugin_state : @ecs.ResourceKey[
  MeshRenderPluginState,
] = @ecs.register_resource(debug_name="bevy_pbr::MeshRenderPluginState")

///|
fn init_mesh_render_resources(world : @ecs.World) -> Unit {
  let ecs_world = world
  render3d_runtime_initialized_ref.val = true
  let ambient = get_global_ambient_light_resource(ecs_world)
  if !ambient.is_present() {
    ambient.insert(GlobalAmbientLight::default())
  }
  let point_light_shadow_map = get_point_light_shadow_map_resource(ecs_world)
  if !point_light_shadow_map.is_present() {
    point_light_shadow_map.insert(PointLightShadowMap::default())
  }
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
  if (try! world.get_resource_ref_mut(auto_exposure_curve_assets_key))
    is Some(curves_ref) {
    let default_curve_handle : @asset.Handle[AutoExposureCompensationCurve] = @asset.Handle::new(
      0,
    )
    if !curves_ref.val.contains(default_curve_handle) {
      curves_ref.val.insert(
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
  app.add_post_update_system_config(
    @app.system(render3d_update_frusta_system).in_set(
      render3d_set_update_frusta,
    ),
  )
}

///|
fn render3d_extract_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_extract_system(world)
}

///|
fn render3d_prepare_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_prepare_system(world)
}

///|
fn render3d_queue_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_queue_system(world)
}

///|
fn render3d_execute_system_in_render_app(world : @ecs.World) -> Unit {
  render3d_execute_system(world)
}

///|
fn configure_mesh_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  ensure_render3d_phase_state_resource(sub_app.world())
  sub_app
  .add_systems(
    @app.PostUpdate,
    @app.system(render3d_extract_system_in_render_app).in_set(
      render3d_set_extract,
    ),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(render3d_prepare_system_in_render_app).in_set(
      render3d_set_prepare,
    ),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(render3d_queue_system_in_render_app).in_set(render3d_set_queue),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(render3d_execute_system_in_render_app).in_set(
      render3d_set_render,
    ),
  )
  .configure_set(@app.PostUpdate, render3d_set_extract, before=[
    render3d_set_prepare,
  ])
  .configure_set(@app.PostUpdate, render3d_set_prepare, before=[
    render3d_set_queue,
  ])
  .configure_set(@app.PostUpdate, render3d_set_queue, before=[
    render3d_set_render,
  ])
}

///|
pub impl @app.PluginReplacement for MeshRenderPlugin with replacement_id(_self) {
  MESH_RENDER_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for MeshRenderPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    mesh_render_plugin_with(app, self)
  }
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
