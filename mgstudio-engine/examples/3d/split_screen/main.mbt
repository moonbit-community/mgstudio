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
/// Port of `bevy/examples/3d/split_screen.rs`.
///
/// Parity notes:
/// - Keeps keyboard controls (`1~4`, `Left/Right`) for deterministic fallback.
/// - Adds primary-pointer click/drag controls as a lightweight fallback for
///   Bevy's per-viewport `UiTargetCamera` button interactions.

///|
priv struct SplitScreenState {
  cameras : Array[(@core.Entity, @math.IVec2)]
  mut active_camera : Int
  mut last_window_size : @math.IVec2
}

///|
let split_screen_state : Ref[SplitScreenState] = Ref::new({
  cameras: [],
  active_camera: 0,
  last_window_size: @math.IVec2::new(0, 0),
})

///|
const INSTRUCTIONS : String = "Split Screen Controls\n---------------------\n1/2/3/4: Select camera\nLeft/Right: Rotate selected camera\nPrimary pointer click: select viewport camera\nPrimary pointer drag: rotate selected camera"

///|
const FOX_SCENE_ASSET : String = "models/animated/Fox.glb"

///|
const POINTER_ROTATION_SPEED : Float = 0.005F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn setup(world : @ecs.World) -> Unit {
  split_screen_state.val.cameras.clear()
  split_screen_state.val.active_camera = 0
  split_screen_state.val.last_window_size = @math.IVec2::new(0, 0)

  // Plane
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(100.0F, 100.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  // Bevy parity: use Fox scene as split-screen content.
  let asset_server = @asset.AssetServer::new()
  let fox_scene = world.spawn_empty()
  try! world.set_by_key(
    fox_scene,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(FOX_SCENE_ASSET),
      ),
    ),
  )

  // Light
  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 10_000.0F, true),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(60.0F, 100.0F, 60.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let camera_positions = [
    @math.Vec3::new(0.0F, 200.0F, -150.0F),
    @math.Vec3::new(150.0F, 150.0F, 50.0F),
    @math.Vec3::new(100.0F, 150.0F, -150.0F),
    @math.Vec3::new(-100.0F, 80.0F, 150.0F),
  ]

  for index in 0..<camera_positions.length() {
    let camera_transform = @transform.Transform::from_xyz(
      camera_positions[index].x,
      camera_positions[index].y,
      camera_positions[index].z,
    ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))

    let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default().with_order(index),
      camera_transform,
    ).spawn(world)

    split_screen_state.val.cameras.push(
      (camera, @math.IVec2::new(index % 2, index / 2)),
    )
  }

  let overlay_font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  @text.Text2dBundle::new(
    @text.Text2d::new(INSTRUCTIONS),
    @text.TextFont::default().with_font(overlay_font).with_font_size(18.0F),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-390.0F, 320.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@sprite.Anchor::top_left())
  .with_bounds(@text.TextBounds::new_horizontal(780.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .with_color(
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore

  set_camera_viewports(world)
}

///|
fn set_camera_viewports(world : @ecs.World) -> Unit {
  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 1 || height <= 1 {
    return
  }

  let window_size = @math.IVec2::new(width, height)
  if window_size.x == split_screen_state.val.last_window_size.x &&
    window_size.y == split_screen_state.val.last_window_size.y {
    return
  }

  let half_size = @math.IVec2::new(width / 2, height / 2)
  if half_size.x <= 0 || half_size.y <= 0 {
    return
  }

  for pair in split_screen_state.val.cameras {
    let entity = pair.0
    let grid_pos = pair.1
    let viewport = @sprite.Viewport::new(
      @math.IVec2::new(grid_pos.x * half_size.x, grid_pos.y * half_size.y),
      half_size,
    )
    if (try! world.get_by_key(entity, @sprite.ecs_key_camera)) is Some(camera) {
      try! (world.replace(
        entity,
        @sprite.ecs_key_camera,
        camera.with_viewport(viewport),
      )
      |> ignore)
    }
  }

  split_screen_state.val.last_window_size = window_size
}

///|
fn button_system(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    split_screen_state.val.active_camera = 0
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    split_screen_state.val.active_camera = 1
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    split_screen_state.val.active_camera = 2
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    split_screen_state.val.active_camera = 3
  }

  if @input.primary_pointer_just_pressed() {
    if @input.primary_pointer_position() is Some(pointer_position) {
      let safe_scale = if @window.window_scale_factor() <= 0.0F {
        1.0F
      } else {
        @window.window_scale_factor()
      }
      let width = float_from_int(@window.window_width()) / safe_scale
      let height = float_from_int(@window.window_height()) / safe_scale
      if width > 0.0F && height > 0.0F {
        let col = if pointer_position.x < width * 0.5F { 0 } else { 1 }
        let row = if pointer_position.y < height * 0.5F { 0 } else { 1 }
        split_screen_state.val.active_camera = row * 2 + col
      }
    }
  }

  let keyboard_angle = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    -0.1F
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    0.1F
  } else {
    0.0F
  }
  let pointer_angle = if @input.primary_pointer_pressed() {
    @input.primary_pointer_delta().x * POINTER_ROTATION_SPEED
  } else {
    0.0F
  }
  let angle = keyboard_angle + pointer_angle
  if angle == 0.0F {
    return
  }

  let camera_count = split_screen_state.val.cameras.length()
  if camera_count == 0 {
    return
  }
  let index = if split_screen_state.val.active_camera < 0 {
    0
  } else if split_screen_state.val.active_camera >= camera_count {
    camera_count - 1
  } else {
    split_screen_state.val.active_camera
  }
  let camera_entity = split_screen_state.val.cameras[index].0

  if (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(transform) {
    let rotated_position = quat_rotate_vec3(
      @math.Quat::from_rotation_y(angle),
      transform.translation,
    )
    let next = @transform.Transform::from_xyz(
      rotated_position.x,
      rotated_position.y,
      rotated_position.z,
    ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    try! (world.replace(camera_entity, @transform.ecs_key_transform, next)
    |> ignore)
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(set_camera_viewports))
  .add_systems(@app.Update, @app.system(button_system))
  .run()
}
