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
/// Port of `bevy/examples/animation/easing_functions.rs`.

///|
const COLS : Int = 12

///|
const EXTENT_X : Float = 1172.0F

///|
const EXTENT_Y : Float = 520.0F

///|
const PLOT_SIZE_X : Float = 80.0F

///|
const PLOT_SIZE_Y : Float = 80.0F

///|
const SAMPLE_COUNT : Int = 100

///|
const DURATION_SECONDS : Float = 2.5F

///|
const TIME_MARGIN_SECONDS : Float = 0.5F

///|
const PLOT_Z : Float = 0.0F

///|
const MARKER_Z : Float = 1.0F

///|
const LABEL_Z : Float = 2.0F

///|
priv struct EaseSpec {
  function : @math.EaseFunction
  label : String
}

///|
priv struct EaseFunctionPlot {
  function : @math.EaseFunction
  color : @sprite.Color
  value_bar_entity : @core.Entity
  progress_dot_entity : @core.Entity
}

///|
let ease_function_plot_key : @ecs.ComponentKey[EaseFunctionPlot] = @ecs.register_component(
  debug_name="examples.animation.easing_functions.EaseFunctionPlot",
)

///|
let progress_text_entity : Ref[@core.Entity?] = Ref::new(None)

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(display_curves))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  progress_text_entity.val = None

  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @transform.Transform::identity()).spawn(
    world,
  )
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let label_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(10.0F)

  spawn_progress_overlay(world, font)

  let rows = easing_rows()
  let max_rows = rows.length()
  let half_extent_x = EXTENT_X / 2.0F
  let half_extent_y = EXTENT_Y / 2.0F
  let half_size_x = PLOT_SIZE_X / 2.0F
  let half_size_y = PLOT_SIZE_Y / 2.0F
  let parent_store = world.component(@hierarchy.ecs_key_parent)
  let plot_store = world.component(ease_function_plot_key)
  let transform_store = world.component(@transform.ecs_key_transform)

  for row in 0..<rows.length() {
    let functions = rows[row]
    for col in 0..<functions.length() {
      let spec = functions[col]
      let color = @sprite.Color::hsl(
        float_from_int(col) / float_from_int(COLS) * 360.0F,
        0.8F,
        0.75F,
      )
      let center = @math.Vec2::new(
        -half_extent_x +
        EXTENT_X / float_from_int(COLS - 1) * float_from_int(col),
        half_extent_y -
        EXTENT_Y / float_from_int(max_rows - 1) * float_from_int(row),
      )

      let plot_entity = world.spawn_empty()
      let value_bar_entity = spawn_marker(
        world,
        5.0F,
        color,
        @math.Vec2::new(half_size_x + 5.0F, -half_size_y),
      )
      let progress_dot_entity = spawn_marker(
        world,
        4.0F,
        color,
        @math.Vec2::new(-half_size_x, -half_size_y),
      )
      parent_store.insert(value_bar_entity, @hierarchy.Parent::new(plot_entity))
      parent_store.insert(
        progress_dot_entity,
        @hierarchy.Parent::new(plot_entity),
      )
      plot_store.insert(plot_entity, EaseFunctionPlot::{
        function: spec.function,
        color,
        value_bar_entity,
        progress_dot_entity,
      })
      transform_store.insert(
        plot_entity,
        transform_from_position(center, PLOT_Z),
      )

      spawn_label(
        spec.label,
        label_font,
        color,
        @math.Vec2::new(center.x, center.y - half_size_y - 15.0F),
      )
    }
  }
}

