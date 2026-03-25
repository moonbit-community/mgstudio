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
/// Port of `bevy/examples/3d/lightmaps.rs`.
///
/// Baseline parity: Bevy's per-mesh `Lightmap` component (`image`, `uv_rect`,
/// `bicubic_sampling`) and deferred prepass components are not exposed in the
/// current mgstudio runtime surface. This port keeps the original scene source,
/// camera setup, args model, and startup/update flow, and applies a global
/// baked-light proxy once the scene is ready.

///|
const LIGHTMAP_EXPOSURE : Float = 250.0F

///|
const DEFAULT_DEFERRED : Bool = false

///|
const DEFAULT_BICUBIC : Bool = false

///|
pub(all) struct Args {
  deferred : Bool
  bicubic : Bool
}

///|
fn default_args() -> Args {
  { deferred: DEFAULT_DEFERRED, bicubic: DEFAULT_BICUBIC }
}

///|
priv struct LightmapsState {
  mut args : Args
  mut scene_root : @core.Entity?
  mut lightmaps_applied : Bool
  mut help_text : @text.TextHandle?
}

///|
let lightmaps_state : Ref[LightmapsState] = Ref::new({
  args: default_args(),
  scene_root: None,
  lightmaps_applied: false,
  help_text: None,
})

///|
fn bool_label(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn status_text() -> String {
  let args = lightmaps_state.val.args
  let applied = if lightmaps_state.val.lightmaps_applied {
    "Applied"
  } else {
    "Waiting for SceneInstanceReady"
  }

  "Bevy lightmaps (adapted)\n" +
  "Scene: models/CornellBox/CornellBox.glb\n" +
  "Args.deferred = " +
  bool_label(args.deferred) +
  ", Args.bicubic = " +
  bool_label(args.bicubic) +
  "\n" +
  "Lightmap proxy status: " +
  applied +
  "\n\n" +
  "Runtime note: per-mesh Lightmap + deferred prepass components are currently unavailable;" +
  " this example applies a global ambient baked-light proxy after scene spawn."
}

///|
fn update_help_text() -> Unit {
  if lightmaps_state.val.help_text is Some(help_text) {
    @text.text_set_content(help_text, status_text())
  }
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
}

///|
fn setup(world : @ecs.World) -> Unit {
  lightmaps_state.val.args = default_args()
  lightmaps_state.val.scene_root = None
  lightmaps_state.val.lightmaps_applied = false
  lightmaps_state.val.help_text = None

  let asset_server = @asset.AssetServer::new()

  set_global_ambient_light(world, @sprite.Color::white(), 0.0F)

  let scene_root = world.spawn_empty()
  try! world.set_by_key(
    scene_root,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/CornellBox/CornellBox.glb",
        ),
      ),
    ),
  )
  lightmaps_state.val.scene_root = Some(scene_root)

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-278.0F, 273.0F, 800.0F),
  ).spawn(world)
  if lightmaps_state.val.args.deferred {
    world.insert_resource(
      @pbr.ecs_key_default_opaque_renderer_method,
      @pbr.DefaultOpaqueRendererMethod::deferred(),
    )
    try! world.set_by_key(
      camera,
      @pbr.ecs_key_depth_prepass,
      @pbr.DepthPrepass::default(),
    )
    world.insert_resource(
      @pbr.ecs_key_default_opaque_renderer_method,
      @pbr.DefaultOpaqueRendererMethod::deferred(),
    )
    try! world.set_by_key(
      camera,
      @pbr.ecs_key_depth_prepass,
      @pbr.DepthPrepass::default(),
    )
    try! world.set_by_key(
      camera,
      @pbr.ecs_key_motion_vector_prepass,
      @pbr.MotionVectorPrepass::default(),
    )
    world.insert_resource(
      @pbr.ecs_key_default_opaque_renderer_method,
      @pbr.DefaultOpaqueRendererMethod::deferred(),
    )
    try! world.set_by_key(
      camera,
      @pbr.ecs_key_depth_prepass,
      @pbr.DepthPrepass::default(),
    )
    try! world.set_by_key(
      camera,
      @pbr.ecs_key_motion_vector_prepass,
      @pbr.MotionVectorPrepass::default(),
    )
    try! world.set_by_key(
      camera,
      @pbr.ecs_key_deferred_prepass,
      @pbr.DeferredPrepass::default(),
    )
    try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  }

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(status_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  lightmaps_state.val.help_text = Some(help_text)
}

///|
fn add_lightmaps_to_meshes(world : @ecs.World) -> Unit {
  if lightmaps_state.val.lightmaps_applied {
    return
  }

  guard lightmaps_state.val.scene_root is Some(scene_root) else { return }
  if !(try! world.contains_by_key(
      scene_root, @scene.ecs_key_scene_instance_ready,
    )) {
    return
  }

  // Proxy for Bevy's per-mesh lightmap pass: keep the scene statically lit and
  // independent from runtime directional/point lights.
  set_global_ambient_light(
    world,
    @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    LIGHTMAP_EXPOSURE,
  )
  lightmaps_state.val.lightmaps_applied = true
  update_help_text()
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(add_lightmaps_to_meshes))
  .run()
}
