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
// Bevy source: `bevy/crates/bevy_ui_render/src/lib.rs`.
pub(all) struct UiCornerRadii {
  top_left : Float
  top_right : Float
  bottom_right : Float
  bottom_left : Float
} derive(ToJson, FromJson)

///|
pub fn UiCornerRadii::new(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> UiCornerRadii {
  { top_left, top_right, bottom_right, bottom_left }
}

///|
pub fn UiCornerRadii::zero() -> UiCornerRadii {
  UiCornerRadii::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
pub type BorderRect = @sprite.BorderRect

///|
pub type PhaseEntityRef = @sprite_render_mesh2d_runtime.PhaseEntityRef

///|
fn phase_entity_ref_for_main(main_entity : @core.Entity) -> PhaseEntityRef {
  @sprite_render_mesh2d_runtime.phase_entity_ref_for_main(main_entity)
}

///|
fn phase_entity_ref_placeholder() -> PhaseEntityRef {
  @sprite_render_mesh2d_runtime.phase_entity_ref_placeholder()
}

///|
pub fn ui_overlay_target_camera(camera : @core.Entity?) -> @core.Entity {
  match camera {
    Some(entity) => entity
    None => @core.Entity::placeholder()
  }
}

///|
pub fn ui_overlay_matches_camera(
  overlay_camera : @core.Entity,
  camera : @core.Entity,
) -> Bool {
  !overlay_camera.is_placeholder() &&
  overlay_camera.id == camera.id &&
  overlay_camera.generation == camera.generation
}

///|
pub(all) struct UiSpriteDrawPayload {
  transform : @transform.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : @color.Color
  texture : @asset.Handle[@asset.Image]
  layers : @camera_render_layers.RenderLayers
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  scissor : @math.Rect?
}

///|
pub(all) struct UiSpriteSliceBatchDrawPayload {
  rotation : Float
  draw_scale : @math.Vec2
  z : Float
  color : @color.Color
  cull_center : @math.Vec2
  cull_half_size : @math.Vec2
  texture : @asset.Handle[@asset.Image]
  layers : @camera_render_layers.RenderLayers
  scissor : @math.Rect?
  slices_xy_uv : Array[Float]
}

///|
pub(all) struct ExtractedUiSprite {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiSpriteDrawPayload
}

///|
pub(all) struct ExtractedUiSpriteSliceBatch {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiSpriteSliceBatchDrawPayload
}

///|
pub(all) struct UiRectDrawPayload {
  transform : @transform.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : @color.Color
  texture : @asset.Handle[@asset.Image]
  layers : @camera_render_layers.RenderLayers
  uv_min : @math.Vec2
  uv_max : @math.Vec2
  scissor : @math.Rect?
  flags : Int
  radius : UiCornerRadii
  border : BorderRect
}

///|
pub(all) struct ExtractedUiRect {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiRectDrawPayload
}

///|
pub(all) struct UiBoxShadowDrawPayload {
  transform : @transform.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : @color.Color
  texture : @asset.Handle[@asset.Image]
  layers : @camera_render_layers.RenderLayers
  size : @math.Vec2
  radius : UiCornerRadii
  blur : Float
  samples : Int
  scissor : @math.Rect?
}

///|
pub(all) struct ExtractedUiBoxShadow {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiBoxShadowDrawPayload
}

///|
pub(all) struct UiTextureSliceDrawPayload {
  transform : @transform.Transform
  anchor_offset : @math.Vec2
  draw_scale : @math.Vec2
  color : @color.Color
  texture : @asset.Handle[@asset.Image]
  layers : @camera_render_layers.RenderLayers
  scissor : @math.Rect?
  texture_slices : @math.Vec4
  target_slices : @math.Vec4
  repeat : @math.Vec4
  atlas_rect : @math.Vec4
}

///|
pub(all) struct ExtractedUiTextureSlice {
  entity : PhaseEntityRef
  extracted_camera_entity : @core.Entity
  payload : UiTextureSliceDrawPayload
}

///|
pub(all) struct ExtractedUiNodes {
  sprites : Array[ExtractedUiSprite]
  sprite_slice_batches : Array[ExtractedUiSpriteSliceBatch]
  rects : Array[ExtractedUiRect]
  box_shadows : Array[ExtractedUiBoxShadow]
  texture_slices : Array[ExtractedUiTextureSlice]
}

///|
pub fn ExtractedUiNodes::new() -> ExtractedUiNodes {
  {
    sprites: [],
    sprite_slice_batches: [],
    rects: [],
    box_shadows: [],
    texture_slices: [],
  }
}

///|
pub let extracted_ui_nodes_key : @ecs.ResourceKey[ExtractedUiNodes] = @ecs.register_resource(
  debug_name="mgstudio_ui_render::ExtractedUiNodes",
)

///|
pub impl @app.Resource for ExtractedUiNodes with fn resource() {
  extracted_ui_nodes_key
}

///|
pub fn ensure_extracted_ui_nodes_resource(world : @ecs.World) -> Unit {
  if world.get_resource(ExtractedUiNodes::resource()) is None {
    world.insert_resource(ExtractedUiNodes::resource(), ExtractedUiNodes::new())
  }
}

///|
pub fn extracted_ui_nodes_or_empty(world : @ecs.World) -> ExtractedUiNodes {
  ensure_extracted_ui_nodes_resource(world)
  match world.get_resource(ExtractedUiNodes::resource()) {
    Some(nodes) => nodes
    None => ExtractedUiNodes::new()
  }
}

///|
fn extracted_ui_nodes_update(
  world : @ecs.World,
  update : (ExtractedUiNodes) -> Unit,
) -> Unit {
  ensure_extracted_ui_nodes_resource(world)
  guard world.get_resource_mut(ExtractedUiNodes::resource()) is Some(nodes) else {
    return
  }
  nodes.modify(update)
}

///|
pub fn clear_extracted_ui_sprites(world : @ecs.World) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) {
    nodes.sprites.clear()
    nodes.sprite_slice_batches.clear()
  })
}

