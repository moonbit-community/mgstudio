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
/// Port of `bevy/examples/3d/parallax_mapping.rs`.

///|
const DEPTH_CHANGE_RATE : Float = 0.1F

///|
const DEPTH_UPDATE_STEP : Float = 0.03F

///|
const MAX_DEPTH : Float = 0.3F

///|
const CAMERA_LERP_FACTOR : Float = 0.2F

///|
priv struct SpinTarget {
  entity : @core.Entity
  speed : Float
}

///|
priv struct ParallaxState {
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
  spin_targets : Array[SpinTarget]
  parallax_materials : Array[@asset.Handle[@pbr.StandardMaterial]]
  mut current_view : Int
  mut target_depth : Float
  mut displayed_depth : Float
  mut depth_update : Bool
  mut target_layers : Float
  mut current_method : @pbr.ParallaxMappingMethod
}

///|
let parallax_state : Ref[ParallaxState] = Ref::new({
  camera: None,
  help_text: None,
  spin_targets: [],
  parallax_materials: [],
  current_view: 0,
  target_depth: 0.09F,
  displayed_depth: 0.09F,
  depth_update: false,
  target_layers: 5.0F,
  current_method: @pbr.ParallaxMappingMethod::Relief(4),
})

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
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn lerpf(start : Float, end_ : Float, t : Float) -> Float {
  start + (end_ - start) * t
}

///|
fn vec3_lerp(start : @math.Vec3, end_ : @math.Vec3, t : Float) -> @math.Vec3 {
  @math.Vec3::new(
    lerpf(start.x, end_.x, t),
    lerpf(start.y, end_.y, t),
    lerpf(start.z, end_.z, t),
  )
}

///|
fn quat_nlerp(start : @math.Quat, end_ : @math.Quat, t : Float) -> @math.Quat {
  @math.Quat::new(
    lerpf(start.x, end_.x, t),
    lerpf(start.y, end_.y, t),
    lerpf(start.z, end_.z, t),
    lerpf(start.w, end_.w, t),
  ).normalize()
}

///|
fn layer_count(level : Float) -> Float {
  @math.pow(2.0F, level)
}

///|
fn float_text(value : Float) -> String {
  let rounded = (value * 100000.0F).round() / 100000.0F
  "\{rounded}"
}

///|
fn parallax_method_text(mapping_method : @pbr.ParallaxMappingMethod) -> String {
  match mapping_method {
    Occlusion => "Parallax Occlusion Mapping"
    Relief(max_steps) => "Relief Mapping with \{max_steps} steps"
  }
}

///|
fn next_parallax_method(
  mapping_method : @pbr.ParallaxMappingMethod,
) -> @pbr.ParallaxMappingMethod {
  match mapping_method {
    Occlusion => Relief(2)
    Relief(max_steps) =>
      if max_steps < 3 {
        Relief(4)
      } else if max_steps < 5 {
        Relief(8)
      } else {
        Occlusion
      }
  }
}

///|
fn view_count() -> Int {
  4
}

///|
fn camera_view_transform(index : Int) -> @transform.Transform {
  if index == 0 {
    return @transform.Transform::from_xyz(1.5F, 1.5F, 1.5F).with_rotation(
      @math.Quat::new(-0.279F, 0.364F, 0.115F, 0.880F).normalize(),
    )
  }
  if index == 1 {
    return @transform.Transform::from_xyz(2.4F, 0.0F, 0.2F).with_rotation(
      @math.Quat::new(0.094F, 0.676F, 0.116F, 0.721F).normalize(),
    )
  }
  if index == 2 {
    return @transform.Transform::from_xyz(2.4F, 2.6F, -4.3F).with_rotation(
      @math.Quat::new(0.170F, 0.908F, 0.308F, 0.225F).normalize(),
    )
  }
  @transform.Transform::from_xyz(-1.0F, 0.8F, -1.2F).with_rotation(
    @math.Quat::new(-0.004F, 0.909F, 0.247F, -0.335F).normalize(),
  )
}

///|
fn help_text_content() -> String {
  let current_layers = layer_count(parallax_state.val.target_layers)
  "Parallax depth scale: \{float_text(parallax_state.val.displayed_depth)}\n" +
  "Layers: \{current_layers.round()}\n" +
  "Method: \{parallax_method_text(parallax_state.val.current_method)}\n\n" +
  "Controls:\n" +
  "Left click - Change view angle\n" +
  "1/2 - Decrease/Increase parallax depth scale\n" +
  "3/4 - Decrease/Increase layer count\n" +
  "Space - Switch parallaxing algorithm\n"
}

