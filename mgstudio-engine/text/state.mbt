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
pub struct TextHandle {
  id : Int
}

///|
pub fn TextHandle::new(id : Int) -> TextHandle {
  TextHandle::{ id, }
}

///|
pub struct TextSpanHandle {
  id : Int
}

///|
pub fn TextSpanHandle::new(id : Int) -> TextSpanHandle {
  TextSpanHandle::{ id, }
}

///|
pub struct Text2dBundle {
  text : Text2d
  font : TextFont
  color : TextColor
  layout : TextLayout
  bounds : TextBounds
  line_height : LineHeight
  shadow : Text2dShadow?
  transform : @math.Transform
  layers : @render2d.RenderLayers
  anchor : @render2d.Anchor
  y_axis : YAxisOrientation
}

///|
pub fn Text2dBundle::new(
  text : Text2d,
  font : TextFont,
  transform : @math.Transform,
) -> Text2dBundle {
  Text2dBundle::{
    text,
    font,
    color: TextColor::default(),
    layout: TextLayout::default(),
    bounds: TextBounds::default(),
    line_height: LineHeight::default(),
    shadow: None,
    transform,
    layers: @render2d.RenderLayers::default(),
    anchor: @render2d.Anchor::default(),
    y_axis: YAxisOrientation::BottomToTop,
  }
}

///|
pub fn Text2dBundle::new_with_layers(
  text : Text2d,
  font : TextFont,
  transform : @math.Transform,
  layers : @render2d.RenderLayers,
) -> Text2dBundle {
  Text2dBundle::{
    text,
    font,
    color: TextColor::default(),
    layout: TextLayout::default(),
    bounds: TextBounds::default(),
    line_height: LineHeight::default(),
    shadow: None,
    transform,
    layers,
    anchor: @render2d.Anchor::default(),
    y_axis: YAxisOrientation::BottomToTop,
  }
}

///|
pub fn Text2dBundle::with_color(
  self : Text2dBundle,
  color : TextColor,
) -> Text2dBundle {
  Text2dBundle::{ ..self, color, }
}

///|
pub fn Text2dBundle::with_layout(
  self : Text2dBundle,
  layout : TextLayout,
) -> Text2dBundle {
  Text2dBundle::{ ..self, layout, }
}

///|
pub fn Text2dBundle::with_bounds(
  self : Text2dBundle,
  bounds : TextBounds,
) -> Text2dBundle {
  Text2dBundle::{ ..self, bounds, }
}

///|
pub fn Text2dBundle::with_line_height(
  self : Text2dBundle,
  line_height : LineHeight,
) -> Text2dBundle {
  Text2dBundle::{ ..self, line_height, }
}

///|
pub fn Text2dBundle::with_shadow(
  self : Text2dBundle,
  shadow : Text2dShadow?,
) -> Text2dBundle {
  Text2dBundle::{ ..self, shadow, }
}

///| Set the anchor used for world-space `Text2d` positioning (Bevy-aligned).
pub fn Text2dBundle::with_anchor(
  self : Text2dBundle,
  anchor : @render2d.Anchor,
) -> Text2dBundle {
  Text2dBundle::{ ..self, anchor }
}

///| Set the layout coordinate orientation.
pub fn Text2dBundle::with_y_axis(
  self : Text2dBundle,
  y_axis : YAxisOrientation,
) -> Text2dBundle {
  Text2dBundle::{ ..self, y_axis }
}

///|
pub fn Text2dBundle::spawn(self : Text2dBundle) -> TextHandle {
  text_spawn(self)
}

///|
pub struct TextSpanBundle {
  span : TextSpan
  font : TextFont
  color : TextColor
  line_height : LineHeight
}

///|
pub fn TextSpanBundle::new(span : TextSpan, font : TextFont) -> TextSpanBundle {
  TextSpanBundle::{
    span,
    font,
    color: TextColor::default(),
    line_height: LineHeight::default(),
  }
}

///|
pub fn TextSpanBundle::spawn(
  self : TextSpanBundle,
  parent : TextHandle,
) -> TextSpanHandle {
  text_spawn_span(parent, self)
}

///|
priv struct TextSpanInstance {
  id : Int
  span : TextSpan
  font : TextFont
  color : TextColor
  line_height : LineHeight
}

