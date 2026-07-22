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
/// Baseline parity:
/// - This example now attaches `ClusteredDecal` components directly with upstream-
///   aligned map channels.
/// - This port keeps the same runtime behavior model: continuous spawn,
///   animated in/out lifetime, seeded ChaCha8 randomness, and emissive toggle.

///|
const PLANE_HALF_SIZE : Float = 2.0F

///|
const PI : Float = 3.141592653589793F

///|
const DECAL_MIN_SIZE : Float = 0.5F

///|
const DECAL_MAX_SIZE : Float = 1.5F

///|
const DECAL_ANIMATE_IN_DURATION : Float = 0.30F

///|
const DECAL_IDLE_DURATION : Float = 10.0F

///|
const DECAL_ANIMATE_OUT_DURATION : Float = 0.30F

///|
const DECAL_SPAWN_INTERVAL : Float = 1.0F

///|
const DECAL_MAPS_ASSET_BASE : String = "https://raw.githubusercontent.com/bevyengine/bevy_asset_files/refs/heads/main/clustered_decal_maps/"

///|
fn decal_maps_asset_url(name : String) -> String {
  DECAL_MAPS_ASSET_BASE + name
}

///|
priv struct AppTextures {
  decal_base_color_texture : @asset.Handle[@asset.Image]
  decal_normal_map_texture : @asset.Handle[@asset.Image]
  decal_metallic_roughness_map_texture : @asset.Handle[@asset.Image]
  decal_emissive_texture : @asset.Handle[@asset.Image]
}

///|
fn AppTextures::AppTextures() -> AppTextures {
  let asset_server = @asset.AssetServer::new()
  {
    decal_base_color_texture: asset_server.load("branding/bevy_bird_dark.png"),
    decal_normal_map_texture: asset_server.load_with_settings(
      decal_maps_asset_url("BevyLogo-Normal.png"),
      fn(settings) { settings.is_srgb = false },
    ),
    decal_metallic_roughness_map_texture: asset_server.load_with_settings(
      decal_maps_asset_url("BevyLogo-MetallicRoughness.png"),
      fn(settings) { settings.is_srgb = false },
    ),
    decal_emissive_texture: asset_server.load(
      decal_maps_asset_url("BevyLogo-Emissive.png"),
    ),
  }
}

///|
let app_textures_resource_key : @ecs.ResourceKey[AppTextures] = @ecs.register_resource(
  debug_name="examples.3d.clustered_decal_maps.AppTextures",
)

///|
impl @app.Resource for AppTextures with fn resource() {
  app_textures_resource_key
}

///|
priv enum ExampleDecalState {
  AnimatingIn(@time.Timer)
  Idling(@time.Timer)
  AnimatingOut(@time.Timer)
}

///|
priv struct ExampleDecal {
  size : Float
  mut state : ExampleDecalState
}

///|
fn ExampleDecal::new(size : Float) -> ExampleDecal {
  {
    size,
    state: AnimatingIn(
      @time.Timer::from_seconds(DECAL_ANIMATE_IN_DURATION, Once),
    ),
  }
}

///|
let example_decal_component_key : @ecs.ComponentKey[ExampleDecal] = @ecs.register_component(
  debug_name="examples.3d.clustered_decal_maps.ExampleDecal",
)

///|
impl @ecs.Component for ExampleDecal with fn component() {
  example_decal_component_key
}

///|
priv enum AppSetting {
  EmissiveDecals(Bool)
}

///|
impl @widgets_lib.WidgetValue for AppSetting with fn widget_debug_name() {
  "examples.3d.clustered_decal_maps.AppSetting"
}

///|
let app_setting_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[AppSetting],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.clustered_decal_maps.AppSetting>",
)

///|
impl @widgets_lib.WidgetValue for AppSetting with fn widget_click_event_key() {
  app_setting_widget_click_event_key
}

///|
let app_setting_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[AppSetting],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.clustered_decal_maps.AppSetting>",
)

///|
impl @widgets_lib.WidgetValue for AppSetting with fn widget_click_sender_key() {
  app_setting_widget_click_sender_key
}

///|
priv struct AppStatus {
  mut emissive_decals : Bool
}

///|
fn AppStatus::AppStatus() -> AppStatus {
  { emissive_decals: false }
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.3d.clustered_decal_maps.AppStatus",
)

///|
impl @app.Resource for AppStatus with fn resource() {
  app_status_resource_key
}

///|
priv struct SeededRng {
  rng : @example_rng.ChaCha8Rng
}

///|
fn SeededRng::SeededRng() -> SeededRng {
  { rng: @example_rng.ChaCha8Rng::seed_from_u64(19878367467712UL) }
}