///|
fn update_help_text() -> Unit {
  guard parallax_state.val.help_text is Some(help_text) else { return }
  @text.text_set_content(help_text, help_text_content())
}

///|
fn apply_layers_to_materials() -> Unit {
  let target_layers = layer_count(parallax_state.val.target_layers)
  for handle in parallax_state.val.parallax_materials {
    guard @pbr.standard_material_get(handle) is Some(material) else { continue }
    @pbr.standard_material_set(
      handle,
      material.with_max_parallax_layer_count(target_layers),
    )
    |> ignore
  }
}

///|
fn apply_method_to_materials() -> Unit {
  let mapping_method = parallax_state.val.current_method
  for handle in parallax_state.val.parallax_materials {
    guard @pbr.standard_material_get(handle) is Some(material) else { continue }
    @pbr.standard_material_set(
      handle,
      material.with_parallax_mapping_method(mapping_method),
    )
    |> ignore
  }
}

///|
fn update_depth_scale_materials() -> Bool {
  if !parallax_state.val.depth_update {
    return false
  }
  let target_depth = parallax_state.val.target_depth
  let mut still_changing = false
  let mut display_depth = parallax_state.val.displayed_depth

  for i in 0..<parallax_state.val.parallax_materials.length() {
    let handle = parallax_state.val.parallax_materials[i]
    guard @pbr.standard_material_get(handle) is Some(material) else { continue }
    let current_depth = material.parallax_depth_scale
    let new_depth = lerpf(current_depth, target_depth, DEPTH_CHANGE_RATE)
    if i == 0 {
      display_depth = new_depth
    }
    if absf(new_depth - current_depth) > 1.0e-9F {
      still_changing = true
    }
    @pbr.standard_material_set(
      handle,
      material.with_parallax_depth_scale(new_depth),
    )
    |> ignore
  }

  if !still_changing {
    parallax_state.val.depth_update = false
    display_depth = target_depth
  }
  parallax_state.val.displayed_depth = display_depth
  true
}

///|
fn push_spin_target(entity : @core.Entity, speed : Float) -> Unit {
  parallax_state.val.spin_targets.push({ entity, speed })
}

///|
fn spawn_help_text(asset_server : @asset.AssetServer) -> Unit {
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
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
  parallax_state.val.help_text = Some(handle)
}

///|
fn spawn_scene(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let tick = world.read_sequence()

  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    light,
    @pbr.PointLight::new(@sprite.Color::white(), 1_800_000.0F, 40.0F, true),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(light, @transform.Transform::from_xyz(2.0F, 1.0F, -1.1F), tick)

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.08F, 0.08F, 0.08F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    ),
    @transform.Transform::from_xyz(2.0F, 1.0F, -1.1F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(10.0F, 10.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.0F, 80.0F / 255.0F, 0.0F, 1.0F),
        )
        .with_perceptual_roughness(0.45F)
        .with_reflectance(0.18F),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, -1.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let normal_texture = asset_server.load_with_settings(
    "textures/parallax_example/cube_normal.png",
    fn(settings) { settings.is_srgb = false },
  )
  let parallax_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::default()
    .with_perceptual_roughness(0.4F)
    .with_base_color_texture(
      Some(asset_server.load("textures/parallax_example/cube_color.png")),
    )
    .with_normal_map_texture(Some(normal_texture))
    .with_depth_map(
      Some(asset_server.load("textures/parallax_example/cube_depth.png")),
    )
    .with_parallax_depth_scale(parallax_state.val.target_depth)
    .with_max_parallax_layer_count(
      layer_count(parallax_state.val.target_layers),
    )
    .with_parallax_mapping_method(parallax_state.val.current_method),
  )
  parallax_state.val.parallax_materials.push(parallax_material)

  let main_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(parallax_material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  ).spawn(world)
  push_spin_target(main_cube, 0.3F)

  let x_pos_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(40.0F, 40.0F, 40.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(parallax_material),
    @transform.Transform::from_xyz(45.0F, 0.0F, 0.0F),
  ).spawn(world)
  push_spin_target(x_pos_cube, -0.1F)

  let x_neg_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(40.0F, 40.0F, 40.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(parallax_material),
    @transform.Transform::from_xyz(-45.0F, 0.0F, 0.0F),
  ).spawn(world)
  push_spin_target(x_neg_cube, -0.1F)

  let z_pos_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(40.0F, 40.0F, 40.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(parallax_material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 45.0F),
  ).spawn(world)
  push_spin_target(z_pos_cube, -0.1F)

  let z_neg_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(40.0F, 40.0F, 40.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(parallax_material),
    @transform.Transform::from_xyz(0.0F, 0.0F, -45.0F),
  ).spawn(world)
  push_spin_target(z_neg_cube, -0.1F)
}

