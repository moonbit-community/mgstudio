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
/// Demonstrates light textures, which modulate light sources.

///|
const CUBE_ROTATION_SPEED : Float = 0.02F

///|
const PI : Float = 3.141592653589793F

///|
const FRAC_PI_2 : Float = 1.5707963267948966F

///|
const FRAC_PI_3 : Float = 1.0471975511965976F

///|
const FRAC_PI_4 : Float = 0.7853981633974483F

///|
const MOVE_SPEED : Float = 0.008F

///|
const SCALE_SPEED : Float = 0.05F

///|
const ROLL_SPEED : Float = 0.01F

///|
fn color_silver() -> @color.Color {
  @color.Color::srgb(0.7529412F, 0.7529412F, 0.7529412F)
}

///|
fn color_yellow() -> @color.Color {
  @color.Color::srgb(1.0F, 1.0F, 0.0F)
}

///|
pub(all) enum Selection {
  Camera
  SpotLight
  PointLight
  DirectionalLight
} derive(Eq, Debug)

///|
pub impl Default for Selection with fn default() {
  Selection::Camera
}

///|
pub(all) enum DragMode {
  Move
  Scale
  Roll
} derive(Eq, Debug)

///|
pub impl Default for DragMode with fn default() {
  DragMode::Move
}

///|
priv struct AppStatus {
  mut selection : Selection
  mut drag_mode : DragMode
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  AppStatus::{ selection: Selection::Camera, drag_mode: DragMode::Move }
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.light_textures.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
let selection_component_key : @ecs.ComponentKey[Selection] = @ecs.register_component(
  debug_name="examples.3d.light_textures.Selection",
)

///|
impl @ecs.Component for Selection with fn component() {
  selection_component_key
}

///|
impl @widgets_lib.WidgetValue for Selection with fn widget_debug_name() {
  "examples.3d.light_textures.Selection"
}

///|
let selection_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[Selection],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.light_textures.Selection>",
)

///|
impl @widgets_lib.WidgetValue for Selection with fn widget_click_event_key() {
  selection_widget_click_event_key
}

///|
let selection_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[Selection],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.light_textures.Selection>",
)

///|
impl @widgets_lib.WidgetValue for Selection with fn widget_click_sender_key() {
  selection_widget_click_sender_key
}

///|
let drag_mode_component_key : @ecs.ComponentKey[DragMode] = @ecs.register_component(
  debug_name="examples.3d.light_textures.DragMode",
)

///|
impl @ecs.Component for DragMode with fn component() {
  drag_mode_component_key
}

///|
priv struct HelpText {}

///|
let help_text_component_key : @ecs.ComponentKey[HelpText] = @ecs.register_component(
  debug_name="examples.3d.light_textures.HelpText",
)

///|
impl @ecs.Component for HelpText with fn component() {
  help_text_component_key
}

///|
priv struct Rotate {}

///|
let rotate_component_key : @ecs.ComponentKey[Rotate] = @ecs.register_component(
  debug_name="examples.3d.light_textures.Rotate",
)

///|
impl @ecs.Component for Rotate with fn component() {
  rotate_component_key
}

///|
fn selection_text(selection : Selection) -> String {
  match selection {
    Selection::Camera => "camera"
    Selection::SpotLight => "spotlight"
    Selection::PointLight => "point light"
    Selection::DirectionalLight => "directional light"
  }
}

///|
fn drag_mode_text(mode : DragMode) -> String {
  match mode {
    DragMode::Move => "move"
    DragMode::Scale => "scale"
    DragMode::Roll => "roll"
  }
}

///|
fn create_help_string(app_status : AppStatus) -> String {
  "Click and drag to \{drag_mode_text(app_status.drag_mode)} \{selection_text(app_status.selection)}"
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Light Textures Example"
  window
}

///|
fn clustered_decals_are_usable() -> Bool {
  @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=0U,
  )
}

///|
fn spawn_cubes(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let transform = @transform.Transform::identity()
  transform.rotate_y(FRAC_PI_3)
  let material_handle = materials
    .peek()
    .add(@pbr.StandardMaterial::from_color(color_silver()))
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.peek() |> @pbr.add_mesh(@math.Cuboid::new(3.0F, 3.0F, 3.0F)),
        ),
        @pbr.MeshMaterial3d::new(material_handle),
        transform,
        Rotate::{  },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.peek()
          |> @pbr.add_mesh(@math.Cuboid::new(-13.0F, -13.0F, -13.0F)),
        ),
        @pbr.MeshMaterial3d::new(material_handle),
        transform,
      ),
    ),
  )
}

