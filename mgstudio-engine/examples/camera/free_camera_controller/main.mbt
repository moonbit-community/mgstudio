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

///|
struct InfoText {}

///|
let info_text_key : @ecs.ComponentKey[InfoText] = @ecs.register_component(
  debug_name="examples.camera.free_camera_controller.InfoText",
)

///|
pub impl @ecs.Component for InfoText with component() {
  info_text_key
}

///|
fn free_camera_text(free_camera : @camera_controller.FreeCamera) -> String {
  "Sensitivity: \{format_float(free_camera.sensitivity, 3)}\nFriction: \{format_float(free_camera.friction, 1)}\nScroll factor: \{format_float(free_camera.scroll_factor, 2)}\nWalk speed: \{format_float(free_camera.walk_speed, 2)}\nRun speed: \{format_float(free_camera.run_speed, 2)}"
}

///|
fn format_float(value : Float, precision : Int) -> String {
  let scale = match precision {
    1 => 10
    2 => 100
    _ => 1000
  }
  let scaled = (value * Float::from_int(scale)).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / scale
  let fraction = abs_scaled % scale
  let fraction_text = if precision == 1 {
    fraction.to_string()
  } else if precision == 2 && fraction < 10 {
    "0\{fraction.to_string()}"
  } else if precision == 3 && fraction < 10 {
    "00\{fraction.to_string()}"
  } else if precision == 3 && fraction < 100 {
    "0\{fraction.to_string()}"
  } else {
    fraction.to_string()
  }
  "\{sign}\{whole.to_string()}.\{fraction_text}"
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F).looking_to(
          @math.Vec3::new(1.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @camera_controller.FreeCamera::{
          ..@camera_controller.FreeCamera::default(),
          sensitivity: 0.2F,
          friction: 25.0F,
          walk_speed: 3.0F,
          run_speed: 9.0F,
        },
      ),
    ),
  )
}

///|
fn spawn_text(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  free_camera_query : @ecs.Query[
    @ecs.Comp[@camera_controller.FreeCamera],
    @ecs.All,
  ],
) -> Unit {
  guard (free_camera_query.single() catch { _ => None })
    is Some(free_camera_comp) else {
    return
  }
  let free_camera = free_camera_comp.value()
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::default().with_order(1).with_clear_color_none(),
        @ui.IsDefaultUiCamera::default(),
      ),
    ),
  )

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
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(-16.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @text.Text::new(free_camera_text(free_camera)),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_bottom(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @text.Text::new(
          "Z/X: decrease/increase sensitivity\nC/V: decrease/increase friction\nF/G: decrease/increase scroll factor\nB: enable/disable controller",
        ),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_right(@ui.Val::Px(12.0F)),
        @text.Text::new(""),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
        InfoText::{  },
      ),
    ),
  )
}

///|
fn update_camera_settings(
  commands : @app.Commands,
  input : @input.ButtonInput[@window.KeyCode],
  camera_query : @ecs.Query[
    (
      @ecs.Comp[@camera_controller.FreeCamera],
      @ecs.Comp[@camera_controller.FreeCameraState],
    ),
    @ecs.All,
  ],
) -> Unit {
  try! camera_query.for_each(fn(entity, data) {
    let (free_camera, free_camera_state) = data
    let mut next_camera = free_camera.value()
    let free_camera_state = free_camera_state.value()
    let mut camera_changed = false

    if input.pressed(@window.KeyCode::KeyZ) {
      next_camera = @camera_controller.FreeCamera::{
        ..next_camera,
        sensitivity: if next_camera.sensitivity - 0.005F < 0.005F {
          0.005F
        } else {
          next_camera.sensitivity - 0.005F
        },
      }
      camera_changed = true
    }
    if input.pressed(@window.KeyCode::KeyX) {
      next_camera = @camera_controller.FreeCamera::{
        ..next_camera,
        sensitivity: next_camera.sensitivity + 0.005F,
      }
      camera_changed = true
    }
    if input.pressed(@window.KeyCode::KeyC) {
      next_camera = @camera_controller.FreeCamera::{
        ..next_camera,
        friction: if next_camera.friction - 0.2F < 0.0F {
          0.0F
        } else {
          next_camera.friction - 0.2F
        },
      }
      camera_changed = true
    }
    if input.pressed(@window.KeyCode::KeyV) {
      next_camera = @camera_controller.FreeCamera::{
        ..next_camera,
        friction: next_camera.friction + 0.2F,
      }
      camera_changed = true
    }
    if input.pressed(@window.KeyCode::KeyF) {
      next_camera = @camera_controller.FreeCamera::{
        ..next_camera,
        scroll_factor: if next_camera.scroll_factor - 0.02F < 0.02F {
          0.02F
        } else {
          next_camera.scroll_factor - 0.02F
        },
      }
      camera_changed = true
    }
    if input.pressed(@window.KeyCode::KeyG) {
      next_camera = @camera_controller.FreeCamera::{
        ..next_camera,
        scroll_factor: next_camera.scroll_factor + 0.02F,
      }
      camera_changed = true
    }
    if camera_changed {
      commands.entity(entity).insert_component(next_camera)
    }

    if input.just_pressed(@window.KeyCode::KeyB) {
      commands
      .entity(entity)
      .insert_component(@camera_controller.FreeCameraState::{
        ..free_camera_state,
        enabled: !free_camera_state.enabled,
      })
    }
  })
}

