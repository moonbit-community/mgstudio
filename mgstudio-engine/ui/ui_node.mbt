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
    try! world.set_by_key(entity, @visibility.ecs_key_visibility, Inherited)
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
) -> @camera_render_layers.RenderLayers {
  match
    (try! world.get_by_key(entity, @camera_render_layers.ecs_key_render_layers)) {
    Some(v) => v
    None => {
      let layers = @camera_render_layers.RenderLayers::RenderLayers()
      try! world.set_by_key(
        entity, @camera_render_layers.ecs_key_render_layers, layers,
      )
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

///|
fn apply_ui_transform(
  world : @ecs.World,
  entity : @core.Entity,
  ctx : UiResolvedCameraState,
  rect : @math.Rect,
  base : @transform.Transform,
) -> @transform.Transform {
  guard (try! world.get_by_key(entity, ecs_key_ui_transform))
    is Some(ui_transform) else {
    return base
  }
  let translation = ui_transform.translation.resolve(
    ctx.scale_factor,
    rect.size(),
    ctx.viewport_size,
  )
  let cam_scale = safe_camera_scale(ctx.camera_scale)
  let cam_rot = ctx.camera_transform.rotation_z()
  let offset = rotate_vec2(
    @math.Vec2::new(translation.x * cam_scale, -translation.y * cam_scale),
    cam_rot,
  )
  let pos = @math.Vec2::new(
    base.translation.x + offset.x,
    base.translation.y + offset.y,
  )
  let scale = @math.Vec2::new(
    base.scale.x * ui_transform.scale.x,
    base.scale.y * ui_transform.scale.y,
  )
  @transform.Transform::from_xy_rotation_scale(
    pos,
    base.rotation_z() - ui_transform.rotation,
    scale,
    z=base.translation.z,
  )
}
