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
priv struct TransparencyState {
  materials : Array[@asset.Handle[@render3d.StandardMaterial]]
}

///|
let transparency_state : Ref[TransparencyState] = Ref::new({ materials: [] })

///|
pub fn app_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(transparency_setup)
  .add_system(transparency_fade_system)
  .run()
}

///|
fn spawn_transparency_mesh(
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
  transparency_state.val.materials.push(material)
}

///|
fn transparency_setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(a) {
    a.val = @render3d.GlobalAmbientLight::new(@render2d.Color::white(), 0.45F)
  }

  let point = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      180000.0F,
      2000.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(point, @math.Transform::from_xyz(260.0F, 320.0F, 260.0F), tick)

  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.32F, 0.48F, 0.32F, 1.0F),
    ),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(900.0F, 900.0F),
    @render3d.MeshMaterial3d::new(floor_material),
    @math.Transform::from_xyz(0.0F, -150.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let mask_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.2F, 0.8F, 0.2F, 0.0F),
    ).with_alpha_mode(@render3d.AlphaMode3d::Mask(0.5F)),
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
  let additive_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.6F, 0.2F, 0.0F),
    ).with_alpha_mode(@render3d.AlphaMode3d::Add),
  )

  spawn_transparency_mesh(
    world,
    @render3d.Mesh3d::from_tetrahedron(140.0F),
    mask_material,
    @math.Transform::from_xyz(-240.0F, -40.0F, -120.0F),
  )
  spawn_transparency_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(120.0F, 120.0F, 120.0F),
    blend_material,
    @math.Transform::from_xyz(-70.0F, -40.0F, 0.0F),
  )
  spawn_transparency_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(120.0F, 120.0F, 120.0F),
    alpha_to_coverage_material,
    @math.Transform::from_xyz(100.0F, -40.0F, 120.0F),
  )
  spawn_transparency_mesh(
    world,
    @render3d.Mesh3d::from_tetrahedron(150.0F),
    additive_material,
    @math.Transform::from_xyz(270.0F, -40.0F, -20.0F),
  )

  let opaque_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.8F, 0.2F, 0.2F, 1.0F),
    ),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(110.0F, 110.0F, 110.0F),
    @render3d.MeshMaterial3d::new(opaque_material),
    @math.Transform::from_xyz(0.0F, -40.0F, -210.0F),
  ).spawn(world)
  |> ignore

  let camera = @render2d.Camera::default()
  @render3d.Camera3dBundle::new(
    camera,
    @math.Transform::from_xyz(-60.0F, 180.0F, 760.0F).looking_at(
      @math.Vec3::new(20.0F, -40.0F, -60.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn transparency_fade_system(_world : @ecs_world.World) -> Unit {
  let alpha = 0.5F + 0.5F * @math.sin(@time.time_elapsed_seconds())
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

///|
fn main {
  app_main()
}
