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
priv struct CameraSettings {
  orbit_distance : Float
  pitch_max : Float
  pitch_min : Float
  pitch_speed : Float
  roll_speed : Float
  yaw_speed : Float
}

///|
let camera_settings_resource_key : @ecs.ResourceKey[CameraSettings] = @ecs.register_resource(
  debug_name="examples.camera.camera_orbit.CameraSettings",
)

///|
impl @app.Resource for CameraSettings with resource() {
  camera_settings_resource_key
}

///|
fn CameraSettings::default() -> CameraSettings {
  let pitch_limit = @math.pi() / 2.0F - 0.01F
  {
    orbit_distance: 20.0F,
    pitch_max: pitch_limit,
    pitch_min: -pitch_limit,
    pitch_speed: 0.003F,
    roll_speed: 1.0F,
    yaw_speed: 0.004F,
  }
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Camera"),
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Plane"),
        @pbr.Mesh3d::new(
          meshes.get_ref().val.add(
            @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          materials.get_ref().val.add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.3F, 0.5F, 0.3F),
            ).with_cull_mode(None),
          ),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Cube"),
        @pbr.Mesh3d::new(
          meshes.get_ref().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
            ),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          materials.get_ref().val.add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.8F, 0.7F, 0.6F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(1.5F, 0.51F, 1.5F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Light"),
        @pbr.PointLight::default(),
        @transform.Transform::from_xyz(3.0F, 8.0F, 5.0F),
      ),
    ),
  )
}

///|
fn instructions(
  asset_server : @app.Res[@asset.AssetServer],
  commands : @app.Commands,
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Instructions"),
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @text.Text::new(
          "Mouse up or down: pitch\nMouse left or right: yaw\nMouse buttons: roll",
        ),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )
}

///|
fn orbit(
  camera_query : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
  camera_settings : @app.Res[CameraSettings],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let settings = camera_settings.get()
  let delta = mouse_motion.get().delta
  let delta_pitch = delta.y * settings.pitch_speed
  let delta_yaw = delta.x * settings.yaw_speed

  let mut delta_roll = 0.0F
  if mouse_buttons.pressed(@window.MouseButton::Left) {
    delta_roll = delta_roll - 1.0F
  }
  if mouse_buttons.pressed(@window.MouseButton::Right) {
    delta_roll = delta_roll + 1.0F
  }
  delta_roll = delta_roll * settings.roll_speed * time.get().delta_seconds()

  try! camera_query.view(fn(_entity, camera_transform) {
    let transform_ref = camera_transform.get_ref()
    let (yaw, pitch, roll) = transform_ref.val.rotation.to_euler(
      @math.EulerRot::YXZ,
    )

    let next_pitch = clamp_float(
      pitch + delta_pitch,
      settings.pitch_min,
      settings.pitch_max,
    )
    let next_roll = roll + delta_roll
    let next_yaw = yaw + delta_yaw
    transform_ref.val.rotation = @math.Quat::from_euler(
      @math.EulerRot::YXZ,
      next_yaw,
      next_pitch,
      next_roll,
    )

    let target = @math.Vec3::zero()
    transform_ref.val.translation = target.sub(
      transform_ref.val.forward().mul_scalar(settings.orbit_distance),
    )
  })
}

///|
fn clamp_float(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    return lower
  }
  if value > upper {
    return upper
  }
  value
}

///|
fn main {
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(setup),
  )
  let instructions_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(instructions),
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(CameraSettings::default)
  .add_systems(
    @app.Startup,
    (setup_system, instructions_system) |> @app.chain(),
  )
  .add_systems(@app.Update, @app.system(@app.system_param5(orbit)))
  .run()
}
