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
pub struct Bouncing {}

///|
let bouncing_component_key : @ecs.ComponentKey[Bouncing] = @ecs.register_component(
  debug_name="examples.3d.bloom_3d.Bouncing",
)

///|
impl @ecs.Component for Bouncing with fn component() {
  bouncing_component_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn float_text_2(value : Float) -> String {
  let scaled = (value * 100.0F).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / 100
  let fraction = abs_scaled % 100
  let fraction_text = if fraction < 10 {
    "0\{fraction}"
  } else {
    fraction.to_string()
  }
  "\{sign}\{whole}.\{fraction_text}"
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
fn stable_bucket(x : Int, z : Int) -> Int {
  let rows = [
    [2, 3, 1, 2, 0, 3, 2, 3, 5, 0],
    [2, 1, 0, 0, 3, 4, 5, 0, 1, 2],
    [1, 4, 0, 2, 4, 2, 3, 5, 1, 1],
    [3, 5, 4, 2, 3, 1, 5, 5, 1, 4],
    [0, 2, 5, 2, 0, 3, 5, 2, 5, 1],
    [5, 2, 0, 1, 2, 4, 0, 2, 0, 5],
    [5, 5, 2, 4, 1, 0, 5, 0, 2, 0],
    [0, 4, 3, 5, 5, 1, 1, 2, 3, 1],
    [3, 2, 0, 0, 3, 1, 5, 0, 4, 4],
    [2, 5, 4, 4, 5, 4, 3, 2, 2, 0],
  ]
  rows[x + 5][z + 5]
}

///|
fn mode_label(mode : @post_process.BloomCompositeMode) -> String {
  match mode {
    EnergyConserving => "Energy-conserving"
    Additive => "Additive"
  }
}

///|
fn bloom_text(bloom : @post_process.Bloom?) -> String {
  match bloom {
    Some(bloom) =>
      "Bloom (Toggle: Space)\n(Q/A) Intensity: \{float_text_2(bloom.intensity)}\n(W/S) Low-frequency boost: \{float_text_2(bloom.low_frequency_boost)}\n(E/D) Low-frequency boost curvature: \{float_text_2(bloom.low_frequency_boost_curvature)}\n(R/F) High-pass frequency: \{float_text_2(bloom.high_pass_frequency)}\n(T/G) Mode: \{mode_label(bloom.composite_mode)}\n(Y/H) Threshold: \{float_text_2(bloom.prefilter.threshold)}\n(U/J) Threshold softness: \{float_text_2(bloom.prefilter.threshold_softness)}\n(I/K) Horizontal Scale: \{float_text_2(bloom.scale.x)}"
    None => "Bloom: Off (Toggle: Space)"
  }
}

///|
fn setup_scene(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @camera_camera.Camera::Camera().with_clear_color(@color.Color::black()),
        @post_process.Tonemapping::TonyMcMapface,
        @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @post_process.Bloom::Bloom(),
      ),
    ),
  )

  let material_emissive1 = materials.modify(fn(material_assets) {
    material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::StandardMaterial().with_emissive(
        @color.Color::new(0.0F, 0.0F, 150.0F, 1.0F),
      ),
    )
  })
  let material_emissive2 = materials.modify(fn(material_assets) {
    material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::StandardMaterial().with_emissive(
        @color.Color::new(1000.0F, 1000.0F, 1000.0F, 1.0F),
      ),
    )
  })
  let material_emissive3 = materials.modify(fn(material_assets) {
    material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::StandardMaterial().with_emissive(
        @color.Color::new(50.0F, 0.0F, 0.0F, 1.0F),
      ),
    )
  })
  let material_non_emissive = materials.modify(fn(material_assets) {
    material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::StandardMaterial().with_base_color(
        @color.Color::black(),
      ),
    )
  })

  let mesh = meshes.modify(fn(mesh_assets) {
    mesh_assets.add(
      @mesh.Mesh::from_3d_geometry(@mesh_primitives_dim3.sphere_mesh(0.4F, 5)),
    )
  })

  for x in -5..<5 {
    for z in -5..<5 {
      let rand = stable_bucket(x, z)
      let (material, scale) = match rand {
        0 => (material_emissive1, 0.5F)
        1 => (material_emissive2, 0.1F)
        2 => (material_emissive3, 1.0F)
        _ => (material_non_emissive, 1.5F)
      }

      ignore(
        commands.spawn(
          (
            @mesh.Mesh3d::new(mesh),
            @pbr.MeshMaterial3dTyped::new(material),
            @transform.Transform::from_xyz(
              float_from_int(x) * 2.0F,
              0.0F,
              float_from_int(z) * 2.0F,
            ).with_scale(@math.Vec3::splat(scale)),
            Bouncing::{  },
          ),
        ),
      )
    }
  }

  ignore(
    commands.spawn(
      (
        @text.Text::Text(),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_bottom(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
      ),
    ),
  )
}

