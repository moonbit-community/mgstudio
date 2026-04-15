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
fn wheat() -> @sprite.Color {
  @sprite.Color::srgb(0.96F, 0.87F, 0.7F)
}

///|
fn yellow() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.92F, 0.0F)
}

///|
fn zinc_600() -> @sprite.Color {
  @sprite.Color::srgb(0.32F, 0.32F, 0.36F)
}

///|
fn font_size() -> @text.FontSize {
  @text.FontSize::Px(25.0F)
}

///|
fn generic_font_label(font_source : @text.FontSource) -> String {
  match font_source {
    Serif => "FontSource::Serif"
    SansSerif => "FontSource::SansSerif"
    Fantasy => "FontSource::Fantasy"
    Cursive => "FontSource::Cursive"
    Monospace => "FontSource::Monospace"
    SystemUi => "FontSource::SystemUi"
    UiSerif => "FontSource::UiSerif"
    UiSansSerif => "FontSource::UiSansSerif"
    UiMonospace => "FontSource::UiMonospace"
    UiRounded => "FontSource::UiRounded"
    Emoji => "FontSource::Emoji"
    Math => "FontSource::Math"
    FangSong => "FontSource::FangSong"
    Handle(_) => "FontSource::Handle"
    Family(name) => "FontSource::Family(\{name})"
  }
}

///|
fn family_description(font_source : @text.FontSource) -> String {
  match font_source {
    Serif => "generic serif font"
    SansSerif => "generic sans serif font"
    Fantasy => "generic fantasy font"
    Cursive => "generic cursive font"
    Monospace => "generic monospace font"
    SystemUi => "generic system ui font"
    UiSerif => "generic ui serif font"
    UiSansSerif => "generic ui sans serif font"
    UiMonospace => "generic ui monospace font"
    UiRounded => "generic ui rounded font"
    Emoji => "generic emoji font"
    Math => "generic math font"
    FangSong => "generic fangsong font"
    Handle(_) => "font handle"
    Family(name) => name
  }
}

///|
fn generic_font_text(font_source : @text.FontSource) -> @text.TextFont {
  @text.TextFont::{
    ..@text.TextFont::from_font_size(font_size()),
    font: font_source,
  }
}

///|
fn spawn_row(
  commands : @app.Commands,
  root : @core.Entity,
  font_source : @text.FontSource,
) -> Unit {
  let row = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_display(@ui.Display::Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(3), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ])
      .with_column_gap(@ui.Val::Px(15.0F))
      .with_width(@ui.Val::Percent(100.0F)),
    ),
  )
  let outline = @ui.Outline::new(
    @ui.Val::Px(2.0F),
    @ui.Val::Px(4.0F),
    zinc_600(),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @text.Text::new(family_description(font_source)),
        generic_font_text(font_source),
        @text.TextColor::new(wheat()),
        @text.TextLayout::new_with_justify(@text.Justify::Center),
        outline,
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @text.Text::new(generic_font_label(font_source)),
        @text.TextFont::from_font_size(font_size()),
        @text.TextColor::new(yellow()),
        @text.TextLayout::new_with_justify(@text.Justify::Center),
        outline,
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @text.Text::new(family_description(font_source)),
        @text.TextFont::from_font_size(font_size()),
        @text.TextLayout::new_with_justify(@text.Justify::Center),
        outline,
      ),
    ),
  )
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_display(@ui.Display::Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(1), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ])
      .with_width(@ui.Val::Px(1200.0F))
      .with_margin(@ui.UiRect::all(@ui.Val::Auto))
      .with_row_gap(@ui.Val::Px(25.0F))
      .with_column_gap(@ui.Val::Px(15.0F)),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new("Generic Font Families"),
        @text.TextFont::from_font_size(font_size()),
        @text.Underline::default(),
      ),
    ),
  )

  let families : Array[@text.FontSource] = [
    @text.FontSource::SansSerif,
    @text.FontSource::Serif,
    @text.FontSource::Fantasy,
    @text.FontSource::Cursive,
    @text.FontSource::Monospace,
  ]
  for font_source in families {
    spawn_row(commands, root, font_source)
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .run()
}
