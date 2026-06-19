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
/// Demonstrates contact shadows, also known as screen-space shadows.

///|
const LIGHT_ROTATION_SPEED : Float = 0.002F

///|
const VERY_LARGE_CINEMA_LIGHT : Float = 1_000_000.0F

///|
enum ContactShadowState {
  Enabled
  Disabled
} derive(Eq, Debug)

///|
enum ShadowMaps {
  Enabled
  Disabled
} derive(Eq, Debug)

///|
enum LightRotation {
  Stationary
  Rotating
} derive(Eq, Debug)

///|
enum LightType {
  Directional
  Point
  Spot
} derive(Eq, Debug)

///|
enum ReceiveShadows {
  Enabled
  Disabled
} derive(Eq, Debug)

///|
enum ExampleSetting {
  ContactShadows(ContactShadowState)
  ShadowMaps(ShadowMaps)
  LightRotation(LightRotation)
  LightType(LightType)
  ReceiveShadows(ReceiveShadows)
} derive(Eq, Debug)

///|
impl @widgets_lib.WidgetValue for ExampleSetting with fn widget_debug_name() {
  "examples.3d.contact_shadows.ExampleSetting"
}

///|
let example_setting_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[ExampleSetting],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.contact_shadows.ExampleSetting>",
)

///|
impl @widgets_lib.WidgetValue for ExampleSetting with fn widget_click_event_key() {
  example_setting_widget_click_event_key
}

///|
let example_setting_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[ExampleSetting],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.contact_shadows.ExampleSetting>",
)

///|
impl @widgets_lib.WidgetValue for ExampleSetting with fn widget_click_sender_key() {
  example_setting_widget_click_sender_key
}

///|
struct AppStatus {
  mut contact_shadows : ContactShadowState
  mut shadow_maps : ShadowMaps
  mut light_rotation : LightRotation
  mut light_type : LightType
  mut receive_shadows : ReceiveShadows
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.contact_shadows.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  AppStatus::{
    contact_shadows: Enabled,
    shadow_maps: Enabled,
    light_rotation: Rotating,
    light_type: Point,
    receive_shadows: Enabled,
  }
}

///|
struct LightContainer {}

///|
let light_container_component_key : @ecs.ComponentKey[LightContainer] = @ecs.register_component(
  debug_name="examples.3d.contact_shadows.LightContainer",
)

///|
impl @ecs.Component for LightContainer with fn component() {
  light_container_component_key
}

///|
struct GroundPlane {}

///|
let ground_plane_component_key : @ecs.ComponentKey[GroundPlane] = @ecs.register_component(
  debug_name="examples.3d.contact_shadows.GroundPlane",
)

///|
impl @ecs.Component for GroundPlane with fn component() {
  ground_plane_component_key
}

///|
let contact_shadows_ui_interaction_set : @app.SystemSet = @app.system_set(
  "examples.3d.contact_shadows.handle_ui_interactions",
)

///|
let contact_shadows_setting_change_set : @app.SystemSet = @app.system_set(
  "examples.3d.contact_shadows.handle_setting_change",
)

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Contact Shadows Example"
  window
}

///|
fn selected(setting : ExampleSetting, app_status : AppStatus) -> Bool {
  match setting {
    ContactShadows(value) => value == app_status.contact_shadows
    ShadowMaps(value) => value == app_status.shadow_maps
    LightRotation(value) => value == app_status.light_rotation
    LightType(value) => value == app_status.light_type
    ReceiveShadows(value) => value == app_status.receive_shadows
  }
}

///|
fn set_primary_window_cursor(
  commands : @app.Commands,
  windows : @ecs.Query[@core.Entity, @ecs.With[@window.PrimaryWindow]],
  icon : @window.SystemCursorIcon,
) -> Unit {
  let primary_window : Ref[@core.Entity?] = Ref(None)
  try! windows.view(fn(_query_entity, entity) {
    if primary_window.val is None {
      primary_window.val = Some(entity)
    }
  })
  guard primary_window.val is Some(entity) else { return }
  commands.entity(entity).insert_component(@window.CursorIcon::from(icon))
}