///|
fn spawn_light(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let parent = commands.spawn(
    (
      @visibility.Visibility::Hidden,
      @transform.Transform::from_xyz(8.0F, 8.0F, 4.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      Selection::DirectionalLight,
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(parent),
        @pbr.DirectionalLight::new(
          @color.Color::white(),
          @light_lux.AMBIENT_DAYLIGHT,
          false,
        ),
        @pbr.DirectionalLightTexture::new(
          Some(asset_server.load("lightmaps/caustic_directional_texture.png")),
          true,
        ),
        @visibility.Visibility::Visible,
      ),
    ),
  )
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  let camera = commands.spawn_component(@camera.Camera3d::Camera3d())
  commands
  .entity(camera)
  .insert(
    (
      @transform.Transform::from_xyz(0.0F, 2.5F, 9.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      Selection::Camera,
    ),
  )
}

///|
fn spawn_light_textures(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.SpotLight::new(
          @color.Color::srgb(1.0F, 1.0F, 0.8F),
          10_000_000.0F,
          20.0F,
          0.25F,
          0.25F,
          true,
        ),
        @transform.Transform::from_translation(
          @math.Vec3::new(6.0F, 1.0F, 2.0F),
        ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
        @pbr.SpotLightTexture::new(
          Some(asset_server.load("lightmaps/torch_spotlight_texture.png")),
        ),
        @visibility.Visibility::Inherited,
        Selection::SpotLight,
      ),
    ),
  )

  let point_parent = commands.spawn(
    (
      @visibility.Visibility::Hidden,
      @transform.Transform::from_translation(@math.Vec3::new(0.0F, 1.8F, 0.01F)).with_scale(
        @math.Vec3::splat(0.1F),
      ),
      Selection::PointLight,
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(point_parent),
        @scene.WorldAssetRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server,
            @gltf.GltfAssetLabel::Scene(0).from_asset("models/Faces/faces.glb"),
          ),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(point_parent),
        @mesh.Mesh3d::new(
          meshes.peek() |> @pbr.add_mesh(@math.Sphere::new(1.0F)),
        ),
        @pbr.MeshMaterial3d::new(
          materials
          .peek()
          .add(
            @pbr.StandardMaterial::StandardMaterial().with_emissive(
              @color.Color::srgb(0.0F, 0.0F, 300.0F),
            ),
          ),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(point_parent),
        @pbr.PointLight::new(
          @color.Color::srgb(0.0F, 0.0F, 1.0F),
          1_000_000.0F,
          20.0F,
          true,
        ),
        @pbr.PointLightTexture::new(
          Some(
            asset_server.load("lightmaps/faces_pointlight_texture_blurred.png"),
          ),
          @pbr.CubemapLayout3d::CrossVertical,
        ),
      ),
    ),
  )
}

///|
fn drag_button(
  commands : @app.Commands,
  parent : @core.Entity,
  label : String,
  mode : DragMode,
) -> @core.Entity {
  let (text, text_font, text_color) = @widgets_lib.ui_text(
    label,
    @color.Color::white(),
  )
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node()
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_padding(
        @ui.UiRect::new(
          @ui.Val::Px(12.0F),
          @ui.Val::Px(6.0F),
          @ui.Val::Px(12.0F),
          @ui.Val::Px(6.0F),
        ),
      )
      .with_border_radius(@ui.BorderRadius::all(@ui.Val::Px(6.0F))),
      @ui.Button::Button(),
      @ui.BackgroundColor::new(@color.Color::black()),
      @ui.BorderColor::new(@color.Color::white()),
      mode,
    ),
  )
  ignore(
    commands.spawn(
      (@hierarchy.Parent::new(button), text, text_font, text_color),
    ),
  )
  button
}

