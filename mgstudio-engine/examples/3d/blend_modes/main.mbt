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
/// Port of `bevy/examples/3d/blend_modes.rs`.

///|
/// Baseline parity: camera HDR toggle and on-screen UI labels are not available
/// in current mgstudio runtime surfaces for this example.

///|
/// Baseline parity: color randomization is implemented as deterministic palette
/// stepping when pressing `C`.

///|
const PI : Float = 3.141592653589793F

///|
const TAU : Float = 6.283185307179586F

///|
priv struct ControlledMaterial {
  handle : @asset.Handle[@render3d.StandardMaterial]
  allow_unlit : Bool
  allow_color : Bool
}

///|
priv struct BlendModesState {
  mut alpha : Float
  mut camera : @core.Entity?
  mut camera_angle : Float
  mut color_seed : Int
  materials : Array[ControlledMaterial]
  mut unlit : Bool
}

///|
let blend_modes_state : Ref[BlendModesState] = Ref::new({
  alpha: 0.9F,
  camera: None,
  camera_angle: 0.0F,
  color_seed: 0,
  materials: [],
  unlit: false,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn palette_color(index : Int, alpha : Float) -> @render2d.Color {
  let slot = index % 8
  if slot == 0 {
    @render2d.Color::new(0.9F, 0.2F, 0.3F, alpha)
  } else if slot == 1 {
    @render2d.Color::new(0.2F, 0.8F, 0.5F, alpha)
  } else if slot == 2 {
    @render2d.Color::new(0.3F, 0.5F, 1.0F, alpha)
  } else if slot == 3 {
    @render2d.Color::new(1.0F, 0.7F, 0.2F, alpha)
  } else if slot == 4 {
    @render2d.Color::new(0.8F, 0.3F, 0.9F, alpha)
  } else if slot == 5 {
    @render2d.Color::new(0.1F, 0.9F, 0.9F, alpha)
  } else if slot == 6 {
    @render2d.Color::new(0.95F, 0.95F, 0.3F, alpha)
  } else {
    @render2d.Color::new(0.95F, 0.4F, 0.4F, alpha)
  }
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
  let stack_step = PI / stacks_f
  let sector_step = TAU / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
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

  let geometry = @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices))
  @render3d.Mesh3d::from_geometry(geometry)
}

///|
fn register_material(
  handle : @asset.Handle[@render3d.StandardMaterial],
  allow_unlit : Bool,
  allow_color : Bool,
) -> Unit {
  blend_modes_state.val.materials.push({ handle, allow_unlit, allow_color })
}

///|
fn spawn_mesh(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
) -> Unit {
  @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let base_color = @render2d.Color::new(
    0.9F,
    0.2F,
    0.3F,
    blend_modes_state.val.alpha,
  )
  let sphere_mesh = uv_sphere_mesh(0.9F, 16, 24)

  let opaque_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Opaque,
    ),
  )
  register_material(opaque_material, true, true)
  spawn_mesh(
    world,
    sphere_mesh,
    opaque_material,
    @math.Transform::from_xyz(-4.0F, 0.0F, 0.0F),
  )

  let blend_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Blend,
    ),
  )
  register_material(blend_material, true, true)
  spawn_mesh(
    world,
    sphere_mesh,
    blend_material,
    @math.Transform::from_xyz(-2.0F, 0.0F, 0.0F),
  )

  let premultiplied_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Premultiplied,
    ),
  )
  register_material(premultiplied_material, true, true)
  spawn_mesh(
    world,
    sphere_mesh,
    premultiplied_material,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )

  let add_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Add,
    ),
  )
  register_material(add_material, true, true)
  spawn_mesh(
    world,
    sphere_mesh,
    add_material,
    @math.Transform::from_xyz(2.0F, 0.0F, 0.0F),
  )

  let multiply_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(base_color).with_alpha_mode(
      @render3d.AlphaMode3d::Multiply,
    ),
  )
  register_material(multiply_material, true, true)
  spawn_mesh(
    world,
    sphere_mesh,
    multiply_material,
    @math.Transform::from_xyz(4.0F, 0.0F, 0.0F),
  )

  let black_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
  )
  let white_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    ),
  )
  register_material(black_material, false, true)
  register_material(white_material, false, true)

  let plane_mesh = @render3d.Mesh3d::from_plane(2.0F, 2.0F)
  for x in -3..<4 {
    for z in -3..<4 {
      let use_black = (x + z) % 2 == 0
      let material = if use_black { black_material } else { white_material }
      spawn_mesh(
        world,
        plane_mesh,
        material,
        @math.Transform::from_xyz(
          float_from_int(x) * 2.0F,
          -1.0F,
          float_from_int(z) * 2.0F,
        ),
      )
    }
  }

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      1_000_000.0F,
      30.0F,
      true,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 2.5F, 10.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  blend_modes_state.val.camera = Some(camera)
}

///|
fn example_control_system(world : @ecs_world.World) -> Unit {
  let delta = @time.time_delta_seconds()
  let state = blend_modes_state.val

  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    state.alpha = clamp01(state.alpha + delta)
  } else if @input.key_pressed(@window.KeyCode::ArrowDown) {
    state.alpha = clamp01(state.alpha - delta)
  }

  if @input.key_just_pressed(@window.KeyCode::Space) {
    state.unlit = !state.unlit
  }

  let randomize_colors = @input.key_just_pressed(@window.KeyCode::KeyC)
  if randomize_colors {
    state.color_seed = state.color_seed + 1
  }

  let rotation = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    -delta
  } else {
    0.0F
  }
  state.camera_angle = state.camera_angle + rotation

  guard state.camera is Some(camera_entity) else { return }
  let radius = 10.0F
  let camera_x = @math.sin(state.camera_angle) * radius
  let camera_z = @math.cos(state.camera_angle) * radius
  let tick = world.read_change_tick()
  world
  .get_transform_store()
  .set(
    camera_entity,
    @math.Transform::from_xyz(camera_x, 2.5F, camera_z).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  |> ignore

  let mut color_index = state.color_seed
  for controlled in state.materials {
    if @render3d.standard_material_get(controlled.handle) is Some(material) {
      let mut next_material = material.with_base_color(
        @render2d.Color::new(
          material.base_color.r,
          material.base_color.g,
          material.base_color.b,
          state.alpha,
        ),
      )
      if controlled.allow_color && randomize_colors {
        next_material = next_material.with_base_color(
          palette_color(color_index, state.alpha),
        )
        color_index = color_index + 1
      }
      if controlled.allow_unlit {
        next_material = next_material.with_unlit(state.unlit)
      }
      @render3d.standard_material_set(controlled.handle, next_material)
      |> ignore
    }
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(example_control_system)
  .run()
}