///|
let seeded_rng_resource_key : @ecs.ResourceKey[SeededRng] = @ecs.register_resource(
  debug_name="examples.3d.clustered_decal_maps.SeededRng",
)

///|
impl @app.Resource for SeededRng with fn resource() {
  seeded_rng_resource_key
}

///|
priv struct DecalSpawnTimer {
  timer : @time.Timer?
}

///|
impl @app.FromWorld for DecalSpawnTimer with fn from_world(_world) {
  { timer: None }
}

///|
fn decal_spawn_timer(state : DecalSpawnTimer) -> @time.Timer {
  match state.timer {
    Some(timer) => timer
    None => @time.Timer::from_seconds(DECAL_SPAWN_INTERVAL, Repeating)
  }
}

///|
fn random_unit(seeded_rng : @app.ResMut[SeededRng]) -> Float {
  seeded_rng.modify(fn(value) { value.rng.random_float() })
}

///|
fn random_range(
  seeded_rng : @app.ResMut[SeededRng],
  min_value : Float,
  max_value : Float,
) -> Float {
  min_value + random_unit(seeded_rng) * (max_value - min_value)
}

///|
fn app_setting_selected(setting : AppSetting, app_status : AppStatus) -> Bool {
  match setting {
    EmissiveDecals(emissive_decals) =>
      emissive_decals == app_status.emissive_decals
  }
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
    @widgets_lib.spawn_option_buttons(commands, panel, "Emissive Decals", [
      (AppSetting::EmissiveDecals(true), "On"),
      (EmissiveDecals(false), "Off"),
    ]),
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
fn handle_emission_type_change(
  app_status : @app.ResMut[AppStatus],
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[AppSetting]],
) -> Unit {
  app_status.modify(fn(status) {
    for event in events.read() {
      let EmissiveDecals(on) = event.get()
      status.emissive_decals = on
    }
  })
}

///|
fn clustered_decal_maps_normal_map() -> @asset.Handle[@asset.Image] {
  let asset_server = @asset.AssetServer::new()
  asset_server.load_with_settings("textures/ScratchedGold-Normal.png", fn(
    settings,
  ) {
    settings.is_srgb = false
  })
}

///|
fn spawn_plane(
  world : @ecs.World,
  normal_map : @asset.Handle[@asset.Image],
) -> Unit {
  let plane_geometry = @mesh_primitives_dim3.PlaneMeshBuilder::new(
    @math.Dir3::from_xyz_unchecked(0.0F, 0.0F, -1.0F),
    @math.Vec2::new(PLANE_HALF_SIZE * 2.0F, PLANE_HALF_SIZE * 2.0F),
  ).build()
  guard plane_geometry.with_duplicated_vertices() is Some(duplicated) else {
    abort("clustered_decal_maps plane must duplicate vertices")
  }
  guard duplicated.with_computed_flat_normals() is Some(flat_normals) else {
    abort("clustered_decal_maps plane must compute flat normals")
  }
  match flat_normals.generate_tangents() {
    Some(_) => abort("clustered_decal_maps plane tangent generation failed")
    None => ()
  }
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @color.Color::new(0.86F, 0.16F, 0.24F, 1.0F),
    ).with_normal_map_texture(Some(normal_map)),
  )
  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets |> @pbr.add_mesh(flat_normals)
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(material),
    Transform(),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_light(world : @ecs.World) -> Unit {
  let point = world.spawn_empty()
  try! world.set_by_key(
    point,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@color.Color::white(), 10_000_000.0F, 100.0F, false),
  )
  try! world.set_by_key(
    point,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(8.0F, 16.0F, -8.0F),
  )
}