///|
fn display_curves(world : @ecs.World) -> Unit {
  let plot_store = world.component(ease_function_plot_key)
  let cycle_seconds = DURATION_SECONDS + TIME_MARGIN_SECONDS * 2.0F
  let elapsed = default_time_or_default(world).elapsed_seconds()
  let loops = (elapsed / cycle_seconds).to_int()
  let loop_offset = float_from_int(loops) * cycle_seconds
  let cycle_elapsed = elapsed - loop_offset
  let now = clamp01((cycle_elapsed - TIME_MARGIN_SECONDS) / DURATION_SECONDS)

  if progress_text_entity.val is Some(text_entity) {
    let text_store = world.component(@text.ecs_key_text)
    if text_store.get(text_entity) is Some(text_value) {
      text_value.content = format_progress(now)
      ignore(text_store.set(text_entity, text_value))
    }
  }

  let gizmos = @sprite.Gizmos::get()
  let transform_store = world.component(@transform.ecs_key_transform)
  world.advance_sequence() |> ignore
  let half_size_x = PLOT_SIZE_X / 2.0F
  let half_size_y = PLOT_SIZE_Y / 2.0F

  plot_store.for_each(fn(entity, plot) {
    guard transform_store.get(entity) is Some(transform) else { return }
    let center = @math.Vec2::new(
      transform.translation.x,
      transform.translation.y,
    )

    let top_right = @math.Vec2::new(
      center.x + half_size_x,
      center.y + half_size_y,
    )
    let top_left = @math.Vec2::new(
      center.x - half_size_x,
      center.y + half_size_y,
    )
    let bottom_left = @math.Vec2::new(
      center.x - half_size_x,
      center.y - half_size_y,
    )
    let bottom_right = @math.Vec2::new(
      center.x + half_size_x,
      center.y - half_size_y,
    )

    gizmos.linestrip_2d(
      [top_right, top_left, bottom_left, bottom_right, top_right],
      plot.color.darker(0.4F),
    )

    let curve = @math.EasingCurve::new(0.0F, 1.0F, plot.function)
    let curve_points : Array[@math.Vec2] = []
    for i in 0..<SAMPLE_COUNT {
      let x = if SAMPLE_COUNT <= 1 {
        0.0F
      } else {
        float_from_int(i) / float_from_int(SAMPLE_COUNT - 1)
      }
      let y = curve.sample_clamped(x)
      curve_points.push(
        @math.Vec2::new(
          center.x - half_size_x + x * PLOT_SIZE_X,
          center.y - half_size_y + y * PLOT_SIZE_Y,
        ),
      )
    }
    gizmos.curve_2d(curve_points, plot.color)

    let y_progress = curve.sample_clamped(now) * PLOT_SIZE_Y
    try! world.set(
      plot.value_bar_entity,
      @transform.ecs_key_transform,
      transform_from_position(
        @math.Vec2::new(half_size_x + 5.0F, -half_size_y + y_progress),
        MARKER_Z,
      ),
    )
    try! world.set(
      plot.progress_dot_entity,
      @transform.ecs_key_transform,
      transform_from_position(
        @math.Vec2::new(
          -half_size_x + now * PLOT_SIZE_X,
          -half_size_y + y_progress,
        ),
        MARKER_Z,
      ),
    )

    gizmos.linestrip_2d(
      [
        @math.Vec2::new(
          center.x - half_size_x,
          center.y - half_size_y + y_progress,
        ),
        @math.Vec2::new(
          center.x + half_size_x,
          center.y - half_size_y + y_progress,
        ),
      ],
      plot.color.darker(0.2F),
    )
  })
}

///|
fn spawn_progress_overlay(
  world : @ecs.World,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default())
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root))
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  world
  .component(@text.ecs_key_text)
  .insert(text_entity, @text.Text::new("Progress: 0.00"))
  world
  .component(@text.ecs_key_text_font)
  .insert(
    text_entity,
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
  )
  world
  .component(@text.ecs_key_text_color)
  .insert(text_entity, @text.TextColor::new(@sprite.Color::white()))
  world
  .component(@text.ecs_key_text_layout)
  .insert(text_entity, @text.TextLayout::new_with_justify(@text.Justify::Left))
  progress_text_entity.val = Some(text_entity)
}

