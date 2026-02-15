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
/// Port of `bevy/examples/3d/wireframe.rs`.

///|
/// Baseline parity: Bevy wireframe pipeline (`WireframePlugin`,
/// polygon_mode_line) is not available in current mgstudio runtime surfaces.

///|
/// Baseline parity: this port renders equivalent wireframe visuals with thin
/// unlit cuboid segments and keeps the same control semantics.

///|
const LINE_THICKNESS : Float = 0.03F

///|
priv struct WireframeState {
  mut custom_is_lime : Bool
  mut global_color_is_white : Bool
  mut global_enabled : Bool
  custom_handles : Array[@asset.Handle[@render3d.StandardMaterial]]
  global_default_handles : Array[@asset.Handle[@render3d.StandardMaterial]]
  global_override_handles : Array[@asset.Handle[@render3d.StandardMaterial]]
}

///|
let wireframe_state : Ref[WireframeState] = Ref::new({
  custom_is_lime: true,
  global_color_is_white: true,
  global_enabled: true,
  custom_handles: [],
  global_default_handles: [],
  global_override_handles: [],
})

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn color_white(alpha : Float) -> @render2d.Color {
  @render2d.Color::new(1.0F, 1.0F, 1.0F, alpha)
}

///|
fn color_deep_pink(alpha : Float) -> @render2d.Color {
  @render2d.Color::new(1.0F, 0.08F, 0.58F, alpha)
}

///|
fn color_lime(alpha : Float) -> @render2d.Color {
  @render2d.Color::new(0.0F, 1.0F, 0.0F, alpha)
}

///|
fn color_red(alpha : Float) -> @render2d.Color {
  @render2d.Color::new(1.0F, 0.0F, 0.0F, alpha)
}

///|
fn wire_material(
  color : @render2d.Color,
) -> @asset.Handle[@render3d.StandardMaterial] {
  @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(color)
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )
}

