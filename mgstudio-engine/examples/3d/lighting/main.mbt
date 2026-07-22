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
const PI : Float = 3.141592653589793F

///|
const MOVE_SPEED : Float = 2.0F

///|
const OVERCAST_DAY : Float = 10_000.0F

///|
priv struct Parameters {
  mut physical_camera_parameters : @camera_camera.PhysicalCameraParameters
}

///|
let parameters_resource_key : @ecs.ResourceKey[Parameters] = @ecs.register_resource(
  debug_name="examples.3d.lighting.Parameters",
)

///|
impl @app.Resource for Parameters with fn resource() {
  parameters_resource_key
}

///|
fn Parameters::Parameters() -> Parameters {
  { physical_camera_parameters: PhysicalCameraParameters() }
}

///|
priv struct Movable {}

///|
let movable_component_key : @ecs.ComponentKey[Movable] = @ecs.register_component(
  debug_name="examples.3d.lighting.Movable",
)

///|
impl @ecs.Component for Movable with fn component() {
  movable_component_key
}

///|
fn round_to_int(value : Float) -> Int {
  if value >= 0.0F {
    (value + 0.5F).to_int()
  } else {
    (value - 0.5F).to_int()
  }
}

///|
fn shutter_denominator(
  parameters : @camera_camera.PhysicalCameraParameters,
) -> Int {
  if parameters.shutter_speed_s <= 0.0F {
    0
  } else {
    round_to_int(1.0F / parameters.shutter_speed_s)
  }
}

///|
fn add_mesh(
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(
    meshes.modify(fn(assets) { assets |> @pbr.add_mesh(geometry) }),
  )
}

