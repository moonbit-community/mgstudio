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
/// Demonstrates depth of field (DOF).

///|
const FOCAL_DISTANCE_SPEED : Float = 0.05F

///|
const APERTURE_F_STOP_SPEED : Float = 0.01F

///|
const MIN_FOCAL_DISTANCE : Float = 0.01F

///|
const MIN_APERTURE_F_STOPS : Float = 0.05F

///|
const DEPTH_OF_FIELD_MAX_DEPTH : Float = 14.0F

///|
const LIGHTMAP_EXPOSURE : Float = 10000.0F

///|
let depth_of_field_adjust_set : @app.SystemSet = @app.system_set(
  "examples.3d.depth_of_field.adjust_focus",
)

///|
let depth_of_field_change_mode_set : @app.SystemSet = @app.system_set(
  "examples.3d.depth_of_field.change_mode",
)

///|
let depth_of_field_update_settings_set : @app.SystemSet = @app.system_set(
  "examples.3d.depth_of_field.update_dof_settings",
)

///|
struct AppSettings {
  mut focal_distance : Float
  mut aperture_f_stops : Float
  mut mode : @pbr.DepthOfFieldMode?
}

///|
let app_settings_resource_key : @ecs.ResourceKey[AppSettings] = @ecs.register_resource(
  debug_name="examples.3d.depth_of_field.AppSettings",
)

///|
impl @app.Resource for AppSettings with fn resource() {
  app_settings_resource_key
}

