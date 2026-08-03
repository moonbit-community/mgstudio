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
const LIGHT_RADIUS : Float = 10.0F

///|
const POINT_LIGHT_INTENSITY : Float = 1_000_000_000.0F

///|
const POINT_LIGHT_RANGE : Float = 110.0F

///|
const DIRECTIONAL_SHADOW_DEPTH_BIAS : Float = 0.20F

///|
const POINT_SHADOW_DEPTH_BIAS : Float = 0.35F

///|
const SHADOW_MAP_NEAR_Z : Float = 50.0F

///|
priv struct PcssCamera {}

///|
let pcss_camera_component_key : @ecs.ComponentKey[PcssCamera] = @ecs.register_component(
  debug_name="examples.3d.pcss.PcssCamera",
)

///|
impl @ecs.Component for PcssCamera with fn component() {
  pcss_camera_component_key
}

///|
priv struct PcssLight {}

///|
let pcss_light_component_key : @ecs.ComponentKey[PcssLight] = @ecs.register_component(
  debug_name="examples.3d.pcss.PcssLight",
)

///|
impl @ecs.Component for PcssLight with fn component() {
  pcss_light_component_key
}

///|
priv enum LightType {
  Directional
  Point
  Spot
} derive(Eq)

///|
priv enum ShadowFilter {
  NonTemporal
  Temporal
} derive(Eq)

///|
priv struct AppStatus {
  mut light_type : LightType
  mut shadow_filter : ShadowFilter
  mut soft_shadows : Bool
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  { light_type: Directional, shadow_filter: NonTemporal, soft_shadows: true }
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.pcss.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
priv enum AppSetting {
  LightType(LightType)
  ShadowFilter(ShadowFilter)
  SoftShadows(Bool)
}

///|
impl @widgets_lib.WidgetValue for AppSetting with fn widget_debug_name() {
  "examples.3d.pcss.AppSetting"
}

///|
let app_setting_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[AppSetting],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.pcss.AppSetting>",
)

///|
impl @widgets_lib.WidgetValue for AppSetting with fn widget_click_event_key() {
  app_setting_widget_click_event_key
}

///|
let app_setting_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[AppSetting],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.pcss.AppSetting>",
)

///|
impl @widgets_lib.WidgetValue for AppSetting with fn widget_click_sender_key() {
  app_setting_widget_click_sender_key
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Percentage Closer Soft Shadows Example"
  window
}

///|
fn soft_shadow_size(enabled : Bool) -> Float? {
  if enabled {
    Some(LIGHT_RADIUS)
  } else {
    None
  }
}

///|
fn create_directional_light(app_status : AppStatus) -> @pbr.DirectionalLight {
  @pbr.DirectionalLight::new(@color.Color::white(), 10_000.0F, true)
  .with_shadow_depth_bias(DIRECTIONAL_SHADOW_DEPTH_BIAS)
  .with_soft_shadow_size(soft_shadow_size(app_status.soft_shadows))
}

///|
fn create_point_light(app_status : AppStatus) -> @pbr.PointLight {
  @pbr.PointLight::new(
    @color.Color::white(),
    POINT_LIGHT_INTENSITY,
    POINT_LIGHT_RANGE,
    true,
  )
  .with_radius(LIGHT_RADIUS)
  .with_soft_shadows_enabled(app_status.soft_shadows)
  .with_shadow_depth_bias(POINT_SHADOW_DEPTH_BIAS)
  .with_shadow_map_near_z(SHADOW_MAP_NEAR_Z)
}

///|
fn create_spot_light(app_status : AppStatus) -> @pbr.SpotLight {
  @pbr.SpotLight::new(
    @color.Color::white(),
    POINT_LIGHT_INTENSITY,
    POINT_LIGHT_RANGE,
    0.0F,
    0.7853981633974483F,
    true,
  )
  .with_radius(LIGHT_RADIUS)
  .with_soft_shadows_enabled(app_status.soft_shadows)
  .with_shadow_depth_bias(DIRECTIONAL_SHADOW_DEPTH_BIAS)
  .with_shadow_map_near_z(SHADOW_MAP_NEAR_Z)
}

