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
test "render3d: light probe gather uses camera visible cluster list" {
  let world = @ecs.World::new()
  let camera = world.spawn()
  let visible_probe = world.spawn()
  let hidden_probe = world.spawn()
  let visible_volume = world.spawn()
  let hidden_volume = world.spawn()
  try! (world.set_by_key(
    camera,
    @light_cluster.VisibleClusterableObjects::component(),
    @light_cluster.VisibleClusterableObjects::from_lists([], [visible_probe], [
      visible_volume,
    ]),
  )
  |> ignore)

  let visible = render3d_camera_visible_reflection_probe_entities(world, camera)
  inspect(visible.length(), content="1")
  inspect(visible[0] == visible_probe, content="true")
  inspect(visible[0] == hidden_probe, content="false")
  let visible_irradiance_volumes = render3d_camera_visible_irradiance_volume_entities(
    world, camera,
  )
  inspect(visible_irradiance_volumes.length(), content="1")
  inspect(visible_irradiance_volumes[0] == visible_volume, content="true")
  inspect(visible_irradiance_volumes[0] == hidden_volume, content="false")
}
