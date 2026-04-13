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
// Bevy source: `bevy/crates/bevy_ui/src/ui_transform.rs`.
pub struct IsDefaultUiCamera {} derive(ToJson, FromJson)

///|
pub fn IsDefaultUiCamera::default() -> IsDefaultUiCamera {
  IsDefaultUiCamera::{  }
}

///|
pub struct UiTargetCamera {
  camera : @core.Entity
} derive(ToJson, FromJson)

///|
pub fn UiTargetCamera::new(camera : @core.Entity) -> UiTargetCamera {
  UiTargetCamera::{ camera, }
}

///|
pub fn UiTargetCamera::entity(self : UiTargetCamera) -> @core.Entity {
  self.camera
}

///|
pub struct ComputedUiTargetCamera {
  camera : @core.Entity
} derive(ToJson, FromJson)

///|
pub fn ComputedUiTargetCamera::new(
  camera : @core.Entity,
) -> ComputedUiTargetCamera {
  ComputedUiTargetCamera::{ camera, }
}

///|
pub fn ComputedUiTargetCamera::default() -> ComputedUiTargetCamera {
  ComputedUiTargetCamera::{ camera: @core.Entity::placeholder() }
}

///|
pub fn ComputedUiTargetCamera::get(
  self : ComputedUiTargetCamera,
) -> @core.Entity? {
  if self.camera.is_placeholder() {
    None
  } else {
    Some(self.camera)
  }
}

///|
pub struct ComputedUiRenderTargetInfo {
  scale_factor : Float
  physical_size : @math.IVec2
} derive(ToJson, FromJson)

///|
pub fn ComputedUiRenderTargetInfo::new(
  scale_factor : Float,
  physical_size : @math.IVec2,
) -> ComputedUiRenderTargetInfo {
  ComputedUiRenderTargetInfo::{ scale_factor, physical_size }
}

///|
pub fn ComputedUiRenderTargetInfo::default() -> ComputedUiRenderTargetInfo {
  ComputedUiRenderTargetInfo::{
    scale_factor: 1.0F,
    physical_size: @math.IVec2::new(0, 0),
  }
}

///|
pub fn ComputedUiRenderTargetInfo::scale_factor(
  self : ComputedUiRenderTargetInfo,
) -> Float {
  safe_scale_factor(self.scale_factor)
}

///|
pub fn ComputedUiRenderTargetInfo::physical_size(
  self : ComputedUiRenderTargetInfo,
) -> @math.IVec2 {
  self.physical_size
}

///|
pub fn ComputedUiRenderTargetInfo::logical_size(
  self : ComputedUiRenderTargetInfo,
) -> @math.Vec2 {
  let scale = self.scale_factor()
  @math.Vec2::new(
    int_to_float(self.physical_size.x) / scale,
    int_to_float(self.physical_size.y) / scale,
  )
}

///|
pub struct UiLayout {
  rect : @math.Rect
} derive(ToJson, FromJson)

///|
pub fn UiLayout::new(rect : @math.Rect) -> UiLayout {
  UiLayout::{ rect, }
}

///|
pub fn UiLayout::rect(self : UiLayout) -> @math.Rect {
  self.rect
}

///|
pub fn UiLayout::size(self : UiLayout) -> @math.Vec2 {
  self.rect.size()
}

///|
pub fn ui_propagate_target_cameras_system(world : @ecs.World) -> Unit {
  let roots = ui_collect_root_entities(world)
  let default_camera_entity = ui_select_default_camera_entity(world)
  for root in roots {
    let camera_entity = match
      (try! world.get_by_key(root, ecs_key_ui_target_camera)) {
      Some(target_camera) => Some(target_camera.entity())
      None => default_camera_entity
    }
    let computed_camera = match camera_entity {
      Some(entity) => ComputedUiTargetCamera::new(entity)
      None => ComputedUiTargetCamera::default()
    }
    let render_target_info = match camera_entity {
      Some(entity) => ui_compute_render_target_info(world, entity)
      None => ComputedUiRenderTargetInfo::default()
    }
    ui_propagate_target_camera_subtree(
      world, root, computed_camera, render_target_info,
    )
  }
}
