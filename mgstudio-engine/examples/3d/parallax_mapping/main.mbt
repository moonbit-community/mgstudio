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
// Bevy source: `bevy/examples/3d/parallax_mapping.rs`.

///|
const DEPTH_CHANGE_RATE : Float = 0.1F

///|
const DEPTH_UPDATE_STEP : Float = 0.03F

///|
const MAX_DEPTH : Float = 0.3F

///|
const CAMERA_LERP_FACTOR : Float = 0.2F

///|
priv struct Spin {
  speed : Float
}

///|
let spin_component_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.3d.parallax_mapping.Spin",
)

///|
impl @ecs.Component for Spin with fn component() {
  spin_component_key
}

///|
priv struct FreeCameraController {}

///|
let free_camera_controller_component_key : @ecs.ComponentKey[
  FreeCameraController,
] = @ecs.register_component(
  debug_name="examples.3d.parallax_mapping.FreeCameraController",
)

///|
impl @ecs.Component for FreeCameraController with fn component() {
  free_camera_controller_component_key
}

///|
priv struct TargetDepth {
  mut value : Float
}

///|
fn TargetDepth::TargetDepth() -> TargetDepth {
  TargetDepth::{ value: 0.09F }
}

///|
impl @app.FromWorld for TargetDepth with fn from_world(_world) {
  TargetDepth::TargetDepth()
}

///|
priv struct TargetLayers {
  mut value : Float
}

///|
fn TargetLayers::TargetLayers() -> TargetLayers {
  TargetLayers::{ value: 5.0F }
}

///|
impl @app.FromWorld for TargetLayers with fn from_world(_world) {
  TargetLayers::TargetLayers()
}

///|
priv struct CurrentMethod {
  value : @pbr.ParallaxMappingMethod
}

///|
fn CurrentMethod::CurrentMethod() -> CurrentMethod {
  CurrentMethod::{ value: @pbr.ParallaxMappingMethod::Relief(4) }
}

///|
impl @app.FromWorld for CurrentMethod with fn from_world(_world) {
  CurrentMethod::CurrentMethod()
}

///|
fn CurrentMethod::display(self : CurrentMethod) -> String {
  match self.value {
    Occlusion => "Parallax Occlusion Mapping"
    Relief(max_steps) => "Relief Mapping with \{max_steps} steps"
  }
}