///|
fn setup(world : @ecs.World) -> Unit {
  parallax_state.val.camera = None
  parallax_state.val.help_text = None
  parallax_state.val.spin_targets.clear()
  parallax_state.val.parallax_materials.clear()
  parallax_state.val.current_view = 0
  parallax_state.val.target_depth = 0.09F
  parallax_state.val.displayed_depth = 0.09F
  parallax_state.val.depth_update = false
  parallax_state.val.target_layers = 5.0F
  parallax_state.val.current_method = @pbr.ParallaxMappingMethod::Relief(4)

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    camera_view_transform(0),
  ).spawn(world)
  parallax_state.val.camera = Some(camera)

  let asset_server = @asset.AssetServer::new()
  spawn_scene(world, asset_server)
  spawn_help_text(asset_server)
  update_help_text()
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in parallax_mapping example")
  }
}

///|
fn spin(world : @ecs.World) -> Unit {
  if parallax_state.val.spin_targets.length() == 0 {
    return
  }
  let delta = world_time(world).delta_seconds()
  if delta <= 0.0F {
    return
  }
  let tick = world.read_sequence()
  let transform_store = world.component(@transform.ecs_key_transform)
  for spin_target in parallax_state.val.spin_targets {
    guard transform_store.get(spin_target.entity) is Some(transform) else {
      continue
    }
    let speed = spin_target.speed * delta
    let next_rotation = transform.rotation
      .mul(@math.Quat::from_rotation_y(speed))
      .mul(@math.Quat::from_rotation_x(speed))
      .mul(@math.Quat::from_rotation_z(-speed))
      .normalize()
    transform_store.set(
      spin_target.entity,
      transform.with_rotation(next_rotation),
      tick,
    )
    |> ignore
  }
}

///|
fn move_camera(world : @ecs.World) -> Unit {
  if @input.mouse_button_just_pressed(@window.MouseButton::Left) {
    parallax_state.val.current_view = (parallax_state.val.current_view + 1) %
      view_count()
  }
  guard parallax_state.val.camera is Some(camera_entity) else { return }
  let transform_store = world.component(@transform.ecs_key_transform)
  guard transform_store.get(camera_entity) is Some(current_transform) else {
    return
  }
  let target_transform = camera_view_transform(parallax_state.val.current_view)
  let next_transform = current_transform
    .with_translation(
      vec3_lerp(
        current_transform.translation,
        target_transform.translation,
        CAMERA_LERP_FACTOR,
      ),
    )
    .with_rotation(
      quat_nlerp(
        current_transform.rotation,
        target_transform.rotation,
        CAMERA_LERP_FACTOR,
      ),
    )
  transform_store.set(camera_entity, next_transform, world.read_sequence())
  |> ignore
}

///|
fn update_parallax_controls(_world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    parallax_state.val.target_depth = clampf(
      parallax_state.val.target_depth - DEPTH_UPDATE_STEP,
      0.0F,
      MAX_DEPTH,
    )
    parallax_state.val.depth_update = true
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    parallax_state.val.target_depth = clampf(
      parallax_state.val.target_depth + DEPTH_UPDATE_STEP,
      0.0F,
      MAX_DEPTH,
    )
    parallax_state.val.depth_update = true
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    parallax_state.val.target_layers = if parallax_state.val.target_layers -
      1.0F <
      0.0F {
      0.0F
    } else {
      parallax_state.val.target_layers - 1.0F
    }
    apply_layers_to_materials()
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    parallax_state.val.target_layers = parallax_state.val.target_layers + 1.0F
    apply_layers_to_materials()
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Space) {
    parallax_state.val.current_method = next_parallax_method(
      parallax_state.val.current_method,
    )
    apply_method_to_materials()
    changed = true
  }
  let depth_changed = update_depth_scale_materials()
  if changed || depth_changed {
    update_help_text()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(spin))
  .add_systems(@app.Update, @app.system(move_camera))
  .add_systems(@app.Update, @app.system(update_parallax_controls))
  .run()
}
