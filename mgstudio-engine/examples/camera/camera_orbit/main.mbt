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
/// Port of `bevy/examples/camera/camera_orbit.rs`.

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
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@ecs.Name::component())
  .insert(camera, @ecs.Name::new("Camera"), tick)

  let plane = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::srgb(0.3F, 0.5F, 0.3F),
        ).with_cull_mode(None),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@ecs.Name::component())
  .insert(plane, @ecs.Name::new("Plane"), tick)

  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::srgb(0.8F, 0.7F, 0.6F),
        ),
      ),
    ),
    @math.Transform::from_xyz(1.5F, 0.51F, 1.5F),
  ).spawn(world)
  world
  .component(@ecs.Name::component())
  .insert(cube, @ecs.Name::new("Cube"), tick)

  let light = world.spawn_empty()
  world
  .component(@ecs.Name::component())
  .insert(light, @ecs.Name::new("Light"), tick)
  world
  .component(@render3d.PointLight::component())
  .insert(light, @render3d.PointLight::default(), tick)
  world
  .component(@math.Transform::component())
  .insert(light, @math.Transform::from_xyz(3.0F, 8.0F, 5.0F), tick)
}

///|
fn instructions(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let overlay_camera = @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(1).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@ui.IsDefaultUiCamera::component())
  .insert(overlay_camera, @ui.IsDefaultUiCamera::default(), tick)

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let asset_server = @asset.AssetServer::new()
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Mouse up or down: pitch\nMouse left or right: yaw\nMouse buttons: roll",
      ),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@render2d.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let text_entity = world.spawn_empty()
  world
  .component(@ecs.Name::component())
  .insert(text_entity, @ecs.Name::new("Instructions"), tick)
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn orbit(
  camera_query : @ecs.Query1Filtered[
    @math.Transform,
    @ecs.With[@render3d.Camera3d],
  ],
  camera_settings_res : @app.Res[CameraSettings],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
) -> Unit {
  let camera_settings = camera_settings_res.get()
  let delta = mouse_motion.get().delta
  let delta_pitch = delta.y * camera_settings.pitch_speed
  let delta_yaw = delta.x * camera_settings.yaw_speed

  let mut delta_roll = 0.0F
  if mouse_buttons.pressed(Left) {
    delta_roll = delta_roll - 1.0F
  }
  if mouse_buttons.pressed(Right) {
    delta_roll = delta_roll + 1.0F
  }
  delta_roll = delta_roll *
    camera_settings.roll_speed *
    @time.time_delta_seconds()

  try! camera_query.view_mut(fn(_entity, camera_transform) {
    let transform_ref = camera_transform.get_ref()
    let (yaw, pitch, roll) = transform_ref.val.rotation.to_euler(
      @math.EulerRot::YXZ,
    )

    let next_pitch = clamp_float(
      pitch + delta_pitch,
      camera_settings.pitch_min,
      camera_settings.pitch_max,
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
      transform_ref.val.forward().mul_scalar(camera_settings.orbit_distance),
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
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .init_resource(CameraSettings::default)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Startup, @app.system(instructions))
  .add_systems(@app.Update, @app.system(@app.system_param4(orbit)))
  .run()
}
