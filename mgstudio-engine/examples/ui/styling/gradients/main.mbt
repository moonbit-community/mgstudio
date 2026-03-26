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
struct GradientStop {
  t : Float
}

///|
let gradient_stop_key : @ecs.ComponentKey[GradientStop] = @ecs.register_component(
  debug_name="examples.ui.styling.gradients.GradientStop",
)

///|
pub impl @ecs.Component for GradientStop with component() {
  gradient_stop_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(10.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(20.0F))),
      @ui.BackgroundColor::new(@sprite.Color::black()),
    ),
  )

  for band in 0..<3 {
    let row = commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_height(@ui.Val::Px(90.0F))
        .with_display(@ui.Display::Flex)
        .with_flex_direction(@ui.FlexDirection::Row),
      ),
    )
    for i in 0..<24 {
      let t = Float::from_int(i) / 23.0F
      commands.spawn(
        (
          @hierarchy.Parent::new(row),
          GradientStop::{ t, },
          @ui.Node::default()
          .with_width(@ui.Val::Percent(100.0F / 24.0F))
          .with_height(@ui.Val::Percent(100.0F)),
          @ui.BackgroundColor::new(
            match band {
              0 => @sprite.Color::srgb(1.0F - t * 0.8F, 0.15F + t * 0.8F, 0.2F)
              1 =>
                @sprite.Color::srgb(
                  0.1F + t * 0.5F,
                  0.2F + t * 0.2F,
                  1.0F - t * 0.6F,
                )
              _ =>
                @sprite.Color::srgb(
                  0.25F + t * 0.6F,
                  0.1F + t * 0.7F,
                  0.6F + t * 0.2F,
                )
            },
          ),
        ),
      )
      |> ignore
    }
  }
}

///|
fn animate_gradients(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Comp[GradientStop], @ecs.Mut[@ui.BackgroundColor]),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, data) {
    let (stop, color) = data
    let t = stop.value().t
    let pulse = 0.5F + 0.5F * @math.sin(elapsed * 0.8F + t * 5.0F)
    color.set(
      @ui.BackgroundColor::new(
        @sprite.Color::srgb(
          0.1F + t * 0.7F,
          0.2F + pulse * 0.5F,
          0.9F - t * 0.6F,
        ),
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_gradients)))
  .run()
}
