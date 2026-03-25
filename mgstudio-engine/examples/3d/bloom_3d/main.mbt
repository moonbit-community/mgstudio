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

///|
pub struct Bouncing {}

///|
let bouncing_component_key : @ecs.ComponentKey[Bouncing] = @ecs.register_component(
  debug_name="examples.3d.bloom_3d.Bouncing",
)

///|
impl @ecs.Component for Bouncing with component() {
  bouncing_component_key
}

///|
pub struct BloomCamera {}

///|
let bloom_camera_component_key : @ecs.ComponentKey[BloomCamera] = @ecs.register_component(
  debug_name="examples.3d.bloom_3d.BloomCamera",
)

///|
impl @ecs.Component for BloomCamera with component() {
  bloom_camera_component_key
}

///|
pub struct BloomInstructions {
  handle : @text.TextHandle
}

///|
let bloom_instructions_resource_key : @ecs.ResourceKey[BloomInstructions] = @ecs.register_resource(
  debug_name="examples.3d.bloom_3d.BloomInstructions",
)

///|
impl @app.Resource for BloomInstructions with resource() {
  bloom_instructions_resource_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn stable_bucket(x : Int, z : Int) -> Int {
  let seed = (x + 11) * 37 + (z + 19) * 97 + x * z * 13
  let normalized = if seed < 0 { -seed } else { seed }
  (normalized + 3) % 6
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
      "Bloom (Toggle: Space)\n" +
      "(Q/A) Intensity: \{bloom.intensity}\n" +
      "(W/S) Low-frequency boost: \{bloom.low_frequency_boost}\n" +
      "(E/D) Low-frequency boost curvature: \{bloom.low_frequency_boost_curvature}\n" +
      "(R/F) High-pass frequency: \{bloom.high_pass_frequency}\n" +
      "(T/G) Mode: " +
      mode_label(bloom.composite_mode) +
      "\n" +
      "(Y/H) Threshold: \{bloom.prefilter.threshold}\n" +
      "(U/J) Threshold softness: \{bloom.prefilter.threshold_softness}\n" +
      "(I/K) Horizontal Scale: \{bloom.scale.x}"
    None => "Bloom: Off (Toggle: Space)"
  }
}

///|
fn bloom_camera_entity(
  camera_query : @ecs.Query[@ecs.Comp[BloomCamera], @ecs.All],
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
fn setup_scene(world : @ecs.World) -> Unit {
  let asset_server = match
    (try! world.get_resource(@asset.asset_server_resource_key())) {
    Some(asset_server) => asset_server
    None =>
      abort(
        "bloom_3d requires the world-owned AssetServer resource; add AssetPlugin before the example startup system runs",
      )
  }

  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default().with_clear_color(@sprite.Color::black()),
      @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_tonemapping(Some(@post_process.Tonemapping::TonyMcMapface))
    .with_bloom(Some(@post_process.Bloom::default()))
    .spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::default())
  try! world.set_by_key(camera, BloomCamera::component(), BloomCamera::{  })

  let material_emissive1 = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::black()).with_emissive(
      @sprite.Color::new(0.0F, 0.0F, 150.0F, 1.0F),
    ),
  )
  let material_emissive2 = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::black()).with_emissive(
      @sprite.Color::new(1000.0F, 1000.0F, 1000.0F, 1.0F),
    ),
  )
  let material_emissive3 = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::black()).with_emissive(
      @sprite.Color::new(50.0F, 0.0F, 0.0F, 1.0F),
    ),
  )
  let material_non_emissive = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::black()),
  )

  let sphere_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_sphere(0.4F)),
    ),
  )
  for xi in 0..<10 {
    let x = xi - 5
    for zi in 0..<10 {
      let z = zi - 5
      let rand = stable_bucket(x, z)
      let (material, scale) = if rand == 0 {
        (material_emissive1, 0.5F)
      } else if rand == 1 {
        (material_emissive2, 0.1F)
      } else if rand == 2 {
        (material_emissive3, 1.0F)
      } else {
        (material_non_emissive, 1.5F)
      }

      let x_pos = float_from_int(x) * 2.0F
      let z_pos = float_from_int(z) * 2.0F
      let entity = @pbr.MeshMaterial3dBundle::new(
        sphere_mesh,
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(x_pos, 0.0F, z_pos).with_scale(
          @math.Vec3::splat(scale),
        ),
      ).spawn(world)
      try! world.set_by_key(entity, Bouncing::component(), Bouncing::{  })
    }
  }

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(bloom_text(Some(@post_process.Bloom::default()))),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
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
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  world.insert_resource(bloom_instructions_resource_key, BloomInstructions::{
    handle: help_text,
  })
}

