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
const HALF_PI : Float = 1.5707963267948966F

///|
struct MyRoundGizmos {}

///|
impl Default for MyRoundGizmos with default() {
  MyRoundGizmos::{  }
}

///|
impl @sprite.GizmoConfigGroup for MyRoundGizmos with gizmo_config_group_marker(
  _self,
) {

}

///|
fn clamp_float(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn gizmo_config_with_line_width(
  config : @gizmos.GizmoConfig,
  width : Float,
) -> @gizmos.GizmoConfig {
  { ..config, line: { ..config.line, width, } }
}

///|
fn gizmo_config_with_line_style(
  config : @gizmos.GizmoConfig,
  style : @gizmos.GizmoLineStyle,
) -> @gizmos.GizmoConfig {
  { ..config, line: { ..config.line, style, } }
}

///|
fn gizmo_config_with_line_joints(
  config : @gizmos.GizmoConfig,
  joints : @gizmos.GizmoLineJoint,
) -> @gizmos.GizmoConfig {
  { ..config, line: { ..config.line, joints, } }
}

///|
fn gizmo_config_toggle_enabled(
  config : @gizmos.GizmoConfig,
) -> @gizmos.GizmoConfig {
  { ..config, enabled: !config.enabled }
}

///|
fn cycle_line_style_forward(
  style : @gizmos.GizmoLineStyle,
) -> @gizmos.GizmoLineStyle {
  match style {
    Solid => Dotted
    Dotted => Dashed(gap_scale=3.0F, line_scale=5.0F)
    Dashed(..) => Solid
  }
}

///|
fn cycle_line_style_backward(
  style : @gizmos.GizmoLineStyle,
) -> @gizmos.GizmoLineStyle {
  match style {
    Solid => Dashed(gap_scale=3.0F, line_scale=5.0F)
    Dotted => Solid
    Dashed(..) => Dotted
  }
}

///|
fn cycle_line_joint_forward(
  joint : @gizmos.GizmoLineJoint,
) -> @gizmos.GizmoLineJoint {
  match joint {
    None => Bevel
    Bevel => Miter
    Miter => Round(4)
    Round(_) => None
  }
}

///|
fn cycle_line_joint_backward(
  joint : @gizmos.GizmoLineJoint,
) -> @gizmos.GizmoLineJoint {
  match joint {
    None => Round(4)
    Bevel => None
    Miter => Bevel
    Round(_) => Miter
  }
}

///|
fn gradient_curve_points(seconds : Float) -> Array[(@math.Vec3, @sprite.Color)] {
  let points : Array[(@math.Vec3, @sprite.Color)] = []
  let steps = 96
  for i in 0..<=steps {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(steps.to_double())
    let phase = t * PI * 5.0F + seconds
    let x = (t - 0.5F) * 10.0F
    let y = 1.2F + @math.sin(phase) * 0.6F
    let z = -3.0F + t * 6.0F
    let color = if t < 0.5F {
      @sprite.Color::srgb(0.0F, 0.8F, 0.8F)
    } else {
      @sprite.Color::srgb(1.0F, 0.2F, 0.6F)
    }
    points.push((@math.Vec3::new(x, y, z), color))
  }
  points
}

///|
fn setup(
  commands : @app.Commands,
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Camera::default(),
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 4.5F, 10.0F).looking_at(
          @math.Vec3::new(0.0F, 0.8F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
        @pbr.PointLight::default().with_shadow_maps_enabled(true),
      ),
    ),
  )

  let plane_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(8.0F, 0.1F, 8.0F),
  )
  let plane_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.5F, 0.3F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::from_xyz(0.0F, -0.05F, 0.0F),
      ),
    ),
  )

  let cube_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(1.0F, 1.0F, 1.0F),
  )
  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.8F, 0.7F, 0.6F)),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(cube_material),
        @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
      ),
    ),
  )

  config_store.modify(fn(store) {
    let (default_config, _default_group) = store.config_mut(
      @gizmos.DefaultGizmoConfigGroup::default(),
    )
    default_config.val = gizmo_config_with_line_joints(
      gizmo_config_with_line_width(default_config.val, 2.0F),
      None,
    )

    let (round_config, _round_group) = store.config_mut(
      MyRoundGizmos::default(),
    )
    round_config.val = gizmo_config_with_line_joints(
      gizmo_config_with_line_width(round_config.val, 4.0F),
      Round(4),
    )
  })
}

