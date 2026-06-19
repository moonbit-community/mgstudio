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
// Bevy source: `bevy/examples/3d/specular_tint.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const ROTATION_SPEED : Float = 0.005F

///|
const HUE_SHIFT_SPEED : Float = 0.2F

///|
const SWITCH_TO_MAP_HELP_TEXT : String = "Press Space to switch to a specular map"

///|
const SWITCH_TO_SOLID_TINT_HELP_TEXT : String = "Press Space to switch to a solid specular tint"

///|
priv struct AppStatus {
  mut tint_type : TintType
  mut hue : Float
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.specular_tint.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  AppStatus::{ tint_type: TintType::Solid, hue: 0.0F }
}

///|
priv struct AppAssets {
  noise_texture : @asset.Handle[@asset.Image]
}

///|
let app_assets_resource_key : @ecs.ResourceKey[AppAssets] = @ecs.register_resource(
  debug_name="examples.3d.specular_tint.AppAssets",
)

///|
impl @app.Resource for AppAssets with fn resource() {
  app_assets_resource_key
}

///|
fn AppAssets::from_asset_server(asset_server : @asset.AssetServer) -> AppAssets {
  AppAssets::{ noise_texture: asset_server.load("textures/AlphaNoise.png") }
}

///|
priv enum TintType {
  Solid
  Map
} derive(Eq)

///|
fn AppStatus::create_text(self : AppStatus) -> @text.Text {
  let tint_map_help_text = match self.tint_type {
    Solid => SWITCH_TO_MAP_HELP_TEXT
    Map => SWITCH_TO_SOLID_TINT_HELP_TEXT
  }
  @text.Text::new(tint_map_help_text)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn sphere_mesh() -> @mesh.Mesh {
  let geometry = @mesh_primitives_dim3.SphereMeshBuilder::from_sphere(
    @math.Sphere::Sphere(),
  ).uv(32, 18)
  @mesh.Mesh::from_3d_geometry(geometry)
}

///|
fn sphere_material(app_status : AppStatus) -> @pbr.StandardMaterial {
  @pbr.StandardMaterial::from_color(@color.Color::black())
  .with_reflectance(1.0F)
  .with_specular_tint(@color.Color::hsva(app_status.hue, 1.0F, 1.0F, 1.0F))
  .with_metallic(0.0F)
  .with_perceptual_roughness(0.0F)
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "mgstudio Specular Tint Example"
  window
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  app_status : @app.Res[AppStatus],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let diffuse_env_map : @asset.Handle[@asset.Image] = asset_server
    .get()
    .load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")
  let specular_env_map : @asset.Handle[@asset.Image] = asset_server
    .get()
    .load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")

  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(-2.0F, 0.0F, 3.5F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.Hdr::Hdr(),
        @camera.Camera3d::Camera3d(),
        @pbr.Skybox::new(specular_env_map, 3000.0F),
        @pbr.EnvironmentMapLight::new(
          Some(diffuse_env_map),
          Some(specular_env_map),
          25000.0F,
        ),
      ),
    ),
  )

  let mesh = meshes.modify(fn(assets) { assets.add(sphere_mesh()) })
  let material = standard_materials.modify(fn(assets) {
    assets.add(sphere_material(app_status.get()))
  })
  ignore(
    commands.spawn(
      (
        @transform.Transform::identity().with_rotation(
          @math.Quat::from_rotation_x(PI * 0.5F),
        ),
        @mesh.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_bottom(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
        app_status.get().create_text(),
      ),
    ),
  )
}

