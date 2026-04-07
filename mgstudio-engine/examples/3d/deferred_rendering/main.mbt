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
/// Compare Deferred / Forward / Forward+Prepass render modes.
const LIGHT_ROTATION_SPEED : Float = 0.6283185307179586F

///|
priv enum DefaultRenderMode {
  Deferred
  Forward
  ForwardPrepass
}

///|
priv struct SpinTarget {
  entity : @core.Entity
  speed : Float
}

///|
priv struct DeferredState {
  mut pause : Bool
  mut hide_ui : Bool
  mut mode : DefaultRenderMode
  mut camera : @core.Entity?
  mut directional_light : @core.Entity?
  spin_targets : Array[SpinTarget]
  mut help_text : @text.TextHandle?
}

///|
fn default_state() -> DeferredState {
  {
    pause: true,
    hide_ui: false,
    mode: DefaultRenderMode::Deferred,
    camera: None,
    directional_light: None,
    spin_targets: [],
    help_text: None,
  }
}

///|
let deferred_state : Ref[DeferredState] = Ref::new(default_state())

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn mode_eq(lhs : DefaultRenderMode, rhs : DefaultRenderMode) -> Bool {
  if lhs is Deferred {
    rhs is Deferred
  } else if lhs is Forward {
    rhs is Forward
  } else {
    rhs is ForwardPrepass
  }
}

///|
fn mode_marker(target : DefaultRenderMode) -> String {
  if mode_eq(deferred_state.val.mode, target) {
    ">"
  } else {
    ""
  }
}

///|
fn help_text_content() -> String {
  if deferred_state.val.hide_ui {
    ""
  } else {
    let pause_label = if deferred_state.val.pause {
      "Paused"
    } else {
      "Playing"
    }
    "(H) Hide UI\n(Space) Play/Pause (\{pause_label})\n\nRendering Method:\n(1) \{mode_marker(DefaultRenderMode::Deferred)} Deferred\n(2) \{mode_marker(DefaultRenderMode::Forward)} Forward\n(3) \{mode_marker(DefaultRenderMode::ForwardPrepass)} Forward + Prepass"
  }
}

///|
fn update_help_text() -> Unit {
  if deferred_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, help_text_content())
  }
}

///|
fn set_default_opaque_method(
  world : @ecs.World,
  renderer_method : @pbr.OpaqueRendererMethod,
) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_default_opaque_renderer_method,
    @pbr.DefaultOpaqueRendererMethod::new(renderer_method),
  )
}

