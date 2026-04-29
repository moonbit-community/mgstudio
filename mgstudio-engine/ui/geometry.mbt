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
// Bevy source: `bevy/crates/bevy_ui/src/geometry.rs`.
pub(all) enum Val {
  Auto
  Px(Float)
  Percent(Float)
  Vw(Float)
  Vh(Float)
  VMin(Float)
  VMax(Float)
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct UiRect {
  left : Val
  right : Val
  top : Val
  bottom : Val
} derive(ToJson, FromJson)

///|
pub fn UiRect::new(left : Val, right : Val, top : Val, bottom : Val) -> UiRect {
  UiRect::{ left, right, top, bottom }
}

///|
pub fn UiRect::default() -> UiRect {
  UiRect::new(Val::Px(0.0F), Val::Px(0.0F), Val::Px(0.0F), Val::Px(0.0F))
}

///|
pub fn UiRect::all(value : Val) -> UiRect {
  UiRect::new(value, value, value, value)
}

///|
pub fn UiRect::px(
  left : Float,
  right : Float,
  top : Float,
  bottom : Float,
) -> UiRect {
  UiRect::new(Val::Px(left), Val::Px(right), Val::Px(top), Val::Px(bottom))
}

///|
pub fn UiRect::percent(
  left : Float,
  right : Float,
  top : Float,
  bottom : Float,
) -> UiRect {
  UiRect::new(
    Val::Percent(left),
    Val::Percent(right),
    Val::Percent(top),
    Val::Percent(bottom),
  )
}

///|
pub fn UiRect::horizontal(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), left: value, right: value }
}

///|
pub fn UiRect::vertical(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), top: value, bottom: value }
}

///|
pub fn UiRect::axes(horizontal : Val, vertical : Val) -> UiRect {
  UiRect::{
    left: horizontal,
    right: horizontal,
    top: vertical,
    bottom: vertical,
  }
}

///|
pub fn UiRect::left(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), left: value }
}

///|
pub fn UiRect::right(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), right: value }
}

///|
pub fn UiRect::top(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), top: value }
}

///|
pub fn UiRect::bottom(value : Val) -> UiRect {
  UiRect::{ ..UiRect::default(), bottom: value }
}

///|
pub struct BorderRadius {
  top_left : Val
  top_right : Val
  bottom_left : Val
  bottom_right : Val
} derive(ToJson, FromJson)

///|
pub fn BorderRadius::default() -> BorderRadius {
  BorderRadius::{
    top_left: Val::Px(0.0F),
    top_right: Val::Px(0.0F),
    bottom_left: Val::Px(0.0F),
    bottom_right: Val::Px(0.0F),
  }
}

///|
pub fn BorderRadius::all(radius : Val) -> BorderRadius {
  BorderRadius::{
    top_left: radius,
    top_right: radius,
    bottom_left: radius,
    bottom_right: radius,
  }
}

///|
pub fn BorderRadius::new(
  top_left : Val,
  top_right : Val,
  bottom_right : Val,
  bottom_left : Val,
) -> BorderRadius {
  BorderRadius::{ top_left, top_right, bottom_left, bottom_right }
}

///|
pub fn BorderRadius::px(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> BorderRadius {
  BorderRadius::new(
    Val::Px(top_left),
    Val::Px(top_right),
    Val::Px(bottom_right),
    Val::Px(bottom_left),
  )
}

///|
pub fn BorderRadius::percent(
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> BorderRadius {
  BorderRadius::new(
    Val::Percent(top_left),
    Val::Percent(top_right),
    Val::Percent(bottom_right),
    Val::Percent(bottom_left),
  )
}

///|
pub struct Outline {
  width : Val
  offset : Val
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn Outline::new(
  width : Val,
  offset : Val,
  color : @sprite.Color,
) -> Outline {
  Outline::{ width, offset, color }
}

///|
pub fn Outline::default() -> Outline {
  Outline::{
    width: Val::Px(0.0F),
    offset: Val::Px(0.0F),
    color: @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
  }
}

///|
pub struct BorderColor {
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn BorderColor::new(color : @sprite.Color) -> BorderColor {
  BorderColor::{ color, }
}
