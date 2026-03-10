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
/// Port of `bevy/examples/3d/visibility_range.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const CAMERA_FOCAL_X : Float = 0.0F

///|
const CAMERA_FOCAL_Y : Float = 0.3F

///|
const CAMERA_FOCAL_Z : Float = 0.0F

///|
const CAMERA_KEYBOARD_ZOOM_SPEED : Float = 0.05F

///|
const CAMERA_KEYBOARD_PAN_SPEED : Float = 0.01F

///|
const CAMERA_MOUSE_MOVEMENT_SPEED : Float = 0.25F

///|
const MIN_ZOOM_DISTANCE : Float = 0.5F

///|
const SHOW_MODE_AUTO : Int = 0

///|
const SHOW_MODE_HIGH : Int = 1

///|
const SHOW_MODE_LOW : Int = 2

///|
priv struct VisibilityRangeState {
  mut camera : @core.Entity?
  mut high_scene_root : @core.Entity?
  mut low_scene_root : @core.Entity?
  mut show_mode : Int
  mut prepass_enabled : Bool
  mut help_text : @text.TextHandle?
}

///|
let visibility_range_state : Ref[VisibilityRangeState] = Ref::new({
  camera: None,
  high_scene_root: None,
  low_scene_root: None,
  show_mode: SHOW_MODE_AUTO,
  prepass_enabled: false,
  help_text: None,
})

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn rotate_y(v : @math.Vec3, angle : Float) -> @math.Vec3 {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @math.Vec3::new(v.x * c + v.z * s, v.y, -v.x * s + v.z * c)
}

///|
fn range_normal_high() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::new(0.0F, 0.0F, 3.0F, 4.0F, false)
}

///|
fn range_normal_low() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::new(3.0F, 4.0F, 8.0F, 9.0F, false)
}

///|
fn range_single_model() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::new(0.0F, 0.0F, 8.0F, 9.0F, false)
}

///|
fn range_invisible() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::invisible()
}

///|
fn create_help_text() -> String {
  let marker_auto = if visibility_range_state.val.show_mode == SHOW_MODE_AUTO {
    ">"
  } else {
    " "
  }
  let marker_high = if visibility_range_state.val.show_mode == SHOW_MODE_HIGH {
    ">"
  } else {
    " "
  }
  let marker_low = if visibility_range_state.val.show_mode == SHOW_MODE_LOW {
    ">"
  } else {
    " "
  }
  let prepass_action = if visibility_range_state.val.prepass_enabled {
    "disable"
  } else {
    "enable"
  }

  marker_auto +
  " (1) Switch from high-poly to low-poly based on camera distance\n" +
  marker_high +
  " (2) Show only the high-poly model\n" +
  marker_low +
  " (3) Show only the low-poly model\n" +
  "Press 1, 2, or 3 to switch which model is shown\n" +
  "Press WASD or use the mouse wheel to move the camera\n" +
  "Press Space to " +
  prepass_action +
  " the prepass"
}

///|
fn update_help_text() -> Unit {
  if visibility_range_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, create_help_text())
  }
}

///|
fn entity_is_descendant_of(
  parent_store : @ecs.ComponentAccess[@hierarchy.Parent],
  entity : @core.Entity,
  root : @core.Entity,
) -> Bool {
  let mut current = entity
  while true {
    if current.id == root.id {
      return true
    }
    if parent_store.get(current) is Some(parent) {
      current = parent.entity()
    } else {
      return false
    }
  }
  false
}

///|
fn apply_visibility_range_for_scene_root(
  world : @ecs.World,
  scene_root : @core.Entity,
  visibility_range : @visibility.VisibilityRange,
) -> Unit {
  let tick = world.read_change_tick()
  let parent_store = world.component(@hierarchy.ecs_key_parent)
  let mesh_store = world.component(@render3d.ecs_key_mesh3d)
  let visibility_range_store = world.component(
    @visibility.ecs_key_visibility_range,
  )
  mesh_store.for_each(fn(entity, _mesh) {
    if entity_is_descendant_of(parent_store, entity, scene_root) {
      if visibility_range_store.contains(entity) {
        visibility_range_store.set(entity, visibility_range, tick) |> ignore
      } else {
        visibility_range_store.insert(entity, visibility_range, tick)
      }
    }
  })
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  visibility_range_state.val.camera = None
  visibility_range_state.val.high_scene_root = None
  visibility_range_state.val.low_scene_root = None
  visibility_range_state.val.show_mode = SHOW_MODE_AUTO
  visibility_range_state.val.prepass_enabled = false
  visibility_range_state.val.help_text = None

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(50.0F, 50.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @sprite.Color::new(0.1F, 0.2F, 0.1F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let high_poly_path = @scene.GltfAssetLabel::Scene(0).from_asset(
    "models/FlightHelmet/FlightHelmet.gltf",
  )
  let low_poly_path = @scene.GltfAssetLabel::Scene(0).from_asset(
    "models/FlightHelmetLowPoly/FlightHelmetLowPoly.gltf",
  )

  let high_scene_root = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    high_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(asset_server, high_poly_path),
    ),
    tick,
  )
  visibility_range_state.val.high_scene_root = Some(high_scene_root)

  let low_scene_root = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    low_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(asset_server, low_poly_path),
    ),
    tick,
  )
  visibility_range_state.val.low_scene_root = Some(low_scene_root)

  let directional = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional,
    @render3d.DirectionalLight::new(@sprite.Color::white(), 20_000.0F, true),
    tick,
  )
  let light_angle = -0.15F * PI
  let light_rotation = @math.Quat::from_rotation_z(0.0F)
    .mul(@math.Quat::from_rotation_y(light_angle))
    .mul(@math.Quat::from_rotation_x(light_angle))
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(light_rotation),
    tick,
  )

  let camera = @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
      @math.Vec3::new(CAMERA_FOCAL_X, CAMERA_FOCAL_Y, CAMERA_FOCAL_Z),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  visibility_range_state.val.camera = Some(camera)
  world
  .component(@render3d.ecs_key_environment_map_light)
  .insert(
    camera,
    @render3d.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      150.0F,
    ),
    tick,
  )

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  visibility_range_state.val.help_text = Some(help_text)
  update_help_text()
}