///|
fn AppSettings::AppSettings() -> AppSettings {
  { focal_distance: 7.0F, aperture_f_stops: 1.0F / 8.0F, mode: Some(Bokeh) }
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn format_fixed(value : Float, decimals : Int) -> String {
  let factor = if decimals == 3 {
    1000
  } else if decimals == 2 {
    100
  } else {
    10
  }
  let scaled = (value * Float::from_double(factor.to_double())).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / factor
  let frac = abs_scaled % factor
  let frac_text = if decimals == 3 && frac < 10 {
    "00\{frac.to_string()}"
  } else if decimals == 3 && frac < 100 {
    "0\{frac.to_string()}"
  } else if decimals == 2 && frac < 10 {
    "0\{frac.to_string()}"
  } else {
    frac.to_string()
  }
  "\{sign}\{whole.to_string()}.\{frac_text}"
}

///|
fn depth_of_field_mode_name(mode : @pbr.DepthOfFieldMode) -> String {
  match mode {
    Bokeh => "Bokeh".to_string()
    Gaussian => "Gaussian".to_string()
  }
}

///|
fn calculate_focal_length(sensor_height : Float, fov : Float) -> Float {
  let half_fov = fov / 2.0F
  let tan_half_fov = @math.sin(half_fov) / @math.cos(half_fov)
  sensor_height / (2.0F * tan_half_fov)
}

///|
fn AppSettings::help_text(self : AppSettings) -> String {
  guard self.mode is Some(mode) else {
    return "Mode: Off (Press Space to change)"
  }

  let sensor_height = @pbr.PhysicalCameraParameters::PhysicalCameraParameters().sensor_height
  let fov = @camera.PerspectiveProjection3d::PerspectiveProjection3d().fov
  "Focal distance: \{format_fixed(self.focal_distance, 2)} m (Press Up/Down to change)\nAperture F-stops: f/\{format_fixed(self.aperture_f_stops, 3)} (Press Left/Right to change)\nSensor height: \{format_fixed(sensor_height * 1000.0F, 2)}mm\nFocal length: \{format_fixed(calculate_focal_length(sensor_height, fov) * 1000.0F, 2)}mm\nMode: \{depth_of_field_mode_name(mode)} (Press Space to change)"
}

///|
fn create_text(app_settings : AppSettings) -> @text.Text {
  @text.Text::new(app_settings.help_text())
}

///|
fn depth_of_field_from_app_settings(
  app_settings : AppSettings,
) -> @pbr.DepthOfField? {
  match app_settings.mode {
    Some(mode) => {
      let depth_of_field = @pbr.DepthOfField::DepthOfField()
      depth_of_field.mode = mode
      depth_of_field.focal_distance = app_settings.focal_distance
      depth_of_field.aperture_f_stops = app_settings.aperture_f_stops
      depth_of_field.max_depth = DEPTH_OF_FIELD_MAX_DEPTH
      Some(depth_of_field)
    }
    None => None
  }
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Depth of Field Example"
  window
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  app_settings : @app.Res[AppSettings],
) -> Unit {
  let settings = app_settings.get()
  let camera = commands.spawn(
    @pbr.Camera3dBundle::new(
      Camera(),
      @transform.Transform::from_xyz(0.0F, 4.5F, 8.25F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_tonemapping(Some(TonyMcMapface))
    .with_bloom(Some(@post_process.Bloom::natural())),
  )

  match depth_of_field_from_app_settings(settings) {
    Some(depth_of_field) =>
      commands.entity(camera).insert_component(depth_of_field)
    None => ()
  }

  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        @scene.scene_load_gltf_scene(
          asset_server.get(),
          @gltf.GltfAssetLabel::Scene(0).from_asset(
            "models/DepthOfFieldExample/DepthOfFieldExample.glb",
          ),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        create_text(settings),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_bottom(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
      ),
    ),
  )
}

///|
fn adjust_focus(
  input : @input.ButtonInput[@window.KeyCode],
  app_settings : @app.ResMut[AppSettings],
) -> Unit {
  let distance_delta = if input.pressed(ArrowDown) {
    -FOCAL_DISTANCE_SPEED
  } else if input.pressed(ArrowUp) {
    FOCAL_DISTANCE_SPEED
  } else {
    0.0F
  }

  let f_stop_delta = if input.pressed(ArrowLeft) {
    -APERTURE_F_STOP_SPEED
  } else if input.pressed(ArrowRight) {
    APERTURE_F_STOP_SPEED
  } else {
    0.0F
  }

  app_settings.modify(fn(settings) {
    settings.focal_distance = maxf(
      settings.focal_distance + distance_delta,
      MIN_FOCAL_DISTANCE,
    )
    settings.aperture_f_stops = maxf(
      settings.aperture_f_stops + f_stop_delta,
      MIN_APERTURE_F_STOPS,
    )
  })
}

///|
fn change_mode(
  input : @input.ButtonInput[@window.KeyCode],
  app_settings : @app.ResMut[AppSettings],
) -> Unit {
  if !input.just_pressed(Space) {
    return
  }
  app_settings.modify(fn(settings) {
    settings.mode = match settings.mode {
      Some(Bokeh) => Some(Gaussian)
      Some(Gaussian) => None
      None => Some(Bokeh)
    }
  })
}

///|
fn update_dof_settings(
  commands : @app.Commands,
  view_targets : @ecs.Query[@core.Entity, @ecs.With[@camera_camera.Camera]],
  app_settings : @app.Res[AppSettings],
) -> Unit {
  let settings = app_settings.get()
  try! view_targets.view(fn(view, _entity) {
    match depth_of_field_from_app_settings(settings) {
      Some(component) => commands.entity(view).insert_component(component)
      None =>
        commands.entity(view).remove_component(@pbr.ecs_key_depth_of_field)
    }
  })
}

///|
fn set_material_lightmap_exposure(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  mesh_material : @pbr.MeshMaterial3d,
) -> Unit {
  let material_handle = mesh_material.material
  materials.modify(fn(material_assets) {
    guard material_assets.get(material_handle) is Some(material) else { return }
    ignore(
      material_assets.set(
        material_handle,
        material.with_lightmap_exposure(LIGHTMAP_EXPOSURE),
      ),
    )
  })
}

///|
type CircuitBoardQuery = @ecs.Query[
  (@ecs.Read[@gltf.GltfMeshName], @ecs.Read[@pbr.MeshMaterial3d]),
  (@ecs.With[@mesh.Mesh3d], @ecs.Without[@pbr.Lightmap]),
]

///|
fn tweak_scene(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  lights : @ecs.Query[
    @ecs.Write[@pbr.DirectionalLight],
    @ecs.Changed[@pbr.DirectionalLight],
  ],
  named_entities : CircuitBoardQuery,
) -> Unit {
  try! lights.view(fn(_entity, light) {
    light.set(light.value().with_shadow_maps_enabled(true))
  })

  let server = asset_server.get()
  try! named_entities.view(fn(entity, data) {
    let (name, mesh_material) = data
    guard name.value().as_str() == "CircuitBoard" else { return }
    set_material_lightmap_exposure(materials, mesh_material.value())
    commands
    .entity(entity)
    .insert_component(
      @pbr.Lightmap::new(
        server.load_image("models/DepthOfFieldExample/CircuitBoardLightmap.hdr"),
      ),
    )
  })
}

///|
fn update_text(
  texts : @ecs.Query[@ecs.Write[@text.Text], @ecs.All],
  app_settings : @app.Res[AppSettings],
) -> Unit {
  let settings = app_settings.get()
  try! texts.view(fn(_entity, value) { value.set(create_text(settings)) })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .init_resource(fn() { AppSettings::AppSettings() })
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_systems_param3(Startup, setup)
  .add_systems_param5(Update, tweak_scene)
  .add_systems(
    Update,
    @app.system_config_param2(adjust_focus).in_set(depth_of_field_adjust_set),
  )
  .add_systems(
    Update,
    @app.system_config_param2(change_mode)
    .after(depth_of_field_adjust_set)
    .in_set(depth_of_field_change_mode_set),
  )
  .add_systems(
    Update,
    @app.system_config_param3(update_dof_settings)
    .after(depth_of_field_change_mode_set)
    .in_set(depth_of_field_update_settings_set),
  )
  .add_systems(
    Update,
    @app.system_config_param2(update_text).after(
      depth_of_field_update_settings_set,
    ),
  )
  .run()
}
