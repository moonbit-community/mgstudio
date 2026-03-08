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
/// Port of `bevy/examples/3d/ssao.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const SSAO_MIN_THICKNESS : Float = 0.0625F

///|
const SSAO_MAX_THICKNESS : Float = 4.0F

///|
struct SphereMarker {}

///|
struct SsaoCamera {}

///|
struct SsaoInstructions {
  handle : @text.TextHandle
}

///|
let sphere_marker_component_key : @ecs.ComponentKey[SphereMarker] = @ecs.register_component(
  debug_name="examples.3d.ssao.SphereMarker",
)

///|
let ssao_camera_component_key : @ecs.ComponentKey[SsaoCamera] = @ecs.register_component(
  debug_name="examples.3d.ssao.SsaoCamera",
)

///|
let ssao_instructions_resource_key : @ecs.ResourceKey[SsaoInstructions] = @ecs.register_resource(
  debug_name="examples.3d.ssao.SsaoInstructions",
)

///|
impl @ecs.Component for SphereMarker with component() {
  sphere_marker_component_key
}

///|
impl @ecs.Component for SsaoCamera with component() {
  ssao_camera_component_key
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
fn marker(current_quality : Int, index : Int) -> String {
  if current_quality == index {
    "*"
  } else {
    ""
  }
}

///|
fn ssao_quality_index(ssao : @render3d.ScreenSpaceAmbientOcclusion?) -> Int {
  match ssao {
    None => 0
    Some(ssao) =>
      match ssao.quality_level {
        Low => 1
        Medium => 2
        High => 3
        Ultra => 4
      }
  }
}

///|
fn ssao_ui_text(
  ssao : @render3d.ScreenSpaceAmbientOcclusion?,
  temporal_jitter_enabled : Bool,
) -> String {
  let quality = ssao_quality_index(ssao)
  let o = marker(quality, 0)
  let l = marker(quality, 1)
  let m = marker(quality, 2)
  let h = marker(quality, 3)
  let u = marker(quality, 4)

  let mut text = ""
  if ssao is Some(ssao) {
    text = text +
      "Constant object thickness: \{ssao.constant_object_thickness} (Up/Down)\n\n"
  }

  text = text + "SSAO Quality:\n"
  text = text + "(1) \{o}Off\{o}\n"
  text = text + "(2) \{l}Low\{l}\n"
  text = text + "(3) \{m}Medium\{m}\n"
  text = text + "(4) \{h}High\{h}\n"
  text = text + "(5) \{u}Ultra\{u}\n\n"
  text = text + "Temporal Antialiasing:\n"
  text = text +
    (if temporal_jitter_enabled {
      "(Space) Enabled"
    } else {
      "(Space) Disabled"
    })
  text
}

///|
fn ssao_camera_entity(
  camera_query : @ecs.Query1Filtered[SsaoCamera, @ecs.All],
) -> @core.Entity? {
  let entity_ref = Ref::new(None)
  try! camera_query.view(fn(entity, _camera) {
    if entity_ref.val is None {
      entity_ref.val = Some(entity)
    }
  })
  entity_ref.val
}

///|
fn current_ssao_value(
  current : @render3d.ScreenSpaceAmbientOcclusion?,
) -> @render3d.ScreenSpaceAmbientOcclusion {
  match current {
    Some(ssao) => ssao
    None => @render3d.ScreenSpaceAmbientOcclusion::default()
  }
}

///|
fn set_ssao_component(
  world : @ecs.World,
  camera_entity : @core.Entity,
  ssao : @render3d.ScreenSpaceAmbientOcclusion,
) -> Unit {
  let tick = world.read_change_tick()
  let store = world.component(@render3d.ecs_key_screen_space_ambient_occlusion)
  if store.contains(camera_entity) {
    store.set(camera_entity, ssao, tick) |> ignore
  } else {
    store.insert(camera_entity, ssao, tick)
  }
}

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@render3d.StandardMaterial]],
) -> Unit {
  let world = @app.current_world().unwrap()
  let tick = world.read_change_tick()

  world.insert_resource(
    @render3d.ecs_key_global_ambient_light,
    @render3d.GlobalAmbientLight::new(@render2d.Color::white(), 1000.0F),
  )

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.0F, -2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_hdr)
  .insert(camera, @render3d.Hdr::default(), tick)
  world
  .component(@render3d.ecs_key_msaa)
  .insert(camera, @render3d.Msaa::Off, tick)
  world
  .component(@render3d.ecs_key_screen_space_ambient_occlusion)
  .insert(camera, @render3d.ScreenSpaceAmbientOcclusion::default(), tick)
  world
  .component(@render3d.ecs_key_temporal_anti_aliasing)
  .insert(camera, @render3d.TemporalAntiAliasing::default(), tick)
  world
  .component(@render3d.ecs_key_temporal_jitter)
  .insert(camera, @render3d.TemporalJitter::default(), tick)
  world
  .component(SsaoCamera::component())
  .insert(camera, SsaoCamera::{  }, tick)

  let base_material = materials.get_ref().val.add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::srgb(0.5F, 0.5F, 0.5F),
    )
    .with_perceptual_roughness(1.0F)
    .with_reflectance(0.0F),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(base_material),
    @math.Transform::from_xyz(0.0F, 0.0F, 1.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(base_material),
    @math.Transform::from_xyz(0.0F, -1.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(base_material),
    @math.Transform::from_xyz(1.0F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let sphere = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_uv_sphere(0.4F, 72, 36),
    @render3d.MeshMaterial3d::new(
      materials.get_ref().val.add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::srgb(0.4F, 0.4F, 0.4F),
        )
        .with_perceptual_roughness(1.0F)
        .with_reflectance(0.0F),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(SphereMarker::component())
  .insert(sphere, SphereMarker::{  }, tick)

  let light = world.spawn_empty()
  world
  .component(@math.ecs_key_transform)
  .insert(
    light,
    @math.Transform::from_rotation(
      @math.Quat::from_euler(
        @math.EulerRot::ZYX,
        0.0F,
        PI * -0.15F,
        PI * -0.15F,
      ),
    ),
    tick,
  )
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 10_000.0F, true),
    tick,
  )

  let instructions = @text.Text2dBundle::new(
      @text.Text2d::new(
        ssao_ui_text(
          Some(@render3d.ScreenSpaceAmbientOcclusion::default()),
          true,
        ),
      ),
      @text.TextFont::default()
      .with_font(asset_server.get().load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::srgba(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .spawn()
  world.insert_resource(ssao_instructions_resource_key, SsaoInstructions::{
    handle: instructions,
  })
}

///|
fn update(
  camera_query : @ecs.Query1Filtered[SsaoCamera, @ecs.All],
  sphere_query : @ecs.Query1Filtered[@math.Transform, @ecs.With[SphereMarker]],
  keycode : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  try! sphere_query.view_mut(fn(_entity, transform) {
    transform.get_ref().val.translation.y = @math.sin(
        time.get().elapsed_secs() / 1.7F,
      ) *
      0.7F
    transform.set_changed()
  })

  guard ssao_camera_entity(camera_query) is Some(camera_entity) else { return }
  let world = @app.current_world().unwrap()
  let ssao_store = world.component(
    @render3d.ecs_key_screen_space_ambient_occlusion,
  )
  let temporal_jitter_store = world.component(@render3d.ecs_key_temporal_jitter)
  let current_ssao = ssao_store.get(camera_entity)
  let base_ssao = current_ssao_value(current_ssao)

  if keycode.just_pressed(@window.KeyCode::Digit2) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @render3d.ScreenSpaceAmbientOcclusionQualityLevel::Low,
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::Digit3) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @render3d.ScreenSpaceAmbientOcclusionQualityLevel::Medium,
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::Digit4) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @render3d.ScreenSpaceAmbientOcclusionQualityLevel::High,
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::Digit5) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @render3d.ScreenSpaceAmbientOcclusionQualityLevel::Ultra,
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::ArrowUp) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_constant_object_thickness(
        clampf(
          base_ssao.constant_object_thickness * 2.0F,
          SSAO_MIN_THICKNESS,
          SSAO_MAX_THICKNESS,
        ),
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::ArrowDown) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_constant_object_thickness(
        clampf(
          base_ssao.constant_object_thickness * 0.5F,
          SSAO_MIN_THICKNESS,
          SSAO_MAX_THICKNESS,
        ),
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::Digit1) {
    ssao_store.remove(camera_entity) |> ignore
  }

  if keycode.just_pressed(@window.KeyCode::Space) {
    if temporal_jitter_store.contains(camera_entity) {
      temporal_jitter_store.remove(camera_entity) |> ignore
    } else {
      temporal_jitter_store.insert(
        camera_entity,
        @render3d.TemporalJitter::default(),
        world.read_change_tick(),
      )
    }
  }

  let instructions = match
    (try! world.get_resource(ssao_instructions_resource_key)) {
    Some(instructions) => instructions
    None => return
  }
  @text.text_set_content(
    instructions.handle,
    ssao_ui_text(
      ssao_store.get(camera_entity),
      temporal_jitter_store.contains(camera_entity),
    ),
  )
}

///|
fn main {
  let plugins = @mgstudio.DefaultPlugins::build().build()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(update)))
  .run()
}