///|
fn CurrentMethod::next_method(self : CurrentMethod) -> CurrentMethod {
  let next = match self.value {
    Occlusion => @pbr.ParallaxMappingMethod::Relief(2)
    Relief(max_steps) =>
      if max_steps < 3 {
        @pbr.ParallaxMappingMethod::Relief(4)
      } else if max_steps < 5 {
        @pbr.ParallaxMappingMethod::Relief(8)
      } else {
        @pbr.ParallaxMappingMethod::Occlusion
      }
  }
  CurrentMethod::{ value: next }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn format_fixed(value : Float, decimals : Int) -> String {
  let scale = match decimals {
    0 => 1
    1 => 10
    2 => 100
    3 => 1000
    4 => 10000
    _ => 100000
  }
  let scaled = (value * float_from_int(scale)).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / scale
  let fraction = abs_scaled % scale
  let mut fraction_text = fraction.to_string()
  let mut pad = decimals - fraction_text.length()
  while pad > 0 {
    fraction_text = "0\{fraction_text}"
    pad = pad - 1
  }
  if decimals <= 0 {
    "\{sign}\{whole}"
  } else {
    "\{sign}\{whole}.\{fraction_text}"
  }
}

///|
fn layer_count(level : Float) -> Float {
  @math.pow(2.0F, level)
}

///|
fn vec3_lerp(
  start : @math.Vec3,
  end_ : @math.Vec3,
  factor : Float,
) -> @math.Vec3 {
  start.add(end_.sub(start).mul_scalar(factor))
}

///|
let camera_positions : Array[@transform.Transform] = [
  @transform.Transform::from_xyz(1.5F, 1.5F, 1.5F).with_rotation(
    @math.Quat::new(-0.279F, 0.364F, 0.115F, 0.880F),
  ),
  @transform.Transform::from_xyz(2.4F, 0.0F, 0.2F).with_rotation(
    @math.Quat::new(0.094F, 0.676F, 0.116F, 0.721F),
  ),
  @transform.Transform::from_xyz(2.4F, 2.6F, -4.3F).with_rotation(
    @math.Quat::new(0.170F, 0.908F, 0.308F, 0.225F),
  ),
  @transform.Transform::from_xyz(-1.0F, 0.8F, -1.2F).with_rotation(
    @math.Quat::new(-0.004F, 0.909F, 0.247F, -0.335F),
  ),
]

///|
fn camera_view_transform(index : Int) -> @transform.Transform {
  camera_positions[index]
}

///|
fn camera_positions_len() -> Int {
  camera_positions.length()
}

///|
fn mesh_with_generated_tangents(geometry : @mesh.Mesh3dGeometry) -> @mesh.Mesh {
  let mesh = @mesh.Mesh::from_3d_geometry(geometry)
  match mesh.generate_tangents() {
    Some(_) => abort("parallax_mapping tangent generation should succeed")
    None => ()
  }
  mesh
}

///|
fn cube_mesh() -> @mesh.Mesh {
  mesh_with_generated_tangents(
    @mesh_primitives_dim3.Meshable::mesh(@math.Cuboid::Cuboid()),
  )
}

///|
fn background_cube_mesh() -> @mesh.Mesh {
  mesh_with_generated_tangents(
    @mesh_primitives_dim3.Meshable::mesh(@math.Cuboid::new(40.0F, 40.0F, 40.0F)),
  )
}

///|
fn light_sphere_mesh() -> @mesh.Mesh {
  let geometry = @mesh_primitives_dim3.SphereMeshBuilder::from_sphere(
    @math.Sphere::new(0.05F),
  ).ico(3) catch {
    _ => abort("parallax_mapping light sphere subdivisions should be valid")
  }
  @mesh.Mesh::from_3d_geometry(geometry)
}

///|
fn spawn_text_span(
  commands : @app.Commands,
  parent : @core.Entity,
  content : String,
) -> @core.Entity {
  commands.spawn((@hierarchy.Parent::new(parent), @text.TextSpan::new(content)))
}

///|
fn spawn_background_cube(
  commands : @app.Commands,
  mesh : @asset.Handle[@mesh.Mesh],
  material : @asset.Handle[@pbr.StandardMaterial],
  translation : @math.Vec3,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_translation(translation),
        Spin::{ speed: -0.1F },
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let normal_handle : @asset.Handle[@asset.Image] = asset_server
    .get()
    .load_with_settings("textures/parallax_example/cube_normal.png", fn(
      settings,
    ) {
      settings.is_srgb = false
    })

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(1.5F, 1.5F, 1.5F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        FreeCameraController::{  },
      ),
    ),
  )

  let light_mesh = meshes.modify(fn(assets) { assets.add(light_sphere_mesh()) })
  let light_material = materials.modify(fn(assets) {
    assets.add(@pbr.StandardMaterial::from_color(@color.Color::white()))
  })
  let light = commands.spawn(
    (
      @pbr.PointLight::PointLight().with_shadow_maps_enabled(true),
      @transform.Transform::from_xyz(2.0F, 1.0F, -1.1F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(light),
        @mesh.Mesh3d::new(light_mesh),
        @pbr.MeshMaterial3d::new(light_material),
      ),
    ),
  )

  let plane_mesh = meshes.modify(fn(assets) {
    assets.add(
      @mesh.Mesh::from_3d_geometry(
        @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
          @math.Vec2::new(10.0F, 10.0F),
        ).build(),
      ),
    )
  })
  let plane_material = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(
        @color.Color::srgb(0.0F, 80.0F / 255.0F, 0.0F),
      )
      .with_perceptual_roughness(0.45F)
      .with_reflectance(0.18F),
    )
  })
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::from_xyz(0.0F, -1.0F, 0.0F),
      ),
    ),
  )

  let parallax_depth_scale = TargetDepth::TargetDepth().value
  let max_parallax_layer_count = layer_count(TargetLayers::TargetLayers().value)
  let parallax_mapping_method = CurrentMethod::CurrentMethod()
  let parallax_material = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::StandardMaterial()
      .with_perceptual_roughness(0.4F)
      .with_base_color_texture(
        Some(
          asset_server.get().load("textures/parallax_example/cube_color.png"),
        ),
      )
      .with_normal_map_texture(Some(normal_handle))
      .with_depth_map(
        Some(
          asset_server.get().load("textures/parallax_example/cube_depth.png"),
        ),
      )
      .with_parallax_depth_scale(parallax_depth_scale)
      .with_parallax_mapping_method(parallax_mapping_method.value)
      .with_max_parallax_layer_count(max_parallax_layer_count),
    )
  })

  let main_cube = meshes.modify(fn(assets) { assets.add(cube_mesh()) })
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(main_cube),
        @pbr.MeshMaterial3d::new(parallax_material),
        Spin::{ speed: 0.3F },
      ),
    ),
  )

  let background_cube = meshes.modify(fn(assets) {
    assets.add(background_cube_mesh())
  })
  spawn_background_cube(
    commands,
    background_cube,
    parallax_material,
    @math.Vec3::new(45.0F, 0.0F, 0.0F),
  )
  spawn_background_cube(
    commands,
    background_cube,
    parallax_material,
    @math.Vec3::new(-45.0F, 0.0F, 0.0F),
  )
  spawn_background_cube(
    commands,
    background_cube,
    parallax_material,
    @math.Vec3::new(0.0F, 0.0F, 45.0F),
  )
  spawn_background_cube(
    commands,
    background_cube,
    parallax_material,
    @math.Vec3::new(0.0F, 0.0F, -45.0F),
  )

  let text = commands.spawn(
    (
      @text.Text::Text(),
      @ui.Node::Node()
      .with_position_type(@ui.PositionType::Absolute)
      .with_top(@ui.px(12.0F))
      .with_left(@ui.px(12.0F)),
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      text,
      "Parallax depth scale: \{format_fixed(parallax_depth_scale, 5)}\n",
    ),
  )
  ignore(
    spawn_text_span(
      commands,
      text,
      "Layers: \{format_fixed(max_parallax_layer_count, 0)}\n",
    ),
  )
  ignore(
    spawn_text_span(commands, text, "\{parallax_mapping_method.display()}\n"),
  )
  ignore(spawn_text_span(commands, text, "\n\n"))
  ignore(spawn_text_span(commands, text, "Controls:\n"))
  ignore(spawn_text_span(commands, text, "Left click - Change view angle\n"))
  ignore(
    spawn_text_span(
      commands, text, "1/2 - Decrease/Increase parallax depth scale\n",
    ),
  )
  ignore(
    spawn_text_span(commands, text, "3/4 - Decrease/Increase layer count\n"),
  )
  ignore(
    spawn_text_span(commands, text, "Space - Switch parallaxing algorithm\n"),
  )
}