///|
fn easing_rows() -> Array[Array[EaseSpec]] {
  [
    [
      ease_spec(@math.EaseFunction::SineIn, "SineIn"),
      ease_spec(@math.EaseFunction::QuadraticIn, "QuadraticIn"),
      ease_spec(@math.EaseFunction::CubicIn, "CubicIn"),
      ease_spec(@math.EaseFunction::QuarticIn, "QuarticIn"),
      ease_spec(@math.EaseFunction::QuinticIn, "QuinticIn"),
      ease_spec(@math.EaseFunction::SmoothStepIn, "SmoothStepIn"),
      ease_spec(@math.EaseFunction::SmootherStepIn, "SmootherStepIn"),
      ease_spec(@math.EaseFunction::CircularIn, "CircularIn"),
      ease_spec(@math.EaseFunction::ExponentialIn, "ExponentialIn"),
      ease_spec(@math.EaseFunction::ElasticIn, "ElasticIn"),
      ease_spec(@math.EaseFunction::BackIn, "BackIn"),
      ease_spec(@math.EaseFunction::BounceIn, "BounceIn"),
    ],
    [
      ease_spec(@math.EaseFunction::SineOut, "SineOut"),
      ease_spec(@math.EaseFunction::QuadraticOut, "QuadraticOut"),
      ease_spec(@math.EaseFunction::CubicOut, "CubicOut"),
      ease_spec(@math.EaseFunction::QuarticOut, "QuarticOut"),
      ease_spec(@math.EaseFunction::QuinticOut, "QuinticOut"),
      ease_spec(@math.EaseFunction::SmoothStepOut, "SmoothStepOut"),
      ease_spec(@math.EaseFunction::SmootherStepOut, "SmootherStepOut"),
      ease_spec(@math.EaseFunction::CircularOut, "CircularOut"),
      ease_spec(@math.EaseFunction::ExponentialOut, "ExponentialOut"),
      ease_spec(@math.EaseFunction::ElasticOut, "ElasticOut"),
      ease_spec(@math.EaseFunction::BackOut, "BackOut"),
      ease_spec(@math.EaseFunction::BounceOut, "BounceOut"),
    ],
    [
      ease_spec(@math.EaseFunction::SineInOut, "SineInOut"),
      ease_spec(@math.EaseFunction::QuadraticInOut, "QuadraticInOut"),
      ease_spec(@math.EaseFunction::CubicInOut, "CubicInOut"),
      ease_spec(@math.EaseFunction::QuarticInOut, "QuarticInOut"),
      ease_spec(@math.EaseFunction::QuinticInOut, "QuinticInOut"),
      ease_spec(@math.EaseFunction::SmoothStep, "SmoothStep"),
      ease_spec(@math.EaseFunction::SmootherStep, "SmootherStep"),
      ease_spec(@math.EaseFunction::CircularInOut, "CircularInOut"),
      ease_spec(@math.EaseFunction::ExponentialInOut, "ExponentialInOut"),
      ease_spec(@math.EaseFunction::ElasticInOut, "ElasticInOut"),
      ease_spec(@math.EaseFunction::BackInOut, "BackInOut"),
      ease_spec(@math.EaseFunction::BounceInOut, "BounceInOut"),
    ],
    [
      ease_spec(@math.EaseFunction::Linear, "Linear"),
      ease_spec(
        @math.EaseFunction::Steps(4, @math.JumpAt::End),
        "Steps(4, End)",
      ),
      ease_spec(
        @math.EaseFunction::Steps(4, @math.JumpAt::Start),
        "Steps(4, Start)",
      ),
      ease_spec(
        @math.EaseFunction::Steps(4, @math.JumpAt::Both),
        "Steps(4, Both)",
      ),
      ease_spec(
        @math.EaseFunction::Steps(4, @math.JumpAt::None),
        "Steps(4, None)",
      ),
      ease_spec(@math.EaseFunction::Elastic(50.0F), "Elastic(50.0)"),
    ],
  ]
}

///|
fn ease_spec(function : @math.EaseFunction, label : String) -> EaseSpec {
  EaseSpec::{ function, label }
}

///|
fn spawn_marker(
  world : @ecs.World,
  size : Float,
  color : @sprite.Color,
  position : @math.Vec2,
) -> @core.Entity {
  @sprite.Mesh2dBundle::new_with_mesh_material(
    @sprite.Mesh2d::new(
      @sprite.mesh_assets_mut_or_abort().val.add(
        @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::new(size, size)).to_mesh(),
      ),
    ),
    @sprite.MeshMaterial2d::new(
      @sprite.color_material_assets_mut_or_abort().val.add(
        @sprite.ColorMaterialAsset::from_color(color),
      ),
    ),
    transform_from_position(position, MARKER_Z),
  ).spawn(world)
}

///|
fn spawn_label(
  label : String,
  font : @text.TextFont,
  color : @sprite.Color,
  position : @math.Vec2,
) -> Unit {
  @text.Text2dBundle::new(
    @text.Text2d::new(label),
    font,
    transform_from_position(position, LABEL_Z),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .spawn()
  |> ignore
}

///|
fn default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in easing_functions example")
  }
}

///|
fn format_progress(now : Float) -> String {
  let scaled = (clamp01(now) * 100.0F + 0.5F).to_int()
  let whole = scaled / 100
  let fraction = scaled % 100
  let fraction_text = if fraction < 10 {
    "0" + fraction.to_string()
  } else {
    fraction.to_string()
  }
  "Progress: " + whole.to_string() + "." + fraction_text
}

///|
fn transform_from_position(
  position : @math.Vec2,
  z : Float,
) -> @transform.Transform {
  @transform.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
    z~,
  )
}

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}
