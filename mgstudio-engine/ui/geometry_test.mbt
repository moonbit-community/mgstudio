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

  let replaced = UiRect::all(Val::Px(1.0F))
    .with_left(Val::Px(2.0F))
    .with_right(Val::Px(3.0F))
    .with_top(Val::Px(4.0F))
    .with_bottom(Val::Px(5.0F))
  debug_inspect(ui_test_val_px_eq(replaced.left, 2.0F), content="true")
  debug_inspect(ui_test_val_px_eq(replaced.right, 3.0F), content="true")
  debug_inspect(ui_test_val_px_eq(replaced.top, 4.0F), content="true")
  debug_inspect(ui_test_val_px_eq(replaced.bottom, 5.0F), content="true")
}

///|
test "ui: Val equality treats numeric zero units as equal" {
  debug_inspect(Val::Px(0.0F) == Val::Percent(0.0F), content="true")
  debug_inspect(Val::Vw(0.0F) == Val::Vh(0.0F), content="true")
  debug_inspect(Val::Px(1.0F) == Val::Percent(1.0F), content="false")
  debug_inspect(Val::Auto == Val::Px(0.0F), content="false")
}

///|
test "ui: Val helpers construct rect sides" {
  let left = Val::Px(3.0F).left()
  debug_inspect(ui_test_val_px_eq(left.left, 3.0F), content="true")
  debug_inspect(ui_test_val_px_eq(left.right, 0.0F), content="true")
  let vertical = Val::Percent(25.0F).vertical()
  debug_inspect(
    ui_test_val_percent_eq(vertical.top, 25.0F) &&
    ui_test_val_percent_eq(vertical.bottom, 25.0F),
    content="true",
  )
}

///|
test "ui: Val parse supports layout units" {
  debug_inspect(Val::parse(" auto ") == Val::Auto, content="true")
  debug_inspect(Val::parse("12px") == Val::Px(12.0F), content="true")
  debug_inspect(Val::parse("-5.5 %") == Val::Percent(-5.5F), content="true")
  debug_inspect(Val::parse("10vw") == Val::Vw(10.0F), content="true")
  debug_inspect(Val::parse("11vh") == Val::Vh(11.0F), content="true")
  debug_inspect(Val::parse("12vmin") == Val::VMin(12.0F), content="true")
  debug_inspect(Val::parse("13vmax") == Val::VMax(13.0F), content="true")

  let mut unit_missing : ValParseError? = None
  ignore(Val::parse("12")) catch {
    err => unit_missing = Some(err)
  }
  debug_inspect(
    unit_missing is Some(ValParseError::UnitMissing),
    content="true",
  )
}

///|
test "ui: Val resolve follows scale and viewport semantics" {
  let target = @math.Vec2::new(640.0F, 480.0F)
  debug_inspect(
    Val::Px(10.0F).resolve(2.0F, 100.0F, target) == 20.0F,
    content="true",
  )
  debug_inspect(
    Val::Percent(25.0F).resolve(2.0F, 200.0F, target) == 50.0F,
    content="true",
  )
  debug_inspect(
    Val::Vw(50.0F).resolve(1.0F, 0.0F, target) == 320.0F,
    content="true",
  )
  debug_inspect(
    Val::Vh(50.0F).resolve(1.0F, 0.0F, target) == 240.0F,
    content="true",
  )
  debug_inspect(
    Val::VMin(50.0F).resolve(1.0F, 0.0F, target) == 240.0F,
    content="true",
  )
  debug_inspect(
    Val::VMax(50.0F).resolve(1.0F, 0.0F, target) == 320.0F,
    content="true",
  )

  let mut non_evaluable : ValArithmeticError? = None
  ignore(Val::Auto.resolve(1.0F, 0.0F, target)) catch {
    err => non_evaluable = Some(err)
  }
  debug_inspect(
    non_evaluable is Some(ValArithmeticError::NonEvaluable),
    content="true",
  )
}

///|
test "ui: BorderRadius helpers mirror corner ordering" {
  let radius = BorderRadius::new(
    Val::Px(1.0F),
    Val::Px(2.0F),
    Val::Px(3.0F),
    Val::Px(4.0F),
  )
  debug_inspect(ui_test_val_px_eq(radius.top_left, 1.0F), content="true")
  debug_inspect(ui_test_val_px_eq(radius.top_right, 2.0F), content="true")
  debug_inspect(ui_test_val_px_eq(radius.bottom_right, 3.0F), content="true")
  debug_inspect(ui_test_val_px_eq(radius.bottom_left, 4.0F), content="true")

  let left = BorderRadius::left(Val::Px(7.0F))
  debug_inspect(ui_test_val_px_eq(left.top_left, 7.0F), content="true")
  debug_inspect(ui_test_val_px_eq(left.bottom_left, 7.0F), content="true")
  debug_inspect(ui_test_val_px_eq(left.top_right, 0.0F), content="true")
  debug_inspect(ui_test_val_px_eq(left.bottom_right, 0.0F), content="true")

  let replaced = BorderRadius::all(Val::Px(1.0F))
    .with_top_left(Val::Px(2.0F))
    .with_top_right(Val::Px(3.0F))
    .with_bottom_right(Val::Px(4.0F))
    .with_bottom_left(Val::Px(5.0F))
  debug_inspect(ui_test_val_px_eq(replaced.top_left, 2.0F), content="true")
  debug_inspect(ui_test_val_px_eq(replaced.top_right, 3.0F), content="true")
  debug_inspect(ui_test_val_px_eq(replaced.bottom_right, 4.0F), content="true")
  debug_inspect(ui_test_val_px_eq(replaced.bottom_left, 5.0F), content="true")
}

///|
test "ui: BorderRadius resolve clamps corner radius" {
  let viewport = @math.Vec2::new(640.0F, 480.0F)
  debug_inspect(
    BorderRadius::resolve_single_corner(Val::Px(100.0F), 1.0F, 80.0F, viewport) ==
    40.0F,
    content="true",
  )
  debug_inspect(
    BorderRadius::resolve_single_corner(
      Val::Percent(25.0F),
      1.0F,
      80.0F,
      viewport,
    ) ==
    20.0F,
    content="true",
  )
}
