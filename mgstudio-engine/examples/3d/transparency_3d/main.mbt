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
/// Port of `bevy/examples/3d/transparency_3d.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const TAU : Float = 6.283185307179586F

///|
priv struct TransparencyState {
  mut materials : Array[@asset.Handle[@render3d.StandardMaterial]]
}

///|
let transparency_state : Ref[TransparencyState] = Ref::new({ materials: [] })

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(fade_transparency)
  .run()
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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

  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
    ),
  )
  let mask_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.2F, 0.7F, 0.1F, 0.0F),
    ).with_alpha_mode(@render3d.AlphaMode3d::Mask(0.5F)),
  )
  let mask_unlit_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.2F, 0.7F, 0.1F, 0.0F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Mask(0.5F))
    .with_unlit(true),
  )
  let blend_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.5F, 0.5F, 1.0F, 0.0F),
    ).with_alpha_mode(@render3d.AlphaMode3d::Blend),
  )
  let alpha_to_coverage_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.5F, 1.0F, 0.5F, 0.0F),
    ).with_alpha_mode(@render3d.AlphaMode3d::AlphaToCoverage),
  )
  let opaque_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.7F, 0.2F, 0.1F, 1.0F),
    ),
  )

  transparency_state.val.materials = [
    floor_material, mask_material, mask_unlit_material, blend_material, alpha_to_coverage_material,
    opaque_material,
  ]

  let sphere_mesh = uv_sphere_mesh(0.5F, 16, 24)
  let cube_mesh = @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F)

  // Opaque plane.
  spawn_mesh(
    world,
    @render3d.Mesh3d::from_plane(6.0F, 6.0F),
    floor_material,
    @math.Transform::identity(),
  )

  // Transparent mask spheres.
  spawn_mesh(
    world,
    sphere_mesh,
    mask_material,
    @math.Transform::from_xyz(1.0F, 0.5F, -1.5F),
  )
  spawn_mesh(
    world,
    sphere_mesh,
    mask_unlit_material,
    @math.Transform::from_xyz(-1.0F, 0.5F, -1.5F),
  )

  // Transparent blend cube.
  spawn_mesh(
    world,
    cube_mesh,
    blend_material,
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  )

  // Transparent alpha-to-coverage cube.
  spawn_mesh(
    world,
    cube_mesh,
    alpha_to_coverage_material,
    @math.Transform::from_xyz(-1.5F, 0.5F, 0.0F),
  )

  // Opaque sphere.
  spawn_mesh(
    world,
    sphere_mesh,
    opaque_material,
    @math.Transform::from_xyz(0.0F, 0.5F, -1.5F),
  )

  let point = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      1_000_000.0F,
      20.0F,
      true,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 3.0F, 5.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn fade_transparency(_world : @ecs_world.World) -> Unit {
  let alpha = @math.sin(@time.time_elapsed_seconds()) / 2.0F + 0.5F
  for handle in transparency_state.val.materials {
    if @render3d.standard_material_get(handle) is Some(material) {
      let next_color = @render2d.Color::new(
        material.base_color.r,
        material.base_color.g,
        material.base_color.b,
        alpha,
      )
      let next_material = material.with_base_color(next_color)
      @render3d.standard_material_set(handle, next_material) |> ignore
    }
  }
}
