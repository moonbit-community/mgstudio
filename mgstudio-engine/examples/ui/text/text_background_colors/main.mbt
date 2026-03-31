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
fn palette_color(index : Int) -> @sprite.Color {
  match index % 5 {
    0 => @sprite.Color::srgb(0.85F, 0.20F, 0.18F)
    1 => @sprite.Color::srgb(0.18F, 0.70F, 0.28F)
    2 => @sprite.Color::srgb(0.18F, 0.37F, 0.88F)
    3 => @sprite.Color::srgb(0.98F, 0.82F, 0.18F)
    _ => @sprite.Color::srgb(0.56F, 0.30F, 0.80F)
  }
}

///|
fn message_text() -> Array[String] {
  [
    "T", "e", "x", "t\n", "B", "a", "c", "k", "g", "r", "o", "u", "n", "d\n", "C",
    "o", "l", "o", "r", "s", "!",
  ]
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param(setup)
  .add_system_param3(cycle_text_background_colors)
  .run()
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.spawn(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
    ),
  )
  let text_entity = commands.spawn(
    (
      @text.Text::default(),
      @text.TextLayout::new_with_justify(@text.Justify::Center),
    ),
  )
  commands.entity(text_entity).insert_component(@hierarchy.Parent::new(root))

  let chars = message_text()
  for i in 0..<chars.length() {
    let span = commands.spawn(
      (
        @text.TextSpan::new(chars[i]),
        @text.TextColor::black(),
        @text.TextFont::default().with_font_size(@text.FontSize::Px(100.0F)),
        @text.TextBackgroundColor::new(palette_color(i)),
      ),
    )
    let span_commands = commands.entity(span)
    span_commands.insert_component(@hierarchy.Parent::new(text_entity))
    ignore(
      span_commands
      .observe_pointer2(fn(
        _pointer : @app.OnPointer[@app.PointerEnter],
        query : @ecs.Query[@ecs.Mut[@text.TextColor], @ecs.All],
      ) {
        let text_color = query.get(span) catch { _ => None }
        if text_color is Some(text_color) {
          text_color.get_ref().val = @text.TextColor::white()
        }
      })
      .observe_pointer2(fn(
        _pointer : @app.OnPointer[@app.PointerLeave],
        query : @ecs.Query[@ecs.Mut[@text.TextColor], @ecs.All],
      ) {
        let text_color = query.get(span) catch { _ => None }
        if text_color is Some(text_color) {
          text_color.get_ref().val = @text.TextColor::black()
        }
      }),
    )
  }
}

///|
fn cycle_text_background_colors(
  time : @app.Res[@time.Time[@time.Real]],
  children_query : @ecs.Query[
    @ecs.Comp[@hierarchy.Children],
    @ecs.With[@text.Text],
  ],
  text_background_colors_query : @ecs.Query[
    @ecs.Mut[@text.TextBackgroundColor],
    @ecs.All,
  ],
) -> Unit {
  let n = time.get().elapsed_secs().to_int()
  let children_comp = children_query.single() catch { _ => None }
  guard children_comp is Some(children_comp) else { return }
  let children = children_comp.value()
  let entities = children.entities()
  for i in 0..<entities.length() {
    let background_color = text_background_colors_query.get(entities[i]) catch {
      _ => None
    }
    if background_color is Some(background_color) {
      background_color.get_ref().val = @text.TextBackgroundColor::new(
        palette_color(i + n),
      )
    }
  }
}
