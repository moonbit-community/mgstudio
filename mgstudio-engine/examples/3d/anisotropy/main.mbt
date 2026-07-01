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
// Bevy source: `bevy/examples/3d/anisotropy.rs`.

///|
const CAMERA_INITIAL_X : Float = -0.4F

///|
const CAMERA_INITIAL_Y : Float = 0.0F

///|
const CAMERA_INITIAL_Z : Float = 0.0F

///|
const SKYBOX_BRIGHTNESS : Float = 5000.0F

///|
const ENVIRONMENT_MAP_INTENSITY : Float = 2500.0F

///|
const SPHERE_BASE_R : Float = 0.81960786F

///|
const SPHERE_BASE_G : Float = 0.8352941F

///|
const SPHERE_BASE_B : Float = 0.85882354F

///|
priv struct AppStatus {
  mut light_mode : LightMode
  mut anisotropy_enabled : Bool
  mut visible_scene : Scene
}

///|
priv struct CameraStopwatch {
  stopwatch : @time.Stopwatch
}

///|
fn CameraStopwatch::CameraStopwatch() -> CameraStopwatch {
  CameraStopwatch::{ stopwatch: @time.Stopwatch::new() }
}

///|
impl @app.FromWorld for CameraStopwatch with fn from_world(_world) {
  CameraStopwatch::CameraStopwatch()
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.anisotropy.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  AppStatus::{
    light_mode: LightMode::Directional,
    anisotropy_enabled: true,
    visible_scene: Scene::BarnLamp,
  }
}

///|
priv enum LightMode {
  Directional
  Point
  EnvironmentMap
} derive(Eq)

///|
priv struct MaterialVariants {
  anisotropic : @asset.Handle[@pbr.StandardMaterial]
  isotropic : @asset.Handle[@pbr.StandardMaterial]
}

///|
let material_variants_component_key : @ecs.ComponentKey[MaterialVariants] = @ecs.register_component(
  debug_name="examples.3d.anisotropy.MaterialVariants",
)

///|
impl @ecs.Component for MaterialVariants with fn component() {
  material_variants_component_key
}

///|
priv enum Scene {
  BarnLamp
  Sphere
} derive(Eq)

///|
let scene_component_key : @ecs.ComponentKey[Scene] = @ecs.register_component(
  debug_name="examples.3d.anisotropy.Scene",
)

///|
impl @ecs.Component for Scene with fn component() {
  scene_component_key
}

///|
fn Scene::next(self : Scene) -> Scene {
  match self {
    BarnLamp => Scene::Sphere
    Sphere => Scene::BarnLamp
  }
}

///|
fn Scene::display(self : Scene) -> String {
  match self {
    BarnLamp => "Barn Lamp"
    Sphere => "Sphere"
  }
}

///|
fn camera_initial_position() -> @math.Vec3 {
  @math.Vec3::new(CAMERA_INITIAL_X, CAMERA_INITIAL_Y, CAMERA_INITIAL_Z)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn AppStatus::create_help_text(self : AppStatus) -> @text.Text {
  let material_variant_help_text = if self.anisotropy_enabled {
    "Press Enter to disable anisotropy"
  } else {
    "Press Enter to enable anisotropy"
  }

  let light_help_text = match self.light_mode {
    Directional => "Press Space to switch to a point light"
    Point => "Press Space to switch to an environment map"
    EnvironmentMap => "Press Space to switch to a directional light"
  }

  let mesh_help_text = "Press Q to change to \{self.visible_scene.next().display()}"
  @text.Text::new(
    "\{material_variant_help_text}\n\{light_help_text}\n\{mesh_help_text}",
  )
}

///|
fn add_skybox_and_environment_map(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
  entity : @core.Entity,
) -> Unit {
  commands
  .entity(entity)
  .insert_component(
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      SKYBOX_BRIGHTNESS,
    ),
  )
  commands
  .entity(entity)
  .insert_component(
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      ENVIRONMENT_MAP_INTENSITY,
    ),
  )
}

///|
fn spawn_directional_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@color.Color::white(), 3000.0F, false),
        @transform.Transform::identity(),
      ),
    ),
  )
}

///|
fn spawn_point_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::PointLight()
        .with_color(@color.Color::white())
        .with_intensity(200_000.0F),
        @transform.Transform::identity(),
      ),
    ),
  )
}