///|
fn on_flight_helmet_pointer_over(
  _pointer : @app.OnPointer[@app.PointerOver],
  commands : @app.Commands,
  windows : @ecs.Query[@core.Entity, @ecs.With[@window.PrimaryWindow]],
) -> Unit {
  set_primary_window_cursor(commands, windows, @window.SystemCursorIcon::Grab)
}

///|
fn on_flight_helmet_pointer_out(
  _pointer : @app.OnPointer[@app.PointerOut],
  commands : @app.Commands,
  windows : @ecs.Query[@core.Entity, @ecs.With[@window.PrimaryWindow]],
) -> Unit {
  set_primary_window_cursor(
    commands,
    windows,
    @window.SystemCursorIcon::Default,
  )
}

///|
fn on_flight_helmet_pointer_drag(
  pointer : @app.OnPointer[@app.PointerDrag],
  scene_roots : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@scene.SceneRoot],
  ],
  commands : @app.Commands,
  windows : @ecs.Query[@core.Entity, @ecs.With[@window.PrimaryWindow]],
) -> Unit {
  try! scene_roots.view(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotate_y(pointer.delta().x * 0.01F) })
  })
  set_primary_window_cursor(
    commands,
    windows,
    @window.SystemCursorIcon::Grabbing,
  )
}

///|
fn on_flight_helmet_pointer_drag_end(
  _pointer : @app.OnPointer[@app.PointerDragEnd],
  commands : @app.Commands,
  windows : @ecs.Query[@core.Entity, @ecs.With[@window.PrimaryWindow]],
) -> Unit {
  set_primary_window_cursor(
    commands,
    windows,
    @window.SystemCursorIcon::Default,
  )
}

///|
fn spawn_lights(commands : @app.Commands) -> Unit {
  let directional_light = commands.spawn(
    (
      @pbr.DirectionalLight::DirectionalLight()
      .with_shadow_maps_enabled(true)
      .with_contact_shadows_enabled(true),
      @visibility.Visibility::Hidden,
    ),
  )

  let point_light = commands.spawn(
    (
      @pbr.PointLight::PointLight()
      .with_intensity(VERY_LARGE_CINEMA_LIGHT * 0.4F)
      .with_shadow_maps_enabled(true)
      .with_contact_shadows_enabled(true),
      @visibility.Visibility::Visible,
    ),
  )

  let spot_light = commands.spawn(
    (
      @pbr.SpotLight::SpotLight()
      .with_intensity(VERY_LARGE_CINEMA_LIGHT * 0.4F)
      .with_shadow_maps_enabled(true)
      .with_contact_shadows_enabled(true),
      @visibility.Visibility::Hidden,
    ),
  )

  let light_container = commands.spawn(
    (
      @transform.Transform::from_xyz(-0.8F, 1.5F, 1.2F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      @visibility.Visibility::Inherited,
      LightContainer::{  },
    ),
  )
  commands
  .entity(directional_light)
  .insert_component(@hierarchy.Parent::new(light_container))
  commands
  .entity(point_light)
  .insert_component(@hierarchy.Parent::new(light_container))
  commands
  .entity(spot_light)
  .insert_component(@hierarchy.Parent::new(light_container))
}

///|
fn spawn_flight_helmet(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let model = commands.spawn(
    (
      @scene.SceneRoot::new(
        @scene.scene_load_gltf_scene(
          asset_server,
          @gltf.GltfAssetLabel::Scene(0).from_asset(
            "models/FlightHelmet/FlightHelmet.gltf",
          ),
        ),
      ),
      @transform.Transform::from_rotation(
        @math.Quat::from_rotation_y(@math.pi()),
      ),
    ),
  )
  ignore(
    commands
    .entity(model)
    .observe_pointer4(on_flight_helmet_pointer_drag)
    .observe_pointer3(on_flight_helmet_pointer_over)
    .observe_pointer3(on_flight_helmet_pointer_out)
    .observe_pointer3(on_flight_helmet_pointer_drag_end),
  )
}

///|
fn spawn_ground_plane(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh = meshes.modify(fn(mesh_assets) {
    mesh_assets
    |> @pbr.add_mesh(
      @mesh_primitives.CircleMeshBuilder::from_circle(@math.Circle::Circle()).build(),
    )
  })
  let material = materials.modify(fn(material_assets) {
    material_assets.add(
      @pbr.StandardMaterial::from_color(@color.Color::srgb(0.06F, 0.06F, 0.06F)),
    )
  })
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_rotation(
          @math.Quat::from_axis_angle(
            @math.Vec3::new(1.0F, 0.0F, 0.0F),
            -@math.pi_half(),
          ),
        ),
        GroundPlane::{  },
      ),
    ),
  )
}

