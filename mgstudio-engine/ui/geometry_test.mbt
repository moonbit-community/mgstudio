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
fn ui_test_val_px_eq(value : Val, expected : Float) -> Bool {
  match value {
    Val::Px(actual) => actual == expected
    _ => false
  }
}

///|
fn ui_test_val_percent_eq(value : Val, expected : Float) -> Bool {
  match value {
    Val::Percent(actual) => actual == expected
    _ => false
  }
}

///|
test "ui: UiRect constructors use left-right-top-bottom order" {
  let rect = UiRect::new(
    Val::Px(1.0F),
    Val::Px(2.0F),
    Val::Px(3.0F),
    Val::Px(4.0F),
  )
  debug_inspect(ui_test_val_px_eq(rect.left, 1.0F), content="true")
  debug_inspect(ui_test_val_px_eq(rect.right, 2.0F), content="true")
  debug_inspect(ui_test_val_px_eq(rect.top, 3.0F), content="true")
  debug_inspect(ui_test_val_px_eq(rect.bottom, 4.0F), content="true")

  let px = UiRect::px(5.0F, 6.0F, 7.0F, 8.0F)
  debug_inspect(ui_test_val_px_eq(px.left, 5.0F), content="true")
  debug_inspect(ui_test_val_px_eq(px.right, 6.0F), content="true")
  debug_inspect(ui_test_val_px_eq(px.top, 7.0F), content="true")
  debug_inspect(ui_test_val_px_eq(px.bottom, 8.0F), content="true")

  let percent = UiRect::percent(9.0F, 10.0F, 11.0F, 12.0F)
  debug_inspect(ui_test_val_percent_eq(percent.left, 9.0F), content="true")
  debug_inspect(ui_test_val_percent_eq(percent.right, 10.0F), content="true")
  debug_inspect(ui_test_val_percent_eq(percent.top, 11.0F), content="true")
  debug_inspect(ui_test_val_percent_eq(percent.bottom, 12.0F), content="true")
}

///|
test "ui: UiRect side helpers mirror geometry defaults" {
  let horizontal = UiRect::horizontal(Val::Px(2.0F))
  debug_inspect(ui_test_val_px_eq(horizontal.left, 2.0F), content="true")
  debug_inspect(ui_test_val_px_eq(horizontal.right, 2.0F), content="true")
  debug_inspect(ui_test_val_px_eq(horizontal.top, 0.0F), content="true")
  debug_inspect(ui_test_val_px_eq(horizontal.bottom, 0.0F), content="true")

  let vertical = UiRect::vertical(Val::Px(3.0F))
  debug_inspect(ui_test_val_px_eq(vertical.left, 0.0F), content="true")
  debug_inspect(ui_test_val_px_eq(vertical.right, 0.0F), content="true")
  debug_inspect(ui_test_val_px_eq(vertical.top, 3.0F), content="true")
  debug_inspect(ui_test_val_px_eq(vertical.bottom, 3.0F), content="true")

  let axes = UiRect::axes(Val::Px(4.0F), Val::Px(5.0F))
  debug_inspect(ui_test_val_px_eq(axes.left, 4.0F), content="true")
  debug_inspect(ui_test_val_px_eq(axes.right, 4.0F), content="true")
  debug_inspect(ui_test_val_px_eq(axes.top, 5.0F), content="true")
  debug_inspect(ui_test_val_px_eq(axes.bottom, 5.0F), content="true")
}