///|
pub fn clear_extracted_ui_rects(world : @ecs.World) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) { nodes.rects.clear() })
}

///|
pub fn clear_extracted_ui_box_shadows(world : @ecs.World) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) { nodes.box_shadows.clear() })
}

///|
pub fn clear_extracted_ui_texture_slices(world : @ecs.World) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) { nodes.texture_slices.clear() })
}

///|
pub fn clear_extracted_ui_nodes(world : @ecs.World) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) {
    nodes.sprites.clear()
    nodes.sprite_slice_batches.clear()
    nodes.rects.clear()
    nodes.box_shadows.clear()
    nodes.texture_slices.clear()
  })
}

///|
pub fn push_extracted_ui_sprite(
  world : @ecs.World,
  target_camera : @core.Entity?,
  payload : UiSpriteDrawPayload,
) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) {
    nodes.sprites.push({
      entity: phase_entity_ref_placeholder(),
      extracted_camera_entity: ui_overlay_target_camera(target_camera),
      payload,
    })
  })
}

///|
pub fn push_extracted_ui_sprite_slice_batch(
  world : @ecs.World,
  target_camera : @core.Entity?,
  payload : UiSpriteSliceBatchDrawPayload,
) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) {
    nodes.sprite_slice_batches.push({
      entity: phase_entity_ref_placeholder(),
      extracted_camera_entity: ui_overlay_target_camera(target_camera),
      payload,
    })
  })
}

///|
pub fn push_extracted_ui_rect(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  payload : UiRectDrawPayload,
) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) {
    nodes.rects.push({
      entity: phase_entity_ref_for_main(entity),
      extracted_camera_entity: ui_overlay_target_camera(target_camera),
      payload,
    })
  })
}

///|
pub fn push_extracted_ui_box_shadow(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  payload : UiBoxShadowDrawPayload,
) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) {
    nodes.box_shadows.push({
      entity: phase_entity_ref_for_main(entity),
      extracted_camera_entity: ui_overlay_target_camera(target_camera),
      payload,
    })
  })
}

///|
pub fn push_extracted_ui_texture_slice(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  payload : UiTextureSliceDrawPayload,
) -> Unit {
  extracted_ui_nodes_update(world, fn(nodes) {
    nodes.texture_slices.push({
      entity: phase_entity_ref_for_main(entity),
      extracted_camera_entity: ui_overlay_target_camera(target_camera),
      payload,
    })
  })
}