///|
fn spawn_buttons(commands : @app.Commands) -> Unit {
  let panel = commands.spawn_component(@widgets_lib.main_ui_node())
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Contact Shadows", [
      (ExampleSetting::ContactShadows(Enabled), "On"),
      (ExampleSetting::ContactShadows(Disabled), "Off"),
    ]),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Shadow Maps", [
      (ExampleSetting::ShadowMaps(Enabled), "On"),
      (ExampleSetting::ShadowMaps(Disabled), "Off"),
    ]),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Light Rotation", [
      (ExampleSetting::LightRotation(Rotating), "On"),
      (ExampleSetting::LightRotation(Stationary), "Off"),
    ]),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Light Type", [
      (ExampleSetting::LightType(Directional), "Directional"),
      (ExampleSetting::LightType(Point), "Point"),
      (ExampleSetting::LightType(Spot), "Spot"),
    ]),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Receive Shadows", [
      (ExampleSetting::ReceiveShadows(Enabled), "On"),
      (ExampleSetting::ReceiveShadows(Disabled), "Off"),
    ]),
  )
}

///|
fn spawn_drag_help_text(commands : @app.Commands) -> Unit {
  let root = commands.spawn_component(
    @ui.Node::Node()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.px(12.0F))
    .with_left(@ui.px(0.0F))
    .with_right(@ui.px(0.0F))
    .with_justify_content(@ui.JustifyContent::Center),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new("Drag model to spin"),
        @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(18.0F)),
      ),
    ),
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
  let pisa_diffuse = asset_server.load(
    "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2",
  )
  let pisa_specular = asset_server.load(
    "environment_maps/pisa_specular_rgb9e5_zstd.ktx2",
  )

  let camera = commands.spawn(
    @pbr.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      @transform.Transform::from_xyz(-0.8F, 0.6F, -0.8F).looking_at(
        @math.Vec3::new(0.0F, 0.35F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).with_motion_blur(
      Some(@post_process.MotionBlur::MotionBlur().with_shutter_angle(2.0F)),
    ),
  )
  commands
  .entity(camera)
  .insert(
    (
      @pbr.ContactShadows::ContactShadows(),
      @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
      @post_process.Bloom::Bloom(),
      @pbr.Hdr::Hdr(),
      @pbr.Skybox::new(pisa_diffuse, 1000.0F),
    ),
  )
  commands
  .entity(camera)
  .insert(
    (
      @pbr.EnvironmentMapLight::new(
        Some(pisa_diffuse),
        Some(pisa_specular),
        1000.0F,
      ),
      @post_process.ScreenSpaceAmbientOcclusion::ScreenSpaceAmbientOcclusion(),
      @pbr.Msaa::Off,
      @post_process.Tonemapping::AcesFitted,
    ),
  )

  spawn_lights(commands)
  spawn_flight_helmet(commands, asset_server)
  spawn_ground_plane(commands, meshes, materials)
  spawn_buttons(commands)
  spawn_drag_help_text(commands)
}

///|
fn rotate_light(
  lights : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[LightContainer],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  if app_status.get().light_rotation != Rotating {
    return
  }
  try! lights.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotate_around(
        @math.Vec3::zero(),
        @math.Quat::from_rotation_y(LIGHT_ROTATION_SPEED),
      )
    })
  })
}

///|
fn handle_ui_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[ExampleSetting]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[ExampleSetting],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[ExampleSetting]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.With[@widgets_lib.RadioButton],
  ],
  radio_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[ExampleSetting]],
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
      selected(sender.value().get(), status),
    )
  })
  try! radio_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      selected(sender.value().get(), status),
    )
  })
}