///|
fn move_camera(world : @ecs.World) -> Unit {
  guard visibility_range_state.val.camera is Some(camera_entity) else { return }
  let transform_store = world.component(@math.ecs_key_transform)
  guard transform_store.get(camera_entity) is Some(camera_transform) else {
    return
  }

  let mut zoom_delta = 0.0F
  let mut theta_delta = 0.0F

  if @input.key_pressed(@window.KeyCode::KeyW) ||
    @input.key_pressed(@window.KeyCode::ArrowUp) {
    zoom_delta = zoom_delta - CAMERA_KEYBOARD_ZOOM_SPEED
  } else if @input.key_pressed(@window.KeyCode::KeyS) ||
    @input.key_pressed(@window.KeyCode::ArrowDown) {
    zoom_delta = zoom_delta + CAMERA_KEYBOARD_ZOOM_SPEED
  }

  if @input.key_pressed(@window.KeyCode::KeyA) ||
    @input.key_pressed(@window.KeyCode::ArrowLeft) {
    theta_delta = theta_delta - CAMERA_KEYBOARD_PAN_SPEED
  } else if @input.key_pressed(@window.KeyCode::KeyD) ||
    @input.key_pressed(@window.KeyCode::ArrowRight) {
    theta_delta = theta_delta + CAMERA_KEYBOARD_PAN_SPEED
  }

  let wheel = @input.mouse_wheel_delta()
  zoom_delta = zoom_delta - wheel.y * CAMERA_MOUSE_MOVEMENT_SPEED

  let focal = @math.Vec3::new(CAMERA_FOCAL_X, CAMERA_FOCAL_Y, CAMERA_FOCAL_Z)
  let direction = camera_transform.translation.sub(focal)
  let magnitude = direction.length()
  let norm = direction.normalize_or_zero()
  let new_direction = rotate_y(norm, theta_delta)
  let new_magnitude = maxf(MIN_ZOOM_DISTANCE, magnitude + zoom_delta)
  let new_translation = focal.add(new_direction.mul_scalar(new_magnitude))

  transform_store.set(
    camera_entity,
    @math.Transform::from_xyz(
      new_translation.x,
      new_translation.y,
      new_translation.z,
    ).looking_at(focal, @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    world.read_change_tick(),
  )
  |> ignore
}

///|
fn update_mode(_world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    visibility_range_state.val.show_mode = SHOW_MODE_AUTO
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    visibility_range_state.val.show_mode = SHOW_MODE_HIGH
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    visibility_range_state.val.show_mode = SHOW_MODE_LOW
    changed = true
  }
  if changed {
    update_help_text()
  }
}

///|
fn toggle_prepass(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  visibility_range_state.val.prepass_enabled = !visibility_range_state.val.prepass_enabled

  guard visibility_range_state.val.camera is Some(camera) else { return }
  let tick = world.read_change_tick()
  if visibility_range_state.val.prepass_enabled {
    world
    .component(@render3d.ecs_key_depth_prepass)
    .insert(camera, @render3d.DepthPrepass::default(), tick)
    world
    .component(@render3d.ecs_key_normal_prepass)
    .insert(camera, @render3d.NormalPrepass::default(), tick)
  } else {
    world.component(@render3d.ecs_key_depth_prepass).remove(camera) |> ignore
    world.component(@render3d.ecs_key_normal_prepass).remove(camera) |> ignore
  }
  update_help_text()
}

///|
fn update_visibility(world : @ecs.World) -> Unit {
  let state = visibility_range_state.val
  guard state.high_scene_root is Some(high_scene_root) else { return }
  guard state.low_scene_root is Some(low_scene_root) else { return }

  let mut high_range = range_normal_high()
  let mut low_range = range_normal_low()
  if state.show_mode == SHOW_MODE_HIGH {
    high_range = range_single_model()
    low_range = range_invisible()
  } else if state.show_mode == SHOW_MODE_LOW {
    high_range = range_invisible()
    low_range = range_single_model()
  }

  apply_visibility_range_for_scene_root(world, high_scene_root, high_range)
  apply_visibility_range_for_scene_root(world, low_scene_root, low_range)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(move_camera))
  .add_systems(@app.Update, @app.system(update_mode))
  .add_systems(@app.Update, @app.system(toggle_prepass))
  .add_systems(@app.Update, @app.system(update_visibility))
  .run()
}