///|
fn spawn_text(commands : @app.Commands, app_status : AppStatus) -> Unit {
  ignore(
    commands.spawn(
      (
        app_status.create_help_text(),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_bottom(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
      ),
    ),
  )
}

///|
fn create_anisotropy_sphere_mesh(
  asset_server : @asset.AssetServer,
) -> @asset.Handle[@mesh.Mesh] {
  let sphere_mesh = @mesh_primitives_dim3.Meshable::mesh(
    @math.Sphere::new(0.1F),
  )
  match sphere_mesh.generate_tangents() {
    Some(_) => abort("anisotropy sphere tangents should generate")
    None => ()
  }
  asset_server.add(@mesh.Mesh::from_3d_geometry(sphere_mesh))
}

///|
fn create_anisotropy_sphere_material(
  asset_server : @asset.AssetServer,
) -> @asset.Handle[@pbr.StandardMaterial] {
  asset_server.add(
    @pbr.StandardMaterial::from_color(
      @color.Color::new(SPHERE_BASE_R, SPHERE_BASE_G, SPHERE_BASE_B, 1.0F),
    )
    .with_anisotropy_rotation(0.5F)
    .with_anisotropy_strength(1.0F),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  app_status : @app.Res[AppStatus],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(
          CAMERA_INITIAL_X,
          CAMERA_INITIAL_Y,
          CAMERA_INITIAL_Z,
        ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
      ),
    ),
  )

  spawn_directional_light(commands)

  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server.get(),
            @gltf.GltfAssetLabel::Scene(0).from_asset(
              "models/AnisotropyBarnLamp/AnisotropyBarnLamp.gltf",
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, 0.07F, -0.13F),
        Scene::BarnLamp,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(create_anisotropy_sphere_mesh(asset_server.get())),
        @pbr.MeshMaterial3d::new(
          create_anisotropy_sphere_material(asset_server.get()),
        ),
        Scene::Sphere,
        @visibility.Visibility::Hidden,
      ),
    ),
  )

  spawn_text(commands, app_status.get())
}

///|
fn create_material_variants(
  commands : @app.Commands,
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  new_meshes : @ecs.Query[
    (@ecs.Read[@pbr.MeshMaterial3d], @ecs.Read[@pbr.MeshMaterial3d]),
    (@ecs.Added[@pbr.MeshMaterial3d], @ecs.Without[MaterialVariants]),
  ],
) -> Unit {
  try! new_meshes.view(fn(entity, data) {
    let (anisotropic_material_handle, _) = data
    guard materials.peek().get(anisotropic_material_handle.value().material)
      is Some(anisotropic_material) else {
      return
    }
    let isotropic = materials.modify(fn(assets) {
      assets.add(
        anisotropic_material
        .with_anisotropy_texture(None)
        .with_anisotropy_strength(0.0F)
        .with_anisotropy_rotation(0.0F),
      )
    })
    commands
    .entity(entity)
    .insert_component(MaterialVariants::{
      anisotropic: anisotropic_material_handle.value().material,
      isotropic,
    })
  })
}