///|
fn draw_example_collection(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  my_gizmos : @gizmos.Gizmos[MyRoundGizmos],
  time : @app.Res[@time.Time[@time.Virtual]],
) -> Unit {
  let seconds = time.get().elapsed_secs()

  gizmos.grid_3d(
    @math.Isometry3d::new(
      @math.Vec3::zero(),
      @math.Quat::from_rotation_x(HALF_PI),
    ),
    @math.IVec2::new(10, 10),
    @math.Vec2::new(0.8F, 0.8F),
    @sprite.Color::srgb(0.65F, 0.65F, 0.65F),
  )
  gizmos.grid_3d(
    @math.Isometry3d::new(
      @math.Vec3::splat(4.0F),
      @math.Quat::from_euler(@math.EulerRot::XYZ, HALF_PI, 0.0F, seconds * 0.5F),
    ),
    @math.IVec2::new(5, 5),
    @math.Vec2::new(0.5F, 0.5F),
    @sprite.Color::srgb(0.6F, 0.2F, 0.8F),
  )

  gizmos.cuboid_3d(
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F).with_scale(
      @math.Vec3::splat(1.25F),
    ),
    @math.Vec3::new(1.0F, 1.0F, 1.0F),
    @sprite.Color::black(),
  )
  gizmos.rect_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(@math.cos(seconds) * 2.5F, 1.0F, 0.0F),
      @math.Quat::from_rotation_y(HALF_PI),
    ),
    @math.Vec2::new(2.0F, 2.0F),
    @sprite.Color::srgb(0.0F, 1.0F, 0.0F),
  )
  gizmos.cross_3d(
    @math.Vec3::new(-1.0F, 1.0F, 1.0F),
    0.5F,
    @sprite.Color::srgb(1.0F, 0.0F, 1.0F),
  )
  gizmos.curve_gradient_3d(gradient_curve_points(seconds))

  my_gizmos.sphere_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(1.0F, 0.5F, 0.0F),
      @math.Quat::identity(),
    ),
    0.5F,
    @sprite.Color::srgb(1.0F, 0.0F, 0.0F),
  )
  my_gizmos.circle_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Quat::from_rotation_x(HALF_PI),
    ),
    3.0F,
    @sprite.Color::black(),
  )
  my_gizmos.circle_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Quat::from_euler(
        @math.EulerRot::XYZ,
        HALF_PI,
        0.0F,
        0.25F + seconds * 0.1F,
      ),
    ),
    3.1F,
    @sprite.Color::srgb(0.0F, 0.0F, 0.5F),
  )
  my_gizmos.arc_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(1.0F, 1.0F, 1.0F),
      @math.Quat::from_euler(@math.EulerRot::XYZ, 0.7F, 0.4F, 0.0F),
    ),
    PI,
    0.2F,
    @sprite.Color::srgb(1.0F, 0.5F, 0.0F),
  )

  for y in [0.0F, 0.5F, 1.0F] {
    gizmos.ray_3d(
      @math.Vec3::new(1.0F, y, 0.0F),
      @math.Vec3::new(-3.0F, @math.sin(seconds * 3.0F), 0.0F),
      @sprite.Color::srgb(0.0F, 0.0F, 1.0F),
    )
  }

  gizmos.arrow_3d(
    @math.Vec3::zero(),
    @math.Vec3::splat(1.5F),
    @sprite.Color::srgb(1.0F, 1.0F, 0.0F),
  )
}

///|
fn update_config(
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
  keyboard : @input.ButtonInput[@window.KeyCode],
  real_time : @app.Res[@time.Time[@time.Real]],
  virtual_time : @app.ResMut[@time.Time[@time.Virtual]],
) -> Unit {
  let delta = real_time.get().delta_secs()
  config_store.modify(fn(store) {
    let (default_config, _default_group) = store.config_mut(
      @gizmos.DefaultGizmoConfigGroup::default(),
    )
    if keyboard.pressed(ArrowRight) {
      default_config.val = gizmo_config_with_line_width(
        default_config.val,
        clamp_float(default_config.val.line.width + 5.0F * delta, 0.0F, 50.0F),
      )
    }
    if keyboard.pressed(ArrowLeft) {
      default_config.val = gizmo_config_with_line_width(
        default_config.val,
        clamp_float(default_config.val.line.width - 5.0F * delta, 0.0F, 50.0F),
      )
    }
    if keyboard.just_pressed(Digit1) {
      default_config.val = gizmo_config_toggle_enabled(default_config.val)
    }
    if keyboard.just_pressed(KeyU) {
      default_config.val = gizmo_config_with_line_style(
        default_config.val,
        cycle_line_style_forward(default_config.val.line.style),
      )
    }
    if keyboard.just_pressed(KeyJ) {
      default_config.val = gizmo_config_with_line_joints(
        default_config.val,
        cycle_line_joint_forward(default_config.val.line.joints),
      )
    }

    let (round_config, _round_group) = store.config_mut(
      MyRoundGizmos::default(),
    )
    if keyboard.pressed(ArrowUp) {
      round_config.val = gizmo_config_with_line_width(
        round_config.val,
        clamp_float(round_config.val.line.width + 5.0F * delta, 0.0F, 50.0F),
      )
    }
    if keyboard.pressed(ArrowDown) {
      round_config.val = gizmo_config_with_line_width(
        round_config.val,
        clamp_float(round_config.val.line.width - 5.0F * delta, 0.0F, 50.0F),
      )
    }
    if keyboard.just_pressed(Digit2) {
      round_config.val = gizmo_config_toggle_enabled(round_config.val)
    }
    if keyboard.just_pressed(KeyI) {
      round_config.val = gizmo_config_with_line_style(
        round_config.val,
        cycle_line_style_backward(round_config.val.line.style),
      )
    }
    if keyboard.just_pressed(KeyK) {
      round_config.val = gizmo_config_with_line_joints(
        round_config.val,
        cycle_line_joint_backward(round_config.val.line.joints),
      )
    }
  })
  if keyboard.just_pressed(Space) {
    virtual_time.set(virtual_time.get().toggle())
  }
}

///|
fn main {
  @gizmos.init_gizmo_group(
    @app.App::new(@ecs.World::new()).add_plugins(
      @mgstudio.DefaultPlugins::default(),
    ),
    MyRoundGizmos::default(),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(draw_example_collection)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param4(update_config)))
  .run()
}