///|
fn spawn_buttons(commands : @app.Commands) -> Unit {
  let panel = commands.spawn_component(@widgets_lib.main_ui_node())
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Drag to Move", [
      (Selection::Camera, "Camera"),
      (Selection::SpotLight, "Spotlight"),
      (Selection::PointLight, "Point Light"),
      (Selection::DirectionalLight, "Directional Light"),
    ]),
  )
  let drag_panel = commands.spawn_component(
    @ui.Node::Node()
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_position_type(@ui.PositionType::Absolute)
    .with_right(@ui.Val::Px(10.0F))
    .with_bottom(@ui.Val::Px(10.0F))
    .with_column_gap(@ui.Val::Px(6.0F)),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, drag_panel, "", [
      (@visibility.Visibility::Inherited, "Show"),
      (@visibility.Visibility::Hidden, "Hide"),
    ]),
  )
  ignore(drag_button(commands, drag_panel, "Scale", DragMode::Scale))
  ignore(drag_button(commands, drag_panel, "Roll", DragMode::Roll))
}

///|
fn spawn_help_text(commands : @app.Commands, app_status : AppStatus) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(create_help_string(app_status)),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        HelpText::{  },
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  app_status : @app.Res[AppStatus],
  app_exit : @ecs.MessageWriter[@app.AppExit],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  if !clustered_decals_are_usable() {
    ignore(app_exit.write(@app.AppExit::error()))
    return
  }
  let asset_server = asset_server.get()
  spawn_cubes(commands, meshes, materials)
  spawn_camera(commands)
  spawn_light(commands, asset_server)
  spawn_buttons(commands)
  spawn_help_text(commands, app_status.get())
  spawn_light_textures(commands, asset_server, meshes, materials)
}

///|
fn draw_gizmos(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
  spotlights : @ecs.Query[
    (
      @ecs.Read[@transform.GlobalTransform],
      @ecs.Read[@pbr.SpotLight],
      @ecs.Read[@visibility.Visibility],
    ),
    @ecs.All,
  ],
) -> Unit {
  try! spotlights.view(fn(_entity, data) {
    let (global_transform, spotlight, visibility) = data
    if visibility.value() == @visibility.Visibility::Hidden {
      return
    }
    let transform = global_transform.value().to_transform_approx()
    transform.rotation = transform.rotation.mul(
      @math.Quat::from_rotation_x(FRAC_PI_2),
    )
    transform.translation = transform.translation.mul_scalar(0.5F)
    @gizmos_primitives.gizmo_draw_cone_3d(
      gizmos,
      @math.Isometry3d::new(transform.translation, transform.rotation),
      @math.Cone::new(7.0F * spotlight.value().outer_angle, 7.0F),
      color_yellow(),
    )
  })
}

///|
fn rotate_cube(
  meshes : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Rotate]],
) -> Unit {
  try! meshes.view(fn(_entity, transform) {
    let next = transform.value()
    next.rotate_y(CUBE_ROTATION_SPEED)
    transform.set(next)
  })
}

///|
fn hide_shadows(
  commands : @app.Commands,
  meshes : @ecs.Query[
    @core.Entity,
    (
      @ecs.With[@mesh.Mesh3d],
      @ecs.Without[@pbr.NotShadowCaster],
      @ecs.Without[Rotate],
    ),
  ],
) -> Unit {
  try! meshes.view(fn(_query_entity, entity) {
    commands
    .entity(entity)
    .insert_component(@pbr.NotShadowCaster::NotShadowCaster())
  })
}

///|
fn handle_selection_ui_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[Selection]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[Selection],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn handle_visibility_ui_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[@visibility.Visibility]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[@visibility.Visibility],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn update_radio_buttons(
  selection_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[Selection]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    (
      @ecs.With[@widgets_lib.RadioButton],
      @ecs.Without[@widgets_lib.WidgetClickSender[@visibility.Visibility]],
    ),
  ],
  selection_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[Selection]],
      @ecs.Write[@text.TextColor],
    ),
    (
      @ecs.With[@widgets_lib.RadioButtonText],
      @ecs.Without[@widgets_lib.WidgetClickSender[@visibility.Visibility]],
    ),
  ],
  visibility_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[@visibility.Visibility]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    (
      @ecs.With[@widgets_lib.RadioButton],
      @ecs.Without[@widgets_lib.WidgetClickSender[Selection]],
    ),
  ],
  visibility_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[@visibility.Visibility]],
      @ecs.Write[@text.TextColor],
    ),
    (
      @ecs.With[@widgets_lib.RadioButtonText],
      @ecs.Without[@widgets_lib.WidgetClickSender[Selection]],
    ),
  ],
  visible : @ecs.Query[
    (@ecs.Read[@visibility.Visibility], @ecs.Read[Selection]),
    @ecs.All,
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  try! selection_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      status.selection == sender.value().get(),
    )
  })
  try! selection_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      status.selection == sender.value().get(),
    )
  })
  let mut current_visibility = @visibility.Visibility::Inherited
  try! visible.view(fn(_entity, data) {
    let (visibility, selection) = data
    if selection.value() == status.selection {
      current_visibility = visibility.value()
    }
  })
  try! visibility_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      sender.value().get() == current_visibility,
    )
  })
  try! visibility_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      sender.value().get() == current_visibility,
    )
  })
}

