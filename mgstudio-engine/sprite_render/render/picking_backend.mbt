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
// Bevy source: `bevy/crates/bevy_sprite/src/picking_backend.rs`.
pub fn render2d_viewport_to_world_2d(
  world : @ecs.World,
  screen : @math.Vec2,
) -> @math.Vec2? {
  guard render_state_ref(world) is Some(rs) else { return None }
  let id = rs.primary_camera
  if id.is_placeholder() {
    return None
  }
  let mut found : ExtractedCamera2d? = None
  for camera in rs.cameras {
    if camera.entity.id == id.id && camera.entity.generation == id.generation {
      found = Some(camera)
      break
    }
  }
  guard found is Some(cam) else { return None }
  cam.camera.viewport_to_world_2d(
    cam.transform,
    screen,
    cam.projection,
    cam.computed.target_size,
    cam.computed.scale_factor,
  )
}

///|
pub fn render2d_world_to_viewport(
  world_ : @ecs.World,
  world : @math.Vec2,
) -> @math.Vec2? {
  guard render_state_ref(world_) is Some(rs) else { return None }
  let id = rs.primary_camera
  if id.is_placeholder() {
    return None
  }
  let mut found : ExtractedCamera2d? = None
  for camera in rs.cameras {
    if camera.entity.id == id.id && camera.entity.generation == id.generation {
      found = Some(camera)
      break
    }
  }
  guard found is Some(cam) else { return None }
  cam.camera.world_to_viewport_2d(
    cam.transform,
    world,
    cam.projection,
    cam.computed.target_size,
    cam.computed.scale_factor,
  )
}
