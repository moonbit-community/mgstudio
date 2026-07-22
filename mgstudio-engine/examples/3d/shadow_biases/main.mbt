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
const SPAWN_PLANE_DEPTH : Float = 300.0F

///|
const SPAWN_HEIGHT : Float = 2.0F

///|
const SPHERE_RADIUS : Float = 0.25F

///|
const POINT_LIGHT_INTENSITY : Float = 1_000_000.0F

///|
const DIRECTIONAL_LIGHT_ILLUMINANCE : Float = 10_000.0F

///|
struct Lights {}

///|
let lights_component_key : @ecs.ComponentKey[Lights] = @ecs.register_component(
  debug_name="examples.3d.shadow_biases.Lights",
)

///|
pub impl @ecs.Component for Lights with fn component() {
  lights_component_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn format_fixed(value : Float, decimals : Int) -> String {
  let factor = if decimals == 2 { 100 } else { 10 }
  let scaled = (value * Float::from_double(factor.to_double())).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / factor
  let frac = abs_scaled % factor
  let frac_text = if decimals == 2 && frac < 10 {
    "0\{frac.to_string()}"
  } else {
    frac.to_string()
  }
  "\{sign}\{whole.to_string()}.\{frac_text}"
}

///|
fn filter_method_name(filter_method : @pbr.ShadowFilteringMethod) -> String {
  match filter_method {
    Hardware2x2 => "Hardware2x2"
    Gaussian => "Gaussian"
    Temporal => "Temporal"
  }
}

///|
fn spawn_text_span(
  commands : @app.Commands,
  parent : @core.Entity,
  content : String,
) -> @core.Entity {
  commands.spawn((@hierarchy.Parent::new(parent), @text.TextSpan::new(content)))
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let white_handle = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::StandardMaterial()
      .with_base_color(@color.Color::white())
      .with_perceptual_roughness(1.0F),
    )
  })
  let sphere_handle = @mesh.Mesh3d::new(
    meshes.modify(fn(assets) {
      assets |> @pbr.add_mesh(@math.Sphere::new(SPHERE_RADIUS))
    }),
  )

  let light_transform = @transform.Transform::from_xyz(5.0F, 5.0F, 0.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let lights = commands.spawn(
    (light_transform, @visibility.Visibility::Inherited, Lights::{  }),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(lights),
        @pbr.PointLight::new(
          @color.Color::white(),
          0.0F,
          SPAWN_PLANE_DEPTH,
          true,
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(lights),
        @pbr.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-1.0F, 1.0F, 1.0F).looking_at(
          @math.Vec3::new(-1.0F, 1.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.FreeCamera::FreeCamera(),
        @pbr.ShadowFilteringMethod::Hardware2x2,
      ),
    ),
  )

  for z_i32 in -300..<=0 {
    if z_i32 % 2 == 0 {
      ignore(
        commands.spawn(
          (
            sphere_handle,
            @pbr.MeshMaterial3dTyped::new(white_handle),
            @transform.Transform::from_xyz(
              0.0F,
              if z_i32 % 4 == 0 {
                SPAWN_HEIGHT
              } else {
                SPHERE_RADIUS
              },
              float_from_int(z_i32),
            ),
          ),
        ),
      )
    }
  }

  let plane_size = 2.0F * SPAWN_PLANE_DEPTH
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.modify(fn(assets) {
            assets
            |> @pbr.add_mesh(
              @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
                @math.Vec2::new(plane_size, plane_size),
              ).build(),
            )
          }),
        ),
        @pbr.MeshMaterial3dTyped::new(white_handle),
      ),
    ),
  )

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let panel = commands.spawn(
    (
      @ui.Node::Node()
      .with_position_type(Absolute)
      .with_padding(@ui.UiRect::all(@ui.px(5.0F))),
      @ui.BackgroundColor::new(@color.Color::black().with_alpha(0.75F)),
      @ui.GlobalZIndex::new(2_147_483_647),
    ),
  )
  let text = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      @ui.Node::Node(),
      @text.Text::Text(),
      @text.TextFont::TextFont().with_font(font).with_font_size(15.0F),
      @text.TextColor::new(@color.Color::white()),
      @text.TextLayout::new_with_justify(Left),
    ),
  )
  ignore(spawn_text_span(commands, text, "Controls:\n"))
  ignore(
    spawn_text_span(commands, text, "R / Z - reset biases to default / zero\n"),
  )
  ignore(
    spawn_text_span(
      commands, text, "L     - switch between directional and point lights [",
    ),
  )
  ignore(spawn_text_span(commands, text, "DirectionalLight"))
  ignore(spawn_text_span(commands, text, "]\n"))
  ignore(
    spawn_text_span(
      commands, text, "F     - switch directional light filter methods [",
    ),
  )
  ignore(spawn_text_span(commands, text, "Hardware2x2"))
  ignore(spawn_text_span(commands, text, "]\n"))
  ignore(
    spawn_text_span(commands, text, "1/2   - change point light depth bias ["),
  )
  ignore(spawn_text_span(commands, text, "0.00"))
  ignore(spawn_text_span(commands, text, "]\n"))
  ignore(
    spawn_text_span(commands, text, "3/4   - change point light normal bias ["),
  )
  ignore(spawn_text_span(commands, text, "0.0"))
  ignore(spawn_text_span(commands, text, "]\n"))
  ignore(
    spawn_text_span(
      commands, text, "5/6   - change direction light depth bias [",
    ),
  )
  ignore(spawn_text_span(commands, text, "0.00"))
  ignore(spawn_text_span(commands, text, "]\n"))
  ignore(
    spawn_text_span(
      commands, text, "7/8   - change direction light normal bias [",
    ),
  )
  ignore(spawn_text_span(commands, text, "0.0"))
  ignore(spawn_text_span(commands, text, "]\n"))
  ignore(
    spawn_text_span(
      commands, text, "left/right/up/down/pgup/pgdown - adjust light position (looking at 0,0,0) [",
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      text,
      "\{format_fixed(light_transform.translation.x, 1)},",
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      text,
      " \{format_fixed(light_transform.translation.y, 1)},",
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      text,
      " \{format_fixed(light_transform.translation.z, 1)}",
    ),
  )
  ignore(spawn_text_span(commands, text, "]\n"))
}

