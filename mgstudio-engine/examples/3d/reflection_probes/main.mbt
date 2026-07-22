// Copyright 2025 International Digital Economy Academy
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
/// This example shows how to place reflection probes in the scene.
///
/// Bevy source: `bevy/examples/3d/reflection_probes.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const ENV_MAP_INTENSITY : Float = 5000.0F

///|
const STOP_ROTATION_HELP_TEXT : String = "Press Enter to stop rotation"

///|
const START_ROTATION_HELP_TEXT : String = "Press Enter to start rotation"

///|
const REFLECTION_MODE_HELP_TEXT : String = "Press Space to switch reflection mode"

///|
const CUBES_SCENE_ASSET : String = "models/cubes/Cubes.glb"

///|
const DIFFUSE_ENV_MAP_ASSET : String = "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"

///|
const SPECULAR_ENV_MAP_ASSET : String = "environment_maps/pisa_specular_rgb9e5_zstd.ktx2"

///|
const SPECULAR_REFLECTION_PROBE_ASSET : String = "environment_maps/cubes_reflection_probe_specular_rgb9e5_zstd.ktx2"

///|
enum ReflectionMode {
  EnvironmentMap
  ReflectionProbe
  GeneratedEnvironmentMap
} derive(Eq, Debug)

///|
fn ReflectionMode::next(self : ReflectionMode) -> ReflectionMode {
  match self {
    EnvironmentMap => ReflectionProbe
    ReflectionProbe => GeneratedEnvironmentMap
    GeneratedEnvironmentMap => EnvironmentMap
  }
}

///|
fn ReflectionMode::to_string(self : ReflectionMode) -> String {
  match self {
    EnvironmentMap => "Environment map"
    ReflectionProbe => "Reflection probe"
    GeneratedEnvironmentMap => "Generated environment map"
  }
}

///|
struct AppStatus {
  mut reflection_mode : ReflectionMode
  mut rotating : Bool
  mut sphere_roughness : Float
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  { reflection_mode: ReflectionProbe, rotating: false, sphere_roughness: 0.2F }
}

///|
fn help_float_2(value : Float) -> String {
  let scaled = (value * 100.0F).round().to_int()
  let whole = scaled / 100
  let fraction = scaled % 100
  let fraction_text = if fraction < 10 {
    "0\{fraction}"
  } else {
    fraction.to_string()
  }
  "\{whole}.\{fraction_text}"
}

///|
fn AppStatus::create_text(self : AppStatus) -> @text.Text {
  let rotation_help_text = if self.rotating {
    STOP_ROTATION_HELP_TEXT
  } else {
    START_ROTATION_HELP_TEXT
  }
  @text.Text::new(
    "\{self.reflection_mode.to_string()}\n\{rotation_help_text}\nRoughness: \{help_float_2(self.sphere_roughness)}\n\{REFLECTION_MODE_HELP_TEXT}\nUp/Down arrows to change roughness",
  )
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.reflection_probes.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
struct Cubemaps {
  diffuse_environment_map : @asset.Handle[@asset.Image]
  specular_environment_map : @asset.Handle[@asset.Image]
  specular_reflection_probe : @asset.Handle[@asset.Image]
}

///|
fn Cubemaps::from_asset_server(asset_server : @asset.AssetServer) -> Cubemaps {
  {
    diffuse_environment_map: asset_server.load_image(DIFFUSE_ENV_MAP_ASSET),
    specular_environment_map: asset_server.load_image(SPECULAR_ENV_MAP_ASSET),
    specular_reflection_probe: asset_server.load_image(
      SPECULAR_REFLECTION_PROBE_ASSET,
    ),
  }
}

///|
let cubemaps_resource_key : @ecs.ResourceKey[Cubemaps] = @ecs.register_resource(
  debug_name="examples.reflection_probes.Cubemaps",
)

///|
impl @app.Resource for Cubemaps with fn resource() {
  cubemaps_resource_key
}

///|
struct SphereMaterial {}

///|
let sphere_material_key : @ecs.ComponentKey[SphereMaterial] = @ecs.register_component(
  debug_name="examples.reflection_probes.SphereMaterial",
)

///|
impl @ecs.Component for SphereMaterial with fn component() {
  sphere_material_key
}

///|
struct CubesScene {}

///|
let cubes_scene_key : @ecs.ComponentKey[CubesScene] = @ecs.register_component(
  debug_name="examples.reflection_probes.CubesScene",
)

///|
impl @ecs.Component for CubesScene with fn component() {
  cubes_scene_key
}

///|
struct HelpText {}

///|
let help_text_key : @ecs.ComponentKey[HelpText] = @ecs.register_component(
  debug_name="examples.reflection_probes.HelpText",
)

///|
impl @ecs.Component for HelpText with fn component() {
  help_text_key
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn create_camera_environment_map_light(
  cubemaps : Cubemaps,
) -> @pbr.EnvironmentMapLight {
  @pbr.EnvironmentMapLight::new(
    Some(cubemaps.diffuse_environment_map),
    Some(cubemaps.specular_environment_map),
    ENV_MAP_INTENSITY,
  )
}

///|
fn spawn_scene(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @scene.WorldAssetRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server,
            @gltf.GltfAssetLabel::Scene(0).from_asset(CUBES_SCENE_ASSET),
          ),
        ),
        CubesScene::{  },
      ),
    ),
  )
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @pbr.Hdr::Hdr(),
        @pbr.Exposure::new(11.0F),
        @post_process.Tonemapping::AcesFitted,
        @transform.Transform::from_xyz(-3.883F, 0.325F, 2.781F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn spawn_sphere(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  app_status : AppStatus,
) -> Unit {
  let sphere_mesh = @mesh_primitives_dim3.SphereMeshBuilder::from_sphere(
    @math.Sphere::new(1.0F),
  ).ico(7) catch {
    TooManyVertices(_, _) =>
      abort("reflection_probes sphere subdivisions produce too many vertices")
  }
  let sphere_mesh = meshes.peek().add(@mesh.Mesh::from_3d_geometry(sphere_mesh))
  let sphere_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::white())
      .with_metallic(1.0F)
      .with_perceptual_roughness(app_status.sphere_roughness),
    )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_mesh),
        @pbr.MeshMaterial3dTyped::new(sphere_material),
        SphereMaterial::{  },
      ),
    ),
  )
}

