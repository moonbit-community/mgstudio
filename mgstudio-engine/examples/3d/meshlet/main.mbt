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
/// Port of `bevy/examples/3d/meshlet.rs`.
///
/// Baseline parity: Bevy's experimental meshlet pipeline (`MeshletPlugin`,
/// `MeshletMesh3d`, `MeshletDebugMaterial`, meshlet-processed asset format) is
/// not exposed in current mgstudio render APIs. This port preserves the scene
/// topology (camera/light/5+5 model rows + floor) and maps meshlet rows to a
/// shared high-density proxy mesh with equivalent transform/material patterns.

///|
const PI : Float = 3.141592653589793F

///|
const TWO_PI : Float = 6.283185307179586F

///|
const DIRECTIONAL_LIGHT_ILLUMINANCE : Float = 100_000.0F

///|
const ENVIRONMENT_LIGHT_INTENSITY : Float = 150.0F

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
  let sector_step = TWO_PI / sectors_f

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

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@render3d.ecs_key_global_ambient_light, ambient)
}

///|
fn color_for_row(index : Int) -> @sprite.Color {
  if index == 0 {
    @sprite.Color::new(0.8627451F, 0.1490196F, 0.1490196F, 1.0F)
  } else if index == 1 {
    @sprite.Color::new(0.9176471F, 0.34509805F, 0.047058824F, 1.0F)
  } else if index == 2 {
    @sprite.Color::new(0.98039216F, 0.8F, 0.08235294F, 1.0F)
  } else if index == 3 {
    @sprite.Color::new(0.08627451F, 0.6392157F, 0.2901961F, 1.0F)
  } else {
    @sprite.Color::new(0.007843138F, 0.5176471F, 0.78039217F, 1.0F)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  world.insert_resource(
    @render3d.ecs_key_directional_light_shadow_map,
    @render3d.DirectionalLightShadowMap::new(4096),
  )

  set_global_ambient_light(world, @sprite.Color::white(), 0.0F)
  let camera = @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(1.8F, 0.4F, -0.1F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_msaa)
  .insert(camera, @render3d.Msaa::Off, tick)
  world
  .component(@render3d.ecs_key_environment_map_light)
  .insert(
    camera,
    @render3d.EnvironmentMapLight::default().with_intensity(
      ENVIRONMENT_LIGHT_INTENSITY,
    ),
    tick,
  )
  world
  .component(@render3d.ecs_key_free_camera)
  .insert(camera, @render3d.FreeCamera::default(), tick)

  let directional = world.spawn_empty()
  let cascade_shadow_config = @render3d.CascadeShadowConfigBuilder::default()
    .with_num_cascades(1)
    .with_maximum_distance(15.0F)
    .build()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional,
    @render3d.DirectionalLight::new(
      @sprite.Color::white(),
      DIRECTIONAL_LIGHT_ILLUMINANCE,
      true,
    ).with_cascade_shadow_config(Some(cascade_shadow_config)),
    tick,
  )
  let light_rot = @math.Quat::from_rotation_y(-0.15F * PI).mul(
    @math.Quat::from_rotation_x(-0.15F * PI),
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional,
    @math.Transform::identity().with_rotation(light_rot),
    tick,
  )

  let mesh_proxy = uv_sphere_mesh(1.0F, 36, 56)
  for i in 0..<5 {
    let x_int = i - 2
    let x = float_from_int(x_int) / 2.0F
    let material = @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(color_for_row(i)).with_perceptual_roughness(
        float_from_int(i) / 4.0F,
      ),
    )
    @render3d.MeshMaterial3dBundle::new(
      mesh_proxy,
      @render3d.MeshMaterial3d::new(material),
      @math.Transform::from_xyz(x, 0.0F, -0.3F).with_scale(
        @math.Vec3::splat(0.2F),
      ),
    ).spawn(world)
    |> ignore
  }

  for i in 0..<5 {
    let x_int = i - 2
    let x = float_from_int(x_int) / 2.0F
    let shade = 0.2F + float_from_int(i) * 0.18F
    let material = @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(
        @sprite.Color::new(shade, shade, shade, 1.0F),
      )
      .with_unlit(true)
      .with_emissive(
        @sprite.Color::new(shade * 0.2F, shade * 0.2F, shade * 0.2F, 1.0F),
      ),
    )
    @render3d.MeshMaterial3dBundle::new(
      mesh_proxy,
      @render3d.MeshMaterial3d::new(material),
      @math.Transform::from_xyz(x, 0.0F, 0.3F)
      .with_scale(@math.Vec3::splat(0.2F))
      .with_rotation(@math.Quat::from_rotation_y(PI)),
    ).spawn(world)
    |> ignore
  }

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@sprite.Color::white()).with_perceptual_roughness(
          1.0F,
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
