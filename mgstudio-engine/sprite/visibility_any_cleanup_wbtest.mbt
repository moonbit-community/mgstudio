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
test "render2d: visibility helper reads typed ViewVisibility component after Any switch" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  inspect(render2d_entity_visible_ecs(world, entity), content="true")

  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  inspect(render2d_entity_visible_ecs(world, entity), content="false")
}
