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
// Bevy source: `bevy/crates/bevy_feathers/src/theme.rs`.

///|
pub struct ThemeToken {
  name : String
} derive(Eq, Debug)

///|
pub fn ThemeToken::new(text : String) -> ThemeToken {
  ThemeToken::{ name: text }
}

///|
pub fn ThemeToken::new_static(text : String) -> ThemeToken {
  ThemeToken::new(text)
}

///|
pub fn ThemeToken::name(self : ThemeToken) -> String {
  self.name
}

///|
pub struct ThemeProps {
  color : Array[(ThemeToken, String)]
}

///|
pub fn ThemeProps::default() -> ThemeProps {
  ThemeProps::{ color: [] }
}

///|
pub fn ThemeProps::set_color(
  self : ThemeProps,
  token : ThemeToken,
  color : String,
) -> Unit {
  for i in 0..<self.color.length() {
    let (existing, _) = self.color[i]
    if existing == token {
      self.color[i] = (token, color)
      return
    }
  }
  self.color.push((token, color))
}

///|
pub fn ThemeProps::get_color(self : ThemeProps, token : ThemeToken) -> String? {
  for entry in self.color {
    let (existing, color) = entry
    if existing == token {
      return Some(color)
    }
  }
  None
}

///|
pub struct UiTheme {
  props : ThemeProps
}

///|
pub fn UiTheme::default() -> UiTheme {
  UiTheme::{ props: ThemeProps::default() }
}

///|
pub fn UiTheme::color(self : UiTheme, token : ThemeToken) -> String {
  self.props.get_color(token).unwrap_or("#ff00ff")
}

///|
pub fn UiTheme::set_color(
  self : UiTheme,
  token : String,
  color : String,
) -> Unit {
  self.props.set_color(ThemeToken::new(token), color)
}

///|
pub struct ThemeBackgroundColor {
  token : ThemeToken
} derive(Debug)

///|
pub struct ThemeBorderColor {
  token : ThemeToken
} derive(Debug)

///|
pub struct ThemeFontColor {
  token : ThemeToken
} derive(Debug)

///|
pub struct ThemedText {} derive(Default, Debug)

///|
pub fn ThemeBackgroundColor::new(token : ThemeToken) -> ThemeBackgroundColor {
  ThemeBackgroundColor::{ token, }
}

///|
pub fn ThemeBorderColor::new(token : ThemeToken) -> ThemeBorderColor {
  ThemeBorderColor::{ token, }
}

///|
pub fn ThemeFontColor::new(token : ThemeToken) -> ThemeFontColor {
  ThemeFontColor::{ token, }
}

///|
pub fn ThemeBackgroundColor::token(self : ThemeBackgroundColor) -> ThemeToken {
  self.token
}

///|
pub fn ThemeBorderColor::token(self : ThemeBorderColor) -> ThemeToken {
  self.token
}

///|
pub fn ThemeFontColor::token(self : ThemeFontColor) -> ThemeToken {
  self.token
}

///|
let ui_theme_resource_key : @ecs.ResourceKey[UiTheme] = @ecs.register_resource(
  debug_name="mgstudio_feathers::UiTheme",
)

///|
let theme_background_color_component_key : @ecs.ComponentKey[
  ThemeBackgroundColor,
] = @ecs.register_component(
  debug_name="mgstudio_feathers::ThemeBackgroundColor",
)

///|
let theme_border_color_component_key : @ecs.ComponentKey[ThemeBorderColor] = @ecs.register_component(
  debug_name="mgstudio_feathers::ThemeBorderColor",
)

///|
let theme_font_color_component_key : @ecs.ComponentKey[ThemeFontColor] = @ecs.register_component(
  debug_name="mgstudio_feathers::ThemeFontColor",
)

///|
let themed_text_component_key : @ecs.ComponentKey[ThemedText] = @ecs.register_component(
  debug_name="mgstudio_feathers::ThemedText",
)

///|
pub impl @app.Resource for UiTheme with resource() {
  ui_theme_resource_key
}

///|
pub impl @ecs.Component for ThemeBackgroundColor with component() {
  theme_background_color_component_key
}

///|
pub impl @ecs.Component for ThemeBorderColor with component() {
  theme_border_color_component_key
}

///|
pub impl @ecs.Component for ThemeFontColor with component() {
  theme_font_color_component_key
}

///|
pub impl @ecs.Component for ThemedText with component() {
  themed_text_component_key
}