///|
fn animate_light(
  lights : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.Or[(@ecs.With[@pbr.DirectionalLight], @ecs.With[@pbr.PointLight])],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let now = time.get().elapsed_seconds()
  let translation = @math.Vec3::new(@math.cos(now), 1.0F, @math.sin(now)).mul(
    @math.Vec3::new(3.0F, 4.0F, 3.0F),
  )
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
fn rotate_camera(
  camera : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
  app_status : @app.Res[AppStatus],
  time : @app.Res[@time.Time[Unit]],
  stopwatch : @app.Local[CameraStopwatch],
) -> Unit {
  if app_status.get().light_mode == LightMode::EnvironmentMap {
    stopwatch.set(CameraStopwatch::{
      stopwatch: stopwatch.get().stopwatch.tick(time.get().delta()),
    })
  }

  let now = stopwatch.get().stopwatch.elapsed_seconds()
  let rotated_position = quat_rotate_vec3(
    @math.Quat::from_rotation_y(now),
    camera_initial_position(),
  )
  try! camera.view(fn(_entity, transform) {
    transform.set(
      @transform.Transform::from_xyz(
        rotated_position.x,
        rotated_position.y,
        rotated_position.z,
      ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    )
  })
}

///|
fn handle_input(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  cameras : @ecs.Query[@core.Entity, @ecs.With[@camera.Camera3d]],
  lights : @ecs.Query[
    @core.Entity,
    @ecs.Or[(@ecs.With[@pbr.DirectionalLight], @ecs.With[@pbr.PointLight])],
  ],
  meshes : @ecs.Query[
    (@ecs.Write[@pbr.MeshMaterial3d], @ecs.Read[MaterialVariants]),
    @ecs.All,
  ],
  scenes : @ecs.Query[
    (@ecs.Write[@visibility.Visibility], @ecs.Read[Scene]),
    @ecs.All,
  ],
  keyboard : @input.ButtonInput[@window.KeyCode],
  app_status : @app.ResMut[AppStatus],
) -> Unit {
  if keyboard.just_pressed(@window.KeyCode::Space) {
    let status = app_status.peek()
    match status.light_mode {
      Directional => {
        status.light_mode = LightMode::Point
        app_status.set(status)
        try! lights.view(fn(light, _entity) { commands.entity(light).despawn() })
        spawn_point_light(commands)
      }
      Point => {
        status.light_mode = LightMode::EnvironmentMap
        app_status.set(status)
        try! lights.view(fn(light, _entity) { commands.entity(light).despawn() })
        try! cameras.view(fn(camera, _entity) {
          add_skybox_and_environment_map(commands, asset_server.get(), camera)
        })
      }
      EnvironmentMap => {
        status.light_mode = LightMode::Directional
        app_status.set(status)
        try! cameras.view(fn(camera, _entity) {
          commands.entity(camera).remove(@pbr.ecs_key_skybox)
          commands.entity(camera).remove(@pbr.ecs_key_environment_map_light)
        })
        spawn_directional_light(commands)
      }
    }
  }

  if keyboard.just_pressed(@window.KeyCode::Enter) {
    let status = app_status.peek()
    status.anisotropy_enabled = !status.anisotropy_enabled
    app_status.set(status)
    try! meshes.view(fn(_entity, data) {
      let (material_handle, material_variants) = data
      material_handle.set(
        @pbr.MeshMaterial3d::new(
          if status.anisotropy_enabled {
            material_variants.value().anisotropic
          } else {
            material_variants.value().isotropic
          },
        ),
      )
    })
  }

  if keyboard.just_pressed(@window.KeyCode::KeyQ) {
    let status = app_status.peek()
    status.visible_scene = status.visible_scene.next()
    app_status.set(status)
    try! scenes.view(fn(_entity, data) {
      let (visibility, scene) = data
      let new_visibility = if scene.value() == status.visible_scene {
        @visibility.Visibility::Inherited
      } else {
        @visibility.Visibility::Hidden
      }
      visibility.set(new_visibility)
    })
  }
}

///|
fn update_help_text(
  text_query : @ecs.Query[@ecs.Write[@text.Text], @ecs.All],
  app_status : @app.Res[AppStatus],
) -> Unit {
  try! text_query.view(fn(_entity, text) {
    text.set(app_status.get().create_help_text())
  })
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "mgstudio Anisotropy Example"
  window
}

///|
fn main {
  let handle_input_system : @app.SystemConfig[@ecs.World] = @app.system_config_param8(
    handle_input,
  )
  let update_help_text_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    update_help_text,
  )
  @app.App::new(@ecs.World::new())
  .insert_resource(AppStatus::AppStatus())
  .add_plugins(
    @mgstudio.DefaultPlugins::build()
    .set(@window.WindowPlugin::{
      ..@window.WindowPlugin::WindowPlugin(),
      primary_window: Some(configured_window()),
    })
    .set(
      @pbr.PbrPlugin::PbrPlugin().with_standard_material_texture_features(
        @pbr.StandardMaterialTextureFeatureSet::StandardMaterialTextureFeatureSet(
          pbr_anisotropy_texture=true,
        ),
      ),
    ),
  )
  .add_systems_param3(@app.Startup, setup)
  .add_systems_param3(@app.Update, create_material_variants)
  .add_systems_param2(@app.Update, animate_light)
  .add_systems_param4(@app.Update, rotate_camera)
  .add_systems(
    @app.Update,
    (handle_input_system, update_help_text_system) |> @app.chain(),
  )
  .run()
}
