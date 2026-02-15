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
/// Baseline parity: Bevy's `VisibilityRange` component and glTF scene HLOD path
/// are not available in current mgstudio runtime surfaces.

///|
/// Baseline parity: this port uses manual distance-based visibility switching
/// between high-poly and low-poly stand-ins.

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
priv struct VisibilityRangeState {
  mut camera : @core.Entity?
  mut high_model : @core.Entity?
  mut low_model : @core.Entity?
  mut show_mode : Int
}

///|
let visibility_range_state : Ref[VisibilityRangeState] = Ref::new({
  camera: None,
  high_model: None,
  low_model: None,
  show_mode: 0,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

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
fn uv_sphere_mesh(
  radius : Float,
  stacks : Int,
  sectors : Int,
) -> @render3d.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = 3.141592653589793F / stacks_f
  let sector_step = 6.283185307179586F / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = 1.5707963267948966F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
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
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  visibility_range_state.val.camera = None
  visibility_range_state.val.high_model = None
  visibility_range_state.val.low_model = None
  visibility_range_state.val.show_mode = 0

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(50.0F, 50.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.1F, 0.2F, 0.1F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let high_model = @render3d.MeshMaterial3dBundle::new(
    uv_sphere_mesh(0.35F, 28, 48),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.8F, 0.8F, 0.9F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.35F, 0.0F),
  ).spawn(world)
  visibility_range_state.val.high_model = Some(high_model)
  world
  .get_visibility_range_store()
  .insert(high_model, range_normal_high(), tick)

  let low_model = @render3d.MeshMaterial3dBundle::new(
    uv_sphere_mesh(0.35F, 8, 12),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.65F, 0.75F, 1.0F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.35F, 0.0F),
  ).spawn(world)
  visibility_range_state.val.low_model = Some(low_model)
  world.get_visibility_range_store().insert(low_model, range_normal_low(), tick)

  let directional = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    directional,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 12_000.0F, true),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    directional,
    @math.Transform::from_xyz(2.0F, 5.0F, 2.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
      @math.Vec3::new(CAMERA_FOCAL_X, CAMERA_FOCAL_Y, CAMERA_FOCAL_Z),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  visibility_range_state.val.camera = Some(camera)
}

///|
fn move_camera(world : @ecs_world.World) -> Unit {
  guard visibility_range_state.val.camera is Some(camera_entity) else { return }
  let transform_store = world.get_transform_store()
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
fn update_mode(_world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    visibility_range_state.val.show_mode = 0
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    visibility_range_state.val.show_mode = 1
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    visibility_range_state.val.show_mode = 2
  }
}

///|
fn update_visibility(world : @ecs_world.World) -> Unit {
  let state = visibility_range_state.val
  guard state.high_model is Some(high_entity) else { return }
  guard state.low_model is Some(low_entity) else { return }

  let mut high_range = range_normal_high()
  let mut low_range = range_normal_low()
  if state.show_mode == 1 {
    high_range = range_single_model()
    low_range = range_invisible()
  } else if state.show_mode == 2 {
    high_range = range_invisible()
    low_range = range_single_model()
  }

  let tick = world.read_change_tick()
  let range_store = world.get_visibility_range_store()
  range_store.set(high_entity, high_range, tick) |> ignore
  range_store.set(low_entity, low_range, tick) |> ignore
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(move_camera)
  .add_system(update_mode)
  .add_system(update_visibility)
  .run()
}
