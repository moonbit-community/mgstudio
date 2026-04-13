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
  props.set_color(tok(WINDOW_BG), GRAY_0)
  props.set_color(tok(BUTTON_BG), GRAY_3)
  props.set_color(tok(BUTTON_BG_HOVER), GRAY_2)
  props.set_color(tok(BUTTON_BG_PRESSED), GRAY_1)
  props.set_color(tok(BUTTON_BG_DISABLED), GRAY_2)
  props.set_color(tok(BUTTON_TEXT), WHITE)
  props.set_color(tok(BUTTON_TEXT_DISABLED), LIGHT_GRAY_2)
  props.set_color(tok(BUTTON_PRIMARY_BG), ACCENT)
  props.set_color(tok(BUTTON_PRIMARY_TEXT), WHITE)
  props.set_color(tok(SLIDER_BG), GRAY_1)
  props.set_color(tok(SLIDER_BAR), ACCENT)
  props.set_color(tok(SLIDER_TEXT), WHITE)
  props.set_color(tok(CHECKBOX_BG), GRAY_2)
  props.set_color(tok(CHECKBOX_BORDER), WARM_GRAY_1)
  props.set_color(tok(CHECKBOX_MARK), WHITE)
  props.set_color(tok(CHECKBOX_TEXT), WHITE)
  props.set_color(tok(RADIO_BORDER), WARM_GRAY_1)
  props.set_color(tok(RADIO_MARK), WHITE)
  props.set_color(tok(RADIO_TEXT), WHITE)
  props.set_color(tok(SWITCH_BG), GRAY_2)
  props.set_color(tok(SWITCH_BORDER), WARM_GRAY_1)
  props.set_color(tok(SWITCH_SLIDE), WHITE)
  props.set_color(tok(COLOR_PLANE_BG), GRAY_1)
  props
}
