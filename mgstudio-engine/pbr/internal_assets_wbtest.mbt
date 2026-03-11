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
fn render3d_test_world_with_asset_server() -> @ecs.World {
  let world = @ecs.World::new()
  world.insert_resource(
    @asset.asset_server_resource_key(),
    @asset.AssetServer::new(),
  )
  world
}

///|
test "render3d: internal assets are stored per world resource" {
  let world_a = render3d_test_world_with_asset_server()
  let world_b = render3d_test_world_with_asset_server()

  init_render3d_resources(world_a)
  init_render3d_resources(world_b)
  inspect(
    render3d_internal_assets_ref(world_a).unwrap().val.skybox_proxy_mesh is None,
    content="true",
  )
  inspect(
    render3d_internal_assets_ref(world_b).unwrap().val.skybox_proxy_mesh is None,
    content="true",
  )
  inspect(
    render3d_internal_assets_ref(world_a).unwrap().val.tonemapping_luts is None,
    content="true",
  )
  inspect(
    render3d_internal_assets_ref(world_b).unwrap().val.tonemapping_luts is None,
    content="true",
  )

  render3d_internal_assets_ref(world_a).unwrap().val.skybox_proxy_mesh = Some(
    @asset.Handle::new(17),
  )
  render3d_tonemapping_lut_handles(world_a) |> ignore

  inspect(
    render3d_internal_assets_ref(world_a).unwrap().val.skybox_proxy_mesh
    is Some(_),
    content="true",
  )
  inspect(
    render3d_internal_assets_ref(world_b).unwrap().val.skybox_proxy_mesh is None,
    content="true",
  )
  inspect(
    render3d_internal_assets_ref(world_a).unwrap().val.tonemapping_luts
    is Some(_),
    content="true",
  )
  inspect(
    render3d_internal_assets_ref(world_b).unwrap().val.tonemapping_luts is None,
    content="true",
  )
}