///|
fn toggle_light(
  input : @input.ButtonInput[@window.KeyCode],
  point_lights : @ecs.Query[@ecs.Write[@pbr.PointLight], @ecs.All],
  directional_lights : @ecs.Query[@ecs.Write[@pbr.DirectionalLight], @ecs.All],
  example_text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  if input.just_pressed(KeyL) {
    let text = example_text.get()
    try! point_lights.for_each(fn(_entity, light) {
      let current = light.value()
      let intensity = if current.intensity == 0.0F {
        ignore(writer.set_text(text, 4, "PointLight"))
        POINT_LIGHT_INTENSITY
      } else {
        0.0F
      }
      light.set(current.with_intensity(intensity))
    })
    try! directional_lights.for_each(fn(_entity, light) {
      let current = light.value()
      let illuminance = if current.illuminance == 0.0F {
        ignore(writer.set_text(text, 4, "DirectionalLight"))
        DIRECTIONAL_LIGHT_ILLUMINANCE
      } else {
        0.0F
      }
      light.set(current.with_illuminance(illuminance))
    })
  }
}

///|
fn adjust_light_position(
  input : @input.ButtonInput[@window.KeyCode],
  lights : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Lights]],
  example_text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  let mut offset = @math.Vec3::zero()
  if input.just_pressed(ArrowLeft) {
    offset = offset.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
  }
  if input.just_pressed(ArrowRight) {
    offset = offset.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  }
  if input.just_pressed(ArrowUp) {
    offset = offset.add(@math.Vec3::new(0.0F, 0.0F, -1.0F))
  }
  if input.just_pressed(ArrowDown) {
    offset = offset.add(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  }
  if input.just_pressed(PageDown) {
    offset = offset.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  }
  if input.just_pressed(PageUp) {
    offset = offset.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if offset.length_squared() > 0.0F {
    let text = example_text.get()
    try! lights.for_each(fn(_entity, light) {
      light.modify(fn(value) {
        value.translation = value.translation.add(offset)
        let next = value.looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        )
        value.rotation = next.rotation
      })
      let current = light.value()
      ignore(
        writer.set_text(text, 22, "\{format_fixed(current.translation.x, 1)},"),
      )
      ignore(
        writer.set_text(text, 23, " \{format_fixed(current.translation.y, 1)},"),
      )
      ignore(
        writer.set_text(text, 24, " \{format_fixed(current.translation.z, 1)}"),
      )
    })
  }
}