///|
fn update_bloom_settings(
  camera : @app.Single[
    (@core.Entity, @ecs.Optional[@post_process.Bloom]),
    @ecs.With[@camera_camera.Camera],
  ],
  text : @app.Single[@ecs.Write[@text.Text], @ecs.All],
  commands : @app.Commands,
  keycode : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let (camera_entity, bloom_comp) = camera.get()
  let current_bloom = bloom_comp.value()

  text.get().set(@text.Text::new(bloom_text(current_bloom)))

  match current_bloom {
    Some(bloom) => {
      if keycode.just_pressed(@window.KeyCode::Space) {
        commands
        .entity(camera_entity)
        .remove_component(@post_process.ecs_key_bloom)
        return
      }

      let dt = time.get().delta_secs()
      let mut intensity = bloom.intensity
      if keycode.pressed(@window.KeyCode::KeyA) {
        intensity = intensity - dt / 10.0F
      }
      if keycode.pressed(@window.KeyCode::KeyQ) {
        intensity = intensity + dt / 10.0F
      }
      intensity = clampf(intensity, 0.0F, 1.0F)

      let mut low_frequency_boost = bloom.low_frequency_boost
      if keycode.pressed(@window.KeyCode::KeyS) {
        low_frequency_boost = low_frequency_boost - dt / 10.0F
      }
      if keycode.pressed(@window.KeyCode::KeyW) {
        low_frequency_boost = low_frequency_boost + dt / 10.0F
      }
      low_frequency_boost = clampf(low_frequency_boost, 0.0F, 1.0F)

      let mut low_frequency_boost_curvature = bloom.low_frequency_boost_curvature
      if keycode.pressed(@window.KeyCode::KeyD) {
        low_frequency_boost_curvature = low_frequency_boost_curvature -
          dt / 10.0F
      }
      if keycode.pressed(@window.KeyCode::KeyE) {
        low_frequency_boost_curvature = low_frequency_boost_curvature +
          dt / 10.0F
      }
      low_frequency_boost_curvature = clampf(
        low_frequency_boost_curvature, 0.0F, 1.0F,
      )

      let mut high_pass_frequency = bloom.high_pass_frequency
      if keycode.pressed(@window.KeyCode::KeyF) {
        high_pass_frequency = high_pass_frequency - dt / 10.0F
      }
      if keycode.pressed(@window.KeyCode::KeyR) {
        high_pass_frequency = high_pass_frequency + dt / 10.0F
      }
      high_pass_frequency = clampf(high_pass_frequency, 0.0F, 1.0F)

      let mut composite_mode = bloom.composite_mode
      if keycode.pressed(@window.KeyCode::KeyG) {
        composite_mode = Additive
      }
      if keycode.pressed(@window.KeyCode::KeyT) {
        composite_mode = EnergyConserving
      }

      let mut threshold = bloom.prefilter.threshold
      if keycode.pressed(@window.KeyCode::KeyH) {
        threshold = threshold - dt
      }
      if keycode.pressed(@window.KeyCode::KeyY) {
        threshold = threshold + dt
      }
      if threshold < 0.0F {
        threshold = 0.0F
      }

      let mut threshold_softness = bloom.prefilter.threshold_softness
      if keycode.pressed(@window.KeyCode::KeyJ) {
        threshold_softness = threshold_softness - dt / 10.0F
      }
      if keycode.pressed(@window.KeyCode::KeyU) {
        threshold_softness = threshold_softness + dt / 10.0F
      }
      threshold_softness = clampf(threshold_softness, 0.0F, 1.0F)

      let mut scale_x = bloom.scale.x
      if keycode.pressed(@window.KeyCode::KeyK) {
        scale_x = scale_x - dt * 2.0F
      }
      if keycode.pressed(@window.KeyCode::KeyI) {
        scale_x = scale_x + dt * 2.0F
      }
      scale_x = clampf(scale_x, 0.0F, 8.0F)

      commands
      .entity(camera_entity)
      .insert_component(
        bloom
        .with_intensity(intensity)
        .with_low_frequency_boost(low_frequency_boost)
        .with_low_frequency_boost_curvature(low_frequency_boost_curvature)
        .with_high_pass_frequency(high_pass_frequency)
        .with_composite_mode(composite_mode)
        .with_prefilter(threshold, threshold_softness)
        .with_scale_x(scale_x),
      )
    }
    None =>
      if keycode.just_pressed(@window.KeyCode::Space) {
        commands
        .entity(camera_entity)
        .insert_component(@post_process.Bloom::Bloom())
      }
  }
}

///|
fn bounce_spheres(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Bouncing]],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! query.view(fn(_entity, transform) {
    let current = transform.value().translation
    transform.modify(fn(value) {
      value.translation.y = @math.sin(current.x + current.z + elapsed)
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param3(@app.Startup, setup_scene)
  .add_systems_param5(@app.Update, update_bloom_settings)
  .add_systems_param2(@app.Update, bounce_spheres)
  .run()
}
