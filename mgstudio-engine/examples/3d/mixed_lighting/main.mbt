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
const LIGHTMAP_EXPOSURE : Float = 600.0F

///|
const SPHERE_OFFSET : Float = 0.2F

///|
const MIXED_LIGHTING_SCENE : String = "models/MixedLightingExample/MixedLightingExample.gltf"

///|
const LIGHTMAP_BAKED : String = "lightmaps/MixedLightingExample-Baked.zstd.ktx2"

///|
const LIGHTMAP_MIXED_DIRECT : String = "lightmaps/MixedLightingExample-MixedDirect.zstd.ktx2"

///|
const LIGHTMAP_MIXED_INDIRECT : String = "lightmaps/MixedLightingExample-MixedIndirect.zstd.ktx2"

///|
pub(all) enum LightingMode {
  Baked
  MixedDirect
  MixedIndirect
  RealTime
} derive(Eq)

///|
impl @widgets_lib.WidgetValue for LightingMode with fn widget_debug_name() {
  "examples.3d.mixed_lighting.LightingMode"
}

///|
let lighting_mode_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[LightingMode],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.mixed_lighting.LightingMode>",
)

///|
impl @widgets_lib.WidgetValue for LightingMode with fn widget_click_event_key() {
  lighting_mode_widget_click_event_key
}

///|
let lighting_mode_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[LightingMode],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.mixed_lighting.LightingMode>",
)

///|
impl @widgets_lib.WidgetValue for LightingMode with fn widget_click_sender_key() {
  lighting_mode_widget_click_sender_key
}

///|
priv struct AppStatus {
  mut lighting_mode : LightingMode
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.mixed_lighting.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  { lighting_mode: MixedIndirect }
}

///|
priv struct LightingModeChanged {}

///|
let lighting_mode_changed_message_key : @ecs.MessageKey[LightingModeChanged] = @ecs.register_message(
  debug_name="examples.3d.mixed_lighting.LightingModeChanged",
)

///|
impl @ecs.Message for LightingModeChanged with fn message() {
  lighting_mode_changed_message_key
}

///|
priv struct HelpText {}

///|
let help_text_component_key : @ecs.ComponentKey[HelpText] = @ecs.register_component(
  debug_name="examples.3d.mixed_lighting.HelpText",
)

///|
impl @ecs.Component for HelpText with fn component() {
  help_text_component_key
}

///|
fn initial_sphere_position() -> @math.Vec3 {
  @math.Vec3::new(0.0F, 0.5233223F, 0.0F)
}

///|
fn uv_rect_opengl(gl_min : @math.Vec2, size : @math.Vec2) -> @math.Rect {
  let min = @math.Vec2::new(gl_min.x, 1.0F - gl_min.y - size.y)
  @math.Rect::new(min, @math.Vec2::new(min.x + size.x, min.y + size.y))
}

///|
fn sphere_uv_rect() -> @math.Rect {
  uv_rect_opengl(@math.Vec2::new(0.788F, 0.484F), @math.Vec2::splat(0.062F))
}

///|
fn lightmap_uv_rect_for_name(name : String) -> @math.Rect? {
  if name == "Plane" {
    return Some(
      uv_rect_opengl(@math.Vec2::splat(0.026F), @math.Vec2::splat(0.710F)),
    )
  }
  if name == "SheenChair_fabric" {
    return Some(
      uv_rect_opengl(
        @math.Vec2::new(0.7864F, 0.02377F),
        @math.Vec2::new(0.1910F, 0.1912F),
      ),
    )
  }
  if name == "SheenChair_label" {
    return Some(
      uv_rect_opengl(
        @math.Vec2::new(0.275F, -0.016F),
        @math.Vec2::new(0.858F, 0.486F),
      ),
    )
  }
  if name == "SheenChair_metal" {
    return Some(
      uv_rect_opengl(
        @math.Vec2::new(0.998F, 0.506F),
        @math.Vec2::new(-0.029F, -0.067F),
      ),
    )
  }
  if name == "SheenChair_wood" {
    return Some(
      uv_rect_opengl(
        @math.Vec2::new(0.787F, 0.257F),
        @math.Vec2::new(0.179F, 0.177F),
      ),
    )
  }
  None
}