///|
fn handle_selection_change(
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[Selection]],
  app_status : @app.ResMut[AppStatus],
) -> Unit {
  app_status.modify(fn(status) {
    for event in events.read() {
      status.selection = event.get()
    }
  })
}

///|
fn toggle_visibility(
  events : @ecs.MessageReader[
    @widgets_lib.WidgetClickEvent[@visibility.Visibility],
  ],
  app_status : @app.Res[AppStatus],
  visibility : @ecs.Query[
    (@ecs.Write[@visibility.Visibility], @ecs.Read[Selection]),
    @ecs.All,
  ],
) -> Unit {
  let mut last_visibility : @visibility.Visibility? = None
  for event in events.read() {
    last_visibility = Some(event.get())
  }
  guard last_visibility is Some(next_visibility) else { return }
  let selection = app_status.get().selection
  try! visibility.view(fn(_entity, data) {
    let (visibility, entity_selection) = data
    if entity_selection.value() == selection {
      visibility.set(next_visibility)
    }
  })
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
fn clamp_vec3(
  value : @math.Vec3,
  min_value : @math.Vec3,
  max_value : @math.Vec3,
) -> @math.Vec3 {
  @math.Vec3::new(
    clampf(value.x, min_value.x, max_value.x),
    clampf(value.y, min_value.y, max_value.y),
    clampf(value.z, min_value.z, max_value.z),
  )
}

///|
fn signum(value : Float) -> Float {
  if value < 0.0F {
    -1.0F
  } else {
    1.0F
  }
}

///|
fn selection_move_factors(selection : Selection) -> (Float, Float) {
  match selection {
    Selection::Camera => (1.0F, -1.0F)
    Selection::SpotLight
    | Selection::PointLight
    | Selection::DirectionalLight => (-1.0F, 1.0F)
  }
}

///|
fn move_selection_transform(
  transform : @transform.Transform,
  selection : Selection,
  delta : @math.Vec2,
) -> @transform.Transform {
  if selection == Selection::PointLight {
    return transform.with_translation(
      transform.translation.add(
        @math.Vec3::new(delta.x * MOVE_SPEED, -delta.y * MOVE_SPEED, 0.0F),
      ),
    )
  }
  let position = transform.translation
  let radius = position.length()
  let horizontal = @math.sqrt(position.x * position.x + position.z * position.z)
  let mut theta = @math.acos(position.y / radius)
  let mut phi = signum(position.z) * @math.acos(position.x / horizontal)
  let (phi_factor, theta_factor) = selection_move_factors(selection)
  phi = phi + phi_factor * delta.x * MOVE_SPEED
  theta = clampf(
    theta + theta_factor * delta.y * MOVE_SPEED,
    0.001F,
    PI - 0.001F,
  )
  let translation = @math.Vec3::new(
    radius * @math.sin(theta) * @math.cos(phi),
    radius * @math.cos(theta),
    radius * @math.sin(theta) * @math.sin(phi),
  )
  let (_, _, roll) = transform.rotation.to_euler(@math.EulerRot::YXZ)
  let oriented = transform
    .with_translation(translation)
    .looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  let (yaw, pitch, _) = oriented.rotation.to_euler(@math.EulerRot::YXZ)
  oriented.with_rotation(
    @math.Quat::from_euler(@math.EulerRot::YXZ, yaw, pitch, roll),
  )
}

///|
fn process_move_input(
  selections : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Selection]),
    @ecs.All,
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  if !mouse_buttons.pressed(@window.MouseButton::Left) ||
    status.drag_mode != DragMode::Move {
    return
  }
  let delta = mouse_motion.get().delta
  try! selections.view(fn(_entity, data) {
    let (transform, selection) = data
    let selection = selection.value()
    if status.selection != selection {
      return
    }
    transform.set(move_selection_transform(transform.value(), selection, delta))
  })
}

