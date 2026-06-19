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
// Bevy source: `bevy/examples/3d/clearcoat.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const SPHERE_SCALE : Float = 0.9F

///|
const SPHERE_ROTATION_SPEED : Float = 0.8F

///|
priv enum LightMode {
  Point
  Directional
}

///|
let light_mode_resource_key : @ecs.ResourceKey[LightMode] = @ecs.register_resource(
  debug_name="examples.3d.clearcoat.LightMode",
)

///|
impl @app.Resource for LightMode with fn resource() {
  light_mode_resource_key
}

///|
priv struct ExampleSphere {}

///|
let example_sphere_component_key : @ecs.ComponentKey[ExampleSphere] = @ecs.register_component(
  debug_name="examples.3d.clearcoat.ExampleSphere",
)

///|
impl @ecs.Component for ExampleSphere with fn component() {
  example_sphere_component_key
}

///|
fn LightMode::create_help_text(self : LightMode) -> @text.Text {
  let help_text = match self {
    Point => "Press Space to switch to a directional light"
    Directional => "Press Space to switch to a point light"
  }
  @text.Text::new(help_text)
}

///|
fn create_point_light() -> @pbr.PointLight {
  @pbr.PointLight::PointLight()
  .with_color(@color.Color::white())
  .with_intensity(100_000.0F)
}

///|
fn create_directional_light() -> @pbr.DirectionalLight {
  @pbr.DirectionalLight::new(@color.Color::white(), 1000.0F, false)
}

///|
fn create_sphere_mesh(
  meshes : @asset.Assets[@mesh.Mesh],
) -> @asset.Handle[@mesh.Mesh] {
  let sphere_mesh = @mesh_primitives_dim3.Meshable::mesh(
    @math.Sphere::new(1.0F),
  )
  match sphere_mesh.generate_tangents() {
    Some(_) => abort("Failed to generate tangents")
    None => ()
  }
  meshes.add(@mesh.Mesh::from_3d_geometry(sphere_mesh))
}

///|
fn spawn_car_paint_sphere(
  commands : @app.Commands,
  materials : @asset.Assets[@pbr.StandardMaterial],
  asset_server : @asset.AssetServer,
  sphere : @asset.Handle[@mesh.Mesh],
) -> Unit {
  let material = materials.add(
    @pbr.StandardMaterial::from_color(@color.Color::new(0.0F, 0.0F, 1.0F, 1.0F))
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.1F)
    .with_normal_map_texture(
      Some(
        asset_server.load_with_settings("textures/BlueNoise-Normal.png", fn(
          settings,
        ) {
          settings.is_srgb = false
        }),
      ),
    )
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.5F),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(-1.0F, 1.0F, 0.0F).with_scale(
          @math.Vec3::splat(SPHERE_SCALE),
        ),
        ExampleSphere::{  },
      ),
    ),
  )
}

///|
fn spawn_coated_glass_bubble_sphere(
  commands : @app.Commands,
  materials : @asset.Assets[@pbr.StandardMaterial],
  sphere : @asset.Handle[@mesh.Mesh],
) -> Unit {
  let material = materials.add(
    @pbr.StandardMaterial::from_color(@color.Color::new(0.9F, 0.9F, 0.9F, 0.3F))
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.1F)
    .with_metallic(0.5F)
    .with_perceptual_roughness(0.1F)
    .with_alpha_mode(@pbr.AlphaMode3d::Blend),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(-1.0F, -1.0F, 0.0F).with_scale(
          @math.Vec3::splat(SPHERE_SCALE),
        ),
        ExampleSphere::{  },
      ),
    ),
  )
}

///|
fn spawn_golf_ball(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server,
            @gltf.GltfAssetLabel::Scene(0).from_asset(
              "models/GolfBall/GolfBall.glb",
            ),
          ),
        ),
        @transform.Transform::from_xyz(1.0F, 1.0F, 0.0F).with_scale(
          @math.Vec3::splat(SPHERE_SCALE),
        ),
        ExampleSphere::{  },
      ),
    ),
  )
}

///|
fn spawn_scratched_gold_ball(
  commands : @app.Commands,
  materials : @asset.Assets[@pbr.StandardMaterial],
  asset_server : @asset.AssetServer,
  sphere : @asset.Handle[@mesh.Mesh],
) -> Unit {
  let material = materials.add(
    @pbr.StandardMaterial::from_color(
      @color.Color::new(1.0F, 0.843F, 0.0F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.3F)
    .with_clearcoat_normal_texture(
      Some(
        asset_server.load_with_settings("textures/ScratchedGold-Normal.png", fn(
          settings,
        ) {
          settings.is_srgb = false
        }),
      ),
    )
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.1F),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(1.0F, -1.0F, 0.0F).with_scale(
          @math.Vec3::splat(SPHERE_SCALE),
        ),
        ExampleSphere::{  },
      ),
    ),
  )
}