///|
fn add_material(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  material : @pbr.StandardMaterial,
) -> @pbr.MeshMaterial3dTyped[@pbr.StandardMaterial] {
  @pbr.MeshMaterial3dTyped::new(
    materials.modify(fn(assets) { assets.add(material) }),
  )
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
  parameters : @app.Res[Parameters],
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let physical_camera_parameters = parameters.get().physical_camera_parameters

  // ground plane
  ignore(
    commands.spawn(
      (
        add_mesh(
          meshes,
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(10.0F, 10.0F),
          ).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial()
          .with_base_color(@color.Color::white())
          .with_perceptual_roughness(1.0F),
        ),
      ),
    ),
  )

  // left wall
  ignore(
    commands.spawn(
      (
        add_mesh(
          meshes,
          @mesh_primitives_dim3.CuboidMeshBuilder::new(5.0F, 0.15F, 5.0F).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial()
          .with_base_color(@color.Color::new(0.294F, 0.0F, 0.51F, 1.0F))
          .with_perceptual_roughness(1.0F),
        ),
        @transform.Transform::from_xyz(2.5F, 2.5F, 0.0F).with_rotation(
          @math.Quat::from_rotation_z(PI / 2.0F),
        ),
      ),
    ),
  )

  // back (right) wall
  ignore(
    commands.spawn(
      (
        add_mesh(
          meshes,
          @mesh_primitives_dim3.CuboidMeshBuilder::new(5.0F, 0.15F, 5.0F).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial()
          .with_base_color(@color.Color::new(0.294F, 0.0F, 0.51F, 1.0F))
          .with_perceptual_roughness(1.0F),
        ),
        @transform.Transform::from_xyz(0.0F, 2.5F, -2.5F).with_rotation(
          @math.Quat::from_rotation_x(PI / 2.0F),
        ),
      ),
    ),
  )

  // logo alpha-mask quad
  ignore(
    commands.spawn(
      (
        add_mesh(
          meshes,
          @mesh_primitives.RectangleMeshBuilder::new(2.0F, 0.5F).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial()
          .with_base_color_texture(
            Some(asset_server.get().load("branding/bevy_logo_light.png")),
          )
          .with_perceptual_roughness(1.0F)
          .with_alpha_mode(Mask(0.5F))
          .with_cull_mode(None),
        ),
        @transform.Transform::from_xyz(-2.2F, 0.5F, 1.0F).with_rotation(
          @math.Quat::from_rotation_y(PI / 8.0F),
        ),
        Movable::{  },
      ),
    ),
  )

  // cube
  ignore(
    commands.spawn(
      (
        add_mesh(
          meshes,
          @mesh_primitives_dim3.CuboidMeshBuilder::CuboidMeshBuilder().build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial().with_base_color(
            @color.Color::new(1.0F, 0.078F, 0.576F, 1.0F),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
        Movable::{  },
      ),
    ),
  )

  // sphere
  ignore(
    commands.spawn(
      (
        add_mesh(
          meshes,
          @mesh_primitives_dim3.SphereMeshBuilder::new(
            0.5F,
            @mesh_primitives_dim3.SphereKind::uv(32, 18),
          ).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial().with_base_color(
            @color.Color::new(0.196F, 0.804F, 0.196F, 1.0F),
          ),
        ),
        @transform.Transform::from_xyz(1.5F, 1.0F, 1.5F),
        Movable::{  },
      ),
    ),
  )

  // ambient light
  commands.insert_resource(
    @pbr.GlobalAmbientLight::new(
      @color.Color::new(1.0F, 0.27F, 0.0F, 1.0F),
      200.0F,
    ),
  )

  // red point light
  let red_light = commands.spawn(
    (
      @pbr.PointLight::PointLight()
      .with_intensity(100_000.0F)
      .with_color(@color.Color::new(1.0F, 0.0F, 0.0F, 1.0F))
      .with_shadow_maps_enabled(true),
      @transform.Transform::from_xyz(1.0F, 2.0F, 0.0F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(red_light),
        add_mesh(
          meshes,
          @mesh_primitives_dim3.SphereMeshBuilder::new(
            0.1F,
            @mesh_primitives_dim3.SphereKind::uv(32, 18),
          ).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial()
          .with_base_color(@color.Color::new(1.0F, 0.0F, 0.0F, 1.0F))
          .with_emissive(@color.Color::new(4.0F, 0.0F, 0.0F, 0.0F)),
        ),
      ),
    ),
  )

  // green spot light
  let green_light = commands.spawn(
    (
      @pbr.SpotLight::new(
        @color.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
        100_000.0F,
        20.0F,
        0.6F,
        0.8F,
        true,
      ),
      @transform.Transform::from_xyz(-1.0F, 2.0F, 0.0F).looking_at(
        @math.Vec3::new(-1.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, 1.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(green_light),
        add_mesh(
          meshes,
          @mesh_primitives_dim3.Capsule3dMeshBuilder::from_capsule(
            @math.Capsule3d::new(0.1F, 0.125F),
          ).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial()
          .with_base_color(@color.Color::new(0.0F, 1.0F, 0.0F, 1.0F))
          .with_emissive(@color.Color::new(0.0F, 4.0F, 0.0F, 0.0F)),
        ),
        @transform.Transform::from_rotation(
          @math.Quat::from_rotation_x(PI / 2.0F),
        ),
      ),
    ),
  )

  // blue point light
  let blue_light = commands.spawn(
    (
      @pbr.PointLight::PointLight()
      .with_intensity(100_000.0F)
      .with_color(@color.Color::new(0.0F, 0.0F, 1.0F, 1.0F))
      .with_shadow_maps_enabled(true),
      @transform.Transform::from_xyz(0.0F, 4.0F, 0.0F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(blue_light),
        add_mesh(
          meshes,
          @mesh_primitives_dim3.SphereMeshBuilder::new(
            0.1F,
            @mesh_primitives_dim3.SphereKind::uv(32, 18),
          ).build(),
        ),
        add_material(
          materials,
          @pbr.StandardMaterial::StandardMaterial()
          .with_base_color(@color.Color::new(0.0F, 0.0F, 1.0F, 1.0F))
          .with_emissive(@color.Color::new(0.0F, 0.0F, 713.0F, 0.0F)),
        ),
      ),
    ),
  )

  // directional sun light
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::DirectionalLight()
        .with_illuminance(OVERCAST_DAY)
        .with_shadow_maps_enabled(true),
        @pbr.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
        .with_first_cascade_far_bound(4.0F)
        .with_maximum_distance(10.0F)
        .build(),
        @transform.Transform::from_xyz(0.0F, 2.0F, 0.0F).with_rotation(
          @math.Quat::from_rotation_x(-PI / 4.0F),
        ),
      ),
    ),
  )

  let text = commands.spawn(
    (
      @text.Text::Text(),
      @text.TextFont::TextFont(),
      @text.TextColor::TextColor(),
      @text.TextLayout::TextLayout(),
      @ui.Node::Node()
      .with_position_type(Absolute)
      .with_top(@ui.px(12.0F))
      .with_left(@ui.px(12.0F)),
    ),
  )
  ignore(spawn_text_span(commands, text, "Ambient light is on\n"))
  ignore(
    spawn_text_span(
      commands,
      text,
      "Aperture: f/\{round_to_int(physical_camera_parameters.aperture_f_stops)}\n",
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      text,
      "Shutter speed: 1/\{shutter_denominator(physical_camera_parameters)}s\n",
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      text,
      "Sensitivity: ISO \{round_to_int(physical_camera_parameters.sensitivity_iso)}\n",
    ),
  )
  ignore(spawn_text_span(commands, text, "\n\n"))
  ignore(spawn_text_span(commands, text, "Controls\n"))
  ignore(spawn_text_span(commands, text, "---------------\n"))
  ignore(spawn_text_span(commands, text, "Arrow keys - Move objects\n"))
  ignore(spawn_text_span(commands, text, "Space - Toggle ambient light\n"))
  ignore(spawn_text_span(commands, text, "1/2 - Decrease/Increase aperture\n"))
  ignore(
    spawn_text_span(commands, text, "3/4 - Decrease/Increase shutter speed\n"),
  )
  ignore(
    spawn_text_span(commands, text, "5/6 - Decrease/Increase sensitivity\n"),
  )
  ignore(spawn_text_span(commands, text, "R - Reset exposure"))

  let ui_camera = commands.spawn(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  commands
  .entity(ui_camera)
  .insert_component(@ui.IsDefaultUiCamera::IsDefaultUiCamera())
  let ui_root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  commands.entity(text).insert_component(@hierarchy.Parent::new(ui_root))

  // camera
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @camera_camera.Camera::Camera(),
        @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @camera_camera.Exposure::from_physical_camera(
          physical_camera_parameters,
        ),
      ),
    ),
  )
}