///|
fn process_scale_input(
  selections : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Selection]),
    @ecs.All,
  ],
  spotlights : @ecs.Query[
    (@ecs.Write[@pbr.SpotLight], @ecs.Read[Selection]),
    @ecs.All,
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  if !mouse_buttons.pressed(@window.MouseButton::Left) ||
    status.drag_mode != DragMode::Scale {
    return
  }
  let delta = mouse_motion.get().delta
  try! selections.view(fn(_entity, data) {
    let (transform, selection) = data
    if status.selection == selection.value() {
      let value = transform.value()
      transform.set(
        value.with_scale(
          clamp_vec3(
            value.scale.mul_scalar(1.0F + delta.x * SCALE_SPEED),
            @math.Vec3::splat(0.01F),
            @math.Vec3::splat(5.0F),
          ),
        ),
      )
    }
  })
  try! spotlights.view(fn(_entity, data) {
    let (spotlight, selection) = data
    if status.selection == selection.value() {
      let outer_angle = clampf(
        spotlight.value().outer_angle * (1.0F + delta.x * SCALE_SPEED),
        0.01F,
        FRAC_PI_4,
      )
      spotlight.set(
        spotlight
        .value()
        .with_outer_angle(outer_angle)
        .with_inner_angle(outer_angle),
      )
    }
  })
}

///|
fn process_roll_input(
  selections : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Selection]),
    @ecs.All,
  ],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()
  if !mouse_buttons.pressed(@window.MouseButton::Left) ||
    status.drag_mode != DragMode::Roll {
    return
  }
  let delta = mouse_motion.get().delta
  try! selections.view(fn(_entity, data) {
    let (transform, selection) = data
    if status.selection != selection.value() {
      return
    }
    let (yaw, pitch, roll) = transform.value().rotation.to_euler(
      @math.EulerRot::YXZ,
    )
    transform.set(
      transform
      .value()
      .with_rotation(
        @math.Quat::from_euler(
          @math.EulerRot::YXZ,
          yaw,
          pitch,
          roll + delta.x * ROLL_SPEED,
        ),
      ),
    )
  })
}

///|
fn switch_drag_mode(
  commands : @app.Commands,
  interactions : @ecs.Query[
    (@ecs.Read[@ui.Interaction], @ecs.Read[DragMode]),
    @ecs.All,
  ],
  windows : @ecs.Query[@core.Entity, @ecs.With[@window.Window]],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
  app_status : @app.ResMut[AppStatus],
) -> Unit {
  if mouse_buttons.pressed(@window.MouseButton::Left) {
    return
  }
  let mut hovered_mode : DragMode? = None
  try! interactions.view(fn(_entity, data) {
    let (interaction, drag_mode) = data
    if interaction.value() == @ui.Interaction::Hovered {
      hovered_mode = Some(drag_mode.value())
    }
  })
  app_status.modify(fn(status) {
    match hovered_mode {
      Some(mode) => status.drag_mode = mode
      None => status.drag_mode = DragMode::Move
    }
  })
  try! windows.view(fn(_query_entity, window_entity) {
    match hovered_mode {
      Some(_) =>
        commands
        .entity(window_entity)
        .insert_component(
          @window.CursorIcon::from(@window.SystemCursorIcon::EwResize),
        )
      None =>
        commands
        .entity(window_entity)
        .remove_component(@window.ecs_key_cursor_icon)
    }
  })
}

///|
fn update_help_text(
  help_text : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[HelpText]],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let next = create_help_string(app_status.get())
  try! help_text.view(fn(_entity, text) { text.set(@text.Text::new(next)) })
}

