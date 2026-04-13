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
// Bevy source: `bevy/crates/bevy_ui_render/src/render_pass.rs`.
fn ensure_ui_scale_resource(world : @ecs.World) -> @ui.UiScale {
  let res = @ui.get_ui_scale_resource(world)
  match res.get() {
    Some(value) => value
    None => {
      let value = @ui.UiScale::new(1.0F)
      res.insert(value)
      value
    }
  }
}

///|
priv struct UiResolvedCameraState {
  camera_entity : @core.Entity?
  viewport_size : @math.Vec2
  render_target_info : @ui.ComputedUiRenderTargetInfo?
}

///|
fn ui_resolved_camera_state_default() -> UiResolvedCameraState {
  UiResolvedCameraState::{
    camera_entity: None,
    viewport_size: @math.Vec2::new(0.0F, 0.0F),
    render_target_info: None,
  }
}

///|
fn ui_resolved_camera_state_from_fallback_ctx(
  ctx : @ui.UiContext,
) -> UiResolvedCameraState {
  UiResolvedCameraState::{
    camera_entity: ctx.camera_entity,
    viewport_size: ctx.viewport_size,
    render_target_info: None,
  }
}

///|
fn ui_resolved_camera_state_from_computed(
  camera_entity : @core.Entity?,
  render_target_info : @ui.ComputedUiRenderTargetInfo,
) -> UiResolvedCameraState {
  UiResolvedCameraState::{
    camera_entity,
    viewport_size: render_target_info.logical_size(),
    render_target_info: Some(render_target_info),
  }
}

///|
fn ui_entity_resolved_camera_state(
  world : @ecs.World,
  entity : @core.Entity,
  fallback_ctx : @ui.UiContext?,
) -> UiResolvedCameraState {
  match
    (try! world.get_by_key(entity, @ui.ecs_key_computed_ui_render_target_info)) {
    Some(render_target_info) =>
      ui_resolved_camera_state_from_computed(
        match
          (try! world.get_by_key(entity, @ui.ecs_key_computed_ui_target_camera)) {
          Some(value) => value.get()
          None => None
        },
        render_target_info,
      )
    None =>
      match fallback_ctx {
        Some(ctx) => ui_resolved_camera_state_from_fallback_ctx(ctx)
        None => ui_resolved_camera_state_default()
      }
  }
}

///|
fn ui_render_extract_system_in_render_app(world : @ecs.World) -> Unit {
  ui_render_extract_system(world)
}
