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
test "ui: image_measure_size_px prefers rect over atlas and texture" {
  let rect = @math.Rect::new(
    @math.Vec2::new(4.0F, 8.0F),
    @math.Vec2::new(34.0F, 23.0F),
  )
  let atlas_rect = @math.Rect::new(
    @math.Vec2::new(5.0F, 7.0F),
    @math.Vec2::new(55.0F, 47.0F),
  )
  let size_px = image_measure_size_px(Some(rect), Some(atlas_rect), () => @math.Vec2::new(
    999.0F, 888.0F,
  ))
  inspect(size_px.x == 30.0F && size_px.y == 15.0F, content="true")
}

///|
test "ui: image_measure_size_px falls back to atlas when rect missing" {
  let atlas_rect = @math.Rect::new(
    @math.Vec2::new(10.0F, 20.0F),
    @math.Vec2::new(42.0F, 68.0F),
  )
  let size_px = image_measure_size_px(None, Some(atlas_rect), () => @math.Vec2::new(
    999.0F, 888.0F,
  ))
  inspect(size_px.x == 32.0F && size_px.y == 48.0F, content="true")
}

///|
test "ui: image_measure_size_px uses texture size when rect and atlas missing" {
  let size_px = image_measure_size_px(None, None, () => @math.Vec2::new(
    64.0F, 16.0F,
  ))
  inspect(size_px.x == 64.0F && size_px.y == 16.0F, content="true")
}