///|
fn cycle_filter_methods(
  input : @input.ButtonInput[@window.KeyCode],
  filter_methods : @ecs.Query[@ecs.Write[@pbr.ShadowFilteringMethod], @ecs.All],
  example_text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  if input.just_pressed(KeyF) {
    let text = example_text.get()
    try! filter_methods.for_each(fn(_entity, filter_method) {
      let next = match filter_method.value() {
        Hardware2x2 => @pbr.ShadowFilteringMethod::Gaussian
        Gaussian => Temporal
        Temporal => Hardware2x2
      }
      filter_method.set(next)
      ignore(writer.set_text(text, 7, filter_method_name(next)))
    })
  }
}

///|
fn adjust_point_light_biases(
  input : @input.ButtonInput[@window.KeyCode],
  query : @ecs.Query[@ecs.Write[@pbr.PointLight], @ecs.All],
  example_text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  let depth_bias_step_size = 0.01F
  let normal_bias_step_size = 0.1F
  let text = example_text.get()
  try! query.for_each(fn(_entity, light) {
    let mut next = light.value()
    if input.just_pressed(Digit1) {
      next = next.with_shadow_depth_bias(
        next.shadow_depth_bias - depth_bias_step_size,
      )
    }
    if input.just_pressed(Digit2) {
      next = next.with_shadow_depth_bias(
        next.shadow_depth_bias + depth_bias_step_size,
      )
    }
    if input.just_pressed(Digit3) {
      next = next.with_shadow_normal_bias(
        next.shadow_normal_bias - normal_bias_step_size,
      )
    }
    if input.just_pressed(Digit4) {
      next = next.with_shadow_normal_bias(
        next.shadow_normal_bias + normal_bias_step_size,
      )
    }
    if input.just_pressed(KeyR) {
      let defaults = @pbr.PointLight::PointLight()
      next = next
        .with_shadow_depth_bias(defaults.shadow_depth_bias)
        .with_shadow_normal_bias(defaults.shadow_normal_bias)
    }
    if input.just_pressed(KeyZ) {
      next = next.with_shadow_depth_bias(0.0F).with_shadow_normal_bias(0.0F)
    }

    light.set(next)
    ignore(writer.set_text(text, 10, format_fixed(next.shadow_depth_bias, 2)))
    ignore(writer.set_text(text, 13, format_fixed(next.shadow_normal_bias, 1)))
  })
}

///|
fn adjust_directional_light_biases(
  input : @input.ButtonInput[@window.KeyCode],
  query : @ecs.Query[@ecs.Write[@pbr.DirectionalLight], @ecs.All],
  example_text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  let depth_bias_step_size = 0.01F
  let normal_bias_step_size = 0.1F
  let text = example_text.get()
  try! query.for_each(fn(_entity, light) {
    let mut next = light.value()
    if input.just_pressed(Digit5) {
      next = next.with_shadow_depth_bias(
        next.shadow_depth_bias - depth_bias_step_size,
      )
    }
    if input.just_pressed(Digit6) {
      next = next.with_shadow_depth_bias(
        next.shadow_depth_bias + depth_bias_step_size,
      )
    }
    if input.just_pressed(Digit7) {
      next = next.with_shadow_normal_bias(
        next.shadow_normal_bias - normal_bias_step_size,
      )
    }
    if input.just_pressed(Digit8) {
      next = next.with_shadow_normal_bias(
        next.shadow_normal_bias + normal_bias_step_size,
      )
    }
    if input.just_pressed(KeyR) {
      let defaults = @pbr.DirectionalLight::DirectionalLight()
      next = next
        .with_shadow_depth_bias(defaults.shadow_depth_bias)
        .with_shadow_normal_bias(defaults.shadow_normal_bias)
    }
    if input.just_pressed(KeyZ) {
      next = next.with_shadow_depth_bias(0.0F).with_shadow_normal_bias(0.0F)
    }

    light.set(next)
    ignore(writer.set_text(text, 16, format_fixed(next.shadow_depth_bias, 2)))
    ignore(writer.set_text(text, 19, format_fixed(next.shadow_normal_bias, 1)))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@pbr.FreeCameraPlugin::FreeCameraPlugin())
  .add_systems_param4(Startup, setup)
  .add_systems_param4(Update, cycle_filter_methods)
  .add_systems_param4(Update, adjust_light_position)
  .add_systems_param4(Update, adjust_point_light_biases)
  .add_systems_param5(Update, toggle_light)
  .add_systems_param4(Update, adjust_directional_light_biases)
  .run()
}
