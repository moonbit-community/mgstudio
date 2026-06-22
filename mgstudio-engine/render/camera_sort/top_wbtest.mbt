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
test "render camera sort: SortedCameras stores Bevy-shaped camera metadata" {
  let first_entity = @core.Entity::new(1, 0)
  let second_entity = @core.Entity::new(2, 0)
  let first = SortedCamera::new(
    first_entity,
    0,
    Some(
      @camera_render_target.NormalizedRenderTarget::Image(
        @camera_render_target.ImageRenderTarget::new(7),
      ),
    ),
    true,
    CameraOutputMode::Write,
  )
  let second = SortedCamera::new(
    second_entity,
    1,
    Some(
      @camera_render_target.NormalizedRenderTarget::TextureView(
        @camera_render_target.ManualTextureViewHandle::new(9),
      ),
    ),
    false,
    CameraOutputMode::Skip,
  )
  let sorted = SortedCameras::{ cameras: [first, second] }
  let entities = sorted.camera_entities()

  debug_inspect(sorted.len(), content="2")
  debug_inspect(sorted.is_empty(), content="false")
  debug_inspect([entities[0].id, entities[1].id], content="[1, 2]")
  debug_inspect(sorted.cameras()[0].hdr(), content="true")
  debug_inspect(sorted.cameras()[0].writes_output(), content="true")
  debug_inspect(sorted.cameras()[1].writes_output(), content="false")
}
