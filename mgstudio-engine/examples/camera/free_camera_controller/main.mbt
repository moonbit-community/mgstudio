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
/// Port of `bevy/examples/camera/free_camera_controller.rs`.

///|
priv struct FreeCameraExampleState {
  mut camera : @core.Entity
  mut info_text : @text.TextHandle?
}

///|
let free_camera_example_state : Ref[FreeCameraExampleState] = Ref::new(FreeCameraExampleState::{
  camera: @core.Entity::placeholder(),
  info_text: None,
})

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
    "0" + fraction.to_string()
  } else if precision == 3 && fraction < 10 {
    "00" + fraction.to_string()
  } else if precision == 3 && fraction < 100 {
    "0" + fraction.to_string()
  } else {
    fraction.to_string()
  }
  sign + whole.to_string() + "." + fraction_text
}

///|
fn ui_spawn_text(
  world : @ecs.World,
  root : @core.Entity,
  content : String,
  font_size : Float,
  left : Float,
  top? : Float = 0.0F,
  bottom? : Float = -1.0F,
  right? : Float = -1.0F,
) -> @text.TextHandle {
  let asset_server = @asset.AssetServer::new()
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(content),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(font_size),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let tick = world.read_change_tick()
  let entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(entity, @hierarchy.Parent::new(root), tick)
  let mut node = @ui.Node::default().with_position_type(
    @ui.PositionType::Absolute,
  )
  node = node.with_left(@ui.Val::Px(left))
  if top >= 0.0F {
    node = node.with_top(@ui.Val::Px(top))
  }
  if bottom >= 0.0F {
    node = node.with_bottom(@ui.Val::Px(bottom))
  }
  if right >= 0.0F {
    node = node.with_right(@ui.Val::Px(right))
  }
  world.component(@ui.ecs_key_node).insert(entity, node, tick)
  world
  .component(@ui.ecs_key_ui_text)
  .insert(entity, @ui.UiText::new(handle), tick)
  handle
}

///|
fn spawn_overlay(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let overlay_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(1).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@ui.ecs_key_is_default_ui_camera)
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

  ui_spawn_text(
    world,
    root,
    "Z/X: decrease/increase sensitivity\nC/V: decrease/increase friction\nF/G: decrease/increase scroll factor\nB: enable/disable controller",
    20.0F,
    12.0F,
    bottom=12.0F,
  )
  |> ignore

  let info_handle = ui_spawn_text(
    world,
    root,
    "",
    20.0F,
    12.0F,
    top=12.0F,
    right=12.0F,
  )
  free_camera_example_state.val.info_text = Some(info_handle)
}

///|
fn spawn_camera(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let camera = @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.0F, 1.0F, 0.0F).looking_to(
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_free_camera)
  .insert(
    camera,
    @render3d.FreeCamera::{
      ..@render3d.FreeCamera::default(),
      sensitivity: 0.2F,
      friction: 25.0F,
      walk_speed: 3.0F,
      run_speed: 9.0F,
    },
    tick,
  )
  free_camera_example_state.val.camera = camera
}