///|
fn apply_render_mode(world : @ecs.World) -> Unit {
  guard deferred_state.val.camera is Some(camera) else { return }
  match deferred_state.val.mode {
    Deferred => {
      set_default_opaque_method(world, @pbr.OpaqueRendererMethod::Deferred)
      try! (world.take(camera, @pbr.ecs_key_normal_prepass) |> ignore)
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
    }
    Forward => {
      set_default_opaque_method(world, @pbr.OpaqueRendererMethod::Forward)
      try! (world.take(camera, @pbr.ecs_key_normal_prepass) |> ignore)
      try! (world.take(camera, @pbr.ecs_key_depth_prepass) |> ignore)
      try! (world.take(camera, @pbr.ecs_key_motion_vector_prepass) |> ignore)
      try! (world.take(camera, @pbr.ecs_key_deferred_prepass) |> ignore)
    }
    ForwardPrepass => {
      set_default_opaque_method(world, @pbr.OpaqueRendererMethod::Forward)
      try! world.set_by_key(
        camera,
        @pbr.ecs_key_normal_prepass,
        @pbr.NormalPrepass::default(),
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
      try! (world.take(camera, @pbr.ecs_key_deferred_prepass) |> ignore)
    }
  }
}

///|
fn spawn_mesh(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @transform.Transform,
) -> @core.Entity {
  @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
}

///|
fn track_spin(entity : @core.Entity, speed : Float) -> Unit {
  deferred_state.val.spin_targets.push({ entity, speed })
}

///|
fn setup(world : @ecs.World) -> Unit {
  deferred_state.val = default_state()
  let asset_server = @asset.AssetServer::new()
  world.insert_resource(
    @pbr.ecs_key_directional_light_shadow_map,
    @pbr.DirectionalLightShadowMap::new(4096),
  )

  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
        @math.Vec3::new(0.0F, 0.3F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_distance_fog(
      Some(
        @pbr.DistanceFog::new(
          @sprite.Color::new(
            43.0F / 255.0F,
            44.0F / 255.0F,
            47.0F / 255.0F,
            1.0F,
          ),
          @pbr.FogFalloff3d::linear(1.0F, 8.0F),
        ),
      ),
    )
    .spawn(world)
  deferred_state.val.camera = Some(camera)
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_fxaa,
    @post_process.Fxaa::default(),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      2000.0F,
    ),
  )

  let directional_light = world.spawn_empty()
  deferred_state.val.directional_light = Some(directional_light)
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 15_000.0F, true).with_cascade_shadow_config_builder(
      @pbr.CascadeShadowConfigBuilder::default()
      .with_num_cascades(3)
      .with_maximum_distance(10.0F),
    ),
  )
  try! world.set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_rotation(
      @math.Quat::from_rotation_x(-0.7853981634F),
    ),
  )

  let helmet_scene = @scene.scene_load_gltf_scene(
    asset_server,
    @gltf.GltfAssetLabel::Scene(0).from_asset(
      "models/FlightHelmet/FlightHelmet.gltf",
    ),
  )
  let helmet_a = world.spawn_empty()
  try! world.set_by_key(
    helmet_a,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(helmet_scene),
  )

  let helmet_b = world.spawn_empty()
  try! world.set_by_key(
    helmet_b,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(helmet_scene),
  )
  try! world.set_by_key(
    helmet_b,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-4.0F, 0.0F, -3.0F),
  )

  let forward_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.1F, 0.2F, 0.1F, 1.0F),
    ).with_opaque_render_method(@pbr.OpaqueRendererMethod::Forward),
  )
  let plane = spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(50.0F, 50.0F)),
      ),
    ),
    forward_material,
    @transform.Transform::identity(),
  )
  plane |> ignore

  let cube_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(0.1F, 0.1F, 0.1F)),
    ),
  )
  spawn_mesh(
    world,
    cube_mesh,
    forward_material,
    @transform.Transform::from_xyz(-0.3F, 0.5F, -0.2F),
  )
  |> ignore
  spawn_mesh(
    world,
    cube_mesh,
    forward_material,
    @transform.Transform::from_xyz(0.2F, 0.5F, 0.2F),
  )
  |> ignore

  let emissive_color = @sprite.Color::new(1.0F, 0.4F, 0.1F, 1.0F)
  let emissive_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(emissive_color).with_unlit(true),
  )
  let emissive_cube = spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.125F, 0.125F, 0.125F),
        ),
      ),
    ),
    emissive_material,
    @transform.Transform::from_xyz(0.4F, 0.5F, -0.8F),
  )
  try! world.set_by_key(
    emissive_cube,
    @pbr.ecs_key_not_shadow_caster,
    @pbr.NotShadowCaster::default(),
  )

  let point_light = world.spawn_empty()
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(emissive_color, 800.0F, 4.0F, true).with_radius(0.125F),
  )
  try! world.set_by_key(
    point_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.4F, 0.5F, -0.8F),
  )

  for i in 0..<6 {
    let j = i % 3
    let s_val = if i < 3 { 0.0F } else { 0.2F }
    let color = if j == 0 {
      @sprite.Color::new(s_val, s_val, 1.0F, 1.0F)
    } else if j == 1 {
      @sprite.Color::new(s_val, 1.0F, s_val, 1.0F)
    } else {
      @sprite.Color::new(1.0F, s_val, s_val, 1.0F)
    }
    let material = @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(color)
      .with_perceptual_roughness(0.089F)
      .with_metallic(0.0F),
    )
    let jf = float_from_int(j)
    let x = jf * 0.25F + (if i < 3 { -0.15F } else { 0.15F }) - 0.4F
    let z = -jf * 0.25F + (if i < 3 { -0.15F } else { 0.15F }) + 0.4F
    let entity = spawn_mesh(
      world,
      @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(0.125F, 0.125F, 0.125F),
          ),
        ),
      ),
      material,
      @transform.Transform::from_xyz(x, 0.125F, z),
    )
    entity |> ignore
  }

  let sky_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(
        136.0F / 255.0F,
        136.0F / 255.0F,
        136.0F / 255.0F,
        1.0F,
      ),
    )
    .with_unlit(true)
    .with_cull_mode(None),
  )
  let sky = spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(2.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    sky_material,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_scale(
      @math.Vec3::splat(1_000_000.0F),
    ),
  )
  try! world.set_by_key(
    sky,
    @pbr.ecs_key_not_shadow_caster,
    @pbr.NotShadowCaster::default(),
  )
  try! world.set_by_key(
    sky,
    @pbr.ecs_key_not_shadow_receiver,
    @pbr.NotShadowReceiver::default(),
  )

  let parallax_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::default()
    .with_perceptual_roughness(0.4F)
    .with_base_color_texture(
      Some(asset_server.load("textures/parallax_example/cube_color.png")),
    )
    .with_normal_map_texture(
      Some(
        asset_server.load_with_settings(
          "textures/parallax_example/cube_normal.png",
          fn(settings) { settings.is_srgb = false },
        ),
      ),
    )
    .with_depth_map(
      Some(asset_server.load("textures/parallax_example/cube_depth.png")),
    )
    .with_parallax_depth_scale(0.09F)
    .with_parallax_mapping_method(@pbr.ParallaxMappingMethod::Relief(4))
    .with_max_parallax_layer_count(32.0F),
  )
  let parallax_cube = spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.15F, 0.15F, 0.15F),
        ),
      ),
    ),
    parallax_material,
    @transform.Transform::from_xyz(0.4F, 0.2F, -0.8F),
  )
  track_spin(parallax_cube, 0.3F)

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-380.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(760.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  deferred_state.val.help_text = Some(help_text)

  apply_render_mode(world)
  update_help_text()
}

