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
test "ui_widgets: owner widget surface exposes core event and marker types" {
  @ui_widgets.Button::default() |> ignore
  @ui_widgets.MenuPopup::default() |> ignore
  @ui_widgets.Slider::default() |> ignore
  @ui_widgets.Scrollbar::new(
    @core.Entity::placeholder(),
    @ui_widgets.ControlOrientation::default(),
    8.0F,
  )
  |> ignore
  @ui_widgets.Popover::default() |> ignore
  ignore(@ui_widgets.ecs_key_checkbox.id())
  ignore(@ui_widgets.ecs_key_radio_group.id())
  ignore(@ui_widgets.ecs_key_radio_button.id())
  ignore(@ui_widgets.ecs_key_menu_item.id())
  debug_inspect(
    @ui_widgets.MenuLayout::default() == @ui_widgets.MenuLayout::Column,
    content="true",
  )
}

///|
test "ui_widgets: plugin entry installs widget plugins on top of ui plugin" {
  let app = @app.App::new(@ecs.World::new())
  @ui_widgets.ui_widgets_plugin(app) |> ignore
  debug_inspect(true, content="true")
}
