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
// Bevy source: `bevy/examples/3d/deferred_rendering.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const FRAC_PI_4 : Float = 0.7853981633974483F

///|
struct Pause {
  mut value : Bool
}

///|
let pause_resource_key : @ecs.ResourceKey[Pause] = @ecs.register_resource(
  debug_name="examples.3d.deferred_rendering.Pause",
)

///|
impl @app.Resource for Pause with fn resource() {
  pause_resource_key
}

///|
fn Pause::Pause(value : Bool) -> Pause {
  Pause::{ value, }
}

///|
struct Spin {
  speed : Float
}

///|
let spin_component_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.3d.deferred_rendering.Spin",
)

///|
impl @ecs.Component for Spin with fn component() {
  spin_component_key
}

///|
fn Spin::Spin(speed : Float) -> Spin {
  Spin::{ speed, }
}

///|
priv enum DefaultRenderMode {
  Deferred
  Forward
  ForwardPrepass
}

///|
fn default_render_mode() -> DefaultRenderMode {
  DefaultRenderMode::Deferred
}

///|
impl @app.FromWorld for DefaultRenderMode with fn from_world(_world) {
  default_render_mode()
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_int(value)
}

///|
fn mesh_handle(
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  mesh : @mesh.Mesh,
) -> @asset.Handle[@mesh.Mesh] {
  meshes.modify(fn(assets) { assets.add(mesh) })
}

///|
fn material_handle(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  material : @pbr.StandardMaterial,
) -> @asset.Handle[@pbr.StandardMaterial] {
  materials.modify(fn(assets) { assets.add(material) })
}

///|
fn material_assets_iter_mut(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  materials.modify(fn(assets) { ignore(assets.iter_mut()) })
}

///|
fn add_mesh_from_geometry(
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  geometry : @mesh.Mesh3dGeometry,
) -> @asset.Handle[@mesh.Mesh] {
  mesh_handle(meshes, @mesh.Mesh::from_3d_geometry(geometry))
}

///|
fn cuboid_mesh(x : Float, y : Float, z : Float) -> @mesh.Mesh {
  @mesh.Mesh::from_3d_geometry(
    @mesh_primitives_dim3.Meshable::mesh(@math.Cuboid::new(x, y, z)),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  let asset_server = asset_server.get()
  let camera = commands.spawn(
    @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
        @math.Vec3::new(0.0F, 0.3F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  commands.entity(camera).insert_component(@pbr.Msaa::Off)
  commands
  .entity(camera)
  .insert_component(
    @pbr.DistanceFog::new(
      @color.Color::new(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F, 1.0F),
      @pbr.FogFalloff3d::linear(1.0F, 8.0F),
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
  commands.entity(camera).insert_component(@pbr.DepthPrepass::DepthPrepass())
  commands
  .entity(camera)
  .insert_component(@pbr.MotionVectorPrepass::MotionVectorPrepass())
  commands
  .entity(camera)
  .insert_component(@pbr.DeferredPrepass::DeferredPrepass())
  commands.entity(camera).insert_component(@post_process.Fxaa::Fxaa())

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@color.Color::white(), 15_000.0F, true).with_cascade_shadow_config_builder(
          @pbr.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
          .with_num_cascades(3)
          .with_maximum_distance(10.0F),
        ),
        @transform.Transform::identity().with_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 0.0F, -FRAC_PI_4),
        ),
      ),
    ),
  )

  let helmet_scene = @scene.scene_load_gltf_scene(
    asset_server,
    @gltf.GltfAssetLabel::Scene(0).from_asset(
      "models/FlightHelmet/FlightHelmet.gltf",
    ),
  )
  ignore(commands.spawn_component(@scene.SceneRoot::new(helmet_scene)))
  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(helmet_scene),
        @transform.Transform::from_xyz(-4.0F, 0.0F, -3.0F),
      ),
    ),
  )

  let forward_material = material_handle(
    materials,
    @pbr.StandardMaterial::from_color(@color.Color::srgb(0.1F, 0.2F, 0.1F)).with_opaque_render_method(
      @pbr.OpaqueRendererMethod::Forward,
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          add_mesh_from_geometry(
            meshes,
            @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
              @math.Vec2::new(50.0F, 50.0F),
            ).build(),
          ),
        ),
        @pbr.MeshMaterial3d::new(forward_material),
      ),
    ),
  )

  let cube_h = mesh_handle(meshes, cuboid_mesh(0.1F, 0.1F, 0.1F))
  let sphere_h = add_mesh_from_geometry(
    meshes,
    @mesh_primitives_dim3.SphereMeshBuilder::from_sphere(
      @math.Sphere::new(0.125F),
    ).uv(32, 18),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(cube_h),
        @pbr.MeshMaterial3d::new(forward_material),
        @transform.Transform::from_xyz(-0.3F, 0.5F, -0.2F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(cube_h),
        @pbr.MeshMaterial3d::new(forward_material),
        @transform.Transform::from_xyz(0.2F, 0.5F, 0.2F),
      ),
    ),
  )

  let sphere_color = @color.Color::srgb(10.0F, 4.0F, 1.0F)
  let sphere_pos = @transform.Transform::from_xyz(0.4F, 0.5F, -0.8F)
  let unlit_mat = @pbr.StandardMaterial::from_color(sphere_color).with_unlit(
    true,
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_h),
        @pbr.MeshMaterial3d::new(material_handle(materials, unlit_mat)),
        sphere_pos,
        @pbr.NotShadowCaster::NotShadowCaster(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::PointLight()
        .with_intensity(800.0F)
        .with_radius(0.125F)
        .with_shadow_maps_enabled(true)
        .with_color(sphere_color),
        sphere_pos,
      ),
    ),
  )

  for i in 0..<6 {
    let j = i % 3
    let s_val = if i < 3 { 0.0F } else { 0.2F }
    let material = if j == 0 {
      material_handle(
        materials,
        @pbr.StandardMaterial::from_color(
          @color.Color::srgb(s_val, s_val, 1.0F),
        )
        .with_perceptual_roughness(0.089F)
        .with_metallic(0.0F),
      )
    } else if j == 1 {
      material_handle(
        materials,
        @pbr.StandardMaterial::from_color(
          @color.Color::srgb(s_val, 1.0F, s_val),
        )
        .with_perceptual_roughness(0.089F)
        .with_metallic(0.0F),
      )
    } else {
      material_handle(
        materials,
        @pbr.StandardMaterial::from_color(
          @color.Color::srgb(1.0F, s_val, s_val),
        )
        .with_perceptual_roughness(0.089F)
        .with_metallic(0.0F),
      )
    }
    let jf = float_from_int(j)
    ignore(
      commands.spawn(
        (
          @mesh.Mesh3d::new(sphere_h),
          @pbr.MeshMaterial3d::new(material),
          @transform.Transform::from_xyz(
            jf * 0.25F + (if i < 3 { -0.15F } else { 0.15F }) - 0.4F,
            0.125F,
            -jf * 0.25F + (if i < 3 { -0.15F } else { 0.15F }) + 0.4F,
          ),
        ),
      ),
    )
  }

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh_handle(meshes, cuboid_mesh(2.0F, 1.0F, 1.0F))),
        @pbr.MeshMaterial3d::new(
          material_handle(
            materials,
            @pbr.StandardMaterial::from_color(
              @color.Color::new(
                136.0F / 255.0F,
                136.0F / 255.0F,
                136.0F / 255.0F,
                1.0F,
              ),
            )
            .with_unlit(true)
            .with_cull_mode(None),
          ),
        ),
        @transform.Transform::Transform().with_scale(
          @math.Vec3::splat(1_000_000.0F),
        ),
        @pbr.NotShadowCaster::NotShadowCaster(),
        @pbr.NotShadowReceiver::NotShadowReceiver(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text::Text(),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
      ),
    ),
  )
}

