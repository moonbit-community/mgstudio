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
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  let font = server.load_font("fonts/FiraSans-Bold.ttf")
  let image = server.load_image(
    "textures/fantasy_ui_borders/panel-border-010.png",
  )
  let slicer = @ui.TextureSlicer::new(@ui.BorderRect::square(22.0F))
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
    ),
  )

  let sizes : Array[(Float, Float)] = [
    (150.0F, 150.0F),
    (300.0F, 150.0F),
    (150.0F, 300.0F),
  ]
  for size in sizes {
    let button = commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Button::default(),
        @ui.ImageNode::new(image).with_mode(@ui.NodeImageMode::Sliced(slicer)),
        @ui.Node::default()
        .with_width(@ui.Val::Px(size.0))
        .with_height(@ui.Val::Px(size.1))
        .with_justify_content(@ui.JustifyContent::Center)
        .with_align_items(@ui.AlignItems::Center)
        .with_margin(@ui.UiRect::all(@ui.Val::Px(20.0F))),
      ),
    )
    ignore(
      commands.spawn(
        (
          @hierarchy.Parent::new(button),
          @text.Text::new("Button"),
          @text.TextFont::default()
          .with_font(font)
          .with_font_size(@text.FontSize::Px(33.0F)),
          @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
        ),
      ),
    )
  }
}

///|
fn button_system(
  buttons : @ecs.Query[
    (
      @ecs.Comp[@ui.Interaction],
      @ecs.Comp[@hierarchy.Children],
      @ecs.Mut[@ui.ImageNode],
    ),
    @ecs.With[@ui.Button],
  ],
  texts : @ecs.Query[@ecs.Mut[@text.Text], @ecs.All],
) -> Unit {
  try! buttons.view(fn(_entity, data) {
    let (interaction_comp, children_comp, image) = data
    let children = children_comp.value().entities()
    if children.length() == 0 {
      return
    }
    let label = children[0]
    guard (texts.get(label) catch { _ => None }) is Some(text) else { return }
    match interaction_comp.value() {
      @ui.Interaction::Pressed => {
        text.get_ref().val.content = "Press"
        image.set(
          image.value().with_color(@sprite.Color::srgb(1.0F, 0.84F, 0.0F)),
        )
      }
      @ui.Interaction::Hovered => {
        text.get_ref().val.content = "Hover"
        image.set(
          image.value().with_color(@sprite.Color::srgb(1.0F, 0.55F, 0.0F)),
        )
      }
      @ui.Interaction::None => {
        text.get_ref().val.content = "Button"
        image.set(image.value().with_color(@sprite.Color::white()))
      }
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(button_system)))
  .run()
}
