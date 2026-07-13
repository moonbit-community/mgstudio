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
fn light_wbtest_sync_light_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  if (try! world.get_by_key(entity, @render_gpu.ecs_key_render_entity)) is None {
    try! world.set_by_key(
      entity,
      @render_gpu.ecs_key_render_entity,
      @render_gpu.RenderEntity::new(entity),
    )
  }
  if (try! world.get_by_key(entity, @render_gpu.ecs_key_main_entity)) is None {
    try! world.set_by_key(
      entity,
      @render_gpu.ecs_key_main_entity,
      @render_gpu.MainEntity::new(entity),
    )
  }
}

///|
fn light_wbtest_extract_directional_lights(world : @ecs.World) -> Unit {
  world.for_each_component(@light.ecs_key_directional_light, fn(entity, _) {
    light_wbtest_sync_light_entity(world, entity)
  })
  ignore(world.increment_change_tick())
  extract_lights(world)
}

///|
fn light_wbtest_point_shadow_map_size(world : @ecs.World) -> Int {
  match world.get_resource(@light.ecs_key_point_light_shadow_map) {
    Some(value) => value.size
    None => -1
  }
}

///|
fn light_wbtest_directional_shadow_map_size(world : @ecs.World) -> Int {
  match world.get_resource(@light.ecs_key_directional_light_shadow_map) {
    Some(value) => value.size
    None => -1
  }
}

///|
fn light_wbtest_u8_at(bytes : Bytes, index : Int) -> Int {
  match bytes.get(index) {
    Some(value) => value.to_int() & 0xFF
    None => 0
  }
}

///|
fn light_wbtest_u32le_at(bytes : Bytes, index : Int) -> UInt {
  (light_wbtest_u8_at(bytes, index) & 0xFF).reinterpret_as_uint() |
  ((light_wbtest_u8_at(bytes, index + 1) & 0xFF).reinterpret_as_uint() << 8) |
  ((light_wbtest_u8_at(bytes, index + 2) & 0xFF).reinterpret_as_uint() << 16) |
  ((light_wbtest_u8_at(bytes, index + 3) & 0xFF).reinterpret_as_uint() << 24)
}

///|
fn light_wbtest_f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
test "pbr/render light: extract_lights mirrors Bevy shadow map resources into render world" {
  let source_world = @ecs.World::new()
  defer source_world.close()
  let render_world = @ecs.World::new()
  defer render_world.close()
  source_world.insert_resource(
    @light.ecs_key_point_light_shadow_map,
    @light.PointLightShadowMap::new(512),
  )
  source_world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(1024),
  )

  extract_shadow_map_resources_from_worlds(
    source_world,
    render_world,
    @core.SystemTicks::new(0, 1),
  )
  inspect(light_wbtest_point_shadow_map_size(render_world), content="512")
  inspect(
    light_wbtest_directional_shadow_map_size(render_world),
    content="1024",
  )

  ignore(source_world.increment_change_tick())
  ignore(source_world.increment_change_tick())
  source_world.insert_resource(
    @light.ecs_key_point_light_shadow_map,
    @light.PointLightShadowMap::new(2048),
  )
  source_world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(4096),
  )
  extract_shadow_map_resources_from_worlds(
    source_world,
    render_world,
    @core.SystemTicks::new(1, 2),
  )
  inspect(light_wbtest_point_shadow_map_size(render_world), content="2048")
  inspect(
    light_wbtest_directional_shadow_map_size(render_world),
    content="4096",
  )
}

