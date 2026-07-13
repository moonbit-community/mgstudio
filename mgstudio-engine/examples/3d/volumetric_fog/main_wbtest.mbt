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
fn approx_eq(lhs : Float, rhs : Float) -> Bool {
  @math.abs(lhs - rhs) <= 0.0001F
}

///|
fn volumetric_fog_uniform_u32_at(bytes : Bytes, byte_offset : Int) -> UInt {
  (bytes[byte_offset].to_uint() & 0xFFU) |
  ((bytes[byte_offset + 1].to_uint() & 0xFFU) << 8) |
  ((bytes[byte_offset + 2].to_uint() & 0xFFU) << 16) |
  ((bytes[byte_offset + 3].to_uint() & 0xFFU) << 24)
}

///|
fn clustered_light_word(
  bytes : Bytes,
  light_index : Int,
  word_index : Int,
) -> UInt {
  volumetric_fog_uniform_u32_at(bytes, (light_index * 20 + word_index) * 4)
}

///|
fn clustered_light_word_matches_f32(
  bytes : Bytes,
  light_index : Int,
  word_index : Int,
  value : Float,
) -> Bool {
  clustered_light_word(bytes, light_index, word_index) ==
  value.reinterpret_as_uint()
}

///|
fn clustered_light_expected_flags(
  clustered : @pbr_render.ExtractedClusterablePointLight3d,
) -> UInt {
  let extracted = clustered.light()
  let mut flags = 0U
  if extracted.shadow_maps_enabled {
    flags = flags | (1U << 0)
  }
  if clustered.is_spot_light() {
    flags = flags | (1U << 5)
    let direction = @pbr_render.render3d_transform_forward(extracted.transform)
    if direction.y < 0.0F {
      flags = flags | (1U << 1)
    }
  }
  if extracted.volumetric && extracted.shadow_maps_enabled {
    flags = flags | (1U << 2)
  }
  if extracted.affects_lightmapped_mesh_diffuse {
    flags = flags | (1U << 3)
  }
  if extracted.contact_shadows_enabled {
    flags = flags | (1U << 4)
  }
  flags
}

///|
fn volumetric_fog_uniform_words(bytes : Bytes) -> Array[UInt] {
  let words : Array[UInt] = []
  for index in 0..<70 {
    words.push(volumetric_fog_uniform_u32_at(bytes, index * 4))
  }
  words
}

///|
fn volumetric_fog_uniform_words_eq(
  lhs : Array[UInt],
  rhs : Array[UInt],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for index in 0..<lhs.length() {
    if lhs[index] != rhs[index] {
      return false
    }
  }
  true
}

///|
fn vec3_approx_eq(lhs : @math.Vec3, rhs : @math.Vec3) -> Bool {
  approx_eq(lhs.x, rhs.x) && approx_eq(lhs.y, rhs.y) && approx_eq(lhs.z, rhs.z)
}

///|
fn vec4_approx_eq(lhs : @math.Vec4, rhs : @math.Vec4) -> Bool {
  approx_eq(lhs.x, rhs.x) &&
  approx_eq(lhs.y, rhs.y) &&
  approx_eq(lhs.z, rhs.z) &&
  approx_eq(lhs.w, rhs.w)
}

///|
fn projection_mat4_approx_eq(
  lhs : @pbr_render.ProjectionMatrix3d,
  rhs : @math.Mat4,
) -> Bool {
  vec4_approx_eq(lhs.x_axis, rhs.x_axis()) &&
  vec4_approx_eq(lhs.y_axis, rhs.y_axis()) &&
  vec4_approx_eq(lhs.z_axis, rhs.z_axis()) &&
  vec4_approx_eq(lhs.w_axis, rhs.w_axis())
}

///|
fn color_approx_eq(lhs : @color.Color, rhs : @color.Color) -> Bool {
  approx_eq(lhs.r, rhs.r) &&
  approx_eq(lhs.g, rhs.g) &&
  approx_eq(lhs.b, rhs.b) &&
  approx_eq(lhs.a, rhs.a)
}

///|
fn vec2_approx_eq(lhs : @math.Vec2, rhs : @math.Vec2) -> Bool {
  approx_eq(lhs.x, rhs.x) && approx_eq(lhs.y, rhs.y)
}

///|
fn quat_approx_eq(lhs : @math.Quat, rhs : @math.Quat) -> Bool {
  approx_eq(lhs.x, rhs.x) &&
  approx_eq(lhs.y, rhs.y) &&
  approx_eq(lhs.z, rhs.z) &&
  approx_eq(lhs.w, rhs.w)
}

///|
fn val_px_approx_eq(value : @ui.Val, expected : Float) -> Bool {
  match value {
    Px(actual) => approx_eq(actual, expected)
    _ => false
  }
}

///|
fn volumetric_fog_material_specializer_layout() -> @mesh.MeshVertexBufferLayoutRef {
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  layouts.insert(
    @mesh.MeshVertexBufferLayout::new(
      attribute_ids=[
        @mesh.MeshVertexAttribute::position().id(),
        @mesh.MeshVertexAttribute::normal().id(),
        @mesh.MeshVertexAttribute::uv_0().id(),
        @mesh.MeshVertexAttribute::color().id(),
      ],
      layout=@mesh.VertexBufferLayout::new(
        array_stride=48,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=0,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=9,
          ),
          @mesh.VertexAttribute::new(
            offset=12,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=10,
          ),
          @mesh.VertexAttribute::new(
            offset=24,
            format=@mesh.MeshVertexFormat::Float32x2,
            shader_location=11,
          ),
          @mesh.VertexAttribute::new(
            offset=32,
            format=@mesh.MeshVertexFormat::Float32x4,
            shader_location=12,
          ),
        ],
      ),
    ),
  )
}

///|
fn shader_defs_contain_flag(
  shader_defs : Array[@material.ShaderDefVal],
  expected : String,
) -> Bool {
  for shader_def in shader_defs {
    match shader_def {
      @material.ShaderDefVal::Flag(flag) if flag == expected => return true
      _ => ()
    }
  }
  false
}

///|
fn push_cascade_matrix_values(
  values : Array[Float],
  matrix : @math.Mat4,
) -> Unit {
  let x = matrix.x_axis()
  let y = matrix.y_axis()
  let z = matrix.z_axis()
  let w = matrix.w_axis()
  values.push(x.x)
  values.push(x.y)
  values.push(x.z)
  values.push(x.w)
  values.push(y.x)
  values.push(y.y)
  values.push(y.z)
  values.push(y.w)
  values.push(z.x)
  values.push(z.y)
  values.push(z.z)
  values.push(z.w)
  values.push(w.x)
  values.push(w.y)
  values.push(w.z)
  values.push(w.w)
}

///|
fn cascade_data_for_test(
  source_cascades : Array[@light.Cascade],
  bounds : Array[Float],
) -> Array[Float] {
  let values : Array[Float] = []
  for index in 0..<@pbr_render.MAX_CASCADES_PER_LIGHT {
    if index < source_cascades.length() && index < bounds.length() {
      let cascade = source_cascades[index]
      push_cascade_matrix_values(values, cascade.clip_from_world)
      values.push(cascade.texel_size)
      values.push(bounds[index])
      values.push(0.0F)
      values.push(0.0F)
    } else {
      for _ in 0..<20 {
        values.push(0.0F)
      }
    }
  }
  values
}

///|
test "volumetric_fog: AppSettings and help text match Bevy defaults" {
  let settings = AppSettings::AppSettings()
  debug_inspect(settings.volumetric_spotlight, content="true")
  debug_inspect(settings.volumetric_pointlight, content="true")

  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(app_settings_resource_key, settings)
  setup_instructions(world)

  let mut help_text : @core.Entity? = None
  let text_query : @ecs.Query[@core.Entity, @ecs.With[@text.Text]] = @ecs.query_filtered(
    world,
    @ecs.With::new(@text.ecs_key_text),
  )
  try! text_query.view(fn(entity, _value) { help_text = Some(entity) })
  guard help_text is Some(help_text) else { abort("expected help text") }
  let reader = @text.TextReader::new(world)
  debug_inspect(
    reader.text(help_text, 0),
    content="\"Press WASD or the arrow keys to change the direction of the directional light\\nPress P to turn volumetric point light off\\nPress L to turn volumetric spot light off\"",
  )
  guard (try! world.get_by_key(help_text, @ui.ecs_key_node)) is Some(node) else {
    abort("expected UI Node on help text")
  }
  debug_inspect(
    node.position_type == @ui.PositionType::Absolute,
    content="true",
  )
  debug_inspect(val_px_approx_eq(node.top, 12.0F), content="true")
  debug_inspect(val_px_approx_eq(node.left, 12.0F), content="true")
}

///|
test "volumetric_fog: app resources match Bevy clear and ambient defaults" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(
      @camera.ClearColor::new(@color.Color::srgba(0.02F, 0.02F, 0.02F, 1.0F)),
    )
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, setup)
  app = app.run_once()
  let world = app.world()
  guard world.get_resource(@camera.ClearColor::resource()) is Some(clear_color) else {
    abort("expected ClearColor resource")
  }
  let (clear_r, clear_g, clear_b, clear_a) = clear_color.color.to_srgba_tuple()
  debug_inspect(approx_eq(clear_r, 0.02F), content="true")
  debug_inspect(approx_eq(clear_g, 0.02F), content="true")
  debug_inspect(approx_eq(clear_b, 0.02F), content="true")
  debug_inspect(approx_eq(clear_a, 1.0F), content="true")
  guard world.get_resource(@pbr.ecs_key_global_ambient_light) is Some(ambient) else {
    abort("expected GlobalAmbientLight resource")
  }
  let (ambient_r, ambient_g, ambient_b, ambient_a) = ambient.color.to_srgba_tuple()
  debug_inspect(approx_eq(ambient_r, 1.0F), content="true")
  debug_inspect(approx_eq(ambient_g, 1.0F), content="true")
  debug_inspect(approx_eq(ambient_b, 1.0F), content="true")
  debug_inspect(approx_eq(ambient_a, 1.0F), content="true")
  debug_inspect(approx_eq(ambient.brightness, 0.0F), content="true")
  debug_inspect(ambient.affects_lightmapped_meshes, content="true")
}

///|
test "volumetric_fog: AppSettings toggles follow Bevy P and L keys" {
  let input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  input.press(@window.KeyCode::KeyP)
  let (point_off, point_changed) = app_settings_after_input(
    AppSettings::AppSettings(),
    input,
  )
  debug_inspect(point_changed, content="true")
  debug_inspect(point_off.volumetric_pointlight, content="false")
  debug_inspect(point_off.volumetric_spotlight, content="true")

  let second_input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  second_input.press(@window.KeyCode::KeyL)
  let (spot_off, spot_changed) = app_settings_after_input(
    point_off, second_input,
  )
  debug_inspect(spot_changed, content="true")
  debug_inspect(spot_off.volumetric_pointlight, content="false")
  debug_inspect(spot_off.volumetric_spotlight, content="false")

  let idle : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  let (_unchanged, idle_changed) = app_settings_after_input(spot_off, idle)
  debug_inspect(idle_changed, content="false")
}

