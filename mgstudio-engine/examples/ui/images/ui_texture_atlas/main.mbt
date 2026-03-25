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
  texture_atlases : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> Unit {
  let server = asset_server.get()
  let font = server.load_font("fonts/FiraSans-Bold.ttf")
  let texture = server.load_image("textures/rpg/chars/gabe/gabe-idle-run.png")
  let atlas_layout = texture_atlases.get_ref().val.add(
    @asset.TextureAtlasLayout::from_grid(@math.UVec2::splat(24), 7, 1),
  )

  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_row_gap(@ui.Val::Px(40.0F)),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.ImageNode::from_atlas_image(
          texture,
          @asset.TextureAtlas::new(atlas_layout, 0),
        ),
        @ui.Node::default()
        .with_width(@ui.Val::Px(256.0F))
        .with_height(@ui.Val::Px(256.0F)),
        @ui.BackgroundColor::new(@sprite.Color::srgb(0.98F, 0.92F, 0.84F)),
        @ui.Outline::new(
          @ui.Val::Px(8.0F),
          @ui.Val::Px(0.0F),
          @sprite.Color::srgb(0.86F, 0.08F, 0.24F),
        ),
      ),
    ),
  )

  let prompt = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @text.Text::new("press "),
      @text.TextFont::from_font_size(@text.FontSize::Px(20.0F)).with_font(font),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(prompt),
        @text.TextSpan::new("space"),
        @text.TextColor::new(@sprite.Color::srgb(1.0F, 0.92F, 0.0F)),
        @text.TextFont::from_font_size(@text.FontSize::Px(20.0F)).with_font(
          font,
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(prompt),
        @text.TextSpan::new(" to advance frames"),
        @text.TextFont::from_font_size(@text.FontSize::Px(20.0F)).with_font(
          font,
        ),
      ),
    ),
  )
}

///|
fn increment_atlas_index(
  image_nodes : @ecs.Query[@ecs.Mut[@ui.ImageNode], @ecs.All],
  keyboard : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  if !keyboard.just_pressed(Space) {
    return
  }
  try! image_nodes.view(fn(_entity, image) {
    guard image.value().texture_atlas is Some(atlas) else { return }
    image.set(
      image
      .value()
      .with_texture_atlas(Some(atlas.with_index((atlas.index + 1) % 6))),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(increment_atlas_index)),
  )
  .run()
}