///|
fn lightmap_handle_for_mode(
  asset_server : @asset.AssetServer,
  mode : LightingMode,
) -> @asset.Handle[@asset.Image]? {
  match mode {
    Baked => Some(asset_server.load(LIGHTMAP_BAKED))
    MixedDirect => Some(asset_server.load(LIGHTMAP_MIXED_DIRECT))
    MixedIndirect => Some(asset_server.load(LIGHTMAP_MIXED_INDIRECT))
    RealTime => None
  }
}

///|
fn set_material_lightmap_exposure(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  mesh_material : @pbr.MeshMaterial3d,
) -> Unit {
  if !mesh_material.is_standard_material() {
    return
  }
  let material_handle : @asset.Handle[@pbr.StandardMaterial] = @asset.Handle::new(
    mesh_material.material_asset_id(),
  )
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
fn lightmap_component(
  image : @asset.Handle[@asset.Image],
  uv_rect : @math.Rect,
) -> @pbr.Lightmap {
  @pbr.Lightmap::new(image).with_uv_rect(uv_rect).with_bicubic_sampling(false)
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  commands.queue(fn(world) {
    ignore(
      @pbr.Camera3dBundle::new(
        Camera(),
        @transform.Transform::from_xyz(-0.7F, 0.7F, 1.0F).looking_at(
          @math.Vec3::new(0.0F, 0.3F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ).spawn(world),
    )
  })
}

///|
#warnings("-unnecessary_annotation")
fn send_lighting_mode_changed_when_scene_ready(
  _event : @ecs.On[@scene.SceneInstanceReady],
  writer : @ecs.MessageWriter[LightingModeChanged],
) -> Unit {
  ignore(writer.write(LightingModeChanged::{  }))
}

///|
fn spawn_scene(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let root = commands.spawn_component(
    @scene.SceneRoot::new(
      asset_server
      .get()
      .load(@gltf.GltfAssetLabel::Scene(0).from_asset(MIXED_LIGHTING_SCENE)),
    ),
  )
  ignore(
    commands.entity(root).observe2(send_lighting_mode_changed_when_scene_ready),
  )
}

///|
fn spawn_buttons(commands : @app.Commands, root : @core.Entity) -> Unit {
  let panel = commands.spawn(
    (@hierarchy.Parent::new(root), @widgets_lib.main_ui_node()),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(commands, panel, "Lighting", [
      (Baked, "Baked"),
      (MixedDirect, "Mixed (Direct)"),
      (MixedIndirect, "Mixed (Indirect)"),
      (RealTime, "Real-Time"),
    ]),
  )
}

///|
fn create_help_text(app_status : AppStatus) -> @text.Text {
  match app_status.lighting_mode {
    Baked =>
      @text.Text::new(
        "Scenery: Static, baked direct light, baked indirect light\nSphere: Static, baked direct light, baked indirect light",
      )
    MixedDirect =>
      @text.Text::new(
        "Scenery: Static, baked direct light, baked indirect light\nSphere: Dynamic, real-time direct light, no indirect light\nClick in the scene to move the sphere",
      )
    MixedIndirect =>
      @text.Text::new(
        "Scenery: Static, real-time direct light, baked indirect light\nSphere: Dynamic, real-time direct light, no indirect light\nClick in the scene to move the sphere",
      )
    RealTime =>
      @text.Text::new(
        "Scenery: Dynamic, real-time direct light, no indirect light\nSphere: Dynamic, real-time direct light, no indirect light\nClick in the scene to move the sphere",
      )
  }
}

///|
fn spawn_help_text(
  commands : @app.Commands,
  root : @core.Entity,
  app_status : AppStatus,
) -> Unit {
  let help_text = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::Node()
      .with_position_type(Absolute)
      .with_top(Px(12.0F))
      .with_left(Px(12.0F)),
      create_help_text(app_status),
      @text.TextFont::TextFont(),
      @text.TextColor::TextColor(),
      @text.TextLayout::TextLayout(),
      @text.LineHeight::default(),
      @text.FontHinting::default(),
    ),
  )
  commands.entity(help_text).insert_component(HelpText::{  })
}

///|
fn spawn_ui(commands : @app.Commands, app_status : AppStatus) -> Unit {
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
      @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  spawn_buttons(commands, root)
  spawn_help_text(commands, root, app_status)
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  app_status : @app.Res[AppStatus],
) -> Unit {
  spawn_camera(commands)
  spawn_scene(commands, asset_server)
  spawn_ui(commands, app_status.get())
}

///|
type LightmapMeshQuery = @ecs.Query[
  (@ecs.Read[@gltf.GltfMeshName], @ecs.Read[@pbr.MeshMaterial3d]),
  @ecs.With[@mesh.Mesh3d],
]

///|
fn update_lightmaps(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : LightmapMeshQuery,
  _reader : @ecs.MessageReader[LightingModeChanged],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let mode = app_status.get().lighting_mode
  let lightmap = lightmap_handle_for_mode(asset_server.get(), mode)
  try! meshes.view(fn(entity, data) {
    let (mesh_name, mesh_material) = data
    let name = mesh_name.value().as_str()
    guard lightmap_uv_rect_for_name(name) is Some(uv_rect) else {
      if name == "Sphere" {
        set_material_lightmap_exposure(materials, mesh_material.value())
        match (lightmap, mode) {
          (Some(image), Baked) =>
            commands
            .entity(entity)
            .insert_component(lightmap_component(image, sphere_uv_rect()))
          _ => commands.entity(entity).remove_component(@pbr.ecs_key_lightmap)
        }
      }
      return
    }
    set_material_lightmap_exposure(materials, mesh_material.value())
    match lightmap {
      Some(image) =>
        commands
        .entity(entity)
        .insert_component(lightmap_component(image, uv_rect))
      None => commands.entity(entity).remove_component(@pbr.ecs_key_lightmap)
    }
  })
}

///|
fn update_directional_light(
  lights : @ecs.Query[@ecs.Write[@pbr.DirectionalLight], @ecs.All],
  _reader : @ecs.MessageReader[LightingModeChanged],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let mode = app_status.get().lighting_mode
  let scenery_is_lit_in_real_time = mode == MixedIndirect || mode == RealTime
  try! lights.view(fn(_entity, light) {
    light.set(
      light
      .value()
      .with_affects_lightmapped_mesh_diffuse(scenery_is_lit_in_real_time)
      .with_shadow_maps_enabled(scenery_is_lit_in_real_time),
    )
  })
}

///|
fn make_sphere_nonpickable(
  commands : @app.Commands,
  spheres : @ecs.Query[
    @ecs.Read[@gltf.GltfMeshName],
    (@ecs.With[@mesh.Mesh3d], @ecs.Without[@picking.Pickable]),
  ],
) -> Unit {
  try! spheres.view(fn(entity, mesh_name) {
    if mesh_name.value().as_str() == "Sphere" {
      commands.entity(entity).insert_component(@picking.pickable_ignore)
    }
  })
}

///|
fn handle_widget_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[LightingMode]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[LightingMode],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[LightingMode]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.With[@widgets_lib.RadioButton],
  ],
  radio_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[LightingMode]],
      @ecs.Write[@text.TextColor],
    ),
    @ecs.With[@widgets_lib.RadioButtonText],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let mode = app_status.get().lighting_mode
  try! radio_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      sender.value().get() == mode,
    )
  })
  try! radio_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      sender.value().get() == mode,
    )
  })
}