///|
fn update_text(
  info_text_query : @ecs.Query[
    (@ecs.Comp[InfoText], @ecs.Mut[@text.Text]),
    @ecs.All,
  ],
  camera_query : @ecs.Query[
    (
      @ecs.Comp[@camera_controller.FreeCamera],
      @ecs.Comp[@camera_controller.FreeCameraState],
    ),
    @ecs.All,
  ],
) -> Unit {
  let content_ref : Ref[String?] = Ref::new(None)
  try! camera_query.for_each(fn(_entity, data) {
    let (free_camera, free_camera_state) = data
    let free_camera = free_camera.value()
    let free_camera_state = free_camera_state.value()
    let walk_speed = format_float(
      free_camera.walk_speed * free_camera_state.speed_multiplier,
      2,
    )
    let run_speed = format_float(
      free_camera.run_speed * free_camera_state.speed_multiplier,
      2,
    )
    content_ref.val = Some(
      "Enabled: \{free_camera_state.enabled.to_string()},\nSensitivity: \{format_float(free_camera.sensitivity, 3)}\nFriction: \{format_float(free_camera.friction, 1)}\nScroll factor: \{format_float(free_camera.scroll_factor, 2)}\nWalk Speed: \{walk_speed}\nRun Speed: \{run_speed}\nSpeed: \{format_float(free_camera_state.velocity.length(), 2)}",
    )
  })
  guard content_ref.val is Some(content) else { return }
  try! info_text_query.for_each(fn(_entity, data) {
    let (_marker, info_text) = data
    info_text.get_ref().val.content = content
  })
}

///|
fn spawn_lights(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::new(
          @sprite.Color::new(1.0F, 0.71F, 0.49F, 1.0F),
          1500.0F,
          20.0F,
          true,
        ),
        @transform.Transform::from_xyz(0.0F, 3.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default(),
        @transform.Transform::from_xyz(-3.5F, 3.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::new(
          @sprite.Color::new(1.0F, 0.44F, 0.44F, 1.0F),
          1200.0F,
          20.0F,
          true,
        ),
        @transform.Transform::from_xyz(0.0F, -0.5F, 0.0F),
      ),
    ),
  )
}

///|
fn spawn_world(
  commands : @app.Commands,
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
) -> Unit {
  let cube = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F)),
  )
  let floor = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(10.0F, 10.0F)),
  )
  let sphere = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_sphere(0.5F)),
  )
  let wall = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(0.2F, 4.0F, 3.0F)),
  )

  let blue_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.11F, 0.31F, 0.66F, 1.0F),
    ),
  )
  let red_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.25F, 0.03F, 0.05F, 1.0F),
    ),
  )
  let white_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()),
  )

  ignore(
    commands.spawn(
      (@pbr.Mesh3d::new(floor), @pbr.MeshMaterial3d::new(white_material)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(floor),
        @pbr.MeshMaterial3d::new(white_material),
        @transform.Transform::from_xyz(0.0F, -0.01F, 0.0F).with_rotation(
          @math.Quat::from_rotation_x(@math.pi()),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(sphere),
        @pbr.MeshMaterial3d::new(blue_material),
        @transform.Transform::from_xyz(3.0F, 1.5F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(wall),
        @pbr.MeshMaterial3d::new(white_material),
        @transform.Transform::from_xyz(-3.0F, 2.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube),
        @pbr.MeshMaterial3d::new(blue_material),
        @transform.Transform::from_xyz(-4.2F, 0.5F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube),
        @pbr.MeshMaterial3d::new(red_material),
        @transform.Transform::from_xyz(3.0F, -2.0F, 0.0F).with_rotation(
          @math.Quat::from_rotation_y(@math.pi() / 4.0F)
          .mul(@math.Quat::from_rotation_x(@math.pi() / 4.0F))
          .normalize(),
        ),
      ),
    ),
  )
}

///|
fn camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_systems(@app.Startup, @app.system(@app.system_param(spawn_camera)))
}

///|
fn camera_settings_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let update_camera_settings_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(update_camera_settings),
  )
  let update_text_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(update_text),
  )
  app
  .add_systems(@app.PostStartup, @app.system(@app.system_param3(spawn_text)))
  .add_systems(
    @app.Update,
    (update_camera_settings_system, update_text_system) |> @app.chain(),
  )
}

///|
fn scene_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_systems(@app.Startup, @app.system(@app.system_param(spawn_lights)))
  .add_systems(@app.Startup, @app.system(@app.system_param3(spawn_world)))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugins([
    @camera_controller.free_camera_plugin, camera_plugin, camera_settings_plugin,
    scene_plugin,
  ])
  .run()
}
