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
///
/// Bevy source: `bevy/examples/3d/meshlet.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const BUNNY_MESHLET_ASSET : String = "meshlet/bunny.meshlet_mesh"

///|
const ENV_DIFFUSE_MAP_ASSET : String = "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"

///|
const ENV_SPECULAR_MAP_ASSET : String = "environment_maps/pisa_specular_rgb9e5_zstd.ktx2"

///|
const DIRECTIONAL_LIGHT_ILLUMINANCE : Float = 100_000.0F

///|
const ENVIRONMENT_LIGHT_INTENSITY : Float = 150.0F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn spawn_meshlet_bunny(
  world : @ecs.World,
  meshlet_mesh : @asset.Handle[@pbr_meshlet.MeshletMesh],
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @transform.Transform,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @pbr_meshlet.ecs_key_meshlet_mesh3d,
    @pbr_meshlet.MeshletMesh3d::new(meshlet_mesh.id()),
  )
  try! world.set_by_key(
    entity,
    @pbr.ecs_key_mesh_material3d,
    @pbr.MeshMaterial3d::new(material),
  )
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_render_layers,
    @sprite.RenderLayers::RenderLayers(),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Inherited,
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(entity, @transform.ecs_key_transform, transform)
  entity
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  world.insert_resource(
    @pbr.ecs_key_directional_light_shadow_map,
    @pbr.DirectionalLightShadowMap::new(4096),
  )

  let camera = @camera.Camera3dBundle::new(
    @sprite.Camera::Camera(),
    @transform.Transform::from_xyz(1.8F, 0.4F, -0.1F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load(ENV_DIFFUSE_MAP_ASSET)),
      Some(asset_server.load(ENV_SPECULAR_MAP_ASSET)),
      ENVIRONMENT_LIGHT_INTENSITY,
    ),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_free_camera,
    @pbr.FreeCamera::FreeCamera(),
  )

  let directional = world.spawn_empty()
  let cascade_shadow_config = @pbr.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(1)
    .with_maximum_distance(15.0F)
    .build()
  try! world.set_by_key(
    directional,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(
      @sprite.Color::white(),
      DIRECTIONAL_LIGHT_ILLUMINANCE,
      true,
    ).with_cascade_shadow_config(Some(cascade_shadow_config)),
  )
  let light_rot = @math.Quat::from_rotation_y(-0.15F * PI).mul(
    @math.Quat::from_rotation_x(-0.15F * PI),
  )
  try! world.set_by_key(
    directional,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_rotation(light_rot),
  )

  let meshlet_mesh : @asset.Handle[@pbr_meshlet.MeshletMesh] = @asset.asset_world_load(
    world,
    BUNNY_MESHLET_ASSET,
  )
  for i in 0..<5 {
    let x_int = i - 2
    let x = float_from_int(x_int) / 2.0F
    let material = @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(color_for_row(i)).with_perceptual_roughness(
        float_from_int(i) / 4.0F,
      ),
    )
    spawn_meshlet_bunny(
      world,
      meshlet_mesh,
      material,
      @transform.Transform::from_xyz(x, 0.0F, -0.3F).with_scale(
        @math.Vec3::splat(0.2F),
      ),
    )
    |> ignore
  }

  for i in 0..<5 {
    let x_int = i - 2
    let x = float_from_int(x_int) / 2.0F
    let shade = 0.2F + float_from_int(i) * 0.18F
    let material = @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(shade, shade, shade, 1.0F),
      )
      .with_unlit(true)
      .with_emissive(
        @sprite.Color::new(shade * 0.2F, shade * 0.2F, shade * 0.2F, 1.0F),
      ),
    )
    spawn_meshlet_bunny(
      world,
      meshlet_mesh,
      material,
      @transform.Transform::from_xyz(x, 0.0F, 0.3F)
      .with_scale(@math.Vec3::splat(0.2F))
      .with_rotation(@math.Quat::from_rotation_y(PI)),
    )
    |> ignore
  }

  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(5.0F, 5.0F),
          ).build(),
        )
      }),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_perceptual_roughness(
          1.0F,
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@pbr_meshlet.MeshletPlugin::new(16_384))
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