///|
test "pbr/render light: directional light uniform byte offsets match bevy mesh_view_types" {
  let first_cascade = GpuDirectionalCascade3d::{
    clip_from_world: ProjectionMatrix3d::from_cols(
      @math.Vec4::new(1.0F, 2.0F, 3.0F, 4.0F),
      @math.Vec4::new(5.0F, 6.0F, 7.0F, 8.0F),
      @math.Vec4::new(9.0F, 10.0F, 11.0F, 12.0F),
      @math.Vec4::new(13.0F, 14.0F, 15.0F, 16.0F),
    ),
    texel_size: 0.125F,
    far_bound: 64.0F,
  }
  let second_cascade = GpuDirectionalCascade3d::{
    clip_from_world: ProjectionMatrix3d::from_cols(
      @math.Vec4::new(17.0F, 18.0F, 19.0F, 20.0F),
      @math.Vec4::new(21.0F, 22.0F, 23.0F, 24.0F),
      @math.Vec4::new(25.0F, 26.0F, 27.0F, 28.0F),
      @math.Vec4::new(29.0F, 30.0F, 31.0F, 32.0F),
    ),
    texel_size: 0.25F,
    far_bound: 128.0F,
  }
  let directional = GpuDirectionalLight3d::{
    cascades: [first_cascade, second_cascade],
    color: @color.Color::new(0.2F, 0.4F, 0.6F, 0.8F),
    dir_to_light: @math.Vec3::new(-0.3F, -0.4F, -0.5F),
    flags: DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED |
    DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC,
    soft_shadow_size: 1.25F,
    shadow_depth_bias: 0.03125F,
    shadow_normal_bias: 0.0625F,
    num_cascades: 2,
    cascades_overlap_proportion: 0.15F,
    depth_texture_base_index: 3,
    decal_index: 9,
    sun_disk_angular_size: 0.01F,
    sun_disk_intensity: 2.5F,
  }
  let lights = GpuLights3d::{
    directional_lights: [directional],
    ambient_color: @color.Color::new(0.1F, 0.2F, 0.3F, 0.4F),
    cluster_dimensions: (4, 5, 6, 120),
    cluster_factors: @math.Vec4::new(0.01F, 0.02F, 0.03F, 0.04F),
    n_directional_lights: 1,
    spot_light_shadowmap_offset: -2,
    ambient_light_affects_lightmapped_meshes: 1,
    n_rect_lights: 0,
    rect_lights: [],
  }
  let bytes = render3d_gpu_lights_uniform_bytes(lights)
  inspect(bytes.length(), content="4576")
  inspect(
    light_wbtest_u32le_at(bytes, 0),
    content=light_wbtest_f32_bits(1.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 60),
    content=light_wbtest_f32_bits(16.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 64),
    content=light_wbtest_f32_bits(0.125F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 68),
    content=light_wbtest_f32_bits(64.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 72),
    content=light_wbtest_f32_bits(0.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 80),
    content=light_wbtest_f32_bits(17.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 144),
    content=light_wbtest_f32_bits(0.25F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 148),
    content=light_wbtest_f32_bits(128.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 320),
    content=light_wbtest_f32_bits(0.2F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 332),
    content=light_wbtest_f32_bits(0.8F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 336),
    content=light_wbtest_f32_bits(-0.3F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 344),
    content=light_wbtest_f32_bits(-0.5F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 348), content="3")
  inspect(
    light_wbtest_u32le_at(bytes, 352),
    content=light_wbtest_f32_bits(1.25F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 356),
    content=light_wbtest_f32_bits(0.03125F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 360),
    content=light_wbtest_f32_bits(0.0625F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 364), content="2")
  inspect(
    light_wbtest_u32le_at(bytes, 368),
    content=light_wbtest_f32_bits(0.15F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 372), content="3")
  inspect(light_wbtest_u32le_at(bytes, 376), content="9")
  inspect(
    light_wbtest_u32le_at(bytes, 380),
    content=light_wbtest_f32_bits(0.01F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 384),
    content=light_wbtest_f32_bits(2.5F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 388),
    content=light_wbtest_f32_bits(0.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 400),
    content=light_wbtest_f32_bits(1.0F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 748), content="65535")
  inspect(
    light_wbtest_u32le_at(bytes, 4000),
    content=light_wbtest_f32_bits(0.1F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 4016), content="4")
  inspect(light_wbtest_u32le_at(bytes, 4028), content="120")
  inspect(
    light_wbtest_u32le_at(bytes, 4032),
    content=light_wbtest_f32_bits(0.01F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 4048), content="1")
  inspect(light_wbtest_u32le_at(bytes, 4052), content="4294967294")
  inspect(light_wbtest_u32le_at(bytes, 4056), content="1")
  inspect(light_wbtest_u32le_at(bytes, 4060), content="0")
}

