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
fn ssao_quality_index(ssao : @post_process.ScreenSpaceAmbientOcclusion?) -> Int {
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
  ssao : @post_process.ScreenSpaceAmbientOcclusion?,
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
    text = "\{text}Constant object thickness: \{ssao.constant_object_thickness} (Up/Down)\n\n"
  }

  text = "\{text}SSAO Quality:\n"
  text = "\{text}(1) \{o}Off\{o}\n"
  text = "\{text}(2) \{l}Low\{l}\n"
  text = "\{text}(3) \{m}Medium\{m}\n"
  text = "\{text}(4) \{h}High\{h}\n"
  text = "\{text}(5) \{u}Ultra\{u}\n\n"
  text = "\{text}Temporal Antialiasing:\n"
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
  camera_query : @ecs.Query[@ecs.Comp[SsaoCamera], @ecs.All],
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
  current : @post_process.ScreenSpaceAmbientOcclusion?,
) -> @post_process.ScreenSpaceAmbientOcclusion {
  match current {
    Some(ssao) => ssao
    None => @post_process.ScreenSpaceAmbientOcclusion::default()
  }
}

///|
fn set_ssao_component(
  world : @ecs.World,
  camera_entity : @core.Entity,
  ssao : @post_process.ScreenSpaceAmbientOcclusion,
) -> Unit {
  if (try! world.contains_by_key(
      camera_entity, @post_process.ecs_key_screen_space_ambient_occlusion,
    )) {
    try! (world.replace(
      camera_entity, @post_process.ecs_key_screen_space_ambient_occlusion, ssao,
    )
    |> ignore)
  } else {
    try! world.set_by_key(
      camera_entity, @post_process.ecs_key_screen_space_ambient_occlusion, ssao,
    )
  }
}

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let world = @app.current_world().unwrap()

  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 1000.0F),
  )

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-2.0F, 2.0F, -2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::default())
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_screen_space_ambient_occlusion,
    @post_process.ScreenSpaceAmbientOcclusion::default(),
  )
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_screen_space_ambient_occlusion,
    @post_process.ScreenSpaceAmbientOcclusion::default(),
  )
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_anti_aliasing,
    @post_process.TemporalAntiAliasing::default(),
  )
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_screen_space_ambient_occlusion,
    @post_process.ScreenSpaceAmbientOcclusion::default(),
  )
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_anti_aliasing,
    @post_process.TemporalAntiAliasing::default(),
  )
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_jitter,
    @post_process.TemporalJitter::default(),
  )
  try! world.set_by_key(camera, SsaoCamera::component(), SsaoCamera::{  })

  let base_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.5F, 0.5F, 0.5F))
    .with_perceptual_roughness(1.0F)
    .with_reflectance(0.0F),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(base_material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 1.0F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(base_material),
    @transform.Transform::from_xyz(0.0F, -1.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(base_material),
    @transform.Transform::from_xyz(1.0F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let sphere = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_uv_sphere(0.4F, 72, 36),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      materials.get_ref().val.add(
        @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.4F, 0.4F, 0.4F))
        .with_perceptual_roughness(1.0F)
        .with_reflectance(0.0F),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(sphere, SphereMarker::component(), SphereMarker::{  })

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_rotation(
      @math.Quat::from_euler(
        @math.EulerRot::ZYX,
        0.0F,
        PI * -0.15F,
        PI * -0.15F,
      ),
    ),
  )
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 10_000.0F, true),
  )

  let instructions = @text.Text2dBundle::new(
      @text.Text2d::new(
        ssao_ui_text(
          Some(@post_process.ScreenSpaceAmbientOcclusion::default()),
          true,
        ),
      ),
      @text.TextFont::default()
      .with_font(asset_server.get().load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::srgba(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .spawn()
  world.insert_resource(ssao_instructions_resource_key, SsaoInstructions::{
    handle: instructions,
  })
}

///|
fn update(
  camera_query : @ecs.Query[@ecs.Comp[SsaoCamera], @ecs.All],
  sphere_query : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[SphereMarker],
  ],
  keycode : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  try! sphere_query.view(fn(_entity, transform) {
    transform.get_ref().val.translation.y = @math.sin(
        time.get().elapsed_secs() / 1.7F,
      ) *
      0.7F
  })

  guard ssao_camera_entity(camera_query) is Some(camera_entity) else { return }
  let world = @app.current_world().unwrap()
  let current_ssao = try! world.get_by_key(
    camera_entity, @post_process.ecs_key_screen_space_ambient_occlusion,
  )
  let base_ssao = current_ssao_value(current_ssao)

  if keycode.just_pressed(@window.KeyCode::Digit2) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @post_process.ScreenSpaceAmbientOcclusionQualityLevel::Low,
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::Digit3) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @post_process.ScreenSpaceAmbientOcclusionQualityLevel::Medium,
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::Digit4) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @post_process.ScreenSpaceAmbientOcclusionQualityLevel::High,
      ),
    )
  }

  if keycode.just_pressed(@window.KeyCode::Digit5) {
    set_ssao_component(
      world,
      camera_entity,
      base_ssao.with_quality_level(
        @post_process.ScreenSpaceAmbientOcclusionQualityLevel::Ultra,
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
    try! (world.take(
      camera_entity, @post_process.ecs_key_screen_space_ambient_occlusion,
    )
    |> ignore)
  }

  if keycode.just_pressed(@window.KeyCode::Space) {
    if (try! world.contains_by_key(
        camera_entity, @post_process.ecs_key_temporal_jitter,
      )) {
      try! (world.take(camera_entity, @post_process.ecs_key_temporal_jitter)
      |> ignore)
    } else {
      try! world.set_by_key(
        camera_entity,
        @post_process.ecs_key_temporal_jitter,
        @post_process.TemporalJitter::default(),
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
      try! world.get_by_key(
        camera_entity, @post_process.ecs_key_screen_space_ambient_occlusion,
      ),
      try! world.contains_by_key(
        camera_entity, @post_process.ecs_key_temporal_jitter,
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::build())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(update)))
  .run()
}
