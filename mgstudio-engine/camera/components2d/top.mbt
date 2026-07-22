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
// Bevy source fragment: `bevy/crates/bevy_camera/src/components.rs::Camera2d`.

///|
pub struct Camera2d {}

///|
#warnings("-unnecessary_annotation")
pub fn Camera2d::Camera2d() -> Camera2d {
  Camera2d::{  }
}

///|
pub let ecs_key_camera2d : @ecs.ComponentKey[Camera2d] = @ecs.register_component(
  debug_name="mgstudio.camera.Camera2d",
)

///|
pub impl @ecs.Component for Camera2d with fn component() {
  ecs_key_camera2d
}

///|
fn encode_camera2d(_camera2d : Camera2d) -> Json {
  (0).to_json()
}

///|
fn decode_camera2d(_json : Json) -> Camera2d {
  Camera2d()
}

///|
pub impl ToJson for Camera2d with fn to_json(self) {
  encode_camera2d(self)
}

///|
pub impl @json.FromJson for Camera2d with fn from_json(json, _path) {
  decode_camera2d(json)
}

///|
pub fn register_camera2d_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_camera2d,
    @camera_primitives.ecs_key_frustum,
    fn() { @camera_primitives.Frustum::default_2d() },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    @camera_camera.ecs_key_camera,
    fn() { Camera() },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    @camera_projection2d.ecs_key_projection,
    fn() { @camera_projection2d.Projection::orthographic_2d() },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    @camera_camera.ecs_key_render_target,
    fn() { Screen },
  )
}

///|
pub fn ensure_camera2d_required_components(world : @ecs.World) -> Unit {
  register_camera2d_required_components(world) catch {
    DuplicateRegistration(_, _) => ()
    ArchetypeExists(component_id) =>
      abort(
        "Camera2d required-component registration ran too late for component \{component_id}",
      )
    CyclicRequirement(requiree, required) =>
      abort(
        "Camera2d required-component cycle detected: \{requiree} -> \{required}",
      )
  }
}