///|
test "pbr/render light: directional shadow cascade override reaches packed gpu lights" {
  let base_directional = GpuDirectionalLight3d::{
    cascades: [],
    color: @color.Color::new(1.0F, 0.5F, 0.25F, 1.0F),
    dir_to_light: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    flags: DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC,
    soft_shadow_size: 0.0F,
    shadow_depth_bias: 0.02F,
    shadow_normal_bias: 0.04F,
    num_cascades: 2,
    cascades_overlap_proportion: 0.0F,
    depth_texture_base_index: 0,
    decal_index: -1,
    sun_disk_angular_size: 0.009F,
    sun_disk_intensity: 1.0F,
  }
  let base_lights = GpuLights3d::{
    directional_lights: [base_directional],
    ambient_color: @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    cluster_dimensions: (16, 9, 24, 3456),
    cluster_factors: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    n_directional_lights: 1,
    spot_light_shadowmap_offset: 0,
    ambient_light_affects_lightmapped_meshes: 0,
    n_rect_lights: 0,
    rect_lights: [],
  }
  let cascade_data = [
    1.0F, 2.0F, 3.0F, 4.0F, 5.0F, 6.0F, 7.0F, 8.0F, 9.0F, 10.0F, 11.0F, 12.0F, 13.0F,
    14.0F, 15.0F, 16.0F, 0.125F, 64.0F, 0.0F, 0.0F, 17.0F, 18.0F, 19.0F, 20.0F, 21.0F,
    22.0F, 23.0F, 24.0F, 25.0F, 26.0F, 27.0F, 28.0F, 29.0F, 30.0F, 31.0F, 32.0F,
    0.25F, 128.0F, 0.0F, 0.0F,
  ]
  let resolved = render3d_gpu_lights_with_directional_shadow_cascades(
    base_lights, 37, 1.0F, 2, 0.33F, cascade_data,
  )
  inspect(resolved.directional_lights[0].num_cascades, content="2")
  inspect(
    resolved.directional_lights[0].flags,
    content=(DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC |
    DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED).to_string(),
  )
  inspect(
    light_wbtest_f32_bits(
      resolved.directional_lights[0].cascades_overlap_proportion,
    ),
    content=light_wbtest_f32_bits(0.0F).to_string(),
  )
  let bytes = render3d_gpu_lights_uniform_bytes(resolved)
  inspect(
    light_wbtest_u32le_at(bytes, 0),
    content=light_wbtest_f32_bits(1.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 60),
    content=light_wbtest_f32_bits(16.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 64),
    content=light_wbtest_f32_bits(0.125F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 68),
    content=light_wbtest_f32_bits(64.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 80),
    content=light_wbtest_f32_bits(17.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 144),
    content=light_wbtest_f32_bits(0.25F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 148),
    content=light_wbtest_f32_bits(128.0F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 348), content="3")
  inspect(light_wbtest_u32le_at(bytes, 364), content="2")
  inspect(
    light_wbtest_u32le_at(bytes, 368),
    content=light_wbtest_f32_bits(0.0F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 372), content="0")
  inspect(
    light_wbtest_u32le_at(bytes, 356),
    content=light_wbtest_f32_bits(0.02F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 360),
    content=light_wbtest_f32_bits(0.04F).to_string(),
  )
}