///|
fn apply_directional_light_settings(
  directional_lights : @ecs.Query[
    (@ecs.Write[@pbr.DirectionalLight], @ecs.Write[@visibility.Visibility]),
    @ecs.All,
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  try! directional_lights.view(fn(_entity, data) {
    let (light, visibility) = data
    light.set(
      light
      .value()
      .with_contact_shadows_enabled(status.contact_shadows == Enabled)
      .with_shadow_maps_enabled(status.shadow_maps == Enabled),
    )
    visibility.set(
      if status.light_type == Directional {
        @visibility.Visibility::Visible
      } else {
        @visibility.Visibility::Hidden
      },
    )
  })
}

///|
fn apply_point_light_settings(
  point_lights : @ecs.Query[
    (@ecs.Write[@pbr.PointLight], @ecs.Write[@visibility.Visibility]),
    @ecs.All,
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  try! point_lights.view(fn(_entity, data) {
    let (light, visibility) = data
    light.set(
      light
      .value()
      .with_contact_shadows_enabled(status.contact_shadows == Enabled)
      .with_shadow_maps_enabled(status.shadow_maps == Enabled),
    )
    visibility.set(
      if status.light_type == Point {
        @visibility.Visibility::Visible
      } else {
        @visibility.Visibility::Hidden
      },
    )
  })
}

///|
fn apply_spot_light_settings(
  spot_lights : @ecs.Query[
    (@ecs.Write[@pbr.SpotLight], @ecs.Write[@visibility.Visibility]),
    @ecs.All,
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  try! spot_lights.view(fn(_entity, data) {
    let (light, visibility) = data
    light.set(
      light
      .value()
      .with_contact_shadows_enabled(status.contact_shadows == Enabled)
      .with_shadow_maps_enabled(status.shadow_maps == Enabled),
    )
    visibility.set(
      if status.light_type == Spot {
        @visibility.Visibility::Visible
      } else {
        @visibility.Visibility::Hidden
      },
    )
  })
}

///|
fn update_receive_shadows(
  commands : @app.Commands,
  ground_planes : @ecs.Query[@core.Entity, @ecs.With[GroundPlane]],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let receive_shadows = app_status.get().receive_shadows
  try! ground_planes.view(fn(_query_entity, entity) {
    match receive_shadows {
      Enabled =>
        commands
        .entity(entity)
        .remove_component(@pbr.ecs_key_not_shadow_receiver)
      Disabled =>
        commands
        .entity(entity)
        .insert_component(@pbr.NotShadowReceiver::NotShadowReceiver())
    }
  })
}

///|
fn handle_setting_change(
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[ExampleSetting]],
  app_status : @app.ResMut[AppStatus],
) -> Unit {
  app_status.modify(fn(status) {
    for event in events.read() {
      match event.get() {
        ContactShadows(value) => status.contact_shadows = value
        ShadowMaps(value) => status.shadow_maps = value
        LightRotation(value) => status.light_rotation = value
        LightType(value) => status.light_type = value
        ReceiveShadows(value) => status.receive_shadows = value
      }
    }
  })
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[ExampleSetting],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_plugins(@mesh_picking.MeshPickingPlugin::MeshPickingPlugin())
  .init_resource(fn() { AppStatus::AppStatus() })
  .insert_resource(@pbr.GlobalAmbientLight::new(@color.Color::white(), 0.0F))
  .add_message(widget_click_message_key)
  .add_systems_param4(@app.Startup, setup)
  .add_systems_param2(@app.Update, rotate_light)
  .add_systems(
    @app.Update,
    @app.system_config_param2(handle_ui_interactions).in_set(
      contact_shadows_ui_interaction_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param2(handle_setting_change)
    .after(contact_shadows_ui_interaction_set)
    .in_set(contact_shadows_setting_change_set),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param3(update_radio_buttons).after(
      contact_shadows_setting_change_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param2(apply_directional_light_settings).after(
      contact_shadows_setting_change_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param2(apply_point_light_settings).after(
      contact_shadows_setting_change_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param2(apply_spot_light_settings).after(
      contact_shadows_setting_change_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system_config_param3(update_receive_shadows).after(
      contact_shadows_setting_change_set,
    ),
  )
  .run()
}