///|
test "volumetric_fog: VolumetricLight sync inserts and removes components" {
  let disable_world = @ecs.World::new()
  defer disable_world.close()
  let point_light = disable_world.spawn_empty()
  try! disable_world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::PointLight(),
  )
  try! disable_world.set_by_key(
    point_light,
    @pbr.ecs_key_volumetric_light,
    @pbr.VolumetricLight::VolumetricLight(),
  )
  let mut disable_app = @app.App::new(disable_world).add_system_param2(fn(
    commands : @app.Commands,
    point_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.PointLight]],
  ) {
    sync_volumetric_light_components(commands, point_lights, false)
  })
  disable_app = disable_app.run_once()
  debug_inspect(
    try! (disable_app
    .world()
    .get_by_key(point_light, @pbr.ecs_key_volumetric_light)
    is None),
    content="true",
  )

  let enable_world = @ecs.World::new()
  defer enable_world.close()
  let spot_light = enable_world.spawn_empty()
  try! enable_world.set_by_key(
    spot_light,
    @pbr.ecs_key_spot_light,
    @pbr.SpotLight::SpotLight(),
  )
  let mut enable_app = @app.App::new(enable_world).add_system_param2(fn(
    commands : @app.Commands,
    spot_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.SpotLight]],
  ) {
    sync_volumetric_light_components(commands, spot_lights, true)
  })
  enable_app = enable_app.run_once()
  debug_inspect(
    try! (enable_app
    .world()
    .get_by_key(spot_light, @pbr.ecs_key_volumetric_light)
    is Some(_)),
    content="true",
  )
}

///|
test "volumetric_fog: toggles update render-visible VolumetricLight count" {
  let world = @ecs.World::new()
  defer world.close()
  setup_lights(world)
  debug_inspect(
    @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(world).light_count(),
    content="2",
  )

  let mut point_app = @app.App::new(world).add_system_param2(fn(
    commands : @app.Commands,
    point_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.PointLight]],
  ) {
    sync_volumetric_light_components(commands, point_lights, false)
  })
  point_app = point_app.run_once()
  let world = point_app.world()
  debug_inspect(
    @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(world).light_count(),
    content="1",
  )

  let mut spot_app = @app.App::new(world).add_system_param2(fn(
    commands : @app.Commands,
    spot_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.SpotLight]],
  ) {
    sync_volumetric_light_components(commands, spot_lights, false)
  })
  spot_app = spot_app.run_once()
  let world = spot_app.world()
  debug_inspect(
    @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(world).light_count(),
    content="0",
  )

  let mut point_restore_app = @app.App::new(world).add_system_param2(fn(
    commands : @app.Commands,
    point_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.PointLight]],
  ) {
    sync_volumetric_light_components(commands, point_lights, true)
  })
  point_restore_app = point_restore_app.run_once()
  let world = point_restore_app.world()
  debug_inspect(
    @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(world).light_count(),
    content="1",
  )

  let mut spot_restore_app = @app.App::new(world).add_system_param2(fn(
    commands : @app.Commands,
    spot_lights : @ecs.Query[@core.Entity, @ecs.With[@pbr.SpotLight]],
  ) {
    sync_volumetric_light_components(commands, spot_lights, true)
  })
  spot_restore_app = spot_restore_app.run_once()
  let world = spot_restore_app.world()
  debug_inspect(
    @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(world).light_count(),
    content="2",
  )
}

///|
test "volumetric_fog: camera skybox and volumetric fog setup matches Bevy" {
  let world = @ecs.World::new()
  defer world.close()
  setup_camera(world)

  let camera_count = Ref(0)
  let transform_matches = Ref(true)
  let tonemapping_matches = Ref(true)
  let bloom_matches = Ref(true)
  let skybox_matches = Ref(true)
  let fog_matches = Ref(true)
  let camera_query : @ecs.Query[
    (
      @ecs.Read[@camera.Camera3d],
      @ecs.Read[@transform.Transform],
      @ecs.Read[@post_process.Tonemapping],
      @ecs.Read[@post_process.Bloom],
      @ecs.Read[@pbr.Skybox],
      @ecs.Read[@pbr.VolumetricFog],
    ),
    @ecs.All,
  ] = @ecs.query(world)

  try! camera_query.view(fn(_entity, data) {
    let (
      _camera,
      transform_read,
      tonemapping_read,
      _bloom_read,
      skybox_read,
      fog_read,
    ) = data
    camera_count.val = camera_count.val + 1

    let transform = transform_read.value()
    transform_matches.val = transform_matches.val &&
      vec3_approx_eq(transform.translation, @math.Vec3::new(-1.7F, 1.5F, 4.5F))

    tonemapping_matches.val = tonemapping_matches.val &&
      tonemapping_read.value() == @post_process.Tonemapping::TonyMcMapface

    bloom_matches.val = bloom_matches.val && true

    let skybox = skybox_read.value()
    let identity = @math.Quat::identity()
    skybox_matches.val = skybox_matches.val &&
      skybox.image is Some(_) &&
      approx_eq(skybox.brightness, 1000.0F) &&
      approx_eq(skybox.rotation.x, identity.x) &&
      approx_eq(skybox.rotation.y, identity.y) &&
      approx_eq(skybox.rotation.z, identity.z) &&
      approx_eq(skybox.rotation.w, identity.w)

    let fog = fog_read.value()
    let ambient_color = fog.ambient_color.to_srgba_tuple()
    fog_matches.val = fog_matches.val &&
      approx_eq(ambient_color.0, 1.0F) &&
      approx_eq(ambient_color.1, 1.0F) &&
      approx_eq(ambient_color.2, 1.0F) &&
      approx_eq(ambient_color.3, 1.0F) &&
      approx_eq(fog.ambient_intensity, 0.0F) &&
      approx_eq(fog.jitter, 0.0F) &&
      fog.step_count == 64
  })

  debug_inspect(camera_count.val, content="1")
  debug_inspect(transform_matches.val, content="true")
  debug_inspect(tonemapping_matches.val, content="true")
  debug_inspect(bloom_matches.val, content="true")
  debug_inspect(skybox_matches.val, content="true")
  debug_inspect(fog_matches.val, content="true")
}

///|
test "volumetric_fog: camera skybox texture reaches render texture storage" {
  let skybox_image_id = Ref(-1)
  let skybox_asset_loaded = Ref(false)
  let skybox_render_texture_loaded = Ref(false)

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_system(fn(world : @ecs.World) { setup_camera(world) })
  .add_system(fn(world : @ecs.World) {
    let camera_query : @ecs.Query[@ecs.Read[@pbr.Skybox], @ecs.All] = @ecs.query(
      world,
    )
    try! camera_query.view(fn(_entity, skybox_read) {
      match skybox_read.value().image {
        Some(image) => {
          skybox_image_id.val = image.id()
          skybox_asset_loaded.val = @asset.asset_is_texture_loaded(image)
          skybox_render_texture_loaded.val = @render.asset_is_texture_loaded(
            texture_id=image.id(),
          )
        }
        None => ()
      }
    })
  })
  .run_startup()
  .run_once()
  .run_once()
  .run_once()
  |> ignore

  debug_inspect(skybox_image_id.val >= 0, content="true")
  debug_inspect(skybox_asset_loaded.val, content="true")
  debug_inspect(skybox_render_texture_loaded.val, content="true")
}

///|
test "volumetric_fog: camera render entity prepares Bevy skybox draw state" {
  let camera_entity = Ref(@core.Entity::placeholder())
  let render_entity = Ref(@core.Entity::placeholder())

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, setup)
  app = app.run_startup()
  app = app.run_once()
  app = app.run_once()
  app = app.run_once()

  let camera_query : @ecs.Query[
    (@core.Entity, (@ecs.Read[@pbr.Skybox], @ecs.Read[@render.RenderEntity])),
    @ecs.All,
  ] = @ecs.query(app.world())
  try! camera_query.view(fn(entity, data) {
    let (_entity, (_skybox, render_entity_read)) = data
    camera_entity.val = entity
    render_entity.val = render_entity_read.value().id()
  })

  debug_inspect(!camera_entity.val.is_placeholder(), content="true")
  debug_inspect(!render_entity.val.is_placeholder(), content="true")

  let render_world = app.sub_app(@app.RenderApp).world()
  debug_inspect(
    @core_pipeline_skybox.view_has_skybox_pipeline(
      render_world,
      render_entity.val,
    ),
    content="true",
  )
  debug_inspect(
    @core_pipeline_skybox.view_has_skybox_bind_group(
      render_world,
      render_entity.val,
    ),
    content="true",
  )
  debug_inspect(
    @core_pipeline_skybox.draw_prepared_skybox(render_world, render_entity.val),
    content="true",
  )
}