///|
fn update_parallax_depth_scale(
  input : @input.ButtonInput[@window.KeyCode],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  target_depth : @app.Local[TargetDepth],
  depth_update : @app.Local[Bool],
  writer : @ui.TextUiWriter,
  text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
) -> Unit {
  let target = target_depth.get()
  let mut update = depth_update.get()
  if input.just_pressed(@window.KeyCode::Digit1) {
    target.value = if target.value - DEPTH_UPDATE_STEP < 0.0F {
      0.0F
    } else {
      target.value - DEPTH_UPDATE_STEP
    }
    update = true
  }
  if input.just_pressed(@window.KeyCode::Digit2) {
    target.value = if target.value + DEPTH_UPDATE_STEP > MAX_DEPTH {
      MAX_DEPTH
    } else {
      target.value + DEPTH_UPDATE_STEP
    }
    update = true
  }
  if update {
    materials.modify(fn(assets) {
      let entries = assets.iter()
      for entry in entries {
        let (handle, material) = entry
        let current_depth = material.parallax_depth_scale
        let new_depth = current_depth +
          (target.value - current_depth) * DEPTH_CHANGE_RATE
        ignore(
          assets.set(handle, material.with_parallax_depth_scale(new_depth)),
        )
        ignore(
          writer.set_text(
            text.get(),
            1,
            "Parallax depth scale: \{format_fixed(new_depth, 5)}\n",
          ),
        )
        if @math.abs(new_depth - current_depth) <= 0.000000001F {
          update = false
        }
      }
    })
  }
  target_depth.set(target)
  depth_update.set(update)
}

