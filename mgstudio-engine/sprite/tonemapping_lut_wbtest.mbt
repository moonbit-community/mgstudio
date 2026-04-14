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
fn render2d_test_world_with_asset_server() -> @ecs.World {
  let world = @ecs.World::new()
  world.insert_resource(
    @asset.asset_server_resource_key(),
    @asset.AssetServer::new(),
  )
  world
}

///|
test "render2d: tonemapping LUT handles are stored per world core_pipeline resource" {
  let world_a = render2d_test_world_with_asset_server()
  let world_b = render2d_test_world_with_asset_server()

  debug_inspect(
    (try! world_a.get_resource(@core_pipeline.ecs_key_tonemapping_luts)) is None,
    content="true",
  )
  debug_inspect(
    (try! world_b.get_resource(@core_pipeline.ecs_key_tonemapping_luts)) is None,
    content="true",
  )

  @core_pipeline.tonemapping_luts_from_world_or_init(world_a) |> ignore

  debug_inspect(
    (try! world_a.get_resource(@core_pipeline.ecs_key_tonemapping_luts))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world_b.get_resource(@core_pipeline.ecs_key_tonemapping_luts)) is None,
    content="true",
  )
}