///|
fn apply_light_type(
  commands : @app.Commands,
  light : @core.Entity,
  app_status : AppStatus,
) -> Unit {
  let entity = commands.entity(light)
  entity.remove_component(@pbr.ecs_key_directional_light)
  entity.remove_component(@pbr.ecs_key_point_light)
  entity.remove_component(@pbr.ecs_key_spot_light)

  match app_status.light_type {
    Directional =>
      commands
      .entity(light)
      .insert_component(create_directional_light(app_status))
    Point =>
      commands.entity(light).insert_component(create_point_light(app_status))
    Spot =>
      commands.entity(light).insert_component(create_spot_light(app_status))
  }
}

///|
fn apply_camera_shadow_filter(
  commands : @app.Commands,
  camera : @core.Entity,
  app_status : AppStatus,
) -> Unit {
  let filter_mode = match app_status.shadow_filter {
    NonTemporal => @pbr.ShadowFilteringMethod::Gaussian
    Temporal => Temporal
  }
  commands.entity(camera).insert_component(filter_mode)
  if app_status.shadow_filter == Temporal {
    commands
    .entity(camera)
    .insert_component(
      @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
    )
  } else {
    commands
    .entity(camera)
    .remove_component(@post_process.ecs_key_temporal_anti_aliasing)
  }
}

///|
fn spawn_camera(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let camera_transform = @transform.Transform::from_xyz(
    -12.912F * 0.7F,
    4.466F * 0.7F,
    -10.624F * 0.7F,
  ).with_rotation(
    @math.Quat::from_euler(YXZ, -134.76F / 180.0F * @math.pi(), -0.175F, 0.0F),
  )
  let camera = commands.spawn(
    @pbr.Camera3dBundle::new(Camera(), camera_transform),
  )
  commands.entity(camera).insert_component(PcssCamera::{  })
  commands.entity(camera).insert_component(@pbr.ShadowFilteringMethod::Gaussian)
  commands
  .entity(camera)
  .insert_component(@post_process.TemporalJitter::TemporalJitter())
  commands.entity(camera).insert_component(@pbr.Msaa::Off)
  commands.entity(camera).insert_component(@pbr.DepthPrepass::DepthPrepass())
  commands
  .entity(camera)
  .insert_component(@pbr.MotionVectorPrepass::MotionVectorPrepass())
  commands
  .entity(camera)
  .insert_component(
    @pbr.Skybox::new(
      asset_server.load("environment_maps/sky_skybox.ktx2"),
      500.0F,
    ),
  )
}

///|
fn spawn_light(commands : @app.Commands, app_status : AppStatus) -> Unit {
  let light = commands.spawn(
    (
      PcssLight::{  },
      @transform.Transform::from_rotation(
        @math.Quat::new(0.6539259F, -0.34646285F, 0.36505926F, -0.5648683F),
      ).with_translation(@math.Vec3::new(57.693F, 34.334F, -6.422F)),
    ),
  )
  apply_light_type(commands, light, app_status)
}

///|
fn spawn_gltf_scene(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        @scene.scene_load_gltf_scene(
          asset_server, "models/PalmTree/PalmTree.gltf#Scene0",
        ),
      ),
    ),
  )
}

///|
fn spawn_buttons(commands : @app.Commands) -> Unit {
  let ui_camera = commands.spawn_component(
    @camera_components2d.Camera2d::Camera2d(),
  )
  commands
  .entity(ui_camera)
  .insert_component(@ui.IsDefaultUiCamera::IsDefaultUiCamera())
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  let panel = commands.spawn(
    (@hierarchy.Parent::new(root), @widgets_lib.main_ui_node()),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Light Type", [
      (AppSetting::LightType(Directional), "Directional"),
      (LightType(Point), "Point"),
      (LightType(Spot), "Spot"),
    ]),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Shadow Filter", [
      (AppSetting::ShadowFilter(NonTemporal), "Non-Temporal"),
      (ShadowFilter(Temporal), "Temporal"),
    ]),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Soft Shadows", [
      (AppSetting::SoftShadows(true), "On"),
      (SoftShadows(false), "Off"),
    ]),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let asset_server = asset_server.get()
  let status = app_status.get()
  spawn_camera(commands, asset_server)
  spawn_light(commands, status)
  spawn_gltf_scene(commands, asset_server)
  spawn_buttons(commands)
  commands.insert_world_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@color.Color::white(), 0.0F),
  )
}

