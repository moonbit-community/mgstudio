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
// Bevy source: `bevy/crates/bevy_feathers/src/dark_theme.rs`.

///|
pub fn create_dark_theme() -> ThemeProps {
  let props = ThemeProps::default()
  let tok = fn(name : String) { ThemeToken::new_static(name) }
  let gray_3_hover = "#54555B"
  let gray_3_pressed = "#616369"
  let accent_hover = "#327DDA"
  let accent_pressed = "#428DEB"
  let white_50 = "#FFFFFF80"
  let gray_1_50 = "#2A2A2E80"
  let gray_3_50 = "#46474D80"
  let accent_50 = "#206EC980"
  let light_gray_1_50 = "#B1B1B280"
  let light_gray_2_30 = "#8383854C"
  props.set_color(tok(WINDOW_BG), GRAY_0)
  props.set_color(tok(BUTTON_BG), GRAY_3)
  props.set_color(tok(BUTTON_BG_HOVER), gray_3_hover)
  props.set_color(tok(BUTTON_BG_PRESSED), gray_3_pressed)
  props.set_color(tok(BUTTON_BG_DISABLED), GRAY_2)
  props.set_color(tok(BUTTON_PRIMARY_BG), ACCENT)
  props.set_color(tok(BUTTON_PRIMARY_BG_HOVER), accent_hover)
  props.set_color(tok(BUTTON_PRIMARY_BG_PRESSED), accent_pressed)
  props.set_color(tok(BUTTON_PRIMARY_BG_DISABLED), GRAY_2)
  props.set_color(tok(BUTTON_TEXT), WHITE)
  props.set_color(tok(BUTTON_TEXT_DISABLED), white_50)
  props.set_color(tok(BUTTON_PRIMARY_TEXT), WHITE)
  props.set_color(tok(BUTTON_PRIMARY_TEXT_DISABLED), white_50)
  props.set_color(tok(SLIDER_BG), GRAY_1)
  props.set_color(tok(SLIDER_BAR), ACCENT)
  props.set_color(tok(SLIDER_BAR_DISABLED), GRAY_2)
  props.set_color(tok(SLIDER_TEXT), WHITE)
  props.set_color(tok(SLIDER_TEXT_DISABLED), white_50)
  props.set_color(tok(CHECKBOX_BG), GRAY_3)
  props.set_color(tok(CHECKBOX_BG_CHECKED), ACCENT)
  props.set_color(tok(CHECKBOX_BG_DISABLED), gray_1_50)
  props.set_color(tok(CHECKBOX_BG_CHECKED_DISABLED), gray_3_50)
  props.set_color(tok(CHECKBOX_BORDER), GRAY_3)
  props.set_color(tok(CHECKBOX_BORDER_HOVER), gray_3_pressed)
  props.set_color(tok(CHECKBOX_BORDER_DISABLED), gray_3_50)
  props.set_color(tok(CHECKBOX_MARK), WHITE)
  props.set_color(tok(CHECKBOX_MARK_DISABLED), LIGHT_GRAY_2)
  props.set_color(tok(CHECKBOX_TEXT), LIGHT_GRAY_1)
  props.set_color(tok(CHECKBOX_TEXT_DISABLED), light_gray_1_50)
  props.set_color(tok(RADIO_BORDER), GRAY_3)
  props.set_color(tok(RADIO_BORDER_HOVER), gray_3_pressed)
  props.set_color(tok(RADIO_BORDER_DISABLED), gray_3_50)
  props.set_color(tok(RADIO_MARK), ACCENT)
  props.set_color(tok(RADIO_MARK_DISABLED), accent_50)
  props.set_color(tok(RADIO_TEXT), LIGHT_GRAY_1)
  props.set_color(tok(RADIO_TEXT_DISABLED), light_gray_1_50)
  props.set_color(tok(SWITCH_BG), GRAY_3)
  props.set_color(tok(SWITCH_BG_CHECKED), ACCENT)
  props.set_color(tok(SWITCH_BG_DISABLED), gray_1_50)
  props.set_color(tok(SWITCH_BG_CHECKED_DISABLED), gray_3_50)
  props.set_color(tok(SWITCH_BORDER), GRAY_3)
  props.set_color(tok(SWITCH_BORDER_HOVER), gray_3_pressed)
  props.set_color(tok(SWITCH_BORDER_DISABLED), gray_3_50)
  props.set_color(tok(SWITCH_SLIDE), LIGHT_GRAY_2)
  props.set_color(tok(SWITCH_SLIDE_DISABLED), light_gray_2_30)
  props.set_color(tok(COLOR_PLANE_BG), GRAY_1)
  props
}
