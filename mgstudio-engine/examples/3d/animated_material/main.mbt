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
/// Port of `bevy/examples/3d/animated_material.rs`.
///
/// Exact parity target: Bevy camera + environment-map setup with per-frame
/// material hue animation.

///|
const GOLDEN_ANGLE_DEG : Float = 137.50777F

///|
const HUE_SPEED_DEG_PER_SEC : Float = 100.0F

///|
priv struct AnimatedMaterialState {
  materials : Array[@asset.Handle[@pbr.StandardMaterial]]
  hues_deg : Array[Float]
}

///|
let animated_material_state : Ref[AnimatedMaterialState] = Ref::new({
  materials: [],
  hues_deg: [],
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn wrap_hue_deg(value : Float) -> Float {
  let mut hue = value
  while hue >= 360.0F {
    hue = hue - 360.0F
  }
  while hue < 0.0F {
    hue = hue + 360.0F
  }
  hue
}

///|
fn color_from_hue_deg(hue_deg : Float) -> @sprite.Color {
  @sprite.Color::hsla(hue_deg, 1.0F, 0.5F, 1.0F)
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  animated_material_state.val.materials.clear()
  animated_material_state.val.hues_deg.clear()
  let asset_server = @asset.AssetServer::new()

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(3.0F, 1.0F, 3.0F).looking_at(
      @math.Vec3::new(0.0F, -0.5F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_environment_map_light)
  .insert(
    camera,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      2_000.0F,
    ),
    tick,
  )

  let cube = @pbr.Mesh3d::from_cuboid(0.5F, 0.5F, 0.5F)

  let mut hue = 0.0F
  for x in -1..<2 {
    for z in -1..<2 {
      let material_handle = @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(color_from_hue_deg(hue)),
      )
      animated_material_state.val.materials.push(material_handle)
      animated_material_state.val.hues_deg.push(hue)

      @pbr.MeshMaterial3dBundle::new(
        cube,
        @pbr.MeshMaterial3d::new(material_handle),
        @transform.Transform::from_xyz(
          float_from_int(x),
          0.0F,
          float_from_int(z),
        ),
      ).spawn(world)
      |> ignore

      hue = hue + GOLDEN_ANGLE_DEG
    }
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in animated_material example")
  }
}

///|
fn animate_materials(world : @ecs.World) -> Unit {
  let delta = world_time(world).delta_seconds()
  if delta <= 0.0F {
    return
  }
  let count = animated_material_state.val.materials.length()
  for i in 0..<count {
    let handle = animated_material_state.val.materials[i]
    let next_hue = wrap_hue_deg(
      animated_material_state.val.hues_deg[i] + delta * HUE_SPEED_DEG_PER_SEC,
    )
    animated_material_state.val.hues_deg[i] = next_hue
    if @pbr.standard_material_get(handle) is Some(material) {
      let next_material = material.with_base_color(color_from_hue_deg(next_hue))
      @pbr.standard_material_set(handle, next_material) |> ignore
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(animate_materials))
  .run()
}