///|
fn update_bloom_settings(
  camera_query : @ecs.Query[@ecs.Comp[BloomCamera], @ecs.All],
  instructions : @app.Res[BloomInstructions],
  keycode : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  guard bloom_camera_entity(camera_query) is Some(camera_entity) else { return }
  let world = @app.current_world().unwrap()
  let current_bloom = try! world.get_by_key(
    camera_entity, @post_process.ecs_key_bloom,
  )
  @text.text_set_content(instructions.get().handle, bloom_text(current_bloom))

  match current_bloom {
    None =>
      if keycode.just_pressed(@window.KeyCode::Space) {
        try! world.set_by_key(
          camera_entity,
          @post_process.ecs_key_bloom,
          @post_process.Bloom::default(),
        )
      }
    Some(bloom) => {
      if keycode.just_pressed(@window.KeyCode::Space) {
        try! (world.take(camera_entity, @post_process.ecs_key_bloom) |> ignore)
        return
      }

      let delta = time.get().delta_secs()
      let mut next = bloom
      let mut changed = false

      if keycode.pressed(@window.KeyCode::KeyA) {
        next = next.with_intensity(next.intensity - delta / 10.0F)
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyQ) {
        next = next.with_intensity(next.intensity + delta / 10.0F)
        changed = true
      }

      if keycode.pressed(@window.KeyCode::KeyS) {
        next = next.with_low_frequency_boost(
          next.low_frequency_boost - delta / 10.0F,
        )
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyW) {
        next = next.with_low_frequency_boost(
          next.low_frequency_boost + delta / 10.0F,
        )
        changed = true
      }

      if keycode.pressed(@window.KeyCode::KeyD) {
        next = next.with_low_frequency_boost_curvature(
          next.low_frequency_boost_curvature - delta / 10.0F,
        )
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyE) {
        next = next.with_low_frequency_boost_curvature(
          next.low_frequency_boost_curvature + delta / 10.0F,
        )
        changed = true
      }

      if keycode.pressed(@window.KeyCode::KeyF) {
        next = next.with_high_pass_frequency(
          next.high_pass_frequency - delta / 10.0F,
        )
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyR) {
        next = next.with_high_pass_frequency(
          next.high_pass_frequency + delta / 10.0F,
        )
        changed = true
      }

      if keycode.pressed(@window.KeyCode::KeyG) {
        next = next.with_composite_mode(
          @post_process.BloomCompositeMode::Additive,
        )
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyT) {
        next = next.with_composite_mode(
          @post_process.BloomCompositeMode::EnergyConserving,
        )
        changed = true
      }

      if keycode.pressed(@window.KeyCode::KeyH) {
        next = next.with_prefilter(
          next.prefilter.threshold - delta,
          next.prefilter.threshold_softness,
        )
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyY) {
        next = next.with_prefilter(
          next.prefilter.threshold + delta,
          next.prefilter.threshold_softness,
        )
        changed = true
      }

      if keycode.pressed(@window.KeyCode::KeyJ) {
        next = next.with_prefilter(
          next.prefilter.threshold,
          next.prefilter.threshold_softness - delta / 10.0F,
        )
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyU) {
        next = next.with_prefilter(
          next.prefilter.threshold,
          next.prefilter.threshold_softness + delta / 10.0F,
        )
        changed = true
      }

      if keycode.pressed(@window.KeyCode::KeyK) {
        next = next.with_scale_x(next.scale.x - delta * 2.0F)
        changed = true
      }
      if keycode.pressed(@window.KeyCode::KeyI) {
        next = next.with_scale_x(next.scale.x + delta * 2.0F)
        changed = true
      }

      if changed {
        try! (world.replace(camera_entity, @post_process.ecs_key_bloom, next)
        |> ignore)
      }
    }
  }
}

///|
fn bounce_spheres(
  query : @ecs.Query[
    (@ecs.Comp[Bouncing], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! query.view(fn(_entity, data) {
    let (_bouncing, transform) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.y = @math.sin(
      transform_ref.val.translation.x +
      transform_ref.val.translation.z +
      elapsed,
    )
  })
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup_scene))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(update_bloom_settings)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(bounce_spheres)))
  .run()
}