///|
#warnings("-unnecessary_annotation")
fn handle_lighting_mode_change(
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[LightingMode]],
  writer : @ecs.MessageWriter[LightingModeChanged],
  app_status : @app.ResMut[AppStatus],
) -> Unit {
  let mut changed = false
  app_status.modify(fn(status) {
    for event in events.read() {
      status.lighting_mode = event.get()
      changed = true
    }
  })
  if changed {
    ignore(writer.write(LightingModeChanged::{  }))
  }
}

///|
fn reset_sphere_position(
  objects : @ecs.Query[
    (@ecs.Read[@gltf.GltfMeshName], @ecs.Write[@transform.Transform]),
    @ecs.All,
  ],
  _reader : @ecs.MessageReader[LightingModeChanged],
  app_status : @app.Res[AppStatus],
) -> Unit {
  if app_status.get().lighting_mode != Baked {
    return
  }
  try! objects.view(fn(_entity, data) {
    let (name, transform) = data
    if name.value().as_str() == "Sphere" {
      transform.modify(fn(value) {
        value.translation = initial_sphere_position()
      })
    }
  })
}

///|
fn move_sphere(
  pointers : @ecs.Query[@ecs.Read[@picking.PointerInteraction], @ecs.All],
  meshes : @ecs.Query[
    (@ecs.Read[@gltf.GltfMeshName], @ecs.Read[@hierarchy.Parent]),
    @ecs.With[@mesh.Mesh3d],
  ],
  transforms : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.All],
  app_status : @app.Res[AppStatus],
) -> Unit {
  if app_status.get().lighting_mode == Baked ||
    !@input.mouse_button_pressed(Left) {
    return
  }
  let sphere_parent : Ref[@core.Entity?] = Ref(None)
  try! meshes.view(fn(_entity, data) {
    let (name, parent) = data
    if sphere_parent.val is None && name.value().as_str() == "Sphere" {
      sphere_parent.val = Some(parent.value().entity())
    }
  })
  guard sphere_parent.val is Some(parent) else { return }
  guard (transforms.get(parent) catch { _ => None }) is Some(transform) else {
    return
  }
  try! pointers.view(fn(_entity, interaction) {
    guard interaction.value().get_nearest_hit() is Some((_hit_entity, hit)) else {
      return
    }
    guard hit.position is Some(position) else { return }
    transform.modify(fn(value) {
      value.translation = position.add(
        @math.Vec3::new(0.0F, SPHERE_OFFSET, 0.0F),
      )
    })
  })
}