///|
fn rotate_camera(
  cameras : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  try! cameras.view(fn(_entity, camera_transform) {
    camera_transform.modify(fn(transform) {
      let translation = quat_rotate_vec3(
        @math.Quat::from_rotation_y(ROTATION_SPEED),
        transform.translation,
      )
      let next = @transform.Transform::from_xyz(
        translation.x,
        translation.y,
        translation.z,
      ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
      transform.translation = next.translation
      transform.rotation = next.rotation
    })
  })
}

///|
fn shift_hue(
  app_status : @app.ResMut[AppStatus],
  objects_with_materials : @ecs.Query[@ecs.Read[@pbr.MeshMaterial3d], @ecs.All],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let status = app_status.peek()
  if status.tint_type != TintType::Solid {
    return
  }

  status.hue = status.hue + HUE_SHIFT_SPEED
  app_status.set(status)

  try! objects_with_materials.view(fn(_entity, material_handle) {
    let material_asset = material_handle.value().material
    standard_materials.modify(fn(assets) {
      guard assets.get(material_asset) is Some(material) else { return }
      ignore(
        assets.set(
          material_asset,
          material.with_specular_tint(
            @color.Color::hsva(status.hue, 1.0F, 1.0F, 1.0F),
          ),
        ),
      )
    })
  })
}

///|
fn toggle_specular_map(
  keyboard : @input.ButtonInput[@window.KeyCode],
  app_status : @app.ResMut[AppStatus],
  app_assets : @app.Res[AppAssets],
  objects_with_materials : @ecs.Query[@ecs.Read[@pbr.MeshMaterial3d], @ecs.All],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Space) {
    return
  }

  let status = app_status.peek()
  status.tint_type = match status.tint_type {
    Solid => TintType::Map
    Map => TintType::Solid
  }
  app_status.set(status)

  try! objects_with_materials.view(fn(_entity, material_handle) {
    let material_asset = material_handle.value().material
    standard_materials.modify(fn(assets) {
      guard assets.get(material_asset) is Some(material) else { return }
      let next_material = match status.tint_type {
        Solid =>
          material.with_reflectance(1.0F).with_specular_tint_texture(None)
        Map =>
          material
          .with_reflectance(2.0F)
          .with_specular_tint(@color.Color::white())
          .with_specular_tint_texture(Some(app_assets.get().noise_texture))
      }
      ignore(assets.set(material_asset, next_material))
    })
  })
}

///|
fn update_text(
  text_query : @ecs.Query[@ecs.Write[@text.Text], @ecs.All],
  app_status : @app.Res[AppStatus],
) -> Unit {
  try! text_query.view(fn(_entity, text) {
    text.set(app_status.get().create_text())
  })
}

///|
let specular_tint_toggle_set : @app.SystemSet = @app.system_set(
  "examples.3d.specular_tint.toggle_specular_map",
)

///|
fn app_assets_from_world_asset_server(app : @app.App[@ecs.World]) -> AppAssets {
  let asset_server : @asset.AssetServer = match
    app.world().get_resource(@asset.AssetServer::resource()) {
    Some(asset_server) => asset_server
    None =>
      abort("specular_tint requires DefaultPlugins to install AssetServer")
  }
  AppAssets::from_asset_server(asset_server)
}

///|
fn main {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      ..@window.WindowPlugin::WindowPlugin(),
      primary_window: Some(configured_window()),
    }),
  )
  let app_assets = app_assets_from_world_asset_server(app)
  let toggle_specular_map_system : @app.SystemConfig[@ecs.World] = @app.system_config_param5(
    toggle_specular_map,
  ).in_set(specular_tint_toggle_set)
  let update_text_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    update_text,
  )
  let shift_hue_system : @app.SystemConfig[@ecs.World] = @app.system_config_param3(
    shift_hue,
  ).after(specular_tint_toggle_set)

  app
  .insert_resource(app_assets)
  .init_resource(fn() { AppStatus::AppStatus() })
  .insert_resource(@pbr.GlobalAmbientLight::new(@color.Color::black(), 0.0F))
  .add_systems_param5(@app.Startup, setup)
  .add_systems_param(@app.Update, rotate_camera)
  .add_systems(
    @app.Update,
    (toggle_specular_map_system, update_text_system) |> @app.chain(),
  )
  .add_systems(@app.Update, shift_hue_system)
  .run()
}
