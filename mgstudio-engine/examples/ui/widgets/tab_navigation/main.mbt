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
fn normal_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.15F, 0.15F, 0.15F)
}

///|
fn hovered_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.25F, 0.25F, 0.25F)
}

///|
fn pressed_button_color() -> @sprite.Color {
  @sprite.Color::srgb(0.35F, 0.75F, 0.35F)
}

///|
fn focus_outline() -> @ui.Outline {
  @ui.Outline::new(@ui.Val::Px(2.0F), @ui.Val::Px(2.0F), @sprite.Color::white())
}

///|
fn spawn_tab_button(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
  tab_index : Int,
) -> Unit {
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Button::default(),
      @input_focus.TabIndex::new(tab_index),
      @ui.Node::default()
      .with_width(@ui.Val::Px(200.0F))
      .with_height(@ui.Val::Px(65.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(5.0F)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BorderColor::new(@sprite.Color::black()),
      @ui.BackgroundColor::new(normal_button_color()),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new(label),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.9F)),
      ),
    ),
  )
  ignore(
    commands
    .entity(button)
    .observe_pointer2(fn(
      _pointer : @app.OnPointer[@app.PointerClick],
      focus : @app.ResMut[@input_focus.InputFocus],
    ) {
      focus.get_ref().val.set(button)
    }),
  )
}

///|
fn spawn_tab_group(
  commands : @app.Commands,
  root : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
  tab_group : @input_focus.TabGroup,
  indices : Array[Int],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new(label),
        @text.TextFont::default().with_font(font).with_font_size(18.0F),
        @text.TextColor::new(@sprite.Color::white()),
      ),
    ),
  )

  let group = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      tab_group,
      @ui.Node::default()
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_column_gap(@ui.Val::Px(6.0F))
      .with_margin(
        @ui.UiRect::new(
          @ui.Val::Px(0.0F),
          @ui.Val::Px(0.0F),
          @ui.Val::Px(0.0F),
          @ui.Val::Px(10.0F),
        ),
      ),
    ),
  )

  for index in indices {
    spawn_tab_button(
      commands,
      group,
      font,
      "TabIndex \{index.to_string()}",
      index,
    )
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_row_gap(@ui.Val::Px(6.0F)),
    ),
  )
  ignore(
    commands
    .entity(root)
    .observe_pointer2(fn(
      _pointer : @app.OnPointer[@app.PointerClick],
      focus : @app.ResMut[@input_focus.InputFocus],
    ) {
      focus.get_ref().val.clear()
    }),
  )

  spawn_tab_group(
    commands,
    root,
    font,
    "TabGroup 0",
    @input_focus.TabGroup::new(0),
    [0, 0, 0, 0],
  )
  spawn_tab_group(
    commands,
    root,
    font,
    "TabGroup 2",
    @input_focus.TabGroup::new(2),
    [3, 2, 1, 0],
  )
  spawn_tab_group(
    commands,
    root,
    font,
    "TabGroup 1",
    @input_focus.TabGroup::new(1),
    [0, 1, 2, 3],
  )
  spawn_tab_group(
    commands,
    root,
    font,
    "Modal TabGroup",
    @input_focus.TabGroup::modal(),
    [0, 3, 1, 2],
  )
}

///|
fn button_system(world : @ecs.World) -> Unit {
  let query : @ecs.Query[
    (
      @ecs.Comp[@ui.Interaction],
      @ecs.Mut[@ui.BackgroundColor],
      @ecs.Mut[@ui.BorderColor],
    ),
    @ecs.With[@ui.Button],
  ] = @ecs.query_filtered(world, @ecs.With::new(@ui.Button::component()))
  try! query.view(fn(_entity, data) {
    let (interaction, background, border) = data
    let next_background = match interaction.value() {
      @ui.Interaction::Pressed => pressed_button_color()
      @ui.Interaction::Hovered => hovered_button_color()
      @ui.Interaction::None => normal_button_color()
    }
    let next_border = match interaction.value() {
      @ui.Interaction::Pressed => @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
      @ui.Interaction::Hovered => @sprite.Color::white()
      @ui.Interaction::None => @sprite.Color::black()
    }
    background.set(@ui.BackgroundColor::new(next_background))
    border.set(@ui.BorderColor::new(next_border))
  })
}

///|
fn focus_system(world : @ecs.World) -> Unit {
  let focused = match
    (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus.get()
    None => None
  }
  let buttons : @ecs.Query[@core.Entity, @ecs.With[@ui.Button]] = @ecs.query_filtered(
    world,
    @ecs.With::new(@ui.Button::component()),
  )
  try! buttons.view(fn(_query_entity, entity) {
    let entity_mut : @ecs.EntityMut? = try world.entity_mut(entity) catch {
      _ => None
    } noraise {
      value => Some(value)
    }
    guard entity_mut is Some(entity_mut) else { return }
    if focused == Some(entity) {
      ignore(
        try entity_mut.insert_component(focus_outline()) catch {
          _ => None
        } noraise {
          value => Some(value)
        },
      )
    } else {
      let removed : @ui.Outline? = try entity_mut.remove_component() catch {
        _ => None
      } noraise {
        value => value
      }
      ignore(removed)
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugins([
    @input_focus.input_dispatch_plugin, @input_focus.tab_navigation_plugin,
  ])
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(button_system))
  .add_systems(@app.Update, @app.system(focus_system))
  .run()
}