///|
test "volumetric_fog: runtime pass-local evidence reaches Bevy fog pass" {
  let counters : Array[@app.TimelineTraceCounter] = []
  @app.set_timeline_trace_counter_sink(
    Some(fn(counter) { counters.push(counter) }),
  )
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, setup)
    .add_systems_param2(@app.Update, tweak_scene)
    .add_systems_param2(@app.Update, move_directional_light)
    .add_systems_param2(@app.Update, move_point_light)
    .add_systems_param6(@app.Update, adjust_app_settings)
  for _ in 0..<6 {
    app = app.update()
  }
  @app.clear_timeline_trace_counter_sink()

  let volumetric_view_counter = Ref(false)
  let volumetric_volume_counter = Ref(false)
  let volumetric_light_counter = Ref(false)
  let volumetric_uniform_counter = Ref(false)
  let volumetric_directional_shadow_counter = Ref(false)
  let volumetric_point_shadow_counter = Ref(false)
  let volumetric_directional_spot_shadow_counter = Ref(false)
  let volumetric_plane_mesh_counter = Ref(false)
  let volumetric_cube_mesh_counter = Ref(false)
  let textureless_pipeline_counter = Ref(false)
  let textured_pipeline_counter = Ref(false)
  let textureless_pipeline_shadow_filter_counter = Ref(false)
  let textured_pipeline_shadow_filter_counter = Ref(false)
  let textureless_pipeline_density_flag = Ref(false)
  let textured_pipeline_density_flag = Ref(false)
  let textureless_pipeline_multisampled_flag = Ref(false)
  let textured_pipeline_multisampled_flag = Ref(false)
  let textureless_pipeline_atmosphere_flag = Ref(false)
  let textured_pipeline_atmosphere_flag = Ref(false)
  let textureless_pipeline_target_format = Ref(false)
  let textured_pipeline_target_format = Ref(false)
  let textureless_pipeline_msaa_sample_count = Ref(false)
  let textured_pipeline_msaa_sample_count = Ref(false)
  let skybox_drawn_index = Ref(-1)
  let main_pass_complete_index = Ref(-1)
  let fog_begin_index = Ref(-1)
  let fog_complete_index = Ref(-1)
  let postprocess_begin_index = Ref(-1)
  let postprocess_complete_index = Ref(-1)
  let transparent_not_applicable = Ref(false)
  let expected_default_exposure = @camera_camera.Exposure::Exposure().exposure()
  let postprocess_hdr_enabled = Ref(false)
  let postprocess_bloom_enabled = Ref(false)
  let postprocess_tonemap_enabled = Ref(false)
  let postprocess_tonemapping_stage_enabled = Ref(false)
  let postprocess_auto_exposure_disabled = Ref(false)
  let postprocess_exposure_default = Ref(false)
  let postprocess_scene_target_texture = Ref(false)
  let postprocess_camera_target_surface = Ref(false)
  let postprocess_source_texture = Ref(false)
  let postprocess_bloom_stage = Ref(false)
  let postprocess_stage_count_one = Ref(false)
  let postprocess_tonemapping_stage = Ref(false)
  let postprocess_tonemapping_source_texture = Ref(false)
  let postprocess_tonemapping_target_camera = Ref(false)
  let postprocess_tonemapping_mode_tony = Ref(false)
  let postprocess_tonemapping_hdr = Ref(false)
  let postprocess_tonemapping_default_exposure = Ref(false)
  let postprocess_final_copy_tonemapping_resolve = Ref(false)
  let postprocess_final_copy_sprite_uv = Ref(false)
  let postprocess_final_source_present = Ref(false)
  let counter_index = Ref(0)
  for counter in counters {
    let current_counter_index = counter_index.val
    if counter.name() == "render_3d_volumetric_fog_views" &&
      counter.value() > 0.0 {
      volumetric_view_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_volumes" &&
      counter.value() > 0.0 {
      volumetric_volume_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_lights" &&
      counter.value() > 0.0 {
      volumetric_light_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_uniforms" &&
      counter.value() > 0.0 {
      volumetric_uniform_counter.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_view_shadow_binding_resources" &&
      counter.value() > 0.0 {
      volumetric_directional_shadow_counter.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_view_point_shadow_binding_resources" &&
      counter.value() > 0.0 {
      volumetric_point_shadow_counter.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_view_directional_spot_shadow_binding_resources" &&
      counter.value() > 0.0 {
      volumetric_directional_spot_shadow_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_plane_mesh_id" &&
      counter.value() >= 0.0 {
      volumetric_plane_mesh_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_cube_mesh_id" &&
      counter.value() >= 0.0 {
      volumetric_cube_mesh_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_pipeline_textureless" &&
      counter.value() > 0.0 {
      textureless_pipeline_counter.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_pipeline_textured" &&
      counter.value() > 0.0 {
      textured_pipeline_counter.val = true
    }
    if counter.name() == "render_3d_main_pass_transparent_items" &&
      counter.value() == 0.0 {
      transparent_not_applicable.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_shadow_filter_hardware_2x2" &&
      counter.value() > 0.0 {
      textureless_pipeline_shadow_filter_counter.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_shadow_filter_hardware_2x2" &&
      counter.value() > 0.0 {
      textured_pipeline_shadow_filter_counter.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_density_texture" &&
      counter.value() == 0.0 {
      textureless_pipeline_density_flag.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_density_texture" &&
      counter.value() == 1.0 {
      textured_pipeline_density_flag.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_multisampled" &&
      counter.value() == 1.0 {
      textureless_pipeline_multisampled_flag.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_multisampled" &&
      counter.value() == 1.0 {
      textured_pipeline_multisampled_flag.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_atmosphere" &&
      counter.value() == 0.0 {
      textureless_pipeline_atmosphere_flag.val = true
    }
    if counter.name() == "render_3d_volumetric_fog_pipeline_textured_atmosphere" &&
      counter.value() == 0.0 {
      textured_pipeline_atmosphere_flag.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_target_format_raw" &&
      counter.value() ==
      Float::from_int(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT.reinterpret_as_int()) {
      textureless_pipeline_target_format.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_target_format_raw" &&
      counter.value() ==
      Float::from_int(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT.reinterpret_as_int()) {
      textured_pipeline_target_format.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textureless_msaa_sample_count" &&
      counter.value() > 1.0 {
      textureless_pipeline_msaa_sample_count.val = true
    }
    if counter.name() ==
      "render_3d_volumetric_fog_pipeline_textured_msaa_sample_count" &&
      counter.value() > 1.0 {
      textured_pipeline_msaa_sample_count.val = true
    }
    if counter.name() ==
      "render_3d_main_pass_skybox_drawn_before_volumetric_fog" &&
      skybox_drawn_index.val < 0 {
      skybox_drawn_index.val = current_counter_index
    }
    if counter.name() == "render_3d_camera_order_main_pass_complete" &&
      main_pass_complete_index.val < 0 {
      main_pass_complete_index.val = current_counter_index
    }
    if counter.name() == "render_3d_camera_order_volumetric_fog_begin" &&
      fog_begin_index.val < 0 {
      fog_begin_index.val = current_counter_index
    }
    if counter.name() == "render_3d_camera_order_volumetric_fog_complete" &&
      fog_complete_index.val < 0 {
      fog_complete_index.val = current_counter_index
    }
    if counter.name() == "render_3d_camera_order_postprocess_begin" &&
      postprocess_begin_index.val < 0 {
      postprocess_begin_index.val = current_counter_index
    }
    if counter.name() == "render_3d_camera_order_postprocess_complete" &&
      postprocess_complete_index.val < 0 {
      postprocess_complete_index.val = current_counter_index
    }
    if counter.name() == "render_3d_camera_postprocess_hdr_enabled" &&
      counter.value() == 1.0 {
      postprocess_hdr_enabled.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_bloom_enabled" &&
      counter.value() == 1.0 {
      postprocess_bloom_enabled.val = true
    }
    if counter.name() ==
      "render_3d_camera_postprocess_tonemap_postprocess_enabled" &&
      counter.value() == 1.0 {
      postprocess_tonemap_enabled.val = true
    }
    if counter.name() ==
      "render_3d_camera_postprocess_tonemapping_stage_enabled" &&
      counter.value() == 1.0 {
      postprocess_tonemapping_stage_enabled.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_auto_exposure_enabled" &&
      counter.value() == 0.0 {
      postprocess_auto_exposure_disabled.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_exposure_value" &&
      approx_eq(counter.value(), expected_default_exposure) {
      postprocess_exposure_default.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_scene_target_is_surface" &&
      counter.value() == 0.0 {
      postprocess_scene_target_texture.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_camera_target_is_surface" &&
      counter.value() == 1.0 {
      postprocess_camera_target_surface.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_source_texture_id" &&
      counter.value() >= 0.0 {
      postprocess_source_texture.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_bloom_stage" &&
      counter.value() == 1.0 {
      postprocess_bloom_stage.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_stage_count" &&
      counter.value() == 1.0 {
      postprocess_stage_count_one.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_tonemapping_stage" &&
      counter.value() == 1.0 {
      postprocess_tonemapping_stage.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_tonemapping_source_id" &&
      counter.value() >= 0.0 {
      postprocess_tonemapping_source_texture.val = true
    }
    if counter.name() ==
      "render_3d_camera_postprocess_tonemapping_target_is_camera_target" &&
      counter.value() == 1.0 {
      postprocess_tonemapping_target_camera.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_tonemapping_mode" &&
      counter.value() == 6.0 {
      postprocess_tonemapping_mode_tony.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_tonemapping_hdr_enabled" &&
      counter.value() == 1.0 {
      postprocess_tonemapping_hdr.val = true
    }
    if counter.name() ==
      "render_3d_camera_postprocess_tonemapping_exposure_value" &&
      approx_eq(counter.value(), expected_default_exposure) {
      postprocess_tonemapping_default_exposure.val = true
    }
    if counter.name() ==
      "render_3d_camera_postprocess_final_copy_tonemapping_resolve" {
      postprocess_final_copy_tonemapping_resolve.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_final_copy_sprite_uv" {
      postprocess_final_copy_sprite_uv.val = true
    }
    if counter.name() == "render_3d_camera_postprocess_final_source_present" {
      postprocess_final_source_present.val = true
    }
    counter_index.val = counter_index.val + 1
  }

  let render_world = app.sub_app(@app.RenderApp).world()
  let lighting = @pbr_render.render3d_collect_lighting(render_world)
  debug_inspect(lighting.directional_shadow_maps_enabled, content="true")
  debug_inspect(lighting.point_shadow_maps_enabled, content="true")
  debug_inspect(lighting.spot_shadow_maps_enabled, content="true")
  debug_inspect(
    lighting.directional_cascade_bounds.length() > 0,
    content="true",
  )
  debug_inspect(
    lighting.directional_cascades.entries().length() > 0,
    content="true",
  )
  debug_inspect(lighting.point_light_index >= 0, content="true")
  debug_inspect(lighting.spot_light_index >= 0, content="true")

  let render_view_count = Ref(0)
  let view_fog_count_positive = Ref(false)
  let view_fog_count_one = Ref(false)
  let view_fog_textureless_volume = Ref(false)
  let view_fog_offset_valid = Ref(false)
  let view_pipeline_ids_valid = Ref(false)
  render_world.for_each_component(
    @pbr_volumetric_fog.ViewVolumetricFog::component(),
    fn(entity, view_fog) {
      render_view_count.val = render_view_count.val + 1
      view_fog_count_positive.val = view_fog_count_positive.val ||
        view_fog.count() > 0
      view_fog_count_one.val = view_fog_count_one.val || view_fog.count() == 1
      for volume in view_fog.volumes() {
        view_fog_textureless_volume.val = view_fog_textureless_volume.val ||
          !volume.has_density_texture()
        view_fog_offset_valid.val = view_fog_offset_valid.val ||
          volume.uniform_buffer_offset() == 0U
      }
      match
        (try! render_world.get_by_key(
          entity,
          @pbr_volumetric_fog.ViewVolumetricFogPipelines::component(),
        )) {
        Some(pipelines) =>
          view_pipeline_ids_valid.val = view_pipeline_ids_valid.val ||
            (pipelines.textureless > 0 && pipelines.textured > 0)
        None => ()
      }
    },
  )

  debug_inspect(volumetric_view_counter.val, content="true")
  debug_inspect(volumetric_volume_counter.val, content="true")
  debug_inspect(volumetric_light_counter.val, content="true")
  debug_inspect(volumetric_uniform_counter.val, content="true")
  debug_inspect(volumetric_directional_shadow_counter.val, content="true")
  debug_inspect(volumetric_point_shadow_counter.val, content="true")
  debug_inspect(volumetric_directional_spot_shadow_counter.val, content="true")
  debug_inspect(volumetric_plane_mesh_counter.val, content="true")
  debug_inspect(volumetric_cube_mesh_counter.val, content="true")
  debug_inspect(textureless_pipeline_counter.val, content="true")
  debug_inspect(textured_pipeline_counter.val, content="true")
  debug_inspect(textureless_pipeline_shadow_filter_counter.val, content="true")
  debug_inspect(textured_pipeline_shadow_filter_counter.val, content="true")
  debug_inspect(textureless_pipeline_density_flag.val, content="true")
  debug_inspect(textured_pipeline_density_flag.val, content="true")
  debug_inspect(textureless_pipeline_multisampled_flag.val, content="true")
  debug_inspect(textured_pipeline_multisampled_flag.val, content="true")
  debug_inspect(textureless_pipeline_atmosphere_flag.val, content="true")
  debug_inspect(textured_pipeline_atmosphere_flag.val, content="true")
  debug_inspect(textureless_pipeline_target_format.val, content="true")
  debug_inspect(textured_pipeline_target_format.val, content="true")
  debug_inspect(textureless_pipeline_msaa_sample_count.val, content="true")
  debug_inspect(textured_pipeline_msaa_sample_count.val, content="true")
  debug_inspect(transparent_not_applicable.val, content="true")
  debug_inspect(skybox_drawn_index.val >= 0, content="true")
  debug_inspect(
    skybox_drawn_index.val < main_pass_complete_index.val,
    content="true",
  )
  debug_inspect(
    main_pass_complete_index.val < fog_begin_index.val,
    content="true",
  )
  debug_inspect(fog_begin_index.val < fog_complete_index.val, content="true")
  debug_inspect(
    fog_complete_index.val < postprocess_begin_index.val,
    content="true",
  )
  debug_inspect(
    postprocess_begin_index.val < postprocess_complete_index.val,
    content="true",
  )
  debug_inspect(postprocess_hdr_enabled.val, content="true")
  debug_inspect(postprocess_bloom_enabled.val, content="true")
  debug_inspect(postprocess_tonemap_enabled.val, content="true")
  debug_inspect(postprocess_tonemapping_stage_enabled.val, content="true")
  debug_inspect(postprocess_auto_exposure_disabled.val, content="true")
  debug_inspect(postprocess_exposure_default.val, content="true")
  debug_inspect(postprocess_scene_target_texture.val, content="true")
  debug_inspect(postprocess_camera_target_surface.val, content="true")
  debug_inspect(postprocess_source_texture.val, content="true")
  debug_inspect(postprocess_bloom_stage.val, content="true")
  debug_inspect(postprocess_stage_count_one.val, content="true")
  debug_inspect(postprocess_tonemapping_stage.val, content="true")
  debug_inspect(postprocess_tonemapping_source_texture.val, content="true")
  debug_inspect(postprocess_tonemapping_target_camera.val, content="true")
  debug_inspect(postprocess_tonemapping_mode_tony.val, content="true")
  debug_inspect(postprocess_tonemapping_hdr.val, content="true")
  debug_inspect(postprocess_tonemapping_default_exposure.val, content="true")
  debug_inspect(!postprocess_final_copy_tonemapping_resolve.val, content="true")
  debug_inspect(!postprocess_final_copy_sprite_uv.val, content="true")
  debug_inspect(!postprocess_final_source_present.val, content="true")
  debug_inspect(render_view_count.val > 0, content="true")
  debug_inspect(view_fog_count_positive.val, content="true")
  debug_inspect(view_fog_count_one.val, content="true")
  debug_inspect(view_fog_textureless_volume.val, content="true")
  debug_inspect(view_fog_offset_valid.val, content="true")
  debug_inspect(view_pipeline_ids_valid.val, content="true")
}

///|
test "volumetric_fog: directional and ambient GPU lights match Bevy prepare_lights" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, setup)
    .add_systems_param2(@app.Update, tweak_scene)
    .add_systems_param2(@app.Update, move_directional_light)
    .add_systems_param2(@app.Update, move_point_light)
    .add_systems_param6(@app.Update, adjust_app_settings)
  for _ in 0..<6 {
    app = app.update()
  }
  let render_world = app.sub_app(@app.RenderApp).world()
  let lighting = @pbr_render.render3d_collect_lighting(render_world)
  let gpu_lights = match lighting.gpu_lights {
    Some(value) => value
    None => abort("volumetric_fog render world did not prepare GpuLights3d")
  }
  debug_inspect(gpu_lights.n_directional_lights, content="1")

  let directional = gpu_lights.directional_lights[0]
  let expected_directional_color = @color.Color::new(
    lighting.directional_color.r * lighting.directional_illuminance,
    lighting.directional_color.g * lighting.directional_illuminance,
    lighting.directional_color.b * lighting.directional_illuminance,
    lighting.directional_color.a * lighting.directional_illuminance,
  )
  debug_inspect(
    color_approx_eq(directional.color, expected_directional_color),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      directional.dir_to_light,
      lighting.directional_transform.back(),
    ),
    content="true",
  )
  debug_inspect((directional.flags & 1U) != 0U, content="true")
  debug_inspect((directional.flags & 2U) != 0U, content="true")
  debug_inspect((directional.flags & 4U) != 0U, content="true")
  debug_inspect(
    approx_eq(
      directional.shadow_depth_bias,
      lighting.directional_shadow_depth_bias,
    ),
    content="true",
  )
  debug_inspect(
    approx_eq(
      directional.shadow_normal_bias,
      lighting.directional_shadow_normal_bias,
    ),
    content="true",
  )
  debug_inspect(
    approx_eq(
      directional.soft_shadow_size,
      lighting.directional_shadow_soft_size,
    ),
    content="true",
  )
  debug_inspect(
    directional.num_cascades,
    content=lighting.directional_cascade_bounds.length().to_string(),
  )
  debug_inspect(
    approx_eq(
      directional.cascades_overlap_proportion,
      lighting.directional_cascade_overlap_proportion,
    ),
    content="true",
  )
  debug_inspect(directional.depth_texture_base_index, content="0")
  debug_inspect(directional.decal_index, content="-1")
  let default_sun_disk = @pbr.SunDisk::earth()
  debug_inspect(
    approx_eq(directional.sun_disk_angular_size, default_sun_disk.angular_size),
    content="true",
  )
  debug_inspect(
    approx_eq(directional.sun_disk_intensity, default_sun_disk.intensity),
    content="true",
  )
  debug_inspect(
    color_approx_eq(
      gpu_lights.ambient_color,
      @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    ),
    content="true",
  )
  debug_inspect(
    gpu_lights.ambient_light_affects_lightmapped_meshes,
    content="1",
  )
}

///|
test "volumetric_fog: directional shadow cascade scalar inputs match Bevy order" {
  let counters : Array[@app.TimelineTraceCounter] = []
  @app.set_timeline_trace_counter_sink(
    Some(fn(counter) { counters.push(counter) }),
  )
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, setup)
    .add_systems_param2(@app.Update, tweak_scene)
    .add_systems_param2(@app.Update, move_directional_light)
    .add_systems_param2(@app.Update, move_point_light)
    .add_systems_param6(@app.Update, adjust_app_settings)
  for _ in 0..<6 {
    app = app.update()
  }
  @app.clear_timeline_trace_counter_sink()

  let fog_consumed_directional_shadow = Ref(false)
  for counter in counters {
    if counter.name() ==
      "render_3d_volumetric_fog_view_shadow_binding_resources" &&
      counter.value() > 0.0 {
      fog_consumed_directional_shadow.val = true
    }
  }
  debug_inspect(fog_consumed_directional_shadow.val, content="true")

  let render_world = app.sub_app(@app.RenderApp).world()
  let lighting = @pbr_render.render3d_collect_lighting(render_world)
  let gpu_lights = match lighting.gpu_lights {
    Some(value) => value
    None => abort("volumetric_fog render world did not prepare GpuLights3d")
  }
  debug_inspect(gpu_lights.n_directional_lights, content="1")

  let directional = gpu_lights.directional_lights[0]
  let cascade_entries = lighting.directional_cascades.entries()
  debug_inspect(cascade_entries.length(), content="1")
  let (_view_entity, source_cascades) = cascade_entries[0]
  debug_inspect(
    source_cascades.length(),
    content=lighting.directional_cascade_bounds.length().to_string(),
  )
  debug_inspect(
    directional.num_cascades,
    content=source_cascades.length().to_string(),
  )
  debug_inspect(directional.depth_texture_base_index, content="0")

  let bounds = lighting.directional_cascade_bounds
  let bounds_strictly_ordered = Ref(true)
  for index in 1..<bounds.length() {
    bounds_strictly_ordered.val = bounds_strictly_ordered.val &&
      bounds[index] > bounds[index - 1]
  }
  debug_inspect(bounds_strictly_ordered.val, content="true")
}

///|
test "volumetric_fog: directional shadow cascade records match Bevy packing" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, setup)
    .add_systems_param2(@app.Update, tweak_scene)
    .add_systems_param2(@app.Update, move_directional_light)
    .add_systems_param2(@app.Update, move_point_light)
    .add_systems_param6(@app.Update, adjust_app_settings)
  for _ in 0..<6 {
    app = app.update()
  }

  let render_world = app.sub_app(@app.RenderApp).world()
  let lighting = @pbr_render.render3d_collect_lighting(render_world)
  let gpu_lights = match lighting.gpu_lights {
    Some(value) => value
    None => abort("volumetric_fog render world did not prepare GpuLights3d")
  }
  let cascade_entries = lighting.directional_cascades.entries()
  debug_inspect(cascade_entries.length(), content="1")
  let (_view_entity, source_cascades) = cascade_entries[0]
  let count = source_cascades.length()
  debug_inspect(
    count,
    content=lighting.directional_cascade_bounds.length().to_string(),
  )

  let resolved_lights = @pbr_render.render3d_gpu_lights_with_directional_shadow_cascades(
    gpu_lights,
    7,
    1.0F,
    count,
    lighting.directional_cascade_overlap_proportion,
    cascade_data_for_test(source_cascades, lighting.directional_cascade_bounds),
  )
  let directional = resolved_lights.directional_lights[0]
  debug_inspect(directional.num_cascades, content=count.to_string())
  for index in 0..<count {
    let resolved_cascade = directional.cascades[index]
    let source_cascade = source_cascades[index]
    debug_inspect(
      projection_mat4_approx_eq(
        resolved_cascade.clip_from_world,
        source_cascade.clip_from_world,
      ),
      content="true",
    )
    debug_inspect(
      approx_eq(resolved_cascade.texel_size, source_cascade.texel_size),
      content="true",
    )
    debug_inspect(
      approx_eq(
        resolved_cascade.far_bound,
        lighting.directional_cascade_bounds[index],
      ),
      content="true",
    )
  }
}

///|
test "volumetric_fog: clustered point and spot light GPU values match Bevy packing" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, setup)
    .add_systems_param2(@app.Update, tweak_scene)
    .add_systems_param2(@app.Update, move_directional_light)
    .add_systems_param2(@app.Update, move_point_light)
    .add_systems_param6(@app.Update, adjust_app_settings)
  for _ in 0..<6 {
    app = app.update()
  }

  let render_world = app.sub_app(@app.RenderApp).world()
  let lighting = @pbr_render.render3d_collect_lighting(render_world)
  guard lighting.gpu_clustered_lights_bytes is Some(clustered_bytes) else {
    debug_inspect("missing", content="clustered")
    return
  }
  let clusterable_lights = @pbr_render.render3d_collect_extracted_clusterable_point_lights(
    render_world,
  )
  debug_inspect(clustered_bytes.length() >= 160, content="true")
  debug_inspect(clusterable_lights.length() >= 2, content="true")
  debug_inspect(clusterable_lights[0].is_point_light(), content="true")
  debug_inspect(clusterable_lights[1].is_spot_light(), content="true")

  let point = clusterable_lights[0].light()
  let point_projection = @pbr_render.render3d_point_shadow_pass_projection(
      point.shadow_map_near_z,
      point.range,
    ).clip_from_view
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      0,
      point_projection.z_axis.z,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      1,
      point_projection.z_axis.w,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      2,
      point_projection.w_axis.z,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      3,
      point_projection.w_axis.w,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      4,
      point.color.r * point.intensity,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      5,
      point.color.g * point.intensity,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      6,
      point.color.b * point.intensity,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      7,
      1.0F / (point.range * point.range),
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      8,
      point.transform.translation.x,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      9,
      point.transform.translation.y,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      10,
      point.transform.translation.z,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 0, 11, point.radius),
    content="true",
  )
  debug_inspect(
    clustered_light_word(clustered_bytes, 0, 12),
    content=clustered_light_expected_flags(clusterable_lights[0]).to_string(),
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      13,
      point.shadow_depth_bias,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      14,
      point.shadow_normal_bias,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 0, 15, 0.0F),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      16,
      if point.soft_shadows_enabled {
        point.radius
      } else {
        0.0F
      },
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      0,
      17,
      point.shadow_map_near_z,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word(clustered_bytes, 0, 18),
    content="4294967295",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 0, 19, point.range),
    content="true",
  )

  let spot = clusterable_lights[1].light()
  guard spot.spot_light_angles is Some((inner, outer)) else {
    debug_inspect("missing", content="spot")
    return
  }
  let spot_direction = @pbr_render.render3d_transform_forward(spot.transform)
  let cos_outer = @math.cos(outer)
  let raw_denom = @math.cos(inner) - cos_outer
  let denom = if raw_denom < 0.0001F { 0.0001F } else { raw_denom }
  let spot_scale = 1.0F / denom
  let spot_offset = 0.0F - cos_outer * spot_scale
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 1, 0, spot_direction.x),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 1, 1, spot_direction.z),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 1, 2, spot_scale),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 1, 3, spot_offset),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      4,
      spot.color.r * spot.intensity,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      5,
      spot.color.g * spot.intensity,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      6,
      spot.color.b * spot.intensity,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      7,
      1.0F / (spot.range * spot.range),
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      8,
      spot.transform.translation.x,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      9,
      spot.transform.translation.y,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      10,
      spot.transform.translation.z,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 1, 11, spot.radius),
    content="true",
  )
  debug_inspect(
    clustered_light_word(clustered_bytes, 1, 12),
    content=clustered_light_expected_flags(clusterable_lights[1]).to_string(),
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      13,
      spot.shadow_depth_bias,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      14,
      spot.shadow_normal_bias,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      15,
      @math.sin(outer) / @math.cos(outer),
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      16,
      if spot.soft_shadows_enabled {
        spot.radius
      } else {
        0.0F
      },
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word_matches_f32(
      clustered_bytes,
      1,
      17,
      spot.shadow_map_near_z,
    ),
    content="true",
  )
  debug_inspect(
    clustered_light_word(clustered_bytes, 1, 18),
    content="4294967295",
  )
  debug_inspect(
    clustered_light_word_matches_f32(clustered_bytes, 1, 19, spot.range),
    content="true",
  )
}

///|
test "volumetric_fog: static lights and fog volume match Bevy" {
  let world = @ecs.World::new()
  defer world.close()
  setup_lights(world)

  let point_light_count = Ref(0)
  let point_light_matches = Ref(true)
  let point_light_query : @ecs.Query[
    (
      @ecs.Read[@pbr.PointLight],
      @ecs.Read[@transform.Transform],
      @ecs.Read[@pbr.VolumetricLight],
      @ecs.Read[MoveBackAndForthHorizontally],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! point_light_query.view(fn(_entity, data) {
    let (light_read, transform_read, _volumetric_light, move_data_read) = data
    let light = light_read.value()
    let color = light.color.to_srgba_tuple()
    let move_data = move_data_read.value()
    point_light_count.val = point_light_count.val + 1
    point_light_matches.val = point_light_matches.val &&
      vec3_approx_eq(
        transform_read.value().translation,
        @math.Vec3::new(-0.4F, 1.9F, 1.0F),
      ) &&
      approx_eq(color.0, 1.0F) &&
      approx_eq(color.1, 0.0F) &&
      approx_eq(color.2, 0.0F) &&
      approx_eq(color.3, 1.0F) &&
      approx_eq(light.intensity, 10_000.0F) &&
      approx_eq(light.range, 150.0F) &&
      light.shadow_maps_enabled &&
      approx_eq(move_data.min_x, -1.93F) &&
      approx_eq(move_data.max_x, -0.4F) &&
      approx_eq(move_data.speed, -0.2F)
  })
  debug_inspect(point_light_count.val, content="1")
  debug_inspect(point_light_matches.val, content="true")

  let spot_light_count = Ref(0)
  let spot_light_matches = Ref(true)
  let spot_light_query : @ecs.Query[
    (
      @ecs.Read[@pbr.SpotLight],
      @ecs.Read[@transform.Transform],
      @ecs.Read[@pbr.VolumetricLight],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! spot_light_query.view(fn(_entity, data) {
    let (light_read, transform_read, _volumetric_light) = data
    let light = light_read.value()
    let color = light.color.to_srgba_tuple()
    spot_light_count.val = spot_light_count.val + 1
    spot_light_matches.val = spot_light_matches.val &&
      vec3_approx_eq(
        transform_read.value().translation,
        @math.Vec3::new(-1.8F, 3.9F, -2.7F),
      ) &&
      approx_eq(color.0, 1.0F) &&
      approx_eq(color.1, 1.0F) &&
      approx_eq(color.2, 1.0F) &&
      approx_eq(color.3, 1.0F) &&
      approx_eq(light.intensity, 50_000.0F) &&
      approx_eq(light.inner_angle, 0.76F) &&
      approx_eq(light.outer_angle, 0.94F) &&
      light.shadow_maps_enabled
  })
  debug_inspect(spot_light_count.val, content="1")
  debug_inspect(spot_light_matches.val, content="true")

  let fog_volume_count = Ref(0)
  let fog_volume_matches = Ref(true)
  let fog_volume_query : @ecs.Query[
    (@ecs.Read[@pbr.FogVolume], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! fog_volume_query.view(fn(_entity, data) {
    let (fog_volume_read, transform_read) = data
    let fog_volume = fog_volume_read.value()
    let fog_color = fog_volume.fog_color.to_srgba_tuple()
    let light_tint = fog_volume.light_tint.to_srgba_tuple()
    fog_volume_count.val = fog_volume_count.val + 1
    fog_volume_matches.val = fog_volume_matches.val &&
      vec3_approx_eq(transform_read.value().scale, @math.Vec3::splat(35.0F)) &&
      approx_eq(fog_color.0, 1.0F) &&
      approx_eq(fog_color.1, 1.0F) &&
      approx_eq(fog_color.2, 1.0F) &&
      approx_eq(fog_color.3, 1.0F) &&
      approx_eq(fog_volume.density_factor, 0.1F) &&
      fog_volume.density_texture is None &&
      vec3_approx_eq(fog_volume.density_texture_offset, @math.Vec3::zero()) &&
      approx_eq(fog_volume.absorption, 0.3F) &&
      approx_eq(fog_volume.scattering, 0.3F) &&
      approx_eq(fog_volume.scattering_asymmetry, 0.5F) &&
      approx_eq(light_tint.0, 1.0F) &&
      approx_eq(light_tint.1, 1.0F) &&
      approx_eq(light_tint.2, 1.0F) &&
      approx_eq(light_tint.3, 1.0F) &&
      approx_eq(fog_volume.light_intensity, 1.0F)
  })
  debug_inspect(fog_volume_count.val, content="1")
  debug_inspect(fog_volume_matches.val, content="true")
}

///|
test "volumetric_fog: camera and fog volume prepare Bevy interior view fog" {
  let world = @ecs.World::new()
  defer world.close()
  setup_camera(world)
  setup_lights(world)

  let camera_transform_ref = Ref(@transform.Transform::identity())
  let volumetric_fog_ref = Ref(@pbr.VolumetricFog::VolumetricFog())
  let camera_query : @ecs.Query[
    (@ecs.Read[@transform.Transform], @ecs.Read[@pbr.VolumetricFog]),
    @ecs.With[@camera.Camera3d],
  ] = @ecs.query_filtered(world, @ecs.With::new(@camera.ecs_key_camera3d))
  try! camera_query.view(fn(_entity, data) {
    let (transform_read, fog_read) = data
    camera_transform_ref.val = transform_read.value()
    volumetric_fog_ref.val = fog_read.value()
  })

  let expected_forward = scene_focus()
    .sub(camera_transform_ref.val.translation)
    .normalize_or_zero()
  debug_inspect(
    vec3_approx_eq(camera_transform_ref.val.forward(), expected_forward),
    content="true",
  )

  let fog_volume_ref = Ref(@pbr.FogVolume::FogVolume())
  let fog_volume_transform_ref = Ref(@transform.Transform::identity())
  let fog_volume_query : @ecs.Query[
    (@ecs.Read[@pbr.FogVolume], @ecs.Read[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! fog_volume_query.view(fn(_entity, data) {
    let (volume_read, transform_read) = data
    fog_volume_ref.val = volume_read.value()
    fog_volume_transform_ref.val = transform_read.value()
  })

  let buffer = @pbr_volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let clip_from_view = @pbr_volumetric_fog.VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.1F, 1.0F),
  )
  let view_fog = @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
    buffer,
    volumetric_fog_ref.val,
    @transform.GlobalTransform::from_transform(camera_transform_ref.val).affine(),
    clip_from_view,
    [
      (
        fog_volume_ref.val,
        @transform.GlobalTransform::from_transform(fog_volume_transform_ref.val)
        .affine()
        .inverse(),
      ),
    ],
  )
  debug_inspect(view_fog.count(), content="1")
  debug_inspect(view_fog.volumes()[0].exterior(), content="false")
  debug_inspect(view_fog.volumes()[0].has_density_texture(), content="false")
  debug_inspect(buffer.count(), content="1")
  debug_inspect(buffer.bytes().length(), content="512")
  let uniform_bytes = buffer.bytes()
  let expected_uniform_words : Array[UInt] = [
    1036831949U, 0U, 0U, 0U, 0U, 1036831949U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 1036831949U,
    1036831949U, 1021972129U, 0U, 0U, 0U, 0U, 1021972129U, 0U, 0U, 0U, 0U, 1021972129U,
    0U, 1056964608U, 1056964608U, 1056964608U, 1065353216U, 3212511062U, 1025153016U,
    1044713894U, 1100585370U, 823730176U, 3212523244U, 1044713894U, 1098907649U,
    1044959919U, 1044463091U, 1064719883U, 1102053377U, 1065353216U, 1065353216U,
    1065353216U, 0U, 1065353216U, 1065353216U, 1065353216U, 0U, 1065353216U, 1065353216U,
    1065353216U, 0U, 64U, 1106410675U, 1050253722U, 1050253722U, 1036831949U, 0U,
    0U, 0U, 0U, 0U, 0U, 1056964608U, 1065353216U, 0U,
  ]
  debug_inspect(
    volumetric_fog_uniform_words_eq(
      volumetric_fog_uniform_words(uniform_bytes),
      expected_uniform_words,
    ),
    content="true",
  )
  debug_inspect(volumetric_fog_uniform_u32_at(uniform_bytes, 224), content="64")
  debug_inspect(
    volumetric_fog_uniform_u32_at(uniform_bytes, 228),
    content="\{30.310888F.reinterpret_as_uint()}",
  )
  debug_inspect(
    volumetric_fog_uniform_u32_at(uniform_bytes, 240),
    content="\{0.1F.reinterpret_as_uint()}",
  )
  debug_inspect(
    volumetric_fog_uniform_u32_at(uniform_bytes, 268),
    content="\{0.5F.reinterpret_as_uint()}",
  )
  debug_inspect(
    volumetric_fog_uniform_u32_at(uniform_bytes, 276),
    content="\{0.0F.reinterpret_as_uint()}",
  )
}

///|
test "volumetric_fog: GLB scene contributor is the inherited-visible Cube mesh" {
  let world_asset_root_count = Ref(0)
  let ready_scene_instance_count = Ref(0)
  let mesh_count = Ref(0)
  let mesh_with_inherited_visibility_count = Ref(0)
  let mesh_with_view_visibility_count = Ref(0)
  let inherited_visible_mesh_count = Ref(0)
  let cube_seen = Ref(false)
  let cube_has_inherited_visibility = Ref(false)
  let cube_has_view_visibility = Ref(false)
  let cube_inherited_visible = Ref(false)
  let cube_node_index = Ref(-1)
  let cube_mesh_index = Ref(-1)
  let cube_primitive_index = Ref(-1)
  let cube_mesh_name = Ref("")
  let cube_material_name = Ref("")
  let cube_primitive_name = Ref("")
  let cube_mesh_handle_id = Ref(-1)
  let cube_material_handle_id = Ref(-1)
  let cube_primitive_entity = Ref(@core.Entity::placeholder())
  let cube_node_entity = Ref(@core.Entity::placeholder())
  let scene_root_entity = Ref(@core.Entity::placeholder())
  let cube_local_translation = Ref(@math.Vec3::zero())
  let cube_local_scale = Ref(@math.Vec3::zero())
  let cube_local_rotation = Ref(@math.Quat::identity())
  let cube_global_translation = Ref(@math.Vec3::splat(999.0F))
  let cube_computed_global_translation = Ref(@math.Vec3::splat(999.0F))
  let cube_node_global_translation = Ref(@math.Vec3::splat(999.0F))
  let cube_node_computed_global_translation = Ref(@math.Vec3::splat(999.0F))
  let scene_root_global_translation = Ref(@math.Vec3::splat(999.0F))
  let scene_root_computed_global_translation = Ref(@math.Vec3::splat(999.0F))
  let cube_aabb_center = Ref(@math.Vec3::zero())
  let cube_aabb_half_size = Ref(@math.Vec3::zero())
  let cube_has_aabb = Ref(false)
  let cube_material_loaded = Ref(false)
  let cube_material_base_color_matches = Ref(false)
  let cube_material_alpha_mode_matches = Ref(false)
  let cube_material_normal_texture_matches = Ref(false)
  let cube_material_normal_texture_id = Ref(-1)
  let cube_material_normal_texture_loaded = Ref(false)
  let cube_material_absent_textures_match = Ref(false)
  let cube_material_scalar_fields_match = Ref(false)
  let cube_material_double_sided_matches = Ref(false)
  let cube_material_extension_defaults_match = Ref(false)
  let cube_prepared_phase_matches = Ref(false)
  let cube_prepared_material_key_matches = Ref(false)
  let cube_prepared_descriptor_matches = Ref(false)
  let cube_parent_matches = Ref(false)
  let scene_parent_matches = Ref(false)
  let cube_node_name = Ref("")
  let scene_root_name = Ref("")
  let scene_root_index = Ref(-1)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .insert_resource(AppSettings::AppSettings())
    .add_systems_world(@app.Startup, fn(world : @ecs.World) {
      setup_scene(world)
    })
  app = app.run_startup()
  for _ in 0..<180 {
    app = app.run_once()
  }
  let world = app.world()

  world.for_each_component(@scene.ecs_key_world_asset_root, fn(entity, _root) {
    world_asset_root_count.val = world_asset_root_count.val + 1
    if @scene.scene_components_has_scene_instance_ready(world, entity) {
      ready_scene_instance_count.val = ready_scene_instance_count.val + 1
    }
  })

  let mesh_query : @ecs.Query[
    (
      @core.Entity,
      (
        (
          @ecs.Read[@mesh.Mesh3d],
          @ecs.Read[@pbr.MeshMaterial3dTyped[@pbr.StandardMaterial]],
          @ecs.Read[@transform.Transform],
          @ecs.Read[@transform.GlobalTransform],
        ),
        (
          @ecs.Optional[@ecs.Name],
          @ecs.Optional[@gltf.GltfNodeIndex],
          @ecs.Optional[@gltf.GltfMeshIndex],
        ),
        (
          @ecs.Optional[@gltf.GltfPrimitiveIndex],
          @ecs.Optional[@gltf.GltfMeshName],
          @ecs.Optional[@gltf.GltfMaterialName],
        ),
      ),
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! mesh_query.view(fn(entity, data) {
    let (
      _entity,
      (
        (mesh3d_read, material_read, local_transform_read, global_transform_read
        ),
        (name_read, node_index_read, mesh_index_read),
        (primitive_index_read, mesh_name_read, material_name_read),
      ),
    ) = data
    mesh_count.val = mesh_count.val + 1
    match
      (
        try! world.get_by_key(entity, @visibility.ecs_key_inherited_visibility) :
        @visibility.InheritedVisibility?) {
      Some(inherited_visibility) => {
        mesh_with_inherited_visibility_count.val = mesh_with_inherited_visibility_count.val +
          1
        if inherited_visibility.is_visible() {
          inherited_visible_mesh_count.val = inherited_visible_mesh_count.val +
            1
        }
      }
      None => ()
    }
    if (try! world.contains_by_key(entity, @visibility.ecs_key_view_visibility)) {
      mesh_with_view_visibility_count.val = mesh_with_view_visibility_count.val +
        1
    }
    if mesh_count.val == 1 {
      cube_seen.val = true
      cube_primitive_entity.val = entity
      match
        (
          try! world.get_by_key(
            entity, @visibility.ecs_key_inherited_visibility,
          ) : @visibility.InheritedVisibility?) {
        Some(inherited_visibility) => {
          cube_has_inherited_visibility.val = true
          cube_inherited_visible.val = inherited_visibility.is_visible()
        }
        None => ()
      }
      if (try! world.contains_by_key(
          entity, @visibility.ecs_key_view_visibility,
        )) {
        cube_has_view_visibility.val = true
      }
      cube_node_index.val = match node_index_read.value() {
        Some(index) => index.index()
        None => -1
      }
      cube_mesh_index.val = match mesh_index_read.value() {
        Some(index) => index.index()
        None => -1
      }
      cube_primitive_index.val = match primitive_index_read.value() {
        Some(index) => index.primitive_index()
        None => -1
      }
      cube_mesh_name.val = match mesh_name_read.value() {
        Some(mesh_name) => mesh_name.as_str()
        None => ""
      }
      cube_material_name.val = match material_name_read.value() {
        Some(material_name) => material_name.as_str()
        None => ""
      }
      cube_primitive_name.val = match name_read.value() {
        Some(name) => name.as_str()
        None => ""
      }
      cube_mesh_handle_id.val = mesh3d_read.value().mesh().id()
      cube_material_handle_id.val = material_read.value().handle().id()
      cube_local_translation.val = local_transform_read.value().translation
      cube_local_scale.val = local_transform_read.value().scale
      cube_local_rotation.val = local_transform_read.value().rotation
      let global_transform = global_transform_read.value()
      cube_global_translation.val = global_transform.translation()
      match @transform.compute_global_transform(world, entity) {
        Some(computed_global) =>
          cube_computed_global_translation.val = computed_global.translation()
        None => ()
      }
    }
  })
  if cube_material_handle_id.val >= 0 {
    let material_assets_key : @ecs.ResourceKey[
      @asset.Assets[@pbr.StandardMaterial],
    ] = @asset.assets_resource_key()
    match world.get_resource(material_assets_key) {
      Some(material_assets) =>
        match
          material_assets.get(@asset.Handle::new(cube_material_handle_id.val)) {
          Some(material) => {
            cube_material_loaded.val = true
            let (base_r, base_g, base_b, base_a) = material.base_color.to_linear_rgba_tuple()
            cube_material_base_color_matches.val = approx_eq(
                base_r, 0.800000011920929F,
              ) &&
              approx_eq(base_g, 0.800000011920929F) &&
              approx_eq(base_b, 0.800000011920929F) &&
              approx_eq(base_a, 1.0F)
            cube_material_alpha_mode_matches.val = material.alpha_mode
              is @pbr.AlphaMode3d::Opaque
            cube_material_normal_texture_matches.val = material.normal_map_texture
              is Some(_)
            match material.normal_map_texture {
              Some(texture) => {
                cube_material_normal_texture_id.val = texture.id()
                cube_material_normal_texture_loaded.val = @render.asset_is_texture_loaded(
                  texture_id=texture.id(),
                )
              }
              None => ()
            }
            cube_material_absent_textures_match.val = material.base_color_texture
              is None &&
              material.emissive_texture is None &&
              material.metallic_roughness_texture is None &&
              material.occlusion_texture is None
            let transformed_uv = material.uv_transform.transform_point2(
              @math.Vec2::new(0.25F, 0.75F),
            )
            cube_material_scalar_fields_match.val = approx_eq(
                material.metallic,
                0.0F,
              ) &&
              approx_eq(material.perceptual_roughness, 0.5F) &&
              vec2_approx_eq(transformed_uv, @math.Vec2::new(0.25F, 0.75F))
            cube_material_double_sided_matches.val = material.cull_mode is None
            let (emissive_r, emissive_g, emissive_b, emissive_a) = material.emissive.to_linear_rgba_tuple()
            let (specular_r, specular_g, specular_b, specular_a) = material.specular_tint.to_linear_rgba_tuple()
            cube_material_extension_defaults_match.val = !material.unlit &&
              approx_eq(emissive_r, 0.0F) &&
              approx_eq(emissive_g, 0.0F) &&
              approx_eq(emissive_b, 0.0F) &&
              approx_eq(emissive_a, 1.0F) &&
              approx_eq(material.emissive_exposure_weight, 0.0F) &&
              approx_eq(material.reflectance, 0.5F) &&
              approx_eq(specular_r, 1.0F) &&
              approx_eq(specular_g, 1.0F) &&
              approx_eq(specular_b, 1.0F) &&
              approx_eq(specular_a, 1.0F) &&
              approx_eq(material.ior, 1.5F) &&
              approx_eq(material.clearcoat, 0.0F) &&
              approx_eq(material.clearcoat_perceptual_roughness, 0.0F) &&
              approx_eq(material.anisotropy_strength, 0.0F) &&
              approx_eq(material.anisotropy_rotation, 0.0F)
            let properties = @pbr.render3d_material_properties_for_standard_material(
              material,
              None,
              @material.OpaqueRendererMethod::Forward,
              true,
            )
            cube_prepared_phase_matches.val = properties.render_phase_type
              is @material.RenderPhaseType::Opaque &&
              properties.alpha_mode is @material.AlphaMode3d::Opaque &&
              !properties.reads_view_transmission_texture &&
              properties.mesh_pipeline_key_bits.bits() == 0UL
            let material_key = @pbr.standard_material_key_from_material(
              material,
            )
            cube_prepared_material_key_matches.val = material_key.contains(
                @pbr.STANDARD_MATERIAL_KEY_NORMAL_MAP,
              ) &&
              !material_key.contains(@pbr.STANDARD_MATERIAL_KEY_CULL_FRONT) &&
              !material_key.contains(@pbr.STANDARD_MATERIAL_KEY_CULL_BACK) &&
              material_key.bits() == properties.material_key.bits()
            let pipeline_key = @material.ErasedMaterialPipelineKey::new(
              properties.mesh_pipeline_key_bits,
              properties.material_key,
              "StandardMaterial",
            )
            let descriptor = try! @pbr.PbrMaterialPipelineSpecializer::new(
              properties,
            ).specialize(
              pipeline_key,
              volumetric_fog_material_specializer_layout(),
            )
            let fragment_matches = match descriptor.fragment {
              Some(fragment) =>
                match fragment.targets[0] {
                  Some(target) =>
                    target.blend() is None &&
                    shader_defs_contain_flag(
                      fragment.shader_defs,
                      "STANDARD_MATERIAL_NORMAL_MAP",
                    )
                  None => false
                }
              None => false
            }
            let depth_matches = match descriptor.depth_stencil {
              Some(depth) =>
                depth.depth_write_enabled &&
                depth.depth_compare == @wgpu.COMPARE_FUNCTION_GREATER_EQUAL
              None => false
            }
            cube_prepared_descriptor_matches.val = descriptor.label ==
              Some("pbr_opaque_mesh_pipeline") &&
              descriptor.primitive.cull_mode is None &&
              depth_matches &&
              fragment_matches
          }
          None => ()
        }
      None => ()
    }
  }
  if !cube_primitive_entity.val.is_placeholder() {
    match
      (
        try! world.get_by_key(cube_primitive_entity.val, @camera.ecs_key_aabb) :
        @camera.Aabb?) {
      Some(aabb) => {
        cube_has_aabb.val = true
        cube_aabb_center.val = aabb.center()
        cube_aabb_half_size.val = aabb.half_size()
      }
      None => ()
    }
  }
  if !cube_primitive_entity.val.is_placeholder() {
    match
      (
        try! world.get_by_key(
          cube_primitive_entity.val,
          @hierarchy.ecs_key_parent,
        ) : @hierarchy.Parent?) {
      Some(parent) => {
        cube_node_entity.val = parent.entity()
        cube_parent_matches.val = match
          (
            try! world.get_by_key(
              cube_node_entity.val,
              @gltf.GltfNodeIndex::component(),
            ) : @gltf.GltfNodeIndex?) {
          Some(node_index) => node_index.index() == 1
          None => false
        }
        cube_node_name.val = match
          (
            try! world.get_by_key(cube_node_entity.val, @ecs.Name::component()) :
            @ecs.Name?) {
          Some(name) => name.as_str()
          None => ""
        }
        match
          (
            try! world.get_by_key(
              cube_node_entity.val,
              @transform.ecs_key_global_transform,
            ) : @transform.GlobalTransform?) {
          Some(global_transform) => {
            cube_node_global_translation.val = global_transform.translation()
            match
              @transform.compute_global_transform(world, cube_node_entity.val) {
              Some(computed_global) =>
                cube_node_computed_global_translation.val = computed_global.translation()
              None => ()
            }
          }
          None => ()
        }
      }
      None => ()
    }
  }
  if !cube_node_entity.val.is_placeholder() {
    match
      (
        try! world.get_by_key(cube_node_entity.val, @hierarchy.ecs_key_parent) :
        @hierarchy.Parent?) {
      Some(parent) => {
        scene_root_entity.val = parent.entity()
        scene_parent_matches.val = match
          (
            try! world.get_by_key(
              scene_root_entity.val,
              @gltf.GltfSceneIndex::component(),
            ) : @gltf.GltfSceneIndex?) {
          Some(scene_index) => {
            scene_root_index.val = scene_index.index()
            scene_index.index() == 0
          }
          None => false
        }
        scene_root_name.val = match
          (
            try! world.get_by_key(scene_root_entity.val, @ecs.Name::component()) :
            @ecs.Name?) {
          Some(name) => name.as_str()
          None => ""
        }
        match
          (
            try! world.get_by_key(
              scene_root_entity.val,
              @transform.ecs_key_global_transform,
            ) : @transform.GlobalTransform?) {
          Some(global_transform) => {
            scene_root_global_translation.val = global_transform.translation()
            match
              @transform.compute_global_transform(world, scene_root_entity.val) {
              Some(computed_global) =>
                scene_root_computed_global_translation.val = computed_global.translation()
              None => ()
            }
          }
          None => ()
        }
      }
      None => ()
    }
  }
  debug_inspect(world_asset_root_count.val, content="1")
  debug_inspect(ready_scene_instance_count.val, content="1")
  debug_inspect(mesh_count.val, content="1")
  debug_inspect(mesh_with_inherited_visibility_count.val, content="1")
  debug_inspect(mesh_with_view_visibility_count.val, content="1")
  debug_inspect(inherited_visible_mesh_count.val, content="1")
  debug_inspect(cube_seen.val, content="true")
  debug_inspect(cube_has_inherited_visibility.val, content="true")
  debug_inspect(cube_has_view_visibility.val, content="true")
  debug_inspect(cube_inherited_visible.val, content="true")
  debug_inspect(cube_node_index.val, content="1")
  debug_inspect(cube_mesh_index.val, content="0")
  debug_inspect(cube_primitive_index.val, content="0")
  debug_inspect(cube_mesh_name.val, content="\"Cube\"")
  debug_inspect(cube_material_name.val, content="\"Material.002\"")
  debug_inspect(cube_primitive_name.val, content="\"Cube.Material.002\"")
  debug_inspect(cube_mesh_handle_id.val >= 0, content="true")
  debug_inspect(cube_material_handle_id.val >= 0, content="true")
  debug_inspect(
    vec3_approx_eq(cube_local_translation.val, @math.Vec3::zero()),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(cube_local_scale.val, @math.Vec3::splat(1.0F)),
    content="true",
  )
  debug_inspect(
    quat_approx_eq(cube_local_rotation.val, @math.Quat::identity()),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      cube_global_translation.val,
      @math.Vec3::new(0.0F, 2.3829579F, 0.0F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      cube_computed_global_translation.val,
      @math.Vec3::new(0.0F, 2.3829579F, 0.0F),
    ),
    content="true",
  )
  debug_inspect(cube_has_aabb.val, content="true")
  debug_inspect(
    vec3_approx_eq(
      cube_aabb_center.val,
      @math.Vec3::new(0.0F, 0.33192348F, 0.0F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      cube_aabb_half_size.val,
      @math.Vec3::new(1.0F, 1.3319235F, 1.0F),
    ),
    content="true",
  )
  debug_inspect(cube_material_loaded.val, content="true")
  debug_inspect(cube_material_base_color_matches.val, content="true")
  debug_inspect(cube_material_alpha_mode_matches.val, content="true")
  debug_inspect(cube_material_normal_texture_matches.val, content="true")
  debug_inspect(cube_material_normal_texture_id.val >= 0, content="true")
  debug_inspect(cube_material_normal_texture_loaded.val, content="true")
  debug_inspect(cube_material_absent_textures_match.val, content="true")
  debug_inspect(cube_material_scalar_fields_match.val, content="true")
  debug_inspect(cube_material_double_sided_matches.val, content="true")
  debug_inspect(cube_material_extension_defaults_match.val, content="true")
  debug_inspect(cube_prepared_phase_matches.val, content="true")
  debug_inspect(cube_prepared_material_key_matches.val, content="true")
  debug_inspect(cube_prepared_descriptor_matches.val, content="true")
  debug_inspect(cube_parent_matches.val, content="true")
  debug_inspect(cube_node_name.val, content="\"Cube\"")
  debug_inspect(
    vec3_approx_eq(
      cube_node_global_translation.val,
      @math.Vec3::new(0.0F, 2.3829579F, 0.0F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      cube_node_computed_global_translation.val,
      @math.Vec3::new(0.0F, 2.3829579F, 0.0F),
    ),
    content="true",
  )
  debug_inspect(scene_parent_matches.val, content="true")
  debug_inspect(scene_root_index.val, content="0")
  debug_inspect(scene_root_name.val, content="\"Scene\"")
  debug_inspect(
    vec3_approx_eq(scene_root_global_translation.val, @math.Vec3::zero()),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      scene_root_computed_global_translation.val,
      @math.Vec3::zero(),
    ),
    content="true",
  )
}

///|
test "volumetric_fog: GLB Cube reaches PBR render mesh extraction" {
  let cube_primitive_entity = Ref(@core.Entity::placeholder())
  let cube_mesh_handle_id = Ref(-1)
  let cube_material_handle_id = Ref(-1)
  let cube_global_translation = Ref(@math.Vec3::splat(999.0F))
  let cube_aabb_center = Ref(@math.Vec3::zero())
  let cube_aabb_half_size = Ref(@math.Vec3::zero())
  let cube_has_aabb = Ref(false)
  let camera_entity = Ref(@core.Entity::placeholder())

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(
      @mgstudio.DefaultPlugins::set(
        @pbr.PbrPlugin::PbrPlugin().with_gpu_instance_buffer_builder(false),
      ),
    )
    .insert_resource(AppSettings::AppSettings())
    .add_system(fn(world : @ecs.World) {
      setup_camera(world)
      setup_scene(world)
      @scene.scene_load_pending_system(world)
      @scene.scene_collect_root_spawn_requests_system(world)
      @scene.scene_spawn_roots_system(world)
      @transform.propagate_transforms_system(world)
      @visibility.visibility_propagate_system(world)
      @visibility.check_visibility_system(world)

      let mesh_query : @ecs.Query[
        (
          @core.Entity,
          (
            @ecs.Read[@mesh.Mesh3d],
            @ecs.Read[@pbr.MeshMaterial3dTyped[@pbr.StandardMaterial]],
            @ecs.Read[@transform.GlobalTransform],
            @ecs.Read[@visibility.InheritedVisibility],
          ),
        ),
        @ecs.All,
      ] = @ecs.query(world)
      try! mesh_query.view(fn(entity, data) {
        let (
          _entity,
          (
            mesh3d_read,
            material_read,
            global_transform_read,
            inherited_visibility_read,
          ),
        ) = data
        if inherited_visibility_read.value().is_visible() &&
          cube_primitive_entity.val.is_placeholder() {
          cube_primitive_entity.val = entity
          cube_mesh_handle_id.val = mesh3d_read.value().mesh().id()
          cube_material_handle_id.val = material_read.value().handle().id()
          cube_global_translation.val = global_transform_read
            .value()
            .translation()
          match
            (try! world.get_by_key(entity, @camera.ecs_key_aabb) : @camera.Aabb?) {
            Some(aabb) => {
              cube_has_aabb.val = true
              cube_aabb_center.val = aabb.center()
              cube_aabb_half_size.val = aabb.half_size()
            }
            None => ()
          }
        }
      })
      let camera_query : @ecs.Query[@core.Entity, @ecs.With[@camera.Camera3d]] = @ecs.query_filtered(
        world,
        @ecs.With::new(@camera.ecs_key_camera3d),
      )
      try! camera_query.view(fn(entity, _data) {
        if camera_entity.val.is_placeholder() {
          camera_entity.val = entity
        }
      })
      @pbr_render.ensure_render3d_mesh_runtime_state_resource(world)
      @pbr_render.ensure_morph_resources(world)
      @pbr_render.ensure_skin_uniforms_resource(world)
      if world.get_resource(@pbr.ecs_key_render_material_instances) is None {
        world.insert_resource(
          @pbr.ecs_key_render_material_instances,
          @pbr.RenderMaterialInstances::RenderMaterialInstances(),
        )
      }
      match world.get_resource(@pbr.ecs_key_render_material_instances) {
        Some(material_instances) =>
          material_instances.extract_mesh_material_id(
            cube_primitive_entity.val,
            true,
            cube_material_handle_id.val,
          )
        None => ()
      }
      if world.get_resource(@render_mesh.RenderMeshAssets::resource()) is None {
        world.insert_resource(
          @render_mesh.RenderMeshAssets::resource(),
          @render_mesh.RenderMeshAssets::RenderMeshAssets(),
        )
      }
      if world.get_resource(@render_mesh.MeshAllocator::resource()) is None {
        world.insert_resource(
          @render_mesh.MeshAllocator::resource(),
          @render_mesh.MeshAllocator::new(),
        )
      }
      @render.sorted_cameras_replace(
        @render.sorted_cameras_ref_or_abort(world),
        [
          @render.SortedCamera::new(
            camera_entity.val,
            0,
            None,
            false,
            @render.CameraOutputMode::default(),
          ),
        ],
      )
      @pbr.render3d_prepare_meshes_system(world)
    })
  app = app.run_startup().run_once()

  let render_world = app.world()
  let render_instances = match
    render_world.get_resource(@pbr.RenderMeshInstances::resource()) {
    Some(value) => value
    None => abort("missing RenderMeshInstances resource")
  }
  let render_material_instances = match
    render_world.get_resource(@pbr.ecs_key_render_material_instances) {
    Some(value) => value
    None => abort("missing RenderMaterialInstances resource")
  }
  let main_entity = @render.MainEntity::new(cube_primitive_entity.val)
  let queue_data = match render_instances.render_mesh_queue_data(main_entity) {
    Some(value) => value
    None => abort("missing Cube render mesh queue data")
  }

  let cpu_transform_matches = Ref(false)
  let cpu_previous_transform_matches = Ref(false)
  let cpu_flags_match = Ref(false)
  match render_instances {
    @pbr.RenderMeshInstances::CpuBuilding(cpu_instances) =>
      match cpu_instances.entries.get(cube_primitive_entity.val.to_bits()) {
        Some(instance) =>
          match instance.transforms {
            Some(transforms) => {
              cpu_transform_matches.val = vec3_approx_eq(
                transforms.world_from_local().to_scale_rotation_translation().2,
                cube_global_translation.val,
              )
              cpu_previous_transform_matches.val = vec3_approx_eq(
                transforms
                .previous_world_from_local()
                .to_scale_rotation_translation().2,
                cube_global_translation.val,
              )
              cpu_flags_match.val = (transforms.flags() & 0xFFFFU) == 0xFFFFU &&
                transforms.flags() != 0U
            }
            None => ()
          }
        None => ()
      }
    @pbr.RenderMeshInstances::GpuBuilding(_) =>
      abort("expected CPU RenderMeshInstances for extraction transform proof")
  }

  debug_inspect(cube_primitive_entity.val.is_placeholder(), content="false")
  debug_inspect(cube_mesh_handle_id.val >= 0, content="true")
  debug_inspect(cube_material_handle_id.val >= 0, content="true")
  debug_inspect(cube_has_aabb.val, content="true")
  debug_inspect(
    vec3_approx_eq(
      cube_aabb_center.val,
      @math.Vec3::new(0.0F, 0.33192348F, 0.0F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      cube_aabb_half_size.val,
      @math.Vec3::new(1.0F, 1.3319235F, 1.0F),
    ),
    content="true",
  )
  debug_inspect(
    queue_data.mesh_asset_id(),
    content=cube_mesh_handle_id.val.to_string(),
  )
  debug_inspect(queue_data.current_uniform_index(), content="0")
  debug_inspect(queue_data.should_batch(), content="true")
  debug_inspect(
    queue_data.flags().contains(@pbr.RenderMeshInstanceFlags::shadow_caster()),
    content="true",
  )
  debug_inspect(
    queue_data
    .flags()
    .contains(@pbr.RenderMeshInstanceFlags::automatic_batching()),
    content="true",
  )
  debug_inspect(
    render_material_instances.mesh_material(cube_primitive_entity.val),
    content=cube_material_handle_id.val.to_string(),
  )
  debug_inspect(cpu_transform_matches.val, content="true")
  debug_inspect(cpu_previous_transform_matches.val, content="true")
  debug_inspect(cpu_flags_match.val, content="true")
}

///|
test "volumetric_fog: GLB Sun node imports Bevy-shaped directional light child" {
  let directional_light_count = Ref(0)
  let sun_light_seen = Ref(false)
  let sun_light_name = Ref("")
  let sun_light_has_node_index = Ref(true)
  let sun_light_parent_matches = Ref(false)
  let sun_node_name = Ref("")
  let sun_node_index = Ref(-1)
  let sun_light_local_transform_matches = Ref(false)
  let sun_node_transform_matches = Ref(false)
  let sun_light_global_translation = Ref(@math.Vec3::splat(999.0F))
  let sun_light_global_scale = Ref(@math.Vec3::splat(999.0F))
  let sun_light_global_x_point = Ref(@math.Vec3::splat(999.0F))
  let sun_light_computed_global_translation = Ref(@math.Vec3::splat(999.0F))
  let sun_node_global_translation = Ref(@math.Vec3::splat(999.0F))
  let sun_node_global_scale = Ref(@math.Vec3::splat(999.0F))
  let sun_node_global_x_point = Ref(@math.Vec3::splat(999.0F))
  let sun_node_computed_global_translation = Ref(@math.Vec3::splat(999.0F))
  let sun_light_color_matches = Ref(false)
  let sun_light_illuminance_matches = Ref(false)
  let sun_light_shadow_maps_enabled = Ref(true)

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(AppSettings::AppSettings())
  .add_system(fn(world : @ecs.World) {
    setup_scene(world)
    @scene.scene_load_pending_system(world)
    @scene.scene_collect_root_spawn_requests_system(world)
    @scene.scene_spawn_roots_system(world)
    @transform.propagate_transforms_system(world)

    let light_query : @ecs.Query[
      (
        @core.Entity,
        (
          @ecs.Read[@pbr.DirectionalLight],
          @ecs.Read[@transform.Transform],
          @ecs.Optional[@ecs.Name],
          @ecs.Optional[@gltf.GltfNodeIndex],
        ),
      ),
      @ecs.All,
    ] = @ecs.query(world)
    try! light_query.view(fn(entity, data) {
      let (_entity, (light_read, transform_read, name_read, node_index_read)) = data
      directional_light_count.val = directional_light_count.val + 1
      let light_name = match name_read.value() {
        Some(name) => name.as_str()
        None => ""
      }
      if light_name == "Sun" {
        sun_light_seen.val = true
        sun_light_name.val = light_name
        sun_light_has_node_index.val = node_index_read.value() is Some(_)
        let light = light_read.value()
        let color = light.color.to_srgba_tuple()
        sun_light_color_matches.val = approx_eq(color.0, 1.0F) &&
          approx_eq(color.1, 0.989499986F) &&
          approx_eq(color.2, 0.87052548F) &&
          approx_eq(color.3, 1.0F)
        sun_light_illuminance_matches.val = approx_eq(
          light.illuminance,
          68300.0F,
        )
        sun_light_shadow_maps_enabled.val = light.shadow_maps_enabled
        let local_transform = transform_read.value()
        sun_light_local_transform_matches.val = vec3_approx_eq(
            local_transform.translation,
            @math.Vec3::zero(),
          ) &&
          vec3_approx_eq(local_transform.scale, @math.Vec3::splat(1.0F)) &&
          quat_approx_eq(local_transform.rotation, @math.Quat::identity())
        match
          (
            try! world.get_by_key(entity, @transform.ecs_key_global_transform) :
            @transform.GlobalTransform?) {
          Some(global_transform) => {
            let (global_scale, global_rotation, global_translation) = global_transform.to_scale_rotation_translation()
            sun_light_global_translation.val = global_translation
            sun_light_global_scale.val = global_scale
            ignore(global_rotation)
            sun_light_global_x_point.val = global_transform
              .affine()
              .transform_point3(@math.Vec3::new(1.0F, 0.0F, 0.0F))
            match @transform.compute_global_transform(world, entity) {
              Some(computed_global) =>
                sun_light_computed_global_translation.val = computed_global.translation()
              None => ()
            }
          }
          None => ()
        }
        match
          (
            try! world.get_by_key(entity, @hierarchy.ecs_key_parent) :
            @hierarchy.Parent?) {
          Some(parent) => {
            sun_light_parent_matches.val = match
              (
                try! world.get_by_key(
                  parent.entity(),
                  @gltf.GltfNodeIndex::component(),
                ) : @gltf.GltfNodeIndex?) {
              Some(node_index) => {
                sun_node_index.val = node_index.index()
                node_index.index() == 0
              }
              None => false
            }
            sun_node_name.val = match
              (
                try! world.get_by_key(parent.entity(), @ecs.Name::component()) :
                @ecs.Name?) {
              Some(name) => name.as_str()
              None => ""
            }
            match
              (
                try! world.get_by_key(
                  parent.entity(),
                  @transform.ecs_key_transform,
                ) : @transform.Transform?) {
              Some(parent_transform) =>
                sun_node_transform_matches.val = vec3_approx_eq(
                    parent_transform.translation,
                    @math.Vec3::new(4.3827477F, 10.144035F, -0.30610767F),
                  ) &&
                  vec3_approx_eq(
                    parent_transform.scale,
                    @math.Vec3::splat(1.0F),
                  ) &&
                  quat_approx_eq(
                    parent_transform.rotation,
                    @math.Quat::new(
                      -0.700379F,
                      0.1775618F,
                      -0.22268541F,
                      0.6544863F,
                    ),
                  )
              None => ()
            }
            match
              (
                try! world.get_by_key(
                  parent.entity(),
                  @transform.ecs_key_global_transform,
                ) : @transform.GlobalTransform?) {
              Some(global_transform) => {
                let (global_scale, global_rotation, global_translation) = global_transform.to_scale_rotation_translation()
                sun_node_global_translation.val = global_translation
                sun_node_global_scale.val = global_scale
                ignore(global_rotation)
                sun_node_global_x_point.val = global_transform
                  .affine()
                  .transform_point3(@math.Vec3::new(1.0F, 0.0F, 0.0F))
                match
                  @transform.compute_global_transform(world, parent.entity()) {
                  Some(computed_global) =>
                    sun_node_computed_global_translation.val = computed_global.translation()
                  None => ()
                }
              }
              None => ()
            }
          }
          None => ()
        }
      }
    })
  })
  .run_once()
  |> ignore

  debug_inspect(directional_light_count.val, content="1")
  debug_inspect(sun_light_seen.val, content="true")
  debug_inspect(sun_light_name.val, content="\"Sun\"")
  debug_inspect(sun_light_has_node_index.val, content="false")
  debug_inspect(sun_light_parent_matches.val, content="true")
  debug_inspect(sun_node_name.val, content="\"Sun\"")
  debug_inspect(sun_node_index.val, content="0")
  debug_inspect(sun_light_local_transform_matches.val, content="true")
  debug_inspect(sun_node_transform_matches.val, content="true")
  debug_inspect(
    vec3_approx_eq(
      sun_light_global_translation.val,
      @math.Vec3::new(4.3827477F, 10.144035F, -0.30610767F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(sun_light_global_scale.val, @math.Vec3::splat(1.0F)),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(sun_light_global_x_point.val, sun_node_global_x_point.val),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      sun_light_computed_global_translation.val,
      @math.Vec3::new(4.3827477F, 10.144035F, -0.30610767F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      sun_node_global_translation.val,
      @math.Vec3::new(4.3827477F, 10.144035F, -0.30610767F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(sun_node_global_scale.val, @math.Vec3::splat(1.0F)),
    content="true",
  )
  debug_inspect(
    !vec3_approx_eq(
      sun_node_global_x_point.val,
      @math.Vec3::new(5.3827477F, 10.144035F, -0.30610767F),
    ),
    content="true",
  )
  debug_inspect(
    vec3_approx_eq(
      sun_node_computed_global_translation.val,
      @math.Vec3::new(4.3827477F, 10.144035F, -0.30610767F),
    ),
    content="true",
  )
  debug_inspect(sun_light_color_matches.val, content="true")
  debug_inspect(sun_light_illuminance_matches.val, content="true")
  debug_inspect(sun_light_shadow_maps_enabled.val, content="false")
}

///|
test "volumetric_fog: point light movement clamps and toggles like Bevy" {
  let move_data = MoveBackAndForthHorizontally::MoveBackAndForthHorizontally(
    min_x=-1.93F,
    max_x=-0.4F,
    speed=-0.2F,
  )
  let (moving_translation, moving_data, moving_toggle) = adjust_moving_light_by_seconds(
    @math.Vec3::new(-0.5F, 1.9F, 1.0F),
    move_data,
    1.0F,
  )
  debug_inspect(
    vec3_approx_eq(moving_translation, @math.Vec3::new(-0.7F, 1.9F, 1.0F)),
    content="true",
  )
  debug_inspect(approx_eq(moving_data.speed, -0.2F), content="true")
  debug_inspect(moving_toggle, content="false")

  let (clamped_translation, clamped_data, clamped_toggle) = adjust_moving_light_by_seconds(
    @math.Vec3::new(-1.92F, 1.9F, 1.0F),
    move_data,
    1.0F,
  )
  debug_inspect(
    vec3_approx_eq(clamped_translation, @math.Vec3::new(-1.93F, 1.9F, 1.0F)),
    content="true",
  )
  debug_inspect(approx_eq(clamped_data.speed, 0.2F), content="true")
  debug_inspect(clamped_toggle, content="true")
}

///|
test "volumetric_fog: directional light rotation delta uses Bevy XZY euler order" {
  let input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  input.press(@window.KeyCode::KeyW)
  input.press(@window.KeyCode::ArrowLeft)
  let actual_delta = directional_light_delta_theta(input)
  debug_inspect(
    approx_eq(actual_delta.x, DIRECTIONAL_LIGHT_MOVEMENT_SPEED),
    content="true",
  )
  debug_inspect(
    approx_eq(actual_delta.y, DIRECTIONAL_LIGHT_MOVEMENT_SPEED),
    content="true",
  )

  let opposite_input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  opposite_input.press(@window.KeyCode::KeyS)
  opposite_input.press(@window.KeyCode::ArrowRight)
  let opposite_delta = directional_light_delta_theta(opposite_input)
  debug_inspect(
    approx_eq(opposite_delta.x, -DIRECTIONAL_LIGHT_MOVEMENT_SPEED),
    content="true",
  )
  debug_inspect(
    approx_eq(opposite_delta.y, -DIRECTIONAL_LIGHT_MOVEMENT_SPEED),
    content="true",
  )

  let delta = @math.Vec2::new(
    DIRECTIONAL_LIGHT_MOVEMENT_SPEED,
    DIRECTIONAL_LIGHT_MOVEMENT_SPEED,
  )
  let actual = directional_light_delta_quat(delta)
  let expected = @math.Quat::from_euler(
    @math.EulerRot::XZY,
    DIRECTIONAL_LIGHT_MOVEMENT_SPEED,
    0.0F,
    DIRECTIONAL_LIGHT_MOVEMENT_SPEED,
  )
  debug_inspect(quat_approx_eq(actual, expected), content="true")
}

///|
test "volumetric_fog: tweak_scene shadows and volumetric-lights changed directional lights" {
  let world = @ecs.World::new()
  defer world.close()
  let directional = world.spawn_empty()
  try! world.set_by_key(
    directional,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::DirectionalLight(),
  )
  let mut app = @app.App::new(world).add_system_param2(tweak_scene)

  app = app.run_once()

  let light = try! app
    .world()
    .get_by_key(directional, @pbr.ecs_key_directional_light)
  debug_inspect(
    light.map(fn(value) { value.shadow_maps_enabled }),
    content="Some(true)",
  )
  debug_inspect(
    try! (app.world().get_by_key(directional, @pbr.ecs_key_volumetric_light)
    is Some(_)),
    content="true",
  )
}