///|
fn spawn_reflection_probe(
  commands : @app.Commands,
  cubemaps : Cubemaps,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.LightProbe::LightProbe(),
        @pbr.EnvironmentMapLight::new(
          Some(cubemaps.diffuse_environment_map),
          Some(cubemaps.specular_reflection_probe),
          ENV_MAP_INTENSITY,
        ),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(2.0F)),
        @pbr.ParallaxCorrection::None,
      ),
    ),
  )
}

///|
fn spawn_text(commands : @app.Commands, app_status : AppStatus) -> Unit {
  ignore(
    commands.spawn(
      (
        app_status.create_text(),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_bottom(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
        HelpText::{  },
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
  app_status : @app.Res[AppStatus],
) -> Unit {
  let asset_server = asset_server.get()
  let cubemaps = Cubemaps::from_asset_server(asset_server)
  let app_status = app_status.get()
  commands.insert_resource(cubemaps)
  spawn_camera(commands)
  spawn_sphere(commands, meshes, materials, app_status)
  spawn_reflection_probe(commands, cubemaps)
  spawn_scene(commands, asset_server)
  spawn_text(commands, app_status)
}

///|
fn add_environment_map_to_camera(
  commands : @app.Commands,
  query : @ecs.Query[@ecs.Read[@camera.Camera3d], @ecs.Added[@camera.Camera3d]],
  cubemaps : @app.Res[Cubemaps],
) -> Unit {
  let cubemaps = cubemaps.get()
  try! query.view(fn(camera_entity, _camera) {
    commands
    .entity(camera_entity)
    .insert(
      (
        create_camera_environment_map_light(cubemaps),
        @pbr.Skybox::new(cubemaps.specular_environment_map, ENV_MAP_INTENSITY),
      ),
    )
  })
}

///|
fn change_reflection_type(
  commands : @app.Commands,
  light_probe_query : @ecs.Query[@ecs.Read[@pbr.LightProbe], @ecs.All],
  cubes_scene_query : @ecs.Query[@ecs.Read[CubesScene], @ecs.All],
  camera_query : @ecs.Query[@ecs.Read[@camera.Camera3d], @ecs.All],
  app_status : @app.ResMut[AppStatus],
  cubemaps : @app.Res[Cubemaps],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  if !@input.key_just_pressed(Space) {
    return
  }

  let next_mode = app_status.modify(fn(status) {
    status.reflection_mode = status.reflection_mode.next()
    status.reflection_mode
  })
  let cubemaps = cubemaps.get()
  let asset_server = asset_server.get()

  try! light_probe_query.view(fn(light_probe, _data) {
    commands.entity(light_probe).despawn()
  })
  try! cubes_scene_query.view(fn(scene_entity, _data) {
    commands.entity(scene_entity).despawn()
  })

  match next_mode {
    EnvironmentMap | GeneratedEnvironmentMap => ()
    ReflectionProbe => {
      spawn_reflection_probe(commands, cubemaps)
      spawn_scene(commands, asset_server)
    }
  }

  try! camera_query.view(fn(camera_entity, _data) {
    let camera_commands = commands.entity(camera_entity)
    camera_commands.remove_component(@pbr.ecs_key_environment_map_light)
    camera_commands.remove_component(
      @pbr.ecs_key_generated_environment_map_light,
    )
    match next_mode {
      EnvironmentMap | ReflectionProbe =>
        camera_commands.insert_component(
          create_camera_environment_map_light(cubemaps),
        )
      GeneratedEnvironmentMap =>
        camera_commands.insert_component(
          @pbr.GeneratedEnvironmentMapLight::new(
            Some(cubemaps.specular_environment_map),
            ENV_MAP_INTENSITY,
          ),
        )
    }
  })
}

///|
fn toggle_rotation(app_status : @app.ResMut[AppStatus]) -> Unit {
  if @input.key_just_pressed(Enter) {
    app_status.modify(fn(status) { status.rotating = !status.rotating })
  }
}

///|
fn update_text(
  text_query : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[HelpText]],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let next = app_status.get().create_text()
  try! text_query.view(fn(_entity, text) { text.set(next) })
}

///|
fn rotate_camera(
  time : @app.Res[@time.Time[Unit]],
  camera_query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  if !app_status.get().rotating {
    return
  }
  let angle = time.get().delta_seconds() * PI / 5.0F
  let cos_v = @math.cos(angle)
  let sin_v = @math.sin(angle)
  try! camera_query.view(fn(_entity, transform) {
    let current = transform.peek()
    let x = current.translation.x
    let z = current.translation.z
    transform.set(
      @transform.Transform::from_xyz(
        cos_v * x - sin_v * z,
        current.translation.y,
        sin_v * x + cos_v * z,
      ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    )
  })
}

///|
fn setup_environment_map_usage(
  cubemaps : @app.Res[Cubemaps],
  _images : @app.ResMut[@asset.Assets[@asset.Image]],
) -> Unit {
  let handle = cubemaps.get().specular_environment_map
  if !@asset.asset_image_has_usage(handle, @asset.IMAGE_USAGE_COPY_SRC) {
    @asset.asset_image_add_usage(handle, @asset.IMAGE_USAGE_COPY_SRC)
  }
}

///|
fn change_sphere_roughness(
  app_status : @app.ResMut[AppStatus],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  sphere_query : @ecs.Query[
    @ecs.Read[@pbr.MeshMaterial3d],
    @ecs.With[SphereMaterial],
  ],
) -> Unit {
  let roughness_delta = if @input.key_pressed(ArrowUp) {
    0.01F
  } else if @input.key_pressed(ArrowDown) {
    -0.01F
  } else {
    0.0F
  }
  if roughness_delta == 0.0F {
    return
  }

  let next_roughness = app_status.modify(fn(status) {
    status.sphere_roughness = clampf(
      status.sphere_roughness + roughness_delta,
      0.0F,
      1.0F,
    )
    status.sphere_roughness
  })
  materials.modify(fn(materials) {
    try! sphere_query.view(fn(_entity, material_handle) {
      let handle : @asset.Handle[@pbr.StandardMaterial] = @asset.Handle::new(
        material_handle.value().material_asset_id(),
      )
      match materials.get(handle) {
        Some(material) =>
          ignore(
            materials.set(
              handle,
              material.with_perceptual_roughness(next_roughness),
            ),
          )
        None => ()
      }
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_systems_param5(Startup, setup)
  .add_systems_param3(PreUpdate, add_environment_map_to_camera)
  .add_systems_param7(Update, change_reflection_type)
  .add_systems_param(Update, toggle_rotation)
  .add_systems_param3(Update, change_sphere_roughness)
  .add_systems_param3(Update, rotate_camera)
  .add_systems_param2(Update, update_text)
  .add_systems_param2(Update, setup_environment_map_usage)
  .run()
}
