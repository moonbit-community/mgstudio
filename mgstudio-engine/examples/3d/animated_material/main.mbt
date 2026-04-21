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
/// Exact parity target: Bevy camera + environment-map setup with per-frame
/// material hue animation.

///|
const GOLDEN_ANGLE_DEG : Float = 137.50777F

///|
const HUE_SPEED_DEG_PER_SEC : Float = 100.0F

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
fn max_float(a : Float, b : Float) -> Float {
  if a >= b {
    a
  } else {
    b
  }
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a <= b {
    a
  } else {
    b
  }
}

///|
fn color_hue_deg(color : @sprite.Color) -> Float {
  let r = color.r
  let g = color.g
  let b = color.b
  let max_channel = max_float(r, max_float(g, b))
  let min_channel = min_float(r, min_float(g, b))
  let delta = max_channel - min_channel
  if delta <= 0.000001F {
    return 0.0F
  }
  let raw_hue = if max_channel == r {
    (g - b) / delta
  } else if max_channel == g {
    (b - r) / delta + 2.0F
  } else {
    (r - g) / delta + 4.0F
  }
  wrap_hue_deg(raw_hue * 60.0F)
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.peek()
  let material_assets = materials.peek()
  let cube = mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(0.5F, 0.5F, 0.5F))

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(3.0F, 1.0F, 3.0F).looking_at(
          @math.Vec3::new(0.0F, -0.5F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.EnvironmentMapLight::new(
          Some(
            asset_server
            .get()
            .load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
          ),
          Some(
            asset_server
            .get()
            .load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
          ),
          2_000.0F,
        ),
      ),
    ),
  )

  let mut hue = 0.0F
  for x in -1..<2 {
    for z in -1..<2 {
      ignore(
        commands.spawn(
          (
            @pbr.Mesh3d::new(cube),
            @pbr.MeshMaterial3d::new(
              material_assets |> @pbr.add_material(color_from_hue_deg(hue)),
            ),
            @transform.Transform::from_xyz(
              float_from_int(x),
              0.0F,
              float_from_int(z),
            ),
          ),
        ),
      )

      hue = hue + GOLDEN_ANGLE_DEG
    }
  }
}

///|
fn animate_materials(
  material_handles : @ecs.Query[@ecs.Comp[@pbr.MeshMaterial3d], @ecs.All],
  time : @app.Res[@time.Time[Unit]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let delta = time.get().delta_seconds()
  if delta <= 0.0F {
    return
  }
  let material_assets = materials.peek()
  try! material_handles.view(fn(_entity, material_handle) {
    let handle = material_handle.value().material
    if material_assets.get(handle) is Some(material) {
      let next_hue = wrap_hue_deg(
        color_hue_deg(material.base_color) + delta * HUE_SPEED_DEG_PER_SEC,
      )
      material_assets.set(
        handle,
        material.with_base_color(color_from_hue_deg(next_hue)),
      )
      |> ignore
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(animate_materials)))
  .run()
}