///|
fn spawn_lights(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let light_a = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    light_a,
    @render3d.PointLight::new(
      @sprite.Color::new(1.0F, 0.71F, 0.49F, 1.0F),
      1500.0F,
      20.0F,
      true,
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(light_a, @math.Transform::from_xyz(0.0F, 3.0F, 0.0F), tick)

  let light_b = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(light_b, @render3d.PointLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(light_b, @math.Transform::from_xyz(-3.5F, 3.0F, 0.0F), tick)

  let light_c = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    light_c,
    @render3d.PointLight::new(
      @sprite.Color::new(1.0F, 0.44F, 0.44F, 1.0F),
      1200.0F,
      20.0F,
      true,
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(light_c, @math.Transform::from_xyz(0.0F, -0.5F, 0.0F), tick)
}

///|
fn spawn_world(world : @ecs.World) -> Unit {
  let white = @render3d.MeshMaterial3d::new(
    @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(@sprite.Color::white()),
    ),
  )
  let blue = @render3d.MeshMaterial3d::new(
    @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(
        @sprite.Color::new(0.11F, 0.31F, 0.66F, 1.0F),
      ),
    ),
  )
  let red = @render3d.MeshMaterial3d::new(
    @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(
        @sprite.Color::new(0.25F, 0.03F, 0.05F, 1.0F),
      ),
    ),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(10.0F, 10.0F),
    white,
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(10.0F, 10.0F),
    white,
    @math.Transform::from_xyz(0.0F, -0.01F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(@math.pi()),
    ),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_sphere(0.5F),
    blue,
    @math.Transform::from_xyz(3.0F, 1.5F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(0.2F, 4.0F, 3.0F),
    white,
    @math.Transform::from_xyz(-3.0F, 2.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    blue,
    @math.Transform::from_xyz(-4.2F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    red,
    @math.Transform::from_xyz(3.0F, -2.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(@math.pi() / 4.0F)
      .mul(@math.Quat::from_rotation_x(@math.pi() / 4.0F))
      .normalize(),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn update_camera_settings(world : @ecs.World) -> Unit {
  let camera = free_camera_example_state.val.camera
  if camera.is_placeholder() {
    return
  }
  let tick = world.read_change_tick()
  let config_store = world.component(@render3d.ecs_key_free_camera)
  let state_store = world.component(@render3d.ecs_key_free_camera_state)

  if config_store.get(camera) is Some(config) {
    let mut next = config
    if @input.key_pressed(@window.KeyCode::KeyZ) {
      next = @render3d.FreeCamera::{
        ..next,
        sensitivity: if next.sensitivity - 0.005F < 0.005F {
          0.005F
        } else {
          next.sensitivity - 0.005F
        },
      }
    }
    if @input.key_pressed(@window.KeyCode::KeyX) {
      next = @render3d.FreeCamera::{
        ..next,
        sensitivity: next.sensitivity + 0.005F,
      }
    }
    if @input.key_pressed(@window.KeyCode::KeyC) {
      next = @render3d.FreeCamera::{
        ..next,
        friction: if next.friction - 0.2F < 0.0F {
          0.0F
        } else {
          next.friction - 0.2F
        },
      }
    }
    if @input.key_pressed(@window.KeyCode::KeyV) {
      next = @render3d.FreeCamera::{ ..next, friction: next.friction + 0.2F }
    }
    if @input.key_pressed(@window.KeyCode::KeyF) {
      next = @render3d.FreeCamera::{
        ..next,
        scroll_factor: if next.scroll_factor - 0.02F < 0.02F {
          0.02F
        } else {
          next.scroll_factor - 0.02F
        },
      }
    }
    if @input.key_pressed(@window.KeyCode::KeyG) {
      next = @render3d.FreeCamera::{
        ..next,
        scroll_factor: next.scroll_factor + 0.02F,
      }
    }
    config_store.set(camera, next, tick) |> ignore
  }

  if @input.key_just_pressed(@window.KeyCode::KeyB) {
    if state_store.get(camera) is Some(state) {
      state_store.set(
        camera,
        @render3d.FreeCameraState::{ ..state, enabled: !state.enabled },
        tick,
      )
      |> ignore
    }
  }
}

///|
fn update_text(world : @ecs.World) -> Unit {
  let camera = free_camera_example_state.val.camera
  if camera.is_placeholder() {
    return
  }
  if free_camera_example_state.val.info_text is Some(handle) {
    let config_store = world.component(@render3d.ecs_key_free_camera)
    let state_store = world.component(@render3d.ecs_key_free_camera_state)
    if config_store.get(camera) is Some(config) {
      if state_store.get(camera) is Some(state) {
        @text.text_set_content(
          handle,
          "Enabled: " +
          state.enabled.to_string() +
          "\nSensitivity: " +
          format_float(config.sensitivity, 3) +
          "\nFriction: " +
          format_float(config.friction, 1) +
          "\nScroll factor: " +
          format_float(config.scroll_factor, 2) +
          "\nWalk Speed: " +
          format_float(config.walk_speed * state.speed_multiplier, 2) +
          "\nRun Speed: " +
          format_float(config.run_speed * state.speed_multiplier, 2) +
          "\nSpeed: " +
          format_float(state.velocity.length(), 2),
        )
      }
    }
  }
}

///|
fn main {
  free_camera_example_state.val.camera = @core.Entity::placeholder()
  free_camera_example_state.val.info_text = None
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@render3d.free_camera_plugin])
  .add_systems(@app.Startup, @app.system(spawn_camera))
  .add_systems(@app.Startup, @app.system(spawn_overlay))
  .add_systems(@app.Startup, @app.system(spawn_lights))
  .add_systems(@app.Startup, @app.system(spawn_world))
  .add_systems(@app.Update, @app.system(update_camera_settings))
  .add_systems(@app.Update, @app.system(update_text))
  .run()
}