///|
priv struct TextInstance {
  id : Int
  text : Text2d
  font : TextFont
  color : TextColor
  layout : TextLayout
  bounds : TextBounds
  line_height : LineHeight
  shadow : Text2dShadow?
  transform : @math.Transform
  layers : @render2d.RenderLayers
  anchor : @render2d.Anchor
  y_axis : YAxisOrientation
  /// When set, this text handle is treated as "UI text" and will be positioned
  /// relative to a UI node's top-left corner (Bevy UI extraction semantics).
  ui_node_size : @math.Vec2?
  spans : Array[TextSpanInstance]
  computed : ComputedTextBlock
  layout_info : TextLayoutInfo
}

///|
priv struct TextState {
  mut next_text_id : Int
  mut next_span_id : Int
  texts : Array[TextInstance]
}

///|
let text_state : Ref[TextState] = Ref::new(TextState::{
  next_text_id: 0,
  next_span_id: 0,
  texts: [],
})

///|
pub fn text_spawn(bundle : Text2dBundle) -> TextHandle {
  let id = text_state.val.next_text_id
  text_state.val.next_text_id = id + 1
  text_state.val.texts.push(TextInstance::{
    id,
    text: bundle.text,
    font: bundle.font,
    color: bundle.color,
    layout: bundle.layout,
    bounds: bundle.bounds,
    line_height: bundle.line_height,
    shadow: bundle.shadow,
    transform: bundle.transform,
    layers: bundle.layers,
    anchor: bundle.anchor,
    y_axis: bundle.y_axis,
    ui_node_size: None,
    spans: [],
    computed: ComputedTextBlock::default(),
    layout_info: TextLayoutInfo::default(),
  })
  TextHandle::{ id, }
}

///|
pub fn text_spawn_span(
  parent : TextHandle,
  bundle : TextSpanBundle,
) -> TextSpanHandle {
  let span_id = text_state.val.next_span_id
  text_state.val.next_span_id = span_id + 1
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == parent.id {
      let instance = text_state.val.texts[i]
      instance.spans.push(TextSpanInstance::{
        id: span_id,
        span: bundle.span,
        font: bundle.font,
        color: bundle.color,
        line_height: bundle.line_height,
      })
      text_state.val.texts[i] = TextInstance::{
        ..instance,
        spans: instance.spans,
        computed: ComputedTextBlock::{
          ..instance.computed,
          needs_rerender: true,
        },
      }
      break
    }
  }
  TextSpanHandle::{ id: span_id }
}

///|
fn text_update_instance(
  handle : TextHandle,
  update : (TextInstance) -> TextInstance,
) -> Unit {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == handle.id {
      text_state.val.texts[i] = update(text_state.val.texts[i])
      break
    }
  }
}

///|
pub fn text_set_content(handle : TextHandle, content : String) -> Unit {
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    text: Text2d::{ content, },
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///| Update the transform of a text handle without marking it as needing rerender.
pub fn text_set_transform(handle : TextHandle, transform : @math.Transform) -> Unit {
  text_update_instance(handle, instance => TextInstance::{ ..instance, transform })
}

///| Update the render layers of a text handle without marking it as needing rerender.
pub fn text_set_layers(
  handle : TextHandle,
  layers : @render2d.RenderLayers,
) -> Unit {
  text_update_instance(handle, instance => TextInstance::{ ..instance, layers })
}

///| Update the anchor of a text handle without marking it as needing rerender.
pub fn text_set_anchor(
  handle : TextHandle,
  anchor : @render2d.Anchor,
) -> Unit {
  text_update_instance(handle, instance => TextInstance::{ ..instance, anchor })
}

///| Update the y-axis orientation of a text handle without marking it as needing rerender.
pub fn text_set_y_axis(handle : TextHandle, y_axis : YAxisOrientation) -> Unit {
  // Orientation affects glyph coordinates, so we must relayout.
  text_update_instance(handle, instance => {
    if instance.y_axis == y_axis {
      instance
    } else {
      TextInstance::{
        ..instance,
        y_axis,
        computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
      }
    }
  })
}

///| Mark a text handle as UI text and provide the size of the owning UI node in logical pixels.
///|
///| This does not affect shaping, but it changes how glyphs are positioned when rendered.
pub fn text_set_ui_node_size(
  handle : TextHandle,
  size : @math.Vec2?,
) -> Unit {
  text_update_instance(handle, instance => TextInstance::{ ..instance, ui_node_size: size })
}

///| Get the last computed logical layout size (may lag by one frame).
pub fn text_get_layout_size(handle : TextHandle) -> @math.Vec2? {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == handle.id {
      return Some(text_state.val.texts[i].layout_info.size)
    }
  }
  None
}