///|
fn switch_mode(world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Space) {
    deferred_state.val.pause = !deferred_state.val.pause
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    deferred_state.val.mode = DefaultRenderMode::Deferred
    apply_render_mode(world)
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    deferred_state.val.mode = DefaultRenderMode::Forward
    apply_render_mode(world)
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    deferred_state.val.mode = DefaultRenderMode::ForwardPrepass
    apply_render_mode(world)
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyH) {
    deferred_state.val.hide_ui = !deferred_state.val.hide_ui
    changed = true
  }
  if changed {
    update_help_text()
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in deferred_rendering example")
  }
}

///|
fn animate_light_direction(world : @ecs.World) -> Unit {
  if deferred_state.val.pause {
    return
  }
  guard deferred_state.val.directional_light is Some(light) else { return }
  guard (try! world.get_by_key(light, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  let delta_angle = LIGHT_ROTATION_SPEED * world_time(world).delta_seconds()
  try! (world.replace(
    light,
    @transform.ecs_key_transform,
    transform.with_rotation(
      transform.rotation
      .mul(@math.Quat::from_rotation_y(delta_angle))
      .normalize(),
    ),
  )
  |> ignore)
}

///|
fn spin(world : @ecs.World) -> Unit {
  if deferred_state.val.pause {
    return
  }
  let delta = world_time(world).delta_seconds()
  for i in 0..<deferred_state.val.spin_targets.length() {
    let target = deferred_state.val.spin_targets[i]
    guard (try! world.get_by_key(target.entity, @transform.ecs_key_transform))
      is Some(transform) else {
      continue
    }
    let speed = target.speed * delta
    let rotation = transform.rotation
      .mul(@math.Quat::from_rotation_y(speed))
      .mul(@math.Quat::from_rotation_x(speed))
      .mul(@math.Quat::from_rotation_z(-speed))
      .normalize()
    try! (world.replace(
      target.entity,
      @transform.ecs_key_transform,
      transform.with_rotation(rotation),
    )
    |> ignore)
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(switch_mode))
  .add_systems(@app.Update, @app.system(animate_light_direction))
  .add_systems(@app.Update, @app.system(spin))
  .run()
}
