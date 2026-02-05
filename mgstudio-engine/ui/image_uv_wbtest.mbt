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
test "ui: ui_uv_from_image_rects handles atlas + rect + flips" {
  let image_size = @math.Vec2::new(128.0F, 128.0F)
  let atlas_rect = @math.Rect::new(
    @math.Vec2::new(32.0F, 32.0F),
    @math.Vec2::new(96.0F, 96.0F),
  )
  let rect = @math.Rect::new(
    @math.Vec2::new(16.0F, 8.0F),
    @math.Vec2::new(48.0F, 24.0F),
  )
  let pair = ui_uv_from_image_rects(
    image_size,
    Some(atlas_rect),
    Some(rect),
    false,
    false,
  )
  let uv_min = pair.0
  let uv_max = pair.1
  // (rect + atlas.min) => min=(48,40) max=(80,56)
  // /128 => min=(0.375,0.3125) max=(0.625,0.4375)
  let ok = uv_min.x == 0.375F &&
    uv_min.y == 0.3125F &&
    uv_max.x == 0.625F &&
    uv_max.y == 0.4375F
  inspect(ok, content="true")
  let flipped = ui_uv_from_image_rects(
    image_size,
    Some(atlas_rect),
    Some(rect),
    true,
    true,
  )
  let uv_min2 = flipped.0
  let uv_max2 = flipped.1
  let ok_flip = uv_min2.x == 0.625F &&
    uv_max2.x == 0.375F &&
    uv_min2.y == 0.4375F &&
    uv_max2.y == 0.3125F
  inspect(ok_flip, content="true")
}

///|
test "ui: ui_uv_from_image_rects defaults to full UVs" {
  let image_size = @math.Vec2::new(128.0F, 128.0F)
  let pair = ui_uv_from_image_rects(image_size, None, None, false, false)
  let ok = pair.0.x == 0.0F &&
    pair.0.y == 0.0F &&
    pair.1.x == 1.0F &&
    pair.1.y == 1.0F
  inspect(ok, content="true")
}