///|
fn adjust_help_text(
  help_texts : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[HelpText]],
  app_status : @app.Res[AppStatus],
  _reader : @ecs.MessageReader[LightingModeChanged],
) -> Unit {
  let text = create_help_text(app_status.get())
  try! help_texts.view(fn(_entity, help_text) { help_text.set(text) })
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[LightingMode],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(
    @pbr.GlobalAmbientLight::new(
      @camera_clear_color.ClearColor::ClearColor().color,
      10000.0F,
    ).with_affects_lightmapped_meshes(true),
  )
  .init_resource(fn() { AppStatus::AppStatus() })
  .add_message(widget_click_message_key)
  .add_message(lighting_mode_changed_message_key)
  .add_systems_param3(Startup, setup)
  .add_systems(
    Update,
    @app.system_config_param6(update_lightmaps).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems(
    Update,
    @app.system_config_param3(update_directional_light).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems_param2(Update, make_sphere_nonpickable)
  .add_systems_param3(Update, update_radio_buttons)
  .add_systems_param3(Update, handle_lighting_mode_change)
  .add_systems_param2(Update, handle_widget_interactions)
  .add_systems(
    Update,
    @app.system_config_param3(reset_sphere_position).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .add_systems_param4(Update, move_sphere)
  .add_systems(
    Update,
    @app.system_config_param3(adjust_help_text).run_if_on_message(
      lighting_mode_changed_message_key,
    ),
  )
  .run()
}