///|
test "pbr/render light: scrolling_fog pass bytes preserve volumetric shadow inputs" {
  let base_directional = GpuDirectionalLight3d::{
    cascades: [],
    color: @color.Color::new(1.0F, 0.95F, 0.85F, 1.0F),
    dir_to_light: @math.Vec3::new(-0.2F, -0.9F, -0.3F),
    flags: DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC,
    soft_shadow_size: 0.0F,
    shadow_depth_bias: 0.02F,
    shadow_normal_bias: 0.04F,
    num_cascades: 2,
    cascades_overlap_proportion: 0.0F,
    depth_texture_base_index: 0,
    decal_index: -1,
    sun_disk_angular_size: 0.00935F,
    sun_disk_intensity: 1.0F,
  }
  let base_lights = GpuLights3d::{
    directional_lights: [base_directional],
    ambient_color: @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    cluster_dimensions: (16, 9, 24, 3456),
    cluster_factors: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    n_directional_lights: 1,
    spot_light_shadowmap_offset: 0,
    ambient_light_affects_lightmapped_meshes: 0,
    n_rect_lights: 0,
    rect_lights: [],
  }
  let cascade_data = [
    1.0F, 2.0F, 3.0F, 4.0F, 5.0F, 6.0F, 7.0F, 8.0F, 9.0F, 10.0F, 11.0F, 12.0F, 13.0F,
    14.0F, 15.0F, 16.0F, 0.125F, 64.0F, 0.0F, 0.0F, 17.0F, 18.0F, 19.0F, 20.0F, 21.0F,
    22.0F, 23.0F, 24.0F, 25.0F, 26.0F, 27.0F, 28.0F, 29.0F, 30.0F, 31.0F, 32.0F,
    0.25F, 128.0F, 0.0F, 0.0F,
  ]
  let lighting = Render3dLightingState::{
    ..render3d_default_lighting_state(),
    gpu_lights: Some(base_lights),
  }
  let encoded = render3d_mesh3d_lights_uniform_bytes_for_pass(
    lighting, 37, 1.0F, 2, 0.33F, cascade_data,
  )
  guard encoded is Some(bytes) else {
    abort("expected scrolling_fog-shaped PBR lights bytes")
  }
  inspect(bytes.length(), content="4576")
  inspect(light_wbtest_u32le_at(bytes, 4048), content="1")
  inspect(light_wbtest_u32le_at(bytes, 348), content="3")
  inspect(light_wbtest_u32le_at(bytes, 364), content="2")
  inspect(
    light_wbtest_u32le_at(bytes, 368),
    content=light_wbtest_f32_bits(0.0F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 372), content="0")
  inspect(
    light_wbtest_u32le_at(bytes, 0),
    content=light_wbtest_f32_bits(1.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 60),
    content=light_wbtest_f32_bits(16.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 64),
    content=light_wbtest_f32_bits(0.125F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 68),
    content=light_wbtest_f32_bits(64.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 80),
    content=light_wbtest_f32_bits(17.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 144),
    content=light_wbtest_f32_bits(0.25F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 148),
    content=light_wbtest_f32_bits(128.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 356),
    content=light_wbtest_f32_bits(0.02F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 360),
    content=light_wbtest_f32_bits(0.04F).to_string(),
  )
}

///|
test "pbr/render light: volumetric cascade shader reads map to Bevy host fields" {
  let directional = GpuDirectionalLight3d::{
    cascades: [
      GpuDirectionalCascade3d::{
        clip_from_world: ProjectionMatrix3d::from_cols(
          @math.Vec4::new(1.0F, 2.0F, 3.0F, 4.0F),
          @math.Vec4::new(5.0F, 6.0F, 7.0F, 8.0F),
          @math.Vec4::new(9.0F, 10.0F, 11.0F, 12.0F),
          @math.Vec4::new(13.0F, 14.0F, 15.0F, 16.0F),
        ),
        texel_size: 0.125F,
        far_bound: 64.0F,
      },
      GpuDirectionalCascade3d::{
        clip_from_world: ProjectionMatrix3d::from_cols(
          @math.Vec4::new(17.0F, 18.0F, 19.0F, 20.0F),
          @math.Vec4::new(21.0F, 22.0F, 23.0F, 24.0F),
          @math.Vec4::new(25.0F, 26.0F, 27.0F, 28.0F),
          @math.Vec4::new(29.0F, 30.0F, 31.0F, 32.0F),
        ),
        texel_size: 0.25F,
        far_bound: 128.0F,
      },
    ],
    color: @color.Color::white(),
    dir_to_light: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    flags: DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED |
    DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC,
    soft_shadow_size: 0.0F,
    shadow_depth_bias: 0.02F,
    shadow_normal_bias: 0.04F,
    num_cascades: 2,
    cascades_overlap_proportion: 0.33F,
    depth_texture_base_index: 7,
    decal_index: -1,
    sun_disk_angular_size: 0.00935F,
    sun_disk_intensity: 1.0F,
  }
  let lights = GpuLights3d::{
    directional_lights: [directional],
    ambient_color: @color.Color::black(),
    cluster_dimensions: (0, 0, 0, 0),
    cluster_factors: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    n_directional_lights: 1,
    spot_light_shadowmap_offset: 0,
    ambient_light_affects_lightmapped_meshes: 0,
    n_rect_lights: 0,
    rect_lights: [],
  }
  let bytes = render3d_gpu_lights_uniform_bytes(lights)
  inspect(bytes.length(), content="4576")

  // Bevy mesh_view_types.wgsl:
  // DirectionalCascade { clip_from_world, texel_size, far_bound }
  inspect(
    light_wbtest_u32le_at(bytes, 0),
    content=light_wbtest_f32_bits(1.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 60),
    content=light_wbtest_f32_bits(16.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 64),
    content=light_wbtest_f32_bits(0.125F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 68),
    content=light_wbtest_f32_bits(64.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 80),
    content=light_wbtest_f32_bits(17.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 140),
    content=light_wbtest_f32_bits(32.0F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 144),
    content=light_wbtest_f32_bits(0.25F).to_string(),
  )
  inspect(
    light_wbtest_u32le_at(bytes, 148),
    content=light_wbtest_f32_bits(128.0F).to_string(),
  )

  // Bevy volumetric_fog.wgsl and shadows.wgsl read these DirectionalLight fields.
  inspect(light_wbtest_u32le_at(bytes, 348), content="3")
  inspect(light_wbtest_u32le_at(bytes, 364), content="2")
  inspect(
    light_wbtest_u32le_at(bytes, 368),
    content=light_wbtest_f32_bits(0.33F).to_string(),
  )
  inspect(light_wbtest_u32le_at(bytes, 372), content="7")
  inspect(light_wbtest_u32le_at(bytes, 4048), content="1")
}