///|
fn switch_method(
  input : @input.ButtonInput[@window.KeyCode],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
  current : @app.Local[CurrentMethod],
) -> Unit {
  if !input.just_pressed(@window.KeyCode::Space) {
    return
  }
  let next = current.get().next_method()
  current.set(next)
  ignore(writer.set_text(text.get(), 3, "\{next.display()}\n"))
  materials.modify(fn(assets) {
    let entries = assets.iter()
    for entry in entries {
      let (handle, material) = entry
      ignore(
        assets.set(handle, material.with_parallax_mapping_method(next.value)),
      )
    }
  })
}

///|
fn update_parallax_layers(
  input : @input.ButtonInput[@window.KeyCode],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  target_layers : @app.Local[TargetLayers],
  text : @app.Single[@core.Entity, @ecs.With[@text.Text]],
  writer : @ui.TextUiWriter,
) -> Unit {
  let target = target_layers.get()
  if input.just_pressed(@window.KeyCode::Digit3) {
    target.value = if target.value - 1.0F < 0.0F {
      0.0F
    } else {
      target.value - 1.0F
    }
  } else if input.just_pressed(@window.KeyCode::Digit4) {
    target.value = target.value + 1.0F
  } else {
    return
  }
  target_layers.set(target)
  let count = layer_count(target.value)
  ignore(writer.set_text(text.get(), 2, "Layers: \{format_fixed(count, 0)}\n"))
  materials.modify(fn(assets) {
    let entries = assets.iter()
    for entry in entries {
      let (handle, material) = entry
      ignore(assets.set(handle, material.with_max_parallax_layer_count(count)))
    }
  })
}

///|
fn spin(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Spin]),
    @ecs.All,
  ],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, data) {
    let (transform, spin) = data
    transform.modify(fn(value) {
      let speed = spin.value().speed * delta
      value.rotate(@math.Quat::from_rotation_y(speed))
      value.rotate(@math.Quat::from_rotation_x(speed))
      value.rotate(@math.Quat::from_rotation_z(-speed))
    })
  })
}

///|
fn move_camera(
  camera : @app.Single[
    @ecs.Write[@transform.Transform],
    @ecs.With[FreeCameraController],
  ],
  current_view : @app.Local[Int],
  button : @input.ButtonInput[@window.MouseButton],
) -> Unit {
  let mut view = current_view.get()
  if button.just_pressed(@window.MouseButton::Left) {
    view = (view + 1) % camera_positions_len()
    current_view.set(view)
  }
  let target = camera_view_transform(view)
  camera
  .get()
  .modify(fn(transform) {
    transform.translation = vec3_lerp(
      transform.translation,
      target.translation,
      CAMERA_LERP_FACTOR,
    )
    transform.rotation = transform.rotation.slerp(
      target.rotation,
      CAMERA_LERP_FACTOR,
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param4(@app.Startup, setup)
  .add_systems_param2(@app.Update, spin)
  .add_systems_param3(@app.Update, move_camera)
  .add_systems_param6(@app.Update, update_parallax_depth_scale)
  .add_systems_param5(@app.Update, update_parallax_layers)
  .add_systems_param5(@app.Update, switch_method)
  .run()
}
