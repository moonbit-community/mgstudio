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
  }
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