///|
fn spawn_camera(world : @ecs.World) -> Unit {
  let camera = @camera.Camera3dBundle::new(
    Camera(),
    @transform.Transform::from_xyz(2.0F, 0.0F, -7.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, Hdr())
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  spawn_plane(world, clustered_decal_maps_normal_map())
  spawn_light(world)
  spawn_camera(world)
}

///|
fn spawn_decal(
  commands : @app.Commands,
  app_status : @app.Res[AppStatus],
  app_textures : @app.Res[AppTextures],
  time : @app.Res[@time.Time[Unit]],
  decal_spawn_timer_state : @app.Local[DecalSpawnTimer],
  seeded_rng : @app.ResMut[SeededRng],
) -> Unit {
  let timer = decal_spawn_timer(decal_spawn_timer_state.get()).tick(
    time.get().delta(),
  )
  decal_spawn_timer_state.set({ timer: Some(timer) })
  if !timer.just_finished() {
    return
  }

  let textures = app_textures.get()
  let x = random_range(seeded_rng, -PLANE_HALF_SIZE, PLANE_HALF_SIZE)
  let y = random_range(seeded_rng, -PLANE_HALF_SIZE, PLANE_HALF_SIZE)
  let size = random_range(seeded_rng, DECAL_MIN_SIZE, DECAL_MAX_SIZE)
  let theta = random_range(seeded_rng, 0.0F, PI)

  let mut clustered_decal = @pbr.ClusteredDecal::ClusteredDecal()
    .with_base_color_texture(Some(textures.decal_base_color_texture))
    .with_normal_map_texture(Some(textures.decal_normal_map_texture))
    .with_metallic_roughness_texture(
      Some(textures.decal_metallic_roughness_map_texture),
    )
  if app_status.get().emissive_decals {
    clustered_decal = clustered_decal.with_emissive_texture(
      Some(textures.decal_emissive_texture),
    )
  }
  ignore(
    commands.spawn(
      (
        clustered_decal,
        @transform.Transform::from_translation(@math.Vec3::new(x, y, 0.0F))
        .with_scale(@math.Vec3::zero())
        .looking_to(
          @math.Vec3::new(0.0F, 0.0F, 1.0F),
          @math.Vec3::new(@math.cos(theta), @math.sin(theta), 0.0F),
        ),
        ExampleDecal::new(size),
      ),
    ),
  )
}

///|
fn tick_decal_state(
  state : ExampleDecalState,
  delta : @core.Duration,
) -> ExampleDecalState? {
  match state {
    AnimatingIn(timer) => {
      let timer = timer.tick(delta)
      if timer.just_finished() {
        Some(Idling(@time.Timer::from_seconds(DECAL_IDLE_DURATION, Once)))
      } else {
        Some(AnimatingIn(timer))
      }
    }
    Idling(timer) => {
      let timer = timer.tick(delta)
      if timer.just_finished() {
        Some(
          AnimatingOut(
            @time.Timer::from_seconds(DECAL_ANIMATE_OUT_DURATION, Once),
          ),
        )
      } else {
        Some(Idling(timer))
      }
    }
    AnimatingOut(timer) => {
      let timer = timer.tick(delta)
      if timer.just_finished() {
        None
      } else {
        Some(AnimatingOut(timer))
      }
    }
  }
}

///|
fn decal_scale_factor(state : ExampleDecalState) -> Float {
  match state {
    AnimatingIn(timer) => timer.fraction()
    Idling(_) => 1.0F
    AnimatingOut(timer) => timer.fraction_remaining()
  }
}

///|
fn animate_decals(
  commands : @app.Commands,
  decals : @ecs.Query[
    (@core.Entity, @ecs.Write[ExampleDecal], @ecs.Write[@transform.Transform]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta()
  try! decals.view(fn(_entity, item) {
    let (entity, example_decal, decal_transform) = item
    let next_state = example_decal.modify(fn(value) {
      match tick_decal_state(value.state, delta) {
        Some(state) => {
          value.state = state
          Some((value.size, state))
        }
        None => None
      }
    })
    guard next_state is Some((size, state)) else {
      commands.entity(entity).despawn()
      return
    }
    let scale_factor = decal_scale_factor(state)
    decal_transform.modify(fn(transform) {
      transform.scale = @math.Vec3::new(
        size * scale_factor,
        size * scale_factor,
        1.0F,
      )
    })
  })
}

///|
fn draw_gizmos(
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
  decals : @ecs.Query[
    @ecs.Read[@transform.GlobalTransform],
    @ecs.With[@pbr.ClusteredDecal],
  ],
) -> Unit {
  try! decals.view(fn(_entity, global_transform) {
    let transform = global_transform.value().to_transform_approx()
    gizmos.cuboid_3d(
      transform,
      transform.scale,
      @color.Color::new(1.0F, 0.84F, 0.0F, 1.0F),
    )
  })
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Clustered Decal Maps Example"
  window
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
  .insert_resource(AppStatus::AppStatus())
  .insert_resource(AppTextures::AppTextures())
  .insert_resource(SeededRng::SeededRng())
  .add_message(widget_click_message_key)
  .add_systems_world(Startup, setup_scene)
  .add_systems_param(Startup, spawn_buttons)
  .add_systems_param2(Update, handle_ui_interactions)
  .add_systems(
    Update,
    @app.system_config_param2(handle_emission_type_change).run_if_on_message(
      widget_click_message_key,
    ),
  )
  .add_systems_param3(Update, update_radio_buttons)
  .add_systems_param6(Update, spawn_decal)
  .add_systems_param3(Update, animate_decals)
  .add_systems_param2(Update, draw_gizmos)
  .run()
}