///|
fn animate_light_direction(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@pbr.DirectionalLight],
  ],
  pause : @app.Res[Pause],
) -> Unit {
  if pause.get().value {
    return
  }
  let delta = time.get().delta_seconds() * PI / 5.0F
  try! query.view(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotate_y(delta) })
  })
}

///|
fn setup_parallax(
  commands : @app.Commands,
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let asset_server = asset_server.get()
  let normal_handle = asset_server.load_with_settings(
    "textures/parallax_example/cube_normal.png",
    fn(settings) { settings.is_srgb = false },
  )

  let cube = @mesh.Mesh::from_3d_geometry(
    @mesh_primitives_dim3.Meshable::mesh(@math.Cuboid::new(0.15F, 0.15F, 0.15F)),
  )
  match cube.generate_tangents() {
    Some(_) =>
      abort("deferred_rendering parallax cube tangent generation failed")
    None => ()
  }

  let parallax_material = material_handle(
    materials,
    @pbr.StandardMaterial::StandardMaterial()
    .with_perceptual_roughness(0.4F)
    .with_base_color_texture(
      Some(asset_server.load("textures/parallax_example/cube_color.png")),
    )
    .with_normal_map_texture(Some(normal_handle))
    .with_depth_map(
      Some(asset_server.load("textures/parallax_example/cube_depth.png")),
    )
    .with_parallax_depth_scale(0.09F)
    .with_parallax_mapping_method(@pbr.ParallaxMappingMethod::Relief(4))
    .with_max_parallax_layer_count(@math.pow(2.0F, 5.0F)),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh_handle(meshes, cube)),
        @pbr.MeshMaterial3d::new(parallax_material),
        @transform.Transform::from_xyz(0.4F, 0.2F, -0.8F),
        Spin::Spin(0.3F),
      ),
    ),
  )
}

///|
fn spin(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Spin]),
    @ecs.All,
  ],
  pause : @app.Res[Pause],
) -> Unit {
  if pause.get().value {
    return
  }
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, item) {
    let (transform, spin) = item
    transform.modify(fn(value) {
      value.rotate_local_y(spin.value().speed * delta)
      value.rotate_local_x(spin.value().speed * delta)
      value.rotate_local_z(-spin.value().speed * delta)
    })
  })
}

