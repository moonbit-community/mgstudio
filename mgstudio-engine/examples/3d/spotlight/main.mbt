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
/// Port of `bevy/examples/3d/spotlight.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const MOVE_SPEED : Float = 2.0F

///|
const LCG_MOD : Int = 2147483647

///|
const INSTRUCTIONS : String = "Controls\n--------\nHorizontal Movement: WASD\nVertical Movement: Space and Shift\nRotate Camera: Left and Right Arrows"

///|
priv struct SpotlightState {
  movables : Array[@core.Entity]
  spotlights : Array[@core.Entity]
  mut camera : @core.Entity?
}

///|
let spotlight_state : Ref[SpotlightState] = Ref::new({
  movables: [],
  spotlights: [],
  camera: None,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn lcg_next(seed : Int) -> Int {
  let mut next = (seed * 1103515245 + 12345) % LCG_MOD
  if next < 0 {
    next = next + LCG_MOD
  }
  next
}

///|
fn lcg_unit(seed : Int) -> Float {
  float_from_int(seed) / float_from_int(LCG_MOD)
}

///|
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @pbr.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
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
  let tick = world.read_change_tick()
  spotlight_state.val.movables.clear()
  spotlight_state.val.spotlights.clear()
  spotlight_state.val.camera = None

  set_global_ambient_light(world, @sprite.Color::white(), 20.0F)

  let ground_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()),
  )
  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(124.0F / 255.0F, 144.0F / 255.0F, 1.0F, 1.0F),
    ),
  )
  let red_emissive = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    ).with_emissive(@sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)),
  )
  let maroon_emissive = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.502F, 0.0F, 0.0F, 1.0F),
    ).with_emissive(@sprite.Color::new(0.369F, 0.0F, 0.0F, 1.0F)),
  )

  let ground = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_plane(100.0F, 100.0F),
    @pbr.MeshMaterial3d::new(ground_material),
    @math.Transform::identity(),
  ).spawn(world)
  spotlight_state.val.movables.push(ground)

  let cube_mesh = @pbr.Mesh3d::from_cuboid(0.5F, 0.5F, 0.5F)
  let mut seed = 1987836746 % LCG_MOD
  for _ in 0..<40 {
    seed = lcg_next(seed)
    let x = -5.0F + lcg_unit(seed) * 10.0F
    seed = lcg_next(seed)
    let y = lcg_unit(seed) * 3.0F
    seed = lcg_next(seed)
    let z = -5.0F + lcg_unit(seed) * 10.0F

    let cube = @pbr.MeshMaterial3dBundle::new(
      cube_mesh,
      @pbr.MeshMaterial3d::new(cube_material),
      @math.Transform::from_xyz(x, y, z),
    ).spawn(world)
    spotlight_state.val.movables.push(cube)
  }

  let marker_mesh = uv_sphere_mesh(0.05F, 18, 32)
  let direction_marker_mesh = uv_sphere_mesh(0.1F, 18, 32)
  for x in 0..<4 {
    for z in 0..<4 {
      let fx = float_from_int(x) - 2.0F
      let fz = float_from_int(z) - 2.0F
      let spotlight = world.spawn_empty()
      world
      .component(@pbr.ecs_key_spot_light)
      .insert(
        spotlight,
        @pbr.SpotLight::new(
          @sprite.Color::white(),
          40_000.0F,
          20.0F,
          PI / 4.0F * 0.85F,
          PI / 4.0F,
          true,
        ),
        tick,
      )
      world
      .component(@math.ecs_key_transform)
      .insert(
        spotlight,
        @math.Transform::from_xyz(1.0F + fx, 2.0F, fz).looking_at(
          @math.Vec3::new(1.0F + fx, 0.0F, fz),
          @math.Vec3::new(1.0F, 0.0F, 0.0F),
        ),
        tick,
      )
      spotlight_state.val.spotlights.push(spotlight)

      let marker = @pbr.MeshMaterial3dBundle::new(
        marker_mesh,
        @pbr.MeshMaterial3d::new(red_emissive),
        @math.Transform::identity(),
      ).spawn(world)
      world
      .component(@hierarchy.ecs_key_parent)
      .insert(marker, @hierarchy.Parent::new(spotlight), tick)

      let direction_marker = @pbr.MeshMaterial3dBundle::new(
        direction_marker_mesh,
        @pbr.MeshMaterial3d::new(maroon_emissive),
        @math.Transform::from_xyz(0.0F, 0.0F, -0.1F),
      ).spawn(world)
      world
      .component(@hierarchy.ecs_key_parent)
      .insert(direction_marker, @hierarchy.Parent::new(spotlight), tick)
      world
      .component(@pbr.ecs_key_not_shadow_caster)
      .insert(direction_marker, @pbr.NotShadowCaster::default(), tick)
    }
  }

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(-4.0F, 5.0F, 10.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world.component(@pbr.ecs_key_hdr).insert(camera, @pbr.Hdr::default(), tick)
  spotlight_state.val.camera = Some(camera)

  let asset_server = @asset.AssetServer::new()
  let overlay_font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  @text.Text2dBundle::new(
    @text.Text2d::new(INSTRUCTIONS),
    @text.TextFont::default().with_font(overlay_font).with_font_size(20.0F),
    @math.Transform::from_xy_rotation_scale(
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
  |> ignore
}

///|
fn light_sway(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let elapsed = @time.time_elapsed_seconds()
  let transform_store = world.component(@math.ecs_key_transform)
  let spot_light_store = world.component(@pbr.ecs_key_spot_light)

  let rotation_x = -@math.pi_half() + @math.sin(elapsed * 0.67F * 3.0F) * 0.5F
  let rotation_y = @math.sin(elapsed * 3.0F) * 0.5F
  let rotation = @math.Quat::from_rotation_x(rotation_x)
    .mul(@math.Quat::from_rotation_y(rotation_y))
    .normalize()

  let angle = (@math.sin(elapsed * 1.2F) + 1.0F) *
    (@math.pi_half() / 2.0F - 0.1F)
  let inner = angle * 0.8F

  for entity in spotlight_state.val.spotlights {
    if transform_store.get(entity) is Some(transform) {
      transform_store.set(entity, transform.with_rotation(rotation), tick)
      |> ignore
    }
    if spot_light_store.get(entity) is Some(light) {
      spot_light_store.set(
        entity,
        @pbr.SpotLight::new(
          light.color,
          light.intensity,
          light.range,
          inner,
          angle,
          light.shadow_maps_enabled,
        ),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn movement(world : @ecs.World) -> Unit {
  let mut translation = @math.Vec3::zero()
  if @input.key_pressed(@window.KeyCode::KeyW) {
    translation = translation.add(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  } else if @input.key_pressed(@window.KeyCode::KeyS) {
    translation = translation.add(@math.Vec3::new(0.0F, 0.0F, -1.0F))
  }

  if @input.key_pressed(@window.KeyCode::KeyA) {
    translation = translation.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  } else if @input.key_pressed(@window.KeyCode::KeyD) {
    translation = translation.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
  }

  if @input.key_pressed(@window.KeyCode::ShiftLeft) {
    translation = translation.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  } else if @input.key_pressed(@window.KeyCode::Space) {
    translation = translation.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  }

  if translation.length_squared() <= 0.0F {
    return
  }

  let delta = translation.mul_scalar(MOVE_SPEED * @time.time_delta_seconds())
  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)
  for entity in spotlight_state.val.movables {
    if transform_store.get(entity) is Some(transform) {
      let next = transform.with_translation(transform.translation.add(delta))
      transform_store.set(entity, next, tick) |> ignore
    }
  }
}

///|
fn rotation(world : @ecs.World) -> Unit {
  guard spotlight_state.val.camera is Some(camera_entity) else { return }

  let delta = @time.time_delta_seconds()
  let angle = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    -delta
  } else {
    0.0F
  }
  if angle == 0.0F {
    return
  }

  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)
  if transform_store.get(camera_entity) is Some(transform) {
    let rotated_position = quat_rotate_vec3(
      @math.Quat::from_rotation_y(angle),
      transform.translation,
    )
    let next = @math.Transform::from_xyz(
      rotated_position.x,
      rotated_position.y,
      rotated_position.z,
    ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    transform_store.set(camera_entity, next, tick) |> ignore
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(light_sway))
  .add_systems(@app.Update, @app.system(movement))
  .add_systems(@app.Update, @app.system(rotation))
  .run()
}
