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
const ENVIRONMENT_MAP_INTENSITY : Float = 100.0F

///|
const OUTER_CUBE_URL : String = "https://github.com/bevyengine/bevy_asset_files/raw/main/pccm_example/outer_cube.glb#Scene0"

///|
const ENV_DIFFUSE_URL : String = "https://github.com/bevyengine/bevy_asset_files/raw/main/pccm_example/env_diffuse.ktx2"

///|
const ENV_SPECULAR_URL : String = "https://github.com/bevyengine/bevy_asset_files/raw/main/pccm_example/env_specular.ktx2"

///|
priv struct AppStatus {
  mut pccm_enabled : PccmEnableStatus
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  AppStatus::{ pccm_enabled: PccmEnableStatus::Enabled }
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.pccm.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
priv enum PccmEnableStatus {
  Enabled
  Disabled
} derive(Eq)

///|
impl @widgets_lib.WidgetValue for PccmEnableStatus with fn widget_debug_name() {
  "examples.3d.pccm.PccmEnableStatus"
}

///|
let pccm_enable_status_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[PccmEnableStatus],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.pccm.PccmEnableStatus>",
)

///|
impl @widgets_lib.WidgetValue for PccmEnableStatus with fn widget_click_event_key() {
  pccm_enable_status_widget_click_event_key
}

///|
let pccm_enable_status_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[PccmEnableStatus],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.pccm.PccmEnableStatus>",
)

///|
impl @widgets_lib.WidgetValue for PccmEnableStatus with fn widget_click_sender_key() {
  pccm_enable_status_widget_click_sender_key
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  let camera = commands.spawn(
    @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 4.0F).looking_at(
        @math.Vec3::new(0.0F, -2.5F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  commands
  .entity(camera)
  .insert_component(@camera_controller.FreeCamera::FreeCamera())
  commands.entity(camera).insert_component(@pbr.Hdr::Hdr())
}

///|
fn spawn_inner_cube(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let cube_geometry = @mesh_primitives_dim3.CuboidMeshBuilder::new(
    10.0F, 2.0F, 4.0F,
  ).build()
  guard cube_geometry.with_duplicated_vertices() is Some(duplicated) else {
    abort("pccm inner cube must duplicate vertices")
  }
  guard duplicated.with_computed_flat_normals() is Some(flat_normals) else {
    abort("pccm inner cube must compute flat normals")
  }
  let cube_mesh = meshes.modify(fn(assets) {
    assets.add(@mesh.Mesh::from_3d_geometry(flat_normals))
  })
  let cube_material = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(@color.Color::white())
      .with_metallic(1.0F)
      .with_reflectance(1.0F)
      .with_perceptual_roughness(0.0F),
    )
  })
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(cube_material),
        @transform.Transform::from_xyz(0.0F, -4.0F, -2.5F),
      ),
    ),
  )
}

///|
fn spawn_reflection_probe(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let diffuse_map = asset_server.load(ENV_DIFFUSE_URL)
  let specular_map = asset_server.load(ENV_SPECULAR_URL)
  ignore(
    commands.spawn(
      (
        @pbr.LightProbe::LightProbe(),
        @pbr.EnvironmentMapLight::new(
          Some(diffuse_map),
          Some(specular_map),
          ENVIRONMENT_MAP_INTENSITY,
        ),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(10.01F)),
      ),
    ),
  )
}

///|
fn spawn_buttons(commands : @app.Commands) -> Unit {
  let ui_camera = commands.spawn(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  commands
  .entity(ui_camera)
  .insert_component(@ui.IsDefaultUiCamera::IsDefaultUiCamera())
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  let panel = commands.spawn(
    (@hierarchy.Parent::new(root), @widgets_lib.main_ui_node()),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Parallax Correction", [
      (PccmEnableStatus::Enabled, "On"),
      (PccmEnableStatus::Disabled, "Off"),
    ]),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let asset_server = asset_server.get()
  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        @scene.scene_load_gltf_scene(asset_server, OUTER_CUBE_URL),
      ),
    ),
  )
  spawn_camera(commands)
  spawn_inner_cube(commands, meshes, materials)
  spawn_reflection_probe(commands, asset_server)
  spawn_buttons(commands)
}

///|
fn handle_ui_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[PccmEnableStatus]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[PccmEnableStatus],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn handle_pccm_enable_change(
  commands : @app.Commands,
  light_probe_query : @ecs.Query[@core.Entity, @ecs.With[@pbr.LightProbe]],
  app_status : @app.ResMut[AppStatus],
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[PccmEnableStatus]],
) -> Unit {
  let light_probe_entity_ref : Ref[@core.Entity?] = Ref(None)
  try! light_probe_query.view(fn(_query_entity, entity) {
    if light_probe_entity_ref.val is None {
      light_probe_entity_ref.val = Some(entity)
    }
  })
  guard light_probe_entity_ref.val is Some(light_probe_entity) else { return }
  app_status.modify(fn(status) {
    for event in events.read() {
      status.pccm_enabled = event.get()
      let correction = match event.get() {
        PccmEnableStatus::Enabled => @pbr.ParallaxCorrection::Auto
        PccmEnableStatus::Disabled => @pbr.ParallaxCorrection::None
      }
      commands.entity(light_probe_entity).insert_component(correction)
    }
  })
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[PccmEnableStatus]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.With[@widgets_lib.RadioButton],
  ],
  radio_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[PccmEnableStatus]],
      @ecs.Write[@text.TextColor],
    ),
    @ecs.With[@widgets_lib.RadioButtonText],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let pccm_enabled = app_status.get().pccm_enabled
  try! radio_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      sender.value().get() == pccm_enabled,
    )
  })
  try! radio_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      sender.value().get() == pccm_enabled,
    )
  })
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[PccmEnableStatus],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@camera_controller.FreeCameraPlugin::FreeCameraPlugin())
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(widget_click_message_key)
  .add_systems_param4(@app.Startup, setup)
  .add_systems_param2(@app.Update, handle_ui_interactions)
  .add_systems(
    @app.Update,
    @app.system_config_param4(handle_pccm_enable_change).run_if_on_message(
      widget_click_message_key,
    ),
  )
  .add_systems_param3(@app.Update, update_radio_buttons)
  .run()
}