///|
fn update_exposure(
  key_input : @input.ButtonInput[@window.KeyCode],
  parameters : @app.ResMut[Parameters],
  exposure : @app.Single[@ecs.Write[@camera_camera.Exposure], @ecs.All],
  text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  let next = parameters.get()
  let mut physical_camera_parameters = next.physical_camera_parameters
  let mut changed = false
  if key_input.just_pressed(Digit2) {
    physical_camera_parameters.aperture_f_stops = physical_camera_parameters.aperture_f_stops *
      2.0F
    changed = true
  } else if key_input.just_pressed(Digit1) {
    physical_camera_parameters.aperture_f_stops = physical_camera_parameters.aperture_f_stops *
      0.5F
    changed = true
  }
  if key_input.just_pressed(Digit4) {
    physical_camera_parameters.shutter_speed_s = physical_camera_parameters.shutter_speed_s *
      2.0F
    changed = true
  } else if key_input.just_pressed(Digit3) {
    physical_camera_parameters.shutter_speed_s = physical_camera_parameters.shutter_speed_s *
      0.5F
    changed = true
  }
  if key_input.just_pressed(Digit6) {
    physical_camera_parameters.sensitivity_iso = physical_camera_parameters.sensitivity_iso +
      100.0F
    changed = true
  } else if key_input.just_pressed(Digit5) {
    physical_camera_parameters.sensitivity_iso = physical_camera_parameters.sensitivity_iso -
      100.0F
    changed = true
  }
  if key_input.just_pressed(KeyR) {
    physical_camera_parameters = PhysicalCameraParameters()
    changed = true
  }

  if changed {
    next.physical_camera_parameters = physical_camera_parameters
    parameters.set(next)
  }

  let entity = text.get()
  ignore(
    writer.set_text(
      entity,
      2,
      "Aperture: f/\{round_to_int(physical_camera_parameters.aperture_f_stops)}\n",
    ),
  )
  ignore(
    writer.set_text(
      entity,
      3,
      "Shutter speed: 1/\{shutter_denominator(physical_camera_parameters)}s\n",
    ),
  )
  ignore(
    writer.set_text(
      entity,
      4,
      "Sensitivity: ISO \{round_to_int(physical_camera_parameters.sensitivity_iso)}\n",
    ),
  )
  exposure
  .get()
  .set(
    @camera_camera.Exposure::from_physical_camera(physical_camera_parameters),
  )
}

///|
fn toggle_ambient_light(
  key_input : @input.ButtonInput[@window.KeyCode],
  ambient_light : @app.ResMut[@pbr.GlobalAmbientLight],
  text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  if key_input.just_pressed(Space) {
    let current = ambient_light.get()
    let next_brightness = if current.brightness > 1.0F { 0.0F } else { 200.0F }
    let next = @pbr.GlobalAmbientLight::new(current.color, next_brightness)
    ambient_light.set(next)

    let ambient_light_state_text = if next_brightness == 0.0F {
      "off"
    } else {
      "on"
    }
    ignore(
      writer.set_text(
        text.get(),
        1,
        "Ambient light is \{ambient_light_state_text}\n",
      ),
    )
  }
}

///|
fn animate_light_direction(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@pbr.DirectionalLight],
  ],
) -> Unit {
  let delta = time.get().delta_seconds() * 0.5F
  try! query.for_each(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotation = value.rotation
        .mul(@math.Quat::from_rotation_y(delta))
        .normalize()
    })
  })
}

///|
fn movement(
  input : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Movable]],
) -> Unit {
  try! query.for_each(fn(_entity, transform) {
    let mut direction = @math.Vec3::zero()
    if input.pressed(ArrowUp) {
      direction = direction.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
    }
    if input.pressed(ArrowDown) {
      direction = direction.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
    }
    if input.pressed(ArrowLeft) {
      direction = direction.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
    }
    if input.pressed(ArrowRight) {
      direction = direction.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
    }

    transform.modify(fn(value) {
      value.translation = value.translation.add(
        direction.mul_scalar(time.get().delta_seconds() * MOVE_SPEED),
      )
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(Parameters::Parameters())
  .add_systems_param5(Startup, setup)
  .add_systems_param5(Update, update_exposure)
  .add_systems_param4(Update, toggle_ambient_light)
  .add_systems_param2(Update, animate_light_direction)
  .add_systems_param3(Update, movement)
  .run()
}
