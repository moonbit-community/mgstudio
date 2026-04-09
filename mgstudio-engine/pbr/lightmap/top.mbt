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
/// Per-mesh lightmap settings aligned with Bevy's `Lightmap`.
pub struct Lightmap {
  image : @asset.Handle[@asset.Image]
  uv_rect : @math.Rect
  bicubic_sampling : Bool
} derive(ToJson, FromJson)

///|
pub fn Lightmap::default() -> Lightmap {
  Lightmap::{
    image: @asset.Handle::new(-1),
    uv_rect: @math.Rect::new(@math.Vec2::zero(), @math.Vec2::new(1.0F, 1.0F)),
    bicubic_sampling: false,
  }
}

///|
pub fn Lightmap::new(image : @asset.Handle[@asset.Image]) -> Lightmap {
  Lightmap::{ ..Lightmap::default(), image, }
}

///|
pub fn Lightmap::with_uv_rect(
  self : Lightmap,
  uv_rect : @math.Rect,
) -> Lightmap {
  Lightmap::{ ..self, uv_rect, }
}

///|
pub fn Lightmap::with_bicubic_sampling(
  self : Lightmap,
  bicubic_sampling : Bool,
) -> Lightmap {
  Lightmap::{ ..self, bicubic_sampling, }
}

///|
pub let ecs_key_lightmap : @ecs.ComponentKey[Lightmap] = @ecs.register_component(
  debug_name="render3d.lightmap",
)

///|
pub impl @ecs.Component for Lightmap with component() {
  ecs_key_lightmap
}
