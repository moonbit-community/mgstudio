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
// Bevy source: `bevy/crates/bevy_ui/src/ui_node.rs`.
fn ensure_visibility_defaults(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  if !(try! world.contains_by_key(entity, @visibility.ecs_key_visibility)) {
    try! world.set_by_key(
      entity,
      @visibility.ecs_key_visibility,
      @visibility.Visibility::Inherited,
    )
  }
  if !(try! world.contains_by_key(
      entity, @visibility.ecs_key_inherited_visibility,
    )) {
    try! world.set_by_key(
      entity,
      @visibility.ecs_key_inherited_visibility,
      @visibility.InheritedVisibility::new(true),
    )
  }
  if !(try! world.contains_by_key(entity, @visibility.ecs_key_view_visibility)) {
    try! world.set_by_key(
      entity,
      @visibility.ecs_key_view_visibility,
      @visibility.ViewVisibility::new(true),
    )
  }
}

///|
fn ensure_layers_default(
  world : @ecs.World,
  entity : @core.Entity,
) -> @sprite.RenderLayers {
  match (try! world.get_by_key(entity, @sprite.ecs_key_render_layers)) {
    Some(v) => v
    None => {
      let layers = @sprite.RenderLayers::default()
      try! world.set_by_key(entity, @sprite.ecs_key_render_layers, layers)
      layers
    }
  }
}

///|
fn ui_world_transform(
  ctx : UiResolvedCameraState,
  rect : @math.Rect,
  z : Float,
) -> @transform.Transform {
  let viewport_w = ctx.viewport_size.x
  let viewport_h = ctx.viewport_size.y
  let cam_scale = safe_camera_scale(ctx.camera_scale)
  let cam_rot = ctx.camera_transform.rotation_z()
  let cam_pos = @math.Vec2::new(
    ctx.camera_transform.translation.x,
    ctx.camera_transform.translation.y,
  )
  let center = rect.center()
  let half_w = viewport_w / 2.0F
  let half_h = viewport_h / 2.0F
  let center_px = @math.Vec2::new(center.x - half_w, half_h - center.y)
  let center_scaled = @math.Vec2::new(
    center_px.x * cam_scale,
    center_px.y * cam_scale,
  )
  let offset = rotate_vec2(center_scaled, cam_rot)
  let world_pos = @math.Vec2::new(cam_pos.x + offset.x, cam_pos.y + offset.y)
  @transform.Transform::from_xy_rotation_scale(
    world_pos,
    cam_rot,
    @math.Vec2::new(cam_scale, cam_scale),
    z~,
  )
}
