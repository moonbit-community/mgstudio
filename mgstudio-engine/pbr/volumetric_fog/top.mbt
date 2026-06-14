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
// Bevy source: `bevy/crates/bevy_pbr/src/volumetric_fog/mod.rs`.

///|
const VOLUMETRIC_FOG_PLUGIN_NAME : String = "mgstudio.pbr.volumetric_fog.VolumetricFogPlugin"

///|
pub type VolumetricFog = @light.VolumetricFog

///|
pub type FogVolume = @light.FogVolume

///|
pub struct VolumetricFogPlugin {}

///|
pub fn VolumetricFogPlugin::VolumetricFogPlugin() -> VolumetricFogPlugin {
  VolumetricFogPlugin::{  }
}

///|
pub impl @app.Plugin for VolumetricFogPlugin with fn name(_self) {
  VOLUMETRIC_FOG_PLUGIN_NAME
}

///|
pub impl @app.Plugin for VolumetricFogPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  volumetric_fog_plugin_install_with(app, self)
}

///|
pub struct FogAssets {
  priv plane_mesh : @asset.Handle[@mesh.Mesh]
  priv cube_mesh : @asset.Handle[@mesh.Mesh]
}

///|
fn FogAssets::new(
  plane_mesh : @asset.Handle[@mesh.Mesh],
  cube_mesh : @asset.Handle[@mesh.Mesh],
) -> FogAssets {
  FogAssets::{ plane_mesh, cube_mesh }
}

///|
pub fn FogAssets::plane_mesh(self : FogAssets) -> @asset.Handle[@mesh.Mesh] {
  self.plane_mesh
}

///|
pub fn FogAssets::cube_mesh(self : FogAssets) -> @asset.Handle[@mesh.Mesh] {
  self.cube_mesh
}

///|
pub struct VolumetricFogPluginState {
  fog_assets : FogAssets?
  extracted_view_count : Int
  extracted_volume_count : Int
  extracted_light_count : Int
}

///|
pub fn VolumetricFogPluginState::VolumetricFogPluginState() -> VolumetricFogPluginState {
  VolumetricFogPluginState::{
    fog_assets: None,
    extracted_view_count: 0,
    extracted_volume_count: 0,
    extracted_light_count: 0,
  }
}

///|
let ecs_key_volumetric_fog_plugin_state : @ecs.ResourceKey[
  VolumetricFogPluginState,
] = @ecs.register_resource(debug_name="mgstudio_pbr::VolumetricFogPluginState")

///|
pub impl @app.Resource for VolumetricFogPluginState with fn resource() {
  ecs_key_volumetric_fog_plugin_state
}

///|
fn volumetric_fog_plugin_state_with_assets(
  state : VolumetricFogPluginState,
  fog_assets : FogAssets,
) -> VolumetricFogPluginState {
  VolumetricFogPluginState::{ ..state, fog_assets: Some(fog_assets) }
}

///|
pub fn VolumetricFogPluginState::fog_assets(
  self : VolumetricFogPluginState,
) -> FogAssets? {
  self.fog_assets
}

///|
pub fn volumetric_fog_plugin_state_with_extracted_counts(
  state : VolumetricFogPluginState,
  extracted_view_count : Int,
  extracted_volume_count : Int,
  extracted_light_count : Int,
) -> VolumetricFogPluginState {
  if extracted_light_count <= 0 {
    return VolumetricFogPluginState::{
      ..state,
      extracted_view_count: 0,
      extracted_volume_count: 0,
      extracted_light_count: 0,
    }
  }
  VolumetricFogPluginState::{
    ..state,
    extracted_view_count: volumetric_fog_non_negative_count(
      extracted_view_count,
    ),
    extracted_volume_count: volumetric_fog_non_negative_count(
      extracted_volume_count,
    ),
    extracted_light_count: volumetric_fog_non_negative_count(
      extracted_light_count,
    ),
  }
}

///|
pub fn volumetric_fog_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  volumetric_fog_plugin_install_with(
    app,
    VolumetricFogPlugin::VolumetricFogPlugin(),
  )
}

///|
pub fn volumetric_fog_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : VolumetricFogPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  if app.contains_resource(ecs_key_volumetric_fog_plugin_state) {
    app
  } else {
    let fog_assets = volumetric_fog_create_fog_assets(app.world())
    app.insert_world_resource(
      ecs_key_volumetric_fog_plugin_state,
      VolumetricFogPluginState::VolumetricFogPluginState()
      |> volumetric_fog_plugin_state_with_assets(fog_assets),
    )
  }
}

///|
fn volumetric_fog_non_negative_count(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
fn volumetric_fog_mesh_assets_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[@asset.Assets[@mesh.Mesh]] {
  let key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  match world.get_resource_mut(key) {
    Some(assets) => assets
    None =>
      abort(
        "VolumetricFogPlugin requires Assets<Mesh>; add MeshPlugin before VolumetricFogPlugin",
      )
  }
}

///|
pub fn volumetric_fog_create_fog_assets(world : @ecs.World) -> FogAssets {
  let meshes = volumetric_fog_mesh_assets_mut_or_abort(world)
  meshes.modify(fn(mesh_assets) {
    let plane_mesh = mesh_assets.add(
      @mesh_primitives_dim3.Meshable::mesh(
        @math.Plane3d::new(
          @math.Vec3::new(0.0F, 0.0F, 1.0F),
          @math.Vec2::new(1.0F, 1.0F),
        ),
      ).to_mesh(),
    )
    let cube_mesh = mesh_assets.add(
      @mesh_primitives_dim3.Meshable::mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F)).to_mesh(),
    )
    FogAssets::new(plane_mesh, cube_mesh)
  })
}
