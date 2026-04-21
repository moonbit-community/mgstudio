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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/scrollbar.rs`.
pub(all) enum ControlOrientation {
  Horizontal
  Vertical
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn ControlOrientation::default() -> ControlOrientation {
  ControlOrientation::Vertical
}

///|
pub struct Scrollbar {
  target : @core.Entity
  orientation : ControlOrientation
  min_thumb_length : Float
} derive(ToJson, FromJson)

///|
pub fn Scrollbar::new(
  target : @core.Entity,
  orientation : ControlOrientation,
  min_thumb_length : Float,
) -> Scrollbar {
  Scrollbar::{ target, orientation, min_thumb_length }
}

///|
pub struct CoreScrollbarThumb {} derive(ToJson, FromJson)

///|
pub struct CoreScrollbarDragState {
  dragging : Bool
  drag_origin : Float
} derive(ToJson, FromJson)

///|
pub fn CoreScrollbarDragState::default() -> CoreScrollbarDragState {
  CoreScrollbarDragState::{ dragging: false, drag_origin: 0.0F }
}

///|
pub let ecs_key_scrollbar : @ecs.ComponentKey[Scrollbar] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::Scrollbar",
)

///|
pub let ecs_key_core_scrollbar_thumb : @ecs.ComponentKey[CoreScrollbarThumb] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::CoreScrollbarThumb",
)

///|
pub let ecs_key_core_scrollbar_drag_state : @ecs.ComponentKey[
  CoreScrollbarDragState,
] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::CoreScrollbarDragState",
)

///|
pub impl @ecs.Component for Scrollbar with component() {
  ecs_key_scrollbar
}

///|
pub impl @ecs.Component for CoreScrollbarThumb with component() {
  ecs_key_core_scrollbar_thumb
}

///|
pub impl @ecs.Component for CoreScrollbarDragState with component() {
  ecs_key_core_scrollbar_drag_state
}

///|
fn scrollbar_on_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  scrollbar_query : @ecs.Query[
    (@ecs.Comp[Scrollbar], @ecs.Comp[@ui.UiLayout]),
    @ecs.All,
  ],
  target_query : @ecs.Query[
    (
      @ecs.Comp[@ui.ScrollPosition],
      @ecs.Comp[@ui.UiLayout],
      @ecs.Comp[@ui.ContentSize]?,
    ),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (scrollbar_query.get(entity) catch { _ => None })
    is Some((scrollbar_comp, scrollbar_layout_comp)) else {
    return
  }
  let scrollbar = scrollbar_comp.value()
  let scrollbar_layout = scrollbar_layout_comp.value()
  guard (target_query.get(scrollbar.target) catch { _ => None })
    is Some((scroll_pos_comp, target_layout_comp, content_size_comp)) else {
    return
  }
  let scroll_pos = scroll_pos_comp.value()
  let target_layout = target_layout_comp.value()
  let content_size = match content_size_comp {
    Some(value) => value.value().size()
    None => target_layout.size()
  }
  let visible_size = target_layout.size()
  let track_size = scrollbar_layout.size()
  let rect = scrollbar_layout.rect()
  let target_next_scroll = match scrollbar.orientation {
    ControlOrientation::Horizontal => {
      let click_ratio = if track_size.x <= 0.0F {
        0.0F
      } else {
        ((pointer.position().x - rect.min.x) / track_size.x).clamp(
          min=0.0F,
          max=1.0F,
        )
      }
      let click_position = click_ratio * content_size.x
      let max_offset = (content_size.x - visible_size.x).max(0.0F)
      let next_offset = (if click_position > scroll_pos.x() {
        scroll_pos.x() + visible_size.x
      } else {
        scroll_pos.x() - visible_size.x
      }).clamp(min=0.0F, max=max_offset)
      scroll_pos.with_x(next_offset)
    }
    ControlOrientation::Vertical => {
      let click_ratio = if track_size.y <= 0.0F {
        0.0F
      } else {
        ((pointer.position().y - rect.min.y) / track_size.y).clamp(
          min=0.0F,
          max=1.0F,
        )
      }
      let click_position = click_ratio * content_size.y
      let max_offset = (content_size.y - visible_size.y).max(0.0F)
      let next_offset = (if click_position > scroll_pos.y() {
        scroll_pos.y() + visible_size.y
      } else {
        scroll_pos.y() - visible_size.y
      }).clamp(min=0.0F, max=max_offset)
      scroll_pos.with_y(next_offset)
    }
  }
  commands.entity(scrollbar.target).insert_component(target_next_scroll)
}

///|
fn scrollbar_update_thumb_system(
  scrollbar_query : @ecs.Query[
    (
      @ecs.Comp[Scrollbar],
      @ecs.Comp[@ui.UiLayout],
      @ecs.Comp[@hierarchy.Children],
    ),
    @ecs.All,
  ],
  target_query : @ecs.Query[
    (
      @ecs.Comp[@ui.ScrollPosition],
      @ecs.Comp[@ui.UiLayout],
      @ecs.Comp[@ui.ContentSize]?,
    ),
    @ecs.All,
  ],
  thumb_query : @ecs.Query[
    (@ecs.Has[CoreScrollbarThumb], @ecs.Mut[@ui.Node]),
    @ecs.All,
  ],
) -> Unit {
  try! scrollbar_query.for_each(fn(_entity, data) {
    let (scrollbar_comp, scrollbar_layout_comp, children_comp) = data
    let scrollbar = scrollbar_comp.value()
    let scrollbar_layout = scrollbar_layout_comp.value()
    let children = children_comp.value()
    guard (target_query.get(scrollbar.target) catch { _ => None })
      is Some((scroll_pos_comp, target_layout_comp, content_size_comp)) else {
      return
    }
    let scroll_pos = scroll_pos_comp.value()
    let target_layout = target_layout_comp.value()
    let content_size = match content_size_comp {
      Some(value) => value.value().size()
      None => target_layout.size()
    }
    let visible_size = target_layout.size()
    let track_size = scrollbar_layout.size()
    for child in children.entities() {
      guard (thumb_query.get(child) catch { _ => None })
        is Some((has_thumb, node_mut)) else {
        continue
      }
      if !has_thumb.present() {
        continue
      }
      let node = node_mut.peek()
      let next_node = match scrollbar.orientation {
        ControlOrientation::Horizontal => {
          let thumb_size = if content_size.x > visible_size.x {
            (track_size.x * visible_size.x / content_size.x).clamp(
              min=scrollbar.min_thumb_length,
              max=track_size.x.max(scrollbar.min_thumb_length),
            )
          } else {
            track_size.x
          }
          let max_offset = (content_size.x - visible_size.x).max(0.0F)
          let thumb_pos = if max_offset > 0.0F {
            scroll_pos.x() * (track_size.x - thumb_size).max(0.0F) / max_offset
          } else {
            0.0F
          }
          node
          .with_position_type(@ui.PositionType::Absolute)
          .with_left(@ui.Val::Px(thumb_pos))
          .with_top(@ui.Val::Px(0.0F))
          .with_bottom(@ui.Val::Px(0.0F))
          .with_width(@ui.Val::Px(thumb_size))
        }
        ControlOrientation::Vertical => {
          let thumb_size = if content_size.y > visible_size.y {
            (track_size.y * visible_size.y / content_size.y).clamp(
              min=scrollbar.min_thumb_length,
              max=track_size.y.max(scrollbar.min_thumb_length),
            )
          } else {
            track_size.y
          }
          let max_offset = (content_size.y - visible_size.y).max(0.0F)
          let thumb_pos = if max_offset > 0.0F {
            scroll_pos.y() * (track_size.y - thumb_size).max(0.0F) / max_offset
          } else {
            0.0F
          }
          node
          .with_position_type(@ui.PositionType::Absolute)
          .with_top(@ui.Val::Px(thumb_pos))
          .with_left(@ui.Val::Px(0.0F))
          .with_right(@ui.Val::Px(0.0F))
          .with_height(@ui.Val::Px(thumb_size))
        }
      }
      node_mut.set(next_node)
      break
    }
  })
}

///|
pub fn scrollbar_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_pointer_observer4(scrollbar_on_pointer_click)
  .add_post_update_system_config(
    @app.system(@app.system_param3(scrollbar_update_thumb_system)).in_set(
      @ui.ui_set_prepare,
    ),
  )
}