///|
fn spawn_wire_segment(
  world : @ecs_world.World,
  start : @math.Vec3,
  end_ : @math.Vec3,
  material : @asset.Handle[@render3d.StandardMaterial],
) -> Unit {
  let dx = end_.x - start.x
  let dy = end_.y - start.y
  let dz = end_.z - start.z
  let length = @math.sqrt(dx * dx + dy * dy + dz * dz)

  let rotation = if absf(dx) >= absf(dy) && absf(dx) >= absf(dz) {
    @math.Quat::identity()
  } else if absf(dy) >= absf(dz) {
    @math.Quat::from_rotation_z(1.5707963267948966F)
  } else {
    @math.Quat::from_rotation_y(-1.5707963267948966F)
  }

  let center = @math.Vec3::new(
    (start.x + end_.x) * 0.5F,
    (start.y + end_.y) * 0.5F,
    (start.z + end_.z) * 0.5F,
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(length, LINE_THICKNESS, LINE_THICKNESS),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(center.x, center.y, center.z).with_rotation(
      rotation,
    ),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_wire_cuboid(
  world : @ecs_world.World,
  center : @math.Vec3,
  size : @math.Vec3,
  material : @asset.Handle[@render3d.StandardMaterial],
) -> Unit {
  let hx = size.x * 0.5F
  let hy = size.y * 0.5F
  let hz = size.z * 0.5F
  let v000 = @math.Vec3::new(center.x - hx, center.y - hy, center.z - hz)
  let v100 = @math.Vec3::new(center.x + hx, center.y - hy, center.z - hz)
  let v110 = @math.Vec3::new(center.x + hx, center.y + hy, center.z - hz)
  let v010 = @math.Vec3::new(center.x - hx, center.y + hy, center.z - hz)
  let v001 = @math.Vec3::new(center.x - hx, center.y - hy, center.z + hz)
  let v101 = @math.Vec3::new(center.x + hx, center.y - hy, center.z + hz)
  let v111 = @math.Vec3::new(center.x + hx, center.y + hy, center.z + hz)
  let v011 = @math.Vec3::new(center.x - hx, center.y + hy, center.z + hz)
  spawn_wire_segment(world, v000, v100, material)
  spawn_wire_segment(world, v100, v110, material)
  spawn_wire_segment(world, v110, v010, material)
  spawn_wire_segment(world, v010, v000, material)
  spawn_wire_segment(world, v001, v101, material)
  spawn_wire_segment(world, v101, v111, material)
  spawn_wire_segment(world, v111, v011, material)
  spawn_wire_segment(world, v011, v001, material)
  spawn_wire_segment(world, v000, v001, material)
  spawn_wire_segment(world, v100, v101, material)
  spawn_wire_segment(world, v110, v111, material)
  spawn_wire_segment(world, v010, v011, material)
}

///|
fn spawn_wire_plane(
  world : @ecs_world.World,
  size : Float,
  material : @asset.Handle[@render3d.StandardMaterial],
) -> Unit {
  let h = size * 0.5F
  let y = 0.01F
  let a = @math.Vec3::new(-h, y, -h)
  let b = @math.Vec3::new(h, y, -h)
  let c = @math.Vec3::new(h, y, h)
  let d = @math.Vec3::new(-h, y, h)
  spawn_wire_segment(world, a, b, material)
  spawn_wire_segment(world, b, c, material)
  spawn_wire_segment(world, c, d, material)
  spawn_wire_segment(world, d, a, material)
  spawn_wire_segment(world, a, c, material)
}

///|
fn set_material_color(
  handle : @asset.Handle[@render3d.StandardMaterial],
  color : @render2d.Color,
) -> Unit {
  if @render3d.standard_material_get(handle) is Some(material) {
    @render3d.standard_material_set(handle, material.with_base_color(color))
    |> ignore
  }
}

///|
fn sync_wireframe_materials() -> Unit {
  let state = wireframe_state.val
  let alpha = if state.global_enabled { 1.0F } else { 0.0F }
  let global_default_color = if state.global_color_is_white {
    color_white(alpha)
  } else {
    color_deep_pink(alpha)
  }

  for handle in state.global_default_handles {
    set_material_color(handle, global_default_color)
  }
  for handle in state.global_override_handles {
    set_material_color(handle, @render2d.Color::new(0.0F, 0.0F, 0.0F, alpha))
  }

  let custom_color = if state.custom_is_lime {
    color_lime(1.0F)
  } else {
    color_red(1.0F)
  }
  for handle in state.custom_handles {
    set_material_color(handle, custom_color)
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color_red(1.0F)),
      ),
    ),
    @math.Transform::from_xyz(-1.0F, 0.5F, -1.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(1.0F, 0.6F, 0.1F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color_lime(1.0F)),
      ),
    ),
    @math.Transform::from_xyz(1.0F, 0.5F, 1.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.1F, 0.2F, 1.0F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let orange_wire = wire_material(color_white(1.0F))
  wireframe_state.val.global_default_handles.push(orange_wire)
  spawn_wire_cuboid(
    world,
    @math.Vec3::new(0.0F, 0.5F, 0.0F),
    @math.Vec3::new(1.0F, 1.0F, 1.0F),
    orange_wire,
  )

  let green_wire = wire_material(color_lime(1.0F))
  wireframe_state.val.custom_handles.push(green_wire)
  spawn_wire_cuboid(
    world,
    @math.Vec3::new(1.0F, 0.5F, 1.0F),
    @math.Vec3::new(1.0F, 1.0F, 1.0F),
    green_wire,
  )

  let plane_wire = wire_material(@render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F))
  wireframe_state.val.global_override_handles.push(plane_wire)
  spawn_wire_plane(world, 5.0F, plane_wire)

  let tick = world.read_change_tick()
  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    light,
    @render3d.PointLight::new(color_white(1.0F), 1_000_000.0F, 20.0F, true),
    tick,
  )
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(2.0F, 4.0F, 2.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  sync_wireframe_materials()
}

///|
fn update_colors(_world : @ecs_world.World) -> Unit {
  let state = wireframe_state.val
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::KeyZ) {
    state.global_enabled = !state.global_enabled
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyX) {
    state.global_color_is_white = !state.global_color_is_white
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    state.custom_is_lime = !state.custom_is_lime
    changed = true
  }
  if changed {
    sync_wireframe_materials()
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(update_colors)
  .run()
}
