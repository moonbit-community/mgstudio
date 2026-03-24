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
struct CursorArea {}

///|
struct CursorReadout {}

///|
let cursor_area_key : @ecs.ComponentKey[CursorArea] = @ecs.register_component(
  debug_name="examples.ui.relative_cursor_position.CursorArea",
)

///|
let cursor_readout_key : @ecs.ComponentKey[CursorReadout] = @ecs.register_component(
  debug_name="examples.ui.relative_cursor_position.CursorReadout",
)

///|
pub impl @ecs.Component for CursorArea with component() {
  cursor_area_key
}

///|
pub impl @ecs.Component for CursorReadout with component() {
  cursor_readout_key
}

///|
fn float_text_1(value : Float) -> String {
  let scaled = (value * 10.0F).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / 10
  let fraction = abs_scaled % 10
  sign + whole.to_string() + "." + fraction.to_string()
}

///|
fn cursor_position_text(
  relative_cursor_position : @ui.RelativeCursorPosition,
) -> String {
  match relative_cursor_position.normalized {
    Some(normalized) =>
      "(" + float_text_1(normalized.x) + ", " + float_text_1(normalized.y) + ")"
    None => "unknown"
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::default().with_viewport(
          @sprite.Viewport::new(
            @math.IVec2::new(200, 100),
            @math.IVec2::new(600, 600),
          ),
        ),
      ),
    ),
  )

  let root = commands.spawn_component(
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_align_items(@ui.AlignItems::Center)
    .with_justify_content(@ui.JustifyContent::Center)
    .with_flex_direction(@ui.FlexDirection::Column),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        CursorArea::{  },
        @ui.RelativeCursorPosition::default(),
        @ui.Node::default()
        .with_width(@ui.Val::Px(250.0F))
        .with_height(@ui.Val::Px(250.0F))
        .with_margin(
          @ui.UiRect::new(
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(15.0F),
          ),
        ),
        @ui.BackgroundColor::new(@sprite.Color::srgb(0.92F, 0.14F, 0.05F)),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        CursorReadout::{  },
        @text.Text::new("(0.0, 0.0)"),
        @text.TextFont::from_font_size(33.0F).with_font(
          asset_server.get().load_font("fonts/FiraSans-Bold.ttf"),
        ),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
      ),
    ),
  )
}

///|
fn relative_cursor_position_system(
  relative_cursor_positions : @ecs.Query2[
    CursorArea,
    @ui.RelativeCursorPosition,
  ],
  outputs : @ecs.Query3[CursorReadout, @text.Text, @text.TextColor],
) -> Unit {
  let current : Ref[@ui.RelativeCursorPosition?] = Ref::new(None)
  try! relative_cursor_positions.view(fn(
    _entity,
    _cursor_area,
    relative_cursor_position,
  ) {
    if current.val is None {
      current.val = Some(relative_cursor_position)
    }
  })
  guard current.val is Some(relative_cursor_position) else { return }

  let content = cursor_position_text(relative_cursor_position)
  let color = if relative_cursor_position.cursor_over() {
    @sprite.Color::srgb(0.1F, 0.9F, 0.1F)
  } else {
    @sprite.Color::srgb(0.9F, 0.1F, 0.1F)
  }

  try! outputs.view(fn(_entity, _readout, text, text_color) {
    text.content = content
    text_color.color = color
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(relative_cursor_position_system)),
  )
  .run()
}
