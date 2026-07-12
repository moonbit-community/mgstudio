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
test "asset: World close cancels pending acquired loads exactly once" {
  let release_count : Ref[Int] = Ref(0)
  let server = asset_server_standalone()
  server.pending_acquired_loads.push({
    handle_id: 7,
    is_ready: fn(_world, _handle_id) { false },
    release: fn() { release_count.val = release_count.val + 1 },
  })
  let world = @ecs.World::new()
  world.insert_resource(asset_server_resource_key, server)

  world.close()
  world.close()
  debug_inspect(release_count.val, content="1")
  debug_inspect(server.pending_acquired_loads.length(), content="0")
  debug_inspect(server.owner_world is None, content="true")
}