///|
fn handle_ui_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[AppSetting]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[AppSetting],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn app_setting_selected(setting : AppSetting, app_status : AppStatus) -> Bool {
  match setting {
    LightType(light_type) => light_type == app_status.light_type
    ShadowFilter(shadow_filter) => shadow_filter == app_status.shadow_filter
    SoftShadows(soft_shadows) => soft_shadows == app_status.soft_shadows
  }
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[AppSetting]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.With[@widgets_lib.RadioButton],
  ],
  radio_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[AppSetting]],
      @ecs.Write[@text.TextColor],
    ),
    @ecs.With[@widgets_lib.RadioButtonText],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  try! radio_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      app_setting_selected(sender.value().get(), status),
    )
  })
  try! radio_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      app_setting_selected(sender.value().get(), status),
    )
  })
}

///|
fn first_pcss_light(
  query : @ecs.Query[@core.Entity, @ecs.With[PcssLight]],
) -> @core.Entity? {
  let entity_ref : Ref[@core.Entity?] = Ref(None)
  try! query.view(fn(_query_entity, entity) {
    if entity_ref.val is None {
      entity_ref.val = Some(entity)
    }
  })
  entity_ref.val
}

///|
fn first_pcss_camera(
  query : @ecs.Query[@core.Entity, @ecs.With[PcssCamera]],
) -> @core.Entity? {
  let entity_ref : Ref[@core.Entity?] = Ref(None)
  try! query.view(fn(_query_entity, entity) {
    if entity_ref.val is None {
      entity_ref.val = Some(entity)
    }
  })
  entity_ref.val
}

///|
fn handle_light_type_change(
  commands : @app.Commands,
  light_query : @ecs.Query[@core.Entity, @ecs.With[PcssLight]],
  app_status : @app.ResMut[AppStatus],
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[AppSetting]],
) -> Unit {
  let result = app_status.modify(fn(status) {
    let mut changed = false
    for event in events.read() {
      match event.get() {
        LightType(light_type) =>
          if status.light_type != light_type {
            status.light_type = light_type
            changed = true
          }
        _ => ()
      }
    }
    (changed, status)
  })
  let (changed, status) = result
  if changed {
    guard first_pcss_light(light_query) is Some(light) else { return }
    apply_light_type(commands, light, status)
  }
}

///|
fn handle_shadow_filter_change(
  commands : @app.Commands,
  camera_query : @ecs.Query[@core.Entity, @ecs.With[PcssCamera]],
  app_status : @app.ResMut[AppStatus],
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[AppSetting]],
) -> Unit {
  let result = app_status.modify(fn(status) {
    let mut changed = false
    for event in events.read() {
      match event.get() {
        ShadowFilter(shadow_filter) =>
          if status.shadow_filter != shadow_filter {
            status.shadow_filter = shadow_filter
            changed = true
          }
        _ => ()
      }
    }
    (changed, status)
  })
  let (changed, status) = result
  if changed {
    guard first_pcss_camera(camera_query) is Some(camera) else { return }
    apply_camera_shadow_filter(commands, camera, status)
  }
}

///|
fn handle_pcss_toggle(
  commands : @app.Commands,
  light_query : @ecs.Query[@core.Entity, @ecs.With[PcssLight]],
  app_status : @app.ResMut[AppStatus],
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[AppSetting]],
) -> Unit {
  let result = app_status.modify(fn(status) {
    let mut changed = false
    for event in events.read() {
      match event.get() {
        SoftShadows(soft_shadows) =>
          if status.soft_shadows != soft_shadows {
            status.soft_shadows = soft_shadows
            changed = true
          }
        _ => ()
      }
    }
    (changed, status)
  })
  let (changed, status) = result
  if changed {
    guard first_pcss_light(light_query) is Some(light) else { return }
    apply_light_type(commands, light, status)
  }
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[AppSetting],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: OnAllClosed,
      close_when_requested: true,
    }),
  )
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(widget_click_message_key)
  .add_systems_param3(Startup, setup)
  .add_systems_param2(Update, handle_ui_interactions)
  .add_systems(
    Update,
    @app.system_config_param4(handle_light_type_change).run_if_on_message(
      widget_click_message_key,
    ),
  )
  .add_systems(
    Update,
    @app.system_config_param4(handle_shadow_filter_change).run_if_on_message(
      widget_click_message_key,
    ),
  )
  .add_systems(
    Update,
    @app.system_config_param4(handle_pcss_toggle).run_if_on_message(
      widget_click_message_key,
    ),
  )
  .add_systems_param3(Update, update_radio_buttons)
  .run()
}
