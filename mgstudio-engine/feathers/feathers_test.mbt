// Copyright 2026 International Digital Economy Academy
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
test "feathers boundary exposes plugin and plugin-group entries" {
  let app = @app.App::new(@ecs.World::new())
  let _ = @feathers.feathers_plugin(app)
  let _group = @feathers.feathers_plugins()
  debug_inspect("ok", content="\"ok\"")
}

///|
test "feathers dark theme covers Bevy token state matrix" {
  let props = create_dark_theme()
  let tok = fn(name : String) { ThemeToken::new_static(name) }
  debug_inspect(
    props.get_color(tok(BUTTON_BG_HOVER)).unwrap(),
    content="\"#54555B\"",
  )
  debug_inspect(
    props.get_color(tok(BUTTON_PRIMARY_BG_PRESSED)).unwrap(),
    content="\"#428DEB\"",
  )
  debug_inspect(
    props.get_color(tok(CHECKBOX_BG_CHECKED_DISABLED)).unwrap(),
    content="\"#46474D80\"",
  )
  debug_inspect(
    props.get_color(tok(RADIO_MARK_DISABLED)).unwrap(),
    content="\"#206EC980\"",
  )
  debug_inspect(
    props.get_color(tok(SWITCH_SLIDE_DISABLED)).unwrap(),
    content="\"#8383854C\"",
  )
}
