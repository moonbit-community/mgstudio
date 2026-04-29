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
/// UI-render API boundary aligned with Bevy crate responsibilities.
/// Runtime implementation lives in `Milky2018/mgstudio/ui_render`.

///|
pub fn ui_render_extract_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let res = @ui.get_ui_context_resource(source_world)
  guard res.get() is Some(ctx0) else { return }
  let fallback_ctx = Some(ctx0)
  let texture_atlas_layouts_key : @ecs.ResourceKey[
    @asset.Assets[@asset.TextureAtlasLayout],
  ] = @asset.assets_resource_key()
  let texture_atlas_layouts = try! source_world.get_resource(
    texture_atlas_layouts_key,
  )
  let stack_res = @ui.get_ui_stack_resource(source_world)
  guard stack_res.get() is Some(stack0) else { return }
  @sprite_render.render2d_clear_overlay_ui_rects(world)
  @sprite_render.render2d_clear_overlay_ui_box_shadows(world)
  @sprite_render.render2d_clear_overlay_ui_texture_slices(world)

  fn atlas_rect_for(
    layouts : @asset.Assets[@asset.TextureAtlasLayout]?,
    atlas : @asset.TextureAtlas,
  ) -> @math.Rect? {
    match layouts {
      Some(layout_assets) =>
        match layout_assets.get(atlas.layout) {
          Some(layout_value) =>
            if atlas.index >= 0 && atlas.index < layout_value.textures.length() {
              Some(layout_value.textures[atlas.index].as_rect())
            } else {
              None
            }
          None => None
        }
      None => None
    }
  }

  let ui_scale = ensure_ui_scale_resource(source_world)
  let ui_scale_value = if ui_scale.value <= 0.0F {
    1.0F
  } else {
    ui_scale.value
  }
  let fallback_px_per_ui = safe_scale_factor(@window.window_scale_factor()) /
    ui_scale_value
  let uv_min = @math.Vec2::new(0.0F, 0.0F)
  let uv_max = @math.Vec2::new(1.0F, 1.0F)
  for i in 0..<stack0.uinodes.length() {
    let entity = stack0.uinodes[i]
    if (try! source_world.get_by_key(
        entity, @visibility.ecs_key_view_visibility,
      ))
      is Some(vv) &&
      !vv.is_visible() {
      continue
    }
    guard (try! source_world.get_by_key(entity, @ui.ecs_key_ui_layout))
      is Some(layout) else {
      continue
    }
    guard (try! source_world.get_by_key(entity, @ui.ecs_key_node)) is Some(_) else {
      continue
    }
    guard (try! source_world.get_by_key(entity, @transform.ecs_key_transform))
      is Some(t0) else {
      continue
    }
    let entity_ctx = ui_entity_resolved_camera_state(
      source_world, entity, fallback_ctx,
    )
    let shadow_samples = match entity_ctx.camera_entity {
      Some(camera_entity) =>
        match
          (
            try! source_world.get_by_key(
              camera_entity, ecs_key_ui_box_shadow_samples,
            ) : BoxShadowSamples?) {
          Some(v) => v.samples
          None => BoxShadowSamples::default().samples
        }
      None => BoxShadowSamples::default().samples
    }
    let rect = layout.rect
    let size = rect.size()
    if size.x <= 0.0F || size.y <= 0.0F {
      continue
    }
    let layers = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_render_layers)) {
      Some(v) => v
      None => @sprite.RenderLayers::default()
    }
    let scissor = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_scissor_rect)) {
      Some(v) => Some(v.rect)
      None => None
    }
    let scale_x = t0.scale.x
    let scale_y = t0.scale.y
    let draw_scale = @math.Vec2::new(scale_x * size.x, scale_y * size.y)
    let scale_min = if scale_x < scale_y { scale_x } else { scale_y }
    let viewport_size = entity_ctx.viewport_size
    let layout_border = layout.border()
    let border_left = layout_border.left * scale_x
    let border_right = layout_border.right * scale_x
    let border_top = layout_border.top * scale_y
    let border_bottom = layout_border.bottom * scale_y
    let border = @sprite.UiBorderRect::new(
      border_left, border_top, border_right, border_bottom,
    )
    let r = layout.border_radius()
    let radius = @sprite.UiCornerRadii::new(
      r.top_left * scale_min,
      r.top_right * scale_min,
      r.bottom_right * scale_min,
      r.bottom_left * scale_min,
    )
    let mut flags = 0
    let aa_enabled = match
      (
        try! source_world.get_by_key(entity, ecs_key_ui_anti_alias) :
        UiAntiAlias?) {
      Some(UiAntiAlias::Off) => false
      _ => true
    }
    if aa_enabled {
      flags = flags | UI_DRAW_FLAG_ANTIALIAS
    }
    let border_flags = ui_draw_border_flags(
      border_left, border_top, border_right, border_bottom,
    )
    let z_base = UI_STACK_Z_BASE + int_to_float(i) * UI_STACK_Z_STEP

    // BoxShadow (behind background/content/border/text).
    match (try! source_world.get_by_key(entity, @ui.ecs_key_box_shadow)) {
      Some(shadow) =>
        if shadow.color.a > 0.0F {
          let spread_x = resolve_axis(
            shadow.spread_radius,
            size.x,
            viewport_size,
          )
          let spread_ratio = (spread_x + size.x) / size.x
          let spread_y = size.y * spread_ratio - size.y
          let shadow_size = @math.Vec2::new(
            size.x + spread_x,
            size.y + spread_y,
          )
          if shadow_size.x > 0.0F && shadow_size.y > 0.0F {
            let blur = clamp_nonneg(
              resolve_axis(shadow.blur_radius, size.x, viewport_size),
            )
            let bounds = @math.Vec2::new(
              shadow_size.x + 6.0F * blur,
              shadow_size.y + 6.0F * blur,
            )
            if bounds.x > 0.0F && bounds.y > 0.0F {
              let offset_x = resolve_axis(
                shadow.x_offset,
                size.x,
                viewport_size,
              )
              let offset_y = resolve_axis(
                shadow.y_offset,
                size.y,
                viewport_size,
              )
              // UI uses +Y down; world uses +Y up.
              let offset_local = @math.Vec2::new(
                offset_x * scale_x,
                -offset_y * scale_y,
              )
              let offset_world = rotate_vec2(offset_local, t0.rotation_z())
              let t_shadow = @transform.Transform::from_xy_rotation_scale(
                @math.Vec2::new(
                  t0.translation.x + offset_world.x,
                  t0.translation.y + offset_world.y,
                ),
                t0.rotation_z(),
                @math.Vec2::new(t0.scale.x, t0.scale.y),
                z=z_base + UI_STACK_Z_SHADOW,
              )
              let radius_shadow = @sprite.UiCornerRadii::new(
                r.top_left * spread_ratio * scale_min,
                r.top_right * spread_ratio * scale_min,
                r.bottom_right * spread_ratio * scale_min,
                r.bottom_left * spread_ratio * scale_min,
              )
              let draw_scale_shadow = @math.Vec2::new(
                scale_x * bounds.x,
                scale_y * bounds.y,
              )
              let size_shadow_world = @math.Vec2::new(
                scale_x * shadow_size.x,
                scale_y * shadow_size.y,
              )
              @sprite_render.render2d_push_ui_box_shadow_scissor(
                world,
                entity,
                entity_ctx.camera_entity,
                ctx0.white_texture,
                t_shadow,
                draw_scale_shadow,
                shadow.color,
                layers,
                scissor,
                size_shadow_world,
                radius_shadow,
                blur * scale_min,
                shadow_samples,
              )
            }
          }
        }
      None => ()
    }

    // Background color.
    let bg_color_opt = match
      (try! source_world.get_by_key(entity, @ui.ecs_key_button_colors)) {
      Some(colors) =>
        Some(
          button_color_for_state(
            colors,
            try! source_world.get_by_key(entity, @ui.ecs_key_interaction),
          ),
        )
      None =>
        match
          (try! source_world.get_by_key(entity, @ui.ecs_key_background_color)) {
          Some(v) => Some(v.color)
          None => None
        }
    }
    match bg_color_opt {
      Some(color) =>
        if color.a > 0.0F {
          let t_bg = transform_with_z(t0, z_base + UI_STACK_Z_BACKGROUND)
          @sprite_render.render2d_push_ui_rect_uv_scissor(
            world,
            entity,
            entity_ctx.camera_entity,
            ctx0.white_texture,
            t_bg,
            draw_scale,
            uv_min,
            uv_max,
            color,
            layers,
            scissor,
            flags,
            radius,
            border,
          )
        }
      None => ()
    }

    // Image content (Bevy `ImageNode`, with `UiImage` compatibility).
    let image_info = match
      (try! source_world.get_by_key(entity, @ui.ecs_key_image_node)) {
      Some(img) =>
        Some(
          (
            img.image,
            img.color,
            img.texture_atlas,
            img.rect,
            img.flip_x,
            img.flip_y,
            Some(img.image_mode),
          ),
        )
      None =>
        match (try! source_world.get_by_key(entity, @ui.ecs_key_ui_image)) {
          Some(img) =>
            Some(
              (
                img.image,
                img.color,
                img.texture_atlas,
                img.rect,
                img.flip_x,
                img.flip_y,
                None,
              ),
            )
          None => None
        }
    }
    match image_info {
      Some(info) => {
        let texture = info.0
        let color = info.1
        let texture_atlas = info.2
        let rect = info.3
        let flip_x = info.4
        let flip_y = info.5
        let mode = match info.6 {
          Some(m) => m
          None => @ui.NodeImageMode::Stretch
        }
        let mut image_width = @asset.asset_texture_width(texture)
        let mut image_height = @asset.asset_texture_height(texture)
        if image_width <= 0 || image_height <= 0 {
          // Avoid division by zero for not-yet-loaded textures.
          image_width = 1
          image_height = 1
        }
        let image_size = @math.Vec2::new(
          Float::from_double(image_width.to_double()),
          Float::from_double(image_height.to_double()),
        )
        let atlas_rect = match texture_atlas {
          Some(atlas) => atlas_rect_for(texture_atlas_layouts, atlas)
          None => None
        }
        let pair = ui_uv_from_image_rects(
          image_size, atlas_rect, rect, flip_x, flip_y,
        )
        let uv_min_img = pair.0
        let uv_max_img = pair.1
        let t_content = transform_with_z(t0, z_base + UI_STACK_Z_CONTENT)
        if color.a > 0.0F && @ui.NodeImageMode::uses_slices(mode) {
          // `size` is in logical UI units. Convert to physical pixels before
          // computing slice/tiling parameters to match Bevy.
          let px_per_ui = match entity_ctx.render_target_info {
            Some(render_target_info) => render_target_info.scale_factor()
            None => fallback_px_per_ui
          }
          let target_size = @math.Vec2::new(
            size.x * px_per_ui,
            size.y * px_per_ui,
          )
          // Image slicing uses the size of the selected texture region (atlas/rect).
          let image_rect = @math.Rect::new(
            @math.Vec2::new(0.0F, 0.0F),
            @math.Vec2::new(image_size.x, image_size.y),
          )
          let texture_rect = match (atlas_rect, rect) {
            (None, None) => image_rect
            (None, Some(r)) => r
            (Some(ar), None) => ar
            (Some(ar), Some(r)) => {
              let min = vec2_add(r.min, ar.min)
              let max = vec2_add(r.max, ar.min)
              @math.Rect::new(min, max)
            }
          }
          let region_size = texture_rect.size()
          let (texture_slices, target_slices, repeat) = compute_texture_slices(
            region_size, target_size, mode,
          )
          let atlas_rect_uv = @math.Vec4::new(
            uv_min_img.x,
            uv_min_img.y,
            uv_max_img.x,
            uv_max_img.y,
          )
          @sprite_render.render2d_push_ui_texture_slice_scissor(
            world,
            entity,
            entity_ctx.camera_entity,
            texture,
            t_content,
            draw_scale,
            color,
            layers,
            scissor,
            texture_slices,
            target_slices,
            repeat,
            atlas_rect_uv,
          )
        } else if color.a > 0.0F {
          @sprite_render.render2d_push_ui_rect_uv_scissor(
            world,
            entity,
            entity_ctx.camera_entity,
            texture,
            t_content,
            draw_scale,
            uv_min_img,
            uv_max_img,
            color,
            layers,
            scissor,
            flags | UI_DRAW_FLAG_TEXTURED,
            radius,
            border,
          )
        }
      }
      None => ()
    }

    // Border.
    let has_border = border_left > 0.0F ||
      border_right > 0.0F ||
      border_top > 0.0F ||
      border_bottom > 0.0F
    if has_border &&
      (try! source_world.get_by_key(entity, @ui.ecs_key_border_color))
      is Some(bc) &&
      bc.color.a > 0.0F {
      let t_border = transform_with_z(t0, z_base + UI_STACK_Z_BORDER)
      @sprite_render.render2d_push_ui_rect_uv_scissor(
        world,
        entity,
        entity_ctx.camera_entity,
        ctx0.white_texture,
        t_border,
        draw_scale,
        uv_min,
        uv_max,
        bc.color,
        layers,
        scissor,
        flags | border_flags,
        radius,
        border,
      )
    }

    // Outline.
    match (try! source_world.get_by_key(entity, @ui.ecs_key_outline)) {
      Some(outline) =>
        if outline.color.a > 0.0F {
          let outline_width = layout.outline_width()
          if outline_width > 0.0F {
            let outline_offset = layout.outline_offset()
            let outer = outline_offset + outline_width
            let outline_size = @math.Vec2::new(
              size.x + 2.0F * outer,
              size.y + 2.0F * outer,
            )
            if outline_size.x > 0.0F && outline_size.y > 0.0F {
              let t_outline = transform_with_z(t0, z_base + UI_STACK_Z_OUTLINE)
              let outline_draw_scale = @math.Vec2::new(
                scale_x * outline_size.x,
                scale_y * outline_size.y,
              )
              let outline_r = layout.outline_radius()
              let outline_border = @sprite.UiBorderRect::new(
                outline_width * scale_x,
                outline_width * scale_y,
                outline_width * scale_x,
                outline_width * scale_y,
              )
              let outline_radius = @sprite.UiCornerRadii::new(
                clamp_radius_nonneg(outline_r.top_left, outline_size) *
                scale_min,
                clamp_radius_nonneg(outline_r.top_right, outline_size) *
                scale_min,
                clamp_radius_nonneg(outline_r.bottom_right, outline_size) *
                scale_min,
                clamp_radius_nonneg(outline_r.bottom_left, outline_size) *
                scale_min,
              )
              @sprite_render.render2d_push_ui_rect_uv_scissor(
                world,
                entity,
                entity_ctx.camera_entity,
                ctx0.white_texture,
                t_outline,
                outline_draw_scale,
                uv_min,
                uv_max,
                outline.color,
                layers,
                scissor,
                flags |
                ui_draw_border_flags(
                  outline_border.left,
                  outline_border.top,
                  outline_border.right,
                  outline_border.bottom,
                ),
                outline_radius,
                outline_border,
              )
            }
          }
        }
      None => ()
    }
  }
}
