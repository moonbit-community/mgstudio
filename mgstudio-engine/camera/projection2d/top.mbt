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
// Bevy source fragment: `bevy/crates/bevy_camera/src/projection.rs`.
// Mgstudio's 2D render path currently carries only the orthographic projection
// subset needed by the Bevy `Camera2d` authoring surface.

///|
pub struct OrthographicProjection {
  scale : Float
} derive(ToJson, FromJson)

///|
pub fn OrthographicProjection::new(scale : Float) -> OrthographicProjection {
  let safe = if scale == 0.0F { 1.0F } else { scale }
  OrthographicProjection::{ scale: safe }
}

///|
pub fn OrthographicProjection::default_2d() -> OrthographicProjection {
  OrthographicProjection::new(1.0F)
}

///|
pub fn OrthographicProjection::with_scale(
  self : OrthographicProjection,
  scale : Float,
) -> OrthographicProjection {
  self |> ignore
  OrthographicProjection::new(scale)
}

///|
pub(all) enum Projection {
  Orthographic(OrthographicProjection)
}

///|
pub fn Projection::orthographic_2d() -> Projection {
  Orthographic(OrthographicProjection::default_2d())
}

///|
pub let ecs_key_projection : @ecs.ComponentKey[Projection] = @ecs.register_component(
  debug_name="mgstudio.camera.Projection2d",
)

///|
pub impl @ecs.Component for Projection with fn component() {
  ecs_key_projection
}

///|
fn encode_projection(projection : Projection) -> Json {
  match projection {
    Orthographic(orthographic) => (0, orthographic.scale).to_json()
  }
}

///|
fn decode_projection(json : Json) -> Projection {
  let (tag, payload) : (Int, Float) = try! @json.from_json(json)
  match tag {
    0 => Orthographic(OrthographicProjection::new(payload))
    _ => Projection::orthographic_2d()
  }
}

///|
pub impl ToJson for Projection with fn to_json(self) {
  encode_projection(self)
}

///|
pub impl @json.FromJson for Projection with fn from_json(json, _path) {
  decode_projection(json)
}