///|
fn spawn_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn((create_point_light(), @transform.Transform::identity())),
  )
}

///|
fn spawn_camera(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let camera = commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @pbr.Hdr::Hdr(),
      @camera.Projection::Perspective(@camera.PerspectiveProjection3d::{
        ..@pbr.PerspectiveProjection3d::PerspectiveProjection3d(),
        fov: 27.0F / 180.0F * PI,
      }),
      @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F),
      @post_process.Tonemapping::AcesFitted,
    ),
  )
  commands
  .entity(camera)
  .insert_component(
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      5000.0F,
    ),
  )
  commands
  .entity(camera)
  .insert_component(
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      2000.0F,
    ),
  )
}

///|
fn spawn_text(commands : @app.Commands, light_mode : LightMode) -> Unit {
  ignore(
    commands.spawn(
      (
        light_mode.create_help_text(),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_bottom(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
  light_mode : @app.Res[LightMode],
) -> Unit {
  let sphere = create_sphere_mesh(meshes.peek())
  spawn_car_paint_sphere(commands, materials.peek(), asset_server.get(), sphere)
  spawn_coated_glass_bubble_sphere(commands, materials.peek(), sphere)
  spawn_golf_ball(commands, asset_server.get())
  spawn_scratched_gold_ball(
    commands,
    materials.peek(),
    asset_server.get(),
    sphere,
  )

  spawn_light(commands)
  spawn_camera(commands, asset_server.get())
  spawn_text(commands, light_mode.get())
}

///|
fn animate_light(
  lights : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.Or[(@ecs.With[@pbr.PointLight], @ecs.With[@pbr.DirectionalLight])],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let now = time.get().elapsed_seconds()
  let translation = @math.Vec3::new(
    @math.sin(now * 1.4F),
    @math.cos(now * 1.0F),
    @math.cos(now * 0.6F),
  ).mul(@math.Vec3::new(3.0F, 4.0F, 3.0F))
  try! lights.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      let next = @transform.Transform::from_xyz(
        translation.x,
        translation.y,
        translation.z,
      ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
      value.translation = next.translation
      value.rotation = next.rotation
    })
  })
}

///|
fn animate_spheres(
  spheres : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[ExampleSphere],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let now = time.get().elapsed_seconds()
  let rotation = @math.Quat::from_rotation_y(SPHERE_ROTATION_SPEED * now)
  try! spheres.view(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotation = rotation })
  })
}

///|
fn handle_input(
  commands : @app.Commands,
  light_query : @ecs.Query[
    @core.Entity,
    @ecs.Or[(@ecs.With[@pbr.PointLight], @ecs.With[@pbr.DirectionalLight])],
  ],
  keyboard : @input.ButtonInput[@window.KeyCode],
  light_mode : @app.ResMut[LightMode],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Space) {
    return
  }

  try! light_query.view(fn(light, _entity) {
    match light_mode.peek() {
      Point => {
        light_mode.set(LightMode::Directional)
        commands.entity(light).remove(@pbr.ecs_key_point_light)
        commands.entity(light).insert_component(create_directional_light())
      }
      Directional => {
        light_mode.set(LightMode::Point)
        commands.entity(light).remove(@pbr.ecs_key_directional_light)
        commands.entity(light).insert_component(create_point_light())
      }
    }
  })
}

///|
fn update_help_text(
  text_query : @ecs.Query[@ecs.Write[@text.Text], @ecs.All],
  light_mode : @app.Res[LightMode],
) -> Unit {
  try! text_query.view(fn(_entity, text) {
    text.set(light_mode.get().create_help_text())
  })
}

///|
fn main {
  let handle_input_system : @app.SystemConfig[@ecs.World] = @app.system_config_param4(
    handle_input,
  )
  let update_help_text_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    update_help_text,
  )
  @app.App::new(@ecs.World::new())
  .insert_resource(LightMode::Point)
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param5(@app.Startup, setup)
  .add_systems_param2(@app.Update, animate_light)
  .add_systems_param2(@app.Update, animate_spheres)
  .add_systems(
    @app.Update,
    (handle_input_system, update_help_text_system) |> @app.chain(),
  )
  .run()
}