///|
test "pbr/render light: directional shadow flags respect texture array layer cap" {
  let world = @ecs.World::new()
  defer world.close()

  let first = world.spawn()
  let first_config = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(MAX_CASCADES_PER_LIGHT)
    .build()
  try! world.set_by_key(
    first,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  try! world.set_by_key(
    first, @light.ecs_key_cascade_shadow_config, first_config,
  )
  try! world.set_by_key(
    first,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )

  let second = world.spawn()
  let second_config = @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(1)
    .build()
  try! world.set_by_key(
    second,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  try! world.set_by_key(
    second, @light.ecs_key_cascade_shadow_config, second_config,
  )
  try! world.set_by_key(
    second,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )

  light_wbtest_extract_directional_lights(world)
  let extracted = render3d_collect_extracted_directional_lights(world)
  let max_texture_array_layers = MAX_CASCADES_PER_LIGHT
  let volumetric_limit = render3d_directional_lights_volumetric_enabled_count(
    extracted, max_texture_array_layers,
  )
  inspect(volumetric_limit, content="1")

  let (first_shadow_enabled, first_cascades) = render3d_directional_light_shadow_state(
    extracted[0],
    0,
    max_texture_array_layers,
  )
  inspect(first_shadow_enabled, content="true")
  inspect(first_cascades, content=MAX_CASCADES_PER_LIGHT.to_string())
  let first_flags = render3d_directional_light_flags_for_gpu(
    extracted[0],
    first_shadow_enabled,
    extracted[0].volumetric && first_shadow_enabled && 0 < volumetric_limit,
  )
  inspect(
    (first_flags & DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED) != 0U,
    content="true",
  )
  inspect(
    (first_flags & DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC) != 0U,
    content="true",
  )

  let (second_shadow_enabled, second_cascades) = render3d_directional_light_shadow_state(
    extracted[1],
    first_cascades,
    max_texture_array_layers,
  )
  inspect(second_shadow_enabled, content="false")
  inspect(second_cascades, content="0")
  let second_flags = render3d_directional_light_flags_for_gpu(
    extracted[1],
    second_shadow_enabled,
    extracted[1].volumetric && second_shadow_enabled && 1 < volumetric_limit,
  )
  inspect(
    (second_flags & DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED) == 0U,
    content="true",
  )
  inspect(
    (second_flags & DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC) == 0U,
    content="true",
  )
}
