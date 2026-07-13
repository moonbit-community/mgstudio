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
test "pbr volumetric fog: plugin creates Bevy fog hull mesh assets" {
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let app = @app.App::new(lifecycle_world_15_0)
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let before_count = match app.world().get_resource(mesh_assets_key) {
    Some(meshes) => meshes.len()
    None => -1
  }
  let app = app.add_plugins(
    @volumetric_fog.VolumetricFogPlugin::VolumetricFogPlugin(),
  )
  let after_count = match app.world().get_resource(mesh_assets_key) {
    Some(meshes) => meshes.len()
    None => -1
  }
  inspect(after_count - before_count, content="2")
  let render_world = app.sub_app(@app.RenderApp).world()
  match render_world.get_resource(@volumetric_fog.FogAssets::resource()) {
    Some(fog_assets) => {
      let meshes = app.world().get_resource(mesh_assets_key).unwrap()
      inspect(
        meshes.get(fog_assets.plane_mesh()).unwrap().vertex_count() > 0,
        content="true",
      )
      inspect(
        meshes.get(fog_assets.cube_mesh()).unwrap().vertex_count() > 0,
        content="true",
      )
    }
    None => inspect("missing fog assets", content="present fog assets")
  }
  match
    render_world.get_resource(@volumetric_fog.VolumetricFogPipeline::resource()) {
    Some(pipeline) =>
      inspect(
        pipeline.shader_path(),
        content="pbr/volumetric_fog/volumetric_fog.wgsl",
      )
    None => inspect("missing pipeline", content="present pipeline")
  }
  inspect(
    render_world.get_resource(
      @volumetric_fog.VolumetricFogUniformBuffer::resource(),
    )
    is Some(_),
    content="true",
  )
}