///|
fn mode_marker(
  current : DefaultRenderMode,
  target : DefaultRenderMode,
) -> String {
  match (current, target) {
    (Deferred, Deferred) => ">"
    (Forward, Forward) => ">"
    (ForwardPrepass, ForwardPrepass) => ">"
    _ => ""
  }
}

///|
fn help_text(mode : DefaultRenderMode, hide_ui : Bool) -> String {
  if hide_ui {
    ""
  } else {
    "(H) Hide UI\n(Space) Play/Pause\n\nRendering Method:\n(1) \{mode_marker(mode, DefaultRenderMode::Deferred)} Deferred\n(2) \{mode_marker(mode, DefaultRenderMode::Forward)} Forward\n(3) \{mode_marker(mode, DefaultRenderMode::ForwardPrepass)} Forward + Prepass"
  }
}

///|
fn switch_mode(
  text : @app.Single[@ecs.Write[@text.Text], @ecs.All],
  commands : @app.Commands,
  keys : @input.ButtonInput[@window.KeyCode],
  default_opaque_renderer_method : @app.ResMut[@pbr.DefaultOpaqueRendererMethod],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  cameras : @ecs.Query[@core.Entity, @ecs.With[@camera_camera.Camera]],
  pause : @app.ResMut[Pause],
  hide_ui : @app.Local[Bool],
  mode : @app.Local[DefaultRenderMode],
) -> Unit {
  let mut next_mode = mode.get()
  let mut next_hide_ui = hide_ui.get()
  let next_pause = pause.get()

  if keys.just_pressed(@window.KeyCode::Space) {
    next_pause.value = !next_pause.value
    pause.set(next_pause)
  }

  if keys.just_pressed(@window.KeyCode::Digit1) {
    next_mode = DefaultRenderMode::Deferred
    default_opaque_renderer_method.set(
      default_opaque_renderer_method.get().set_to_deferred(),
    )
    println("DefaultOpaqueRendererMethod: Deferred")
    material_assets_iter_mut(materials)
    try! cameras.view(fn(camera_entity, _) {
      commands.entity(camera_entity).remove(@pbr.ecs_key_normal_prepass)
      commands
      .entity(camera_entity)
      .insert_component(@pbr.DepthPrepass::DepthPrepass())
      commands
      .entity(camera_entity)
      .insert_component(@pbr.MotionVectorPrepass::MotionVectorPrepass())
      commands
      .entity(camera_entity)
      .insert_component(@pbr.DeferredPrepass::DeferredPrepass())
    })
  }
  if keys.just_pressed(@window.KeyCode::Digit2) {
    next_mode = DefaultRenderMode::Forward
    default_opaque_renderer_method.set(
      default_opaque_renderer_method.get().set_to_forward(),
    )
    println("DefaultOpaqueRendererMethod: Forward")
    material_assets_iter_mut(materials)
    try! cameras.view(fn(camera_entity, _) {
      commands.entity(camera_entity).remove(@pbr.ecs_key_normal_prepass)
      commands.entity(camera_entity).remove(@pbr.ecs_key_depth_prepass)
      commands.entity(camera_entity).remove(@pbr.ecs_key_motion_vector_prepass)
      commands.entity(camera_entity).remove(@pbr.ecs_key_deferred_prepass)
    })
  }
  if keys.just_pressed(@window.KeyCode::Digit3) {
    next_mode = DefaultRenderMode::ForwardPrepass
    default_opaque_renderer_method.set(
      default_opaque_renderer_method.get().set_to_forward(),
    )
    println("DefaultOpaqueRendererMethod: Forward + Prepass")
    material_assets_iter_mut(materials)
    try! cameras.view(fn(camera_entity, _) {
      commands
      .entity(camera_entity)
      .insert_component(@pbr.NormalPrepass::NormalPrepass())
      commands
      .entity(camera_entity)
      .insert_component(@pbr.DepthPrepass::DepthPrepass())
      commands
      .entity(camera_entity)
      .insert_component(@pbr.MotionVectorPrepass::MotionVectorPrepass())
      commands.entity(camera_entity).remove(@pbr.ecs_key_deferred_prepass)
    })
  }

  if keys.just_pressed(@window.KeyCode::KeyH) {
    next_hide_ui = !next_hide_ui
  }

  text.get().set(@text.Text::new(help_text(next_mode, next_hide_ui)))
  hide_ui.set(next_hide_ui)
  mode.set(next_mode)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@pbr.DefaultOpaqueRendererMethod::deferred())
  .insert_resource(@pbr.DirectionalLightShadowMap::new(4096))
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(Pause::Pause(true))
  .add_systems_param4(@app.Startup, setup)
  .add_systems_param4(@app.Startup, setup_parallax)
  .add_systems_param3(@app.Update, animate_light_direction)
  .add_systems_param9(@app.Update, switch_mode)
  .add_systems_param3(@app.Update, spin)
  .run()
}