///|
fn update_button_visibility(
  drag_nodes : @ecs.Query[
    @ecs.Write[@visibility.Visibility],
    (
      @ecs.With[DragMode],
      @ecs.Without[@widgets_lib.WidgetClickSender[@visibility.Visibility]],
    ),
  ],
  visibility_nodes : @ecs.Query[
    @ecs.Write[@visibility.Visibility],
    (
      @ecs.With[@widgets_lib.WidgetClickSender[@visibility.Visibility]],
      @ecs.Without[DragMode],
    ),
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let visible = match app_status.get().selection {
    Selection::Camera => @visibility.Visibility::Hidden
    Selection::SpotLight
    | Selection::PointLight
    | Selection::DirectionalLight => @visibility.Visibility::Visible
  }
  try! drag_nodes.view(fn(_entity, visibility) { visibility.set(visible) })
  try! visibility_nodes.view(fn(_entity, visibility) { visibility.set(visible) })
}

///|
fn update_directional_light(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  selections : @ecs.Query[
    (@ecs.Read[Selection], @ecs.Read[@visibility.Visibility]),
    @ecs.All,
  ],
  lights : @ecs.Query[
    (
      @core.Entity,
      @ecs.Write[@pbr.DirectionalLight],
      @ecs.Read[@pbr.DirectionalLightTexture]?,
    ),
    @ecs.All,
  ],
) -> Unit {
  let mut directional_visible = false
  let mut any_texture_light_visible = false
  try! selections.view(fn(_entity, data) {
    let (selection, visibility) = data
    if visibility.value() == @visibility.Visibility::Hidden {
      return
    }
    match selection.value() {
      Selection::DirectionalLight => directional_visible = true
      Selection::SpotLight | Selection::PointLight =>
        any_texture_light_visible = true
      Selection::Camera => ()
    }
  })
  try! lights.view(fn(_query_entity, data) {
    let (entity, light, maybe_texture) = data
    if directional_visible {
      light.set(light.value().with_illuminance(@light_lux.AMBIENT_DAYLIGHT))
      if maybe_texture is None {
        commands
        .entity(entity)
        .insert_component(
          @pbr.DirectionalLightTexture::new(
            Some(
              asset_server
              .get()
              .load("lightmaps/caustic_directional_texture.png"),
            ),
            true,
          ),
        )
      }
    } else if any_texture_light_visible {
      light.set(light.value().with_illuminance(@light_lux.CLEAR_SUNRISE))
      if maybe_texture is Some(_) {
        commands
        .entity(entity)
        .remove_component(@pbr.ecs_key_directional_light_texture)
      }
    } else {
      light.set(light.value().with_illuminance(@light_lux.AMBIENT_DAYLIGHT))
      if maybe_texture is Some(_) {
        commands
        .entity(entity)
        .remove_component(@pbr.ecs_key_directional_light_texture)
      }
    }
  })
}

///|
let light_textures_selection_interaction_set : @app.SystemSet = @app.system_set(
  "examples.3d.light_textures.selection_interaction",
)

///|
let light_textures_visibility_interaction_set : @app.SystemSet = @app.system_set(
  "examples.3d.light_textures.visibility_interaction",
)

///|
fn main {
  let selection_widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[Selection],
  ] = @widgets_lib.widget_click_event_key()
  let visibility_widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[@visibility.Visibility],
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
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(selection_widget_click_message_key)
  .add_message(visibility_widget_click_message_key)
  .add_systems_param6(@app.Startup, setup)
  .add_systems_param2(@app.Update, draw_gizmos)
  .add_systems_param(@app.Update, rotate_cube)
  .add_systems_param2(@app.Update, hide_shadows)
  .add_system_config(
    @app.system_config_param2(handle_selection_ui_interactions).in_set(
      light_textures_selection_interaction_set,
    ),
  )
  .add_system_config(
    @app.system_config_param2(handle_visibility_ui_interactions).in_set(
      light_textures_visibility_interaction_set,
    ),
  )
  .add_system_config(
    @app.system_config_param2(handle_selection_change).after(
      light_textures_selection_interaction_set,
    ),
  )
  .add_system_config(
    @app.system_config_param6(update_radio_buttons)
    .after(light_textures_selection_interaction_set)
    .after(light_textures_visibility_interaction_set),
  )
  .add_systems_param3(@app.Update, toggle_visibility)
  .add_systems_param4(@app.Update, update_directional_light)
  .add_systems_param4(@app.Update, process_move_input)
  .add_systems_param5(@app.Update, process_scale_input)
  .add_systems_param4(@app.Update, process_roll_input)
  .add_systems_param5(@app.Update, switch_drag_mode)
  .add_systems_param2(@app.Update, update_help_text)
  .add_systems_param3(@app.Update, update_button_visibility)
  .run()
}
