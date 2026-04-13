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
pub(all) struct Render3dLightingState {
  ambient_color : @sprite.Color
  ambient_brightness : Float
  directional_dir : @math.Vec3
  directional_color : @sprite.Color
  directional_illuminance : Float
  point_entity : @core.Entity?
  point_pos : @math.Vec3
  point_color : @sprite.Color
  point_intensity : Float
  point_range : Float
  point_shadow_maps_enabled : Bool
  point_shadow_depth_bias : Float
  point_shadow_map_near_z : Float
  spot_pos : @math.Vec3
  spot_dir : @math.Vec3
  spot_color : @sprite.Color
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
}

///|
pub const MAX_DIRECTIONAL_LIGHTS : Int = 10

///|
pub const MAX_CASCADES_PER_LIGHT : Int = 4

///|
const POINT_LIGHT_FLAG_SHADOW_MAPS_ENABLED : UInt = 1U << 0

///|
const POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE : UInt = 1U << 1

///|
const POINT_LIGHT_FLAG_VOLUMETRIC : UInt = 1U << 2

///|
const POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE : UInt = 1U << 3

///|
const POINT_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED : UInt = 1U << 4

///|
const POINT_LIGHT_FLAG_NONE : UInt = 0U

const DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED : UInt = 1U << 0

///|
const DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC : UInt = 1U << 1

///|
const DIRECTIONAL_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE : UInt = 1U << 2

///|
const DIRECTIONAL_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED : UInt = 1U << 3

///|
const DIRECTIONAL_LIGHT_FLAG_NONE : UInt = 0U

///|
const DIRECTIONAL_LIGHT_FLAG_UNINITIALIZED : UInt = 0xFFFFU

///|
fn render3d_sqrt2() -> Float {
  @math.sqrt(2.0F)
}

///|
fn render3d_tan(value : Float) -> Float {
  let sinv = @math.sin(value)
  let cosv = @math.cos(value)
  if cosv >= 0.0F && cosv < 1.0e-6F {
    sinv / 1.0e-6F
  } else if cosv < 0.0F && cosv > -1.0e-6F {
    sinv / -1.0e-6F
  } else {
    sinv / cosv
  }
}

///|
fn render3d_transform_back(transform : @transform.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, 1.0F)).normalize_or_zero()
}

///|
fn render3d_scale_color(color : @sprite.Color, scale : Float) -> @sprite.Color {
  @sprite.Color::new(
    color.r * scale,
    color.g * scale,
    color.b * scale,
    color.a * scale,
  )
}

///|
fn render3d_bool_sort_key(value : Bool) -> Int {
  if value {
    1
  } else {
    0
  }
}

///|
fn render3d_bool_inverted_sort_key(value : Bool) -> Int {
  if value {
    0
  } else {
    1
  }
}

///|
fn render3d_point_light_shadow_texel_size(world : @ecs.World) -> Float {
  let shadow_map_size = match
    (try! world.get_resource(@light.ecs_key_point_light_shadow_map)) {
    Some(v) => if v.size <= 0 { 1 } else { v.size }
    None => @light.PointLightShadowMap::default().size
  }
  2.0F / Float::from_double(shadow_map_size.to_double())
}

///|
fn render3d_directional_light_shadow_map_size(world : @ecs.World) -> Int {
  match (try! world.get_resource(@light.ecs_key_directional_light_shadow_map)) {
    Some(v) => if v.size <= 0 { 1 } else { v.size }
    None => @light.DirectionalLightShadowMap::default().size
  }
}

///|
fn render3d_light_is_view_visible(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  match (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
    Some(v) => v.is_visible()
    None => true
  }
}

///|
fn render3d_directional_light_decal_index(
  world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  match (try! world.get_resource(@pbr_decal.ecs_key_render_clustered_decals)) {
    Some(decals) => match decals.get_decal_index(entity) {
      Some(index) => index
      None => -1
    }
    None => -1
  }
}

///|
pub struct ExtractedPointLight3d {
  entity : @core.Entity
  color : @sprite.Color
  intensity : Float
  range : Float
  radius : Float
  transform : @transform.Transform
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  shadow_map_near_z : Float
  spot_light_angles : (Float, Float)?
  volumetric : Bool
  soft_shadows_enabled : Bool
  affects_lightmapped_mesh_diffuse : Bool
}

///|
pub struct ExtractedClusterablePointLight3d {
  clusterable_type_order : Int
  light : ExtractedPointLight3d
}

///|
pub fn ExtractedClusterablePointLight3d::is_point_light(
  self : ExtractedClusterablePointLight3d,
) -> Bool {
  self.clusterable_type_order == 0
}

///|
pub fn ExtractedClusterablePointLight3d::is_spot_light(
  self : ExtractedClusterablePointLight3d,
) -> Bool {
  self.clusterable_type_order == 1
}

///|
pub fn ExtractedClusterablePointLight3d::light(
  self : ExtractedClusterablePointLight3d,
) -> ExtractedPointLight3d {
  self.light
}

///|
pub struct ExtractedDirectionalLight3d {
  entity : @core.Entity
  color : @sprite.Color
  illuminance : Float
  transform : @transform.Transform
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  volumetric : Bool
  affects_lightmapped_mesh_diffuse : Bool
  soft_shadow_size : Float?
  cascade_count : Int
  cascade_overlap_proportion : Float
  sun_disk_angular_size : Float
  sun_disk_intensity : Float
}

///|
pub struct GpuDirectionalCascade3d {
  far_bound : Float
  texel_size : Float
  clip_from_world : ProjectionMatrix3d
}

///|
pub struct GpuDirectionalLight3d {
  cascades : Array[GpuDirectionalCascade3d]
  color : @sprite.Color
  dir_to_light : @math.Vec3
  flags : UInt
  soft_shadow_size : Float
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  num_cascades : Int
  cascades_overlap_proportion : Float
  depth_texture_base_index : Int
  decal_index : Int
  sun_disk_angular_size : Float
  sun_disk_intensity : Float
}

///|
pub struct GpuLights3d {
  directional_lights : Array[GpuDirectionalLight3d]
  ambient_color : @sprite.Color
  cluster_dimensions : (Int, Int, Int, Int)
  cluster_factors : @math.Vec4
  n_directional_lights : Int
  spot_light_shadowmap_offset : Int
  ambient_light_affects_lightmapped_meshes : Int
}

///|
pub fn render3d_point_light_flags(extracted : ExtractedPointLight3d) -> UInt {
  let mut flags = POINT_LIGHT_FLAG_NONE
  if extracted.shadow_maps_enabled {
    flags = flags | POINT_LIGHT_FLAG_SHADOW_MAPS_ENABLED
  }
  if extracted.spot_light_angles is Some(_) {
    let light_direction = render3d_transform_forward(extracted.transform)
    if light_direction.y < 0.0F {
      flags = flags | POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE
    }
  }
  if extracted.volumetric && extracted.shadow_maps_enabled {
    flags = flags | POINT_LIGHT_FLAG_VOLUMETRIC
  }
  if extracted.affects_lightmapped_mesh_diffuse {
    flags = flags | POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE
  }
  if extracted.contact_shadows_enabled {
    flags = flags | POINT_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED
  }
  flags
}

///|
pub fn render3d_directional_light_flags(
  extracted : ExtractedDirectionalLight3d,
) -> UInt {
  let mut flags = DIRECTIONAL_LIGHT_FLAG_NONE
  if extracted.shadow_maps_enabled {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED
  }
  if extracted.volumetric && extracted.shadow_maps_enabled {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC
  }
  if extracted.affects_lightmapped_mesh_diffuse {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE
  }
  if extracted.contact_shadows_enabled {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED
  }
  flags
}

///|
fn render3d_extract_light_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
    Some(v) => v
    None => @transform.Transform::identity()
  }
}

///|
fn render3d_extract_point_light(
  world : @ecs.World,
  entity : @core.Entity,
  light : @light.PointLight,
  volumetric : Bool,
  point_light_texel_size : Float,
) -> ExtractedPointLight3d {
  let transform = render3d_extract_light_transform(world, entity)
  ExtractedPointLight3d::{
    entity,
    color: light.color,
    // Bevy parity: point-light authoring uses lumens, extracted runtime stores
    // luminous intensity (lumens/steradian).
    intensity: light.intensity / (4.0F * @math.pi()),
    range: if light.range > 0.0F { light.range } else { 1.0F },
    radius: if light.radius > 0.0F { light.radius } else { 0.0F },
    transform,
    shadow_maps_enabled: light.shadow_maps_enabled,
    contact_shadows_enabled: light.contact_shadows_enabled,
    shadow_depth_bias: light.shadow_depth_bias,
    shadow_normal_bias: light.shadow_normal_bias * point_light_texel_size *
      render3d_sqrt2(),
    shadow_map_near_z: if light.shadow_map_near_z > 0.0001F {
      light.shadow_map_near_z
    } else {
      0.0001F
    },
    spot_light_angles: None,
    volumetric,
    soft_shadows_enabled: light.soft_shadows_enabled,
    affects_lightmapped_mesh_diffuse: light.affects_lightmapped_mesh_diffuse,
  }
}

///|
fn render3d_extract_spot_light(
  world : @ecs.World,
  entity : @core.Entity,
  light : @light.SpotLight,
  volumetric : Bool,
  directional_light_shadow_map_size : Int,
) -> ExtractedPointLight3d {
  let transform = render3d_extract_light_transform(world, entity)
  let inner = light.inner_angle
  let outer = if light.outer_angle < inner {
    inner
  } else {
    light.outer_angle
  }
  let safe_shadow_map_size = if directional_light_shadow_map_size <= 0 {
    1
  } else {
    directional_light_shadow_map_size
  }
  let texel_size = 2.0F * render3d_tan(outer) /
    Float::from_double(safe_shadow_map_size.to_double())
  ExtractedPointLight3d::{
    entity,
    color: light.color,
    // Bevy parity: spot-light authoring uses lumens, extracted runtime stores
    // luminous intensity (lumens/steradian).
    intensity: light.intensity / (4.0F * @math.pi()),
    range: if light.range > 0.0F { light.range } else { 1.0F },
    radius: if light.radius > 0.0F { light.radius } else { 0.0F },
    transform,
    shadow_maps_enabled: light.shadow_maps_enabled,
    contact_shadows_enabled: light.contact_shadows_enabled,
    shadow_depth_bias: light.shadow_depth_bias,
    shadow_normal_bias: light.shadow_normal_bias * texel_size * render3d_sqrt2(),
    shadow_map_near_z: if light.shadow_map_near_z > 0.0001F {
      light.shadow_map_near_z
    } else {
      0.0001F
    },
    spot_light_angles: Some((inner, outer)),
    volumetric,
    soft_shadows_enabled: light.soft_shadows_enabled,
    affects_lightmapped_mesh_diffuse: light.affects_lightmapped_mesh_diffuse,
  }
}

///|
fn render3d_extract_directional_light(
  world : @ecs.World,
  entity : @core.Entity,
  light : @light.DirectionalLight,
  volumetric : Bool,
) -> ExtractedDirectionalLight3d {
  let transform = render3d_extract_light_transform(world, entity)
  let sun_disk = match (try! world.get_by_key(entity, @light.ecs_key_sun_disk)) {
    Some(v) => v
    None => @light.SunDisk::default()
  }
  let cascade_config = match light.cascade_shadow_config {
    Some(config) => config
    None => @light.CascadeShadowConfig::default()
  }
  let cascade_count = cascade_config.bounds.length()
  let cascade_overlap_proportion = cascade_config.overlap_proportion
  ExtractedDirectionalLight3d::{
    entity,
    color: light.color,
    illuminance: light.illuminance,
    transform,
    shadow_maps_enabled: light.shadow_maps_enabled,
    contact_shadows_enabled: light.contact_shadows_enabled,
    shadow_depth_bias: light.shadow_depth_bias,
    shadow_normal_bias: light.shadow_normal_bias * render3d_sqrt2(),
    volumetric,
    affects_lightmapped_mesh_diffuse: light.affects_lightmapped_mesh_diffuse,
    soft_shadow_size: light.soft_shadow_size,
    cascade_count: if cascade_count > MAX_CASCADES_PER_LIGHT {
      MAX_CASCADES_PER_LIGHT
    } else if cascade_count < 0 {
      0
    } else {
      cascade_count
    },
    cascade_overlap_proportion,
    sun_disk_angular_size: sun_disk.angular_size,
    sun_disk_intensity: sun_disk.intensity,
  }
}

///|
pub fn render3d_collect_extracted_point_lights(
  world : @ecs.World,
) -> Array[ExtractedPointLight3d] {
  let point_light_texel_size = render3d_point_light_shadow_texel_size(world)
  let extracted : Array[ExtractedPointLight3d] = []
  world.for_each_component(@light.ecs_key_point_light, fn(entity, light) {
    if !render3d_light_is_view_visible(world, entity) {
      return
    }
    let volumetric = (try!
      world.get_by_key(entity, @light.ecs_key_volumetric_light))
      is Some(_)
    extracted.push(
      render3d_extract_point_light(
        world,
        entity,
        light,
        volumetric,
        point_light_texel_size,
      ),
    )
  })
  extracted.sort_by(fn(left, right) {
    let shadow_cmp = cmp_int(
      render3d_bool_inverted_sort_key(left.shadow_maps_enabled),
      render3d_bool_inverted_sort_key(right.shadow_maps_enabled),
    )
    if shadow_cmp != 0 {
      return shadow_cmp
    }
    let volumetric_cmp = cmp_int(
      render3d_bool_inverted_sort_key(left.volumetric),
      render3d_bool_inverted_sort_key(right.volumetric),
    )
    if volumetric_cmp != 0 {
      return volumetric_cmp
    }
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  extracted
}

///|
pub fn render3d_collect_extracted_spot_lights(
  world : @ecs.World,
) -> Array[ExtractedPointLight3d] {
  let directional_light_shadow_map_size = render3d_directional_light_shadow_map_size(
    world,
  )
  let extracted : Array[ExtractedPointLight3d] = []
  world.for_each_component(@light.ecs_key_spot_light, fn(entity, light) {
    if !render3d_light_is_view_visible(world, entity) {
      return
    }
    let volumetric = (try!
      world.get_by_key(entity, @light.ecs_key_volumetric_light))
      is Some(_)
    extracted.push(
      render3d_extract_spot_light(
        world,
        entity,
        light,
        volumetric,
        directional_light_shadow_map_size,
      ),
    )
  })
  extracted.sort_by(fn(left, right) {
    let shadow_cmp = cmp_int(
      render3d_bool_inverted_sort_key(left.shadow_maps_enabled),
      render3d_bool_inverted_sort_key(right.shadow_maps_enabled),
    )
    if shadow_cmp != 0 {
      return shadow_cmp
    }
    let volumetric_cmp = cmp_int(
      render3d_bool_inverted_sort_key(left.volumetric),
      render3d_bool_inverted_sort_key(right.volumetric),
    )
    if volumetric_cmp != 0 {
      return volumetric_cmp
    }
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  extracted
}

///|
fn render3d_clusterable_light_sort_by_key(
  left_order : Int,
  left : ExtractedPointLight3d,
  right_order : Int,
  right : ExtractedPointLight3d,
) -> Int {
  let type_cmp = cmp_int(left_order, right_order)
  if type_cmp != 0 {
    return type_cmp
  }
  let shadow_cmp = cmp_int(
    render3d_bool_inverted_sort_key(left.shadow_maps_enabled),
    render3d_bool_inverted_sort_key(right.shadow_maps_enabled),
  )
  if shadow_cmp != 0 {
    return shadow_cmp
  }
  let volumetric_cmp = cmp_int(
    render3d_bool_inverted_sort_key(left.volumetric),
    render3d_bool_inverted_sort_key(right.volumetric),
  )
  if volumetric_cmp != 0 {
    return volumetric_cmp
  }
  let id_cmp = cmp_int(left.entity.id, right.entity.id)
  if id_cmp != 0 {
    return id_cmp
  }
  cmp_int(left.entity.generation, right.entity.generation)
}

///|
pub fn render3d_collect_extracted_clusterable_point_lights(
  world : @ecs.World,
) -> Array[ExtractedClusterablePointLight3d] {
  let combined : Array[(Int, ExtractedPointLight3d)] = []
  for point in render3d_collect_extracted_point_lights(world) {
    combined.push((0, point))
  }
  for spot in render3d_collect_extracted_spot_lights(world) {
    combined.push((1, spot))
  }
  combined.sort_by(fn(left, right) {
    render3d_clusterable_light_sort_by_key(
      left.0,
      left.1,
      right.0,
      right.1,
    )
  })
  combined.map(fn(item) {
    ExtractedClusterablePointLight3d::{
      clusterable_type_order: item.0,
      light: item.1,
    }
  })
}

///|
pub fn render3d_collect_extracted_directional_lights(
  world : @ecs.World,
) -> Array[ExtractedDirectionalLight3d] {
  let extracted : Array[ExtractedDirectionalLight3d] = []
  world.for_each_component(@light.ecs_key_directional_light, fn(entity, light) {
    if !render3d_light_is_view_visible(world, entity) {
      return
    }
    let volumetric = (try!
      world.get_by_key(entity, @light.ecs_key_volumetric_light))
      is Some(_)
    extracted.push(
      render3d_extract_directional_light(world, entity, light, volumetric),
    )
  })
  extracted.sort_by(fn(left, right) {
    let volumetric_cmp = cmp_int(
      render3d_bool_sort_key(left.volumetric),
      render3d_bool_sort_key(right.volumetric),
    )
    if volumetric_cmp != 0 {
      return volumetric_cmp
    }
    let shadow_cmp = cmp_int(
      render3d_bool_sort_key(left.shadow_maps_enabled),
      render3d_bool_sort_key(right.shadow_maps_enabled),
    )
    if shadow_cmp != 0 {
      return shadow_cmp
    }
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  extracted
}

///|
fn render3d_gpu_directional_cascade_default() -> GpuDirectionalCascade3d {
  GpuDirectionalCascade3d::{
    far_bound: 0.0F,
    texel_size: 1.0F,
    clip_from_world: ProjectionMatrix3d::from_cols(
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
  }
}

///|
fn render3d_gpu_directional_light_default() -> GpuDirectionalLight3d {
  let cascades : Array[GpuDirectionalCascade3d] = []
  while cascades.length() < MAX_CASCADES_PER_LIGHT {
    cascades.push(render3d_gpu_directional_cascade_default())
  }
  GpuDirectionalLight3d::{
    cascades,
    color: @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    dir_to_light: @math.Vec3::new(0.0F, 0.0F, 1.0F),
    flags: DIRECTIONAL_LIGHT_FLAG_UNINITIALIZED,
    soft_shadow_size: 0.0F,
    shadow_depth_bias: 0.0F,
    shadow_normal_bias: 0.0F,
    num_cascades: 0,
    cascades_overlap_proportion: 0.0F,
    depth_texture_base_index: 0,
    decal_index: -1,
    sun_disk_angular_size: 0.0F,
    sun_disk_intensity: 0.0F,
  }
}

///|
pub fn render3d_collect_gpu_lights(world : @ecs.World) -> GpuLights3d {
  let directional = render3d_collect_extracted_directional_lights(world)
  let clusterable_point_lights = render3d_collect_extracted_clusterable_point_lights(
    world,
  )
  let mut point_light_count = 0
  for item in clusterable_point_lights {
    if item.is_point_light() {
      point_light_count += 1
    }
  }
  let ambient = if (try! world.get_resource(@light.ecs_key_global_ambient_light))
    is Some(v) {
    v
  } else {
    @light.GlobalAmbientLight::default()
  }
  let cluster_dimensions_x = 16
  let cluster_dimensions_y = 9
  let cluster_dimensions_z = 24
  let n_clusters = cluster_dimensions_x * cluster_dimensions_y * cluster_dimensions_z
  let cluster_factors_zw = @light_cluster.calculate_cluster_factors(
    0.1F,
    1000.0F,
    Float::from_double(cluster_dimensions_z.to_double()),
    false,
  )
  let gpu_directional_lights : Array[GpuDirectionalLight3d] = []
  let mut directional_shadow_texture_base_index = 0
  let max_count = if directional.length() < MAX_DIRECTIONAL_LIGHTS {
    directional.length()
  } else {
    MAX_DIRECTIONAL_LIGHTS
  }
  for i in 0..<max_count {
    let item = directional[i]
    let cascades : Array[GpuDirectionalCascade3d] = []
    let cascade_count = if item.shadow_maps_enabled {
      if item.cascade_count <= 0 {
        0
      } else {
        item.cascade_count
      }
    } else {
      0
    }
    for _ in 0..<cascade_count {
      cascades.push(render3d_gpu_directional_cascade_default())
    }
    let num_cascades = cascades.length()
    while cascades.length() < MAX_CASCADES_PER_LIGHT {
      cascades.push(render3d_gpu_directional_cascade_default())
    }
    gpu_directional_lights.push(GpuDirectionalLight3d::{
      cascades,
      color: render3d_scale_color(item.color, item.illuminance),
      dir_to_light: render3d_transform_back(item.transform),
      flags: render3d_directional_light_flags(item),
      soft_shadow_size: item.soft_shadow_size.unwrap_or(0.0F),
      shadow_depth_bias: item.shadow_depth_bias,
      shadow_normal_bias: item.shadow_normal_bias,
      num_cascades,
      cascades_overlap_proportion: item.cascade_overlap_proportion,
      depth_texture_base_index: directional_shadow_texture_base_index,
      decal_index: render3d_directional_light_decal_index(world, item.entity),
      sun_disk_angular_size: item.sun_disk_angular_size,
      sun_disk_intensity: item.sun_disk_intensity,
    })
    directional_shadow_texture_base_index += num_cascades
  }
  while gpu_directional_lights.length() < MAX_DIRECTIONAL_LIGHTS {
    gpu_directional_lights.push(render3d_gpu_directional_light_default())
  }
  GpuLights3d::{
    directional_lights: gpu_directional_lights,
    ambient_color: render3d_scale_color(ambient.color, ambient.brightness),
    cluster_dimensions: (
      cluster_dimensions_x,
      cluster_dimensions_y,
      cluster_dimensions_z,
      n_clusters,
    ),
    cluster_factors: @math.Vec4::new(
      0.0F,
      0.0F,
      cluster_factors_zw.x,
      cluster_factors_zw.y,
    ),
    n_directional_lights: max_count,
    spot_light_shadowmap_offset: directional_shadow_texture_base_index -
      point_light_count,
    ambient_light_affects_lightmapped_meshes: if ambient
      .affects_lightmapped_meshes {
      1
    } else {
      0
    },
  }
}

///|
pub fn render3d_default_lighting_state() -> Render3dLightingState {
  Render3dLightingState::{
    ambient_color: @sprite.Color::white(),
    ambient_brightness: 80.0F,
    directional_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    directional_color: @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    directional_illuminance: 0.0F,
    point_entity: None,
    point_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    point_color: @sprite.Color::white(),
    point_intensity: 0.0F,
    point_range: 1.0F,
    point_shadow_maps_enabled: false,
    point_shadow_depth_bias: 0.08F,
    point_shadow_map_near_z: 0.1F,
    spot_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    spot_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    spot_color: @sprite.Color::white(),
    spot_intensity: 0.0F,
    spot_range: 1.0F,
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
  }
}

///|
pub fn render3d_collect_lighting(world : @ecs.World) -> Render3dLightingState {
  let mut lighting = render3d_default_lighting_state()
  if (try! world.get_resource(@light.ecs_key_global_ambient_light))
    is Some(ambient) {
    lighting = Render3dLightingState::{
      ..lighting,
      ambient_color: ambient.color,
      ambient_brightness: ambient.brightness,
    }
  }
  let directional_lights = render3d_collect_extracted_directional_lights(world)
  if directional_lights.length() > 0 {
    let directional = directional_lights[0]
    lighting = Render3dLightingState::{
      ..lighting,
      directional_dir: render3d_transform_back(directional.transform),
      directional_color: directional.color,
      directional_illuminance: directional.illuminance,
    }
  }
  let point_lights = render3d_collect_extracted_point_lights(world)
  if point_lights.length() > 0 {
    let point = point_lights[0]
    lighting = Render3dLightingState::{
      ..lighting,
      point_entity: Some(point.entity),
      point_pos: point.transform.translation,
      point_color: point.color,
      point_intensity: point.intensity,
      point_range: point.range,
      point_shadow_maps_enabled: point.shadow_maps_enabled,
      point_shadow_depth_bias: point.shadow_depth_bias,
      point_shadow_map_near_z: point.shadow_map_near_z,
    }
    let point_flags = render3d_point_light_flags(point)
    point_flags |> ignore
  }
  let spot_lights = render3d_collect_extracted_spot_lights(world)
  if spot_lights.length() > 0 {
    let spot = spot_lights[0]
    let spot_flags = render3d_point_light_flags(spot)
    spot_flags |> ignore
    match spot.spot_light_angles {
      Some((inner, outer)) =>
        lighting = Render3dLightingState::{
          ..lighting,
          spot_pos: spot.transform.translation,
          spot_dir: render3d_transform_forward(spot.transform),
          spot_color: spot.color,
          spot_intensity: spot.intensity,
          spot_range: spot.range,
          spot_inner_angle: inner,
          spot_outer_angle: outer,
        }
      None =>
        lighting = Render3dLightingState::{
          ..lighting,
          spot_pos: spot.transform.translation,
          spot_dir: render3d_transform_forward(spot.transform),
          spot_color: spot.color,
          spot_intensity: spot.intensity,
          spot_range: spot.range,
        }
    }
  }
  let gpu_lights = render3d_collect_gpu_lights(world)
  gpu_lights.n_directional_lights |> ignore
  lighting
}

///|
pub fn render3d_point_shadow_face_transform(
  light_position : @math.Vec3,
  face_index : Int,
) -> @transform.Transform {
  let (forward, up) = match face_index {
    // Match Bevy's `CUBE_MAP_FACES` exactly:
    // [+X, -X, +Y, -Y, +Z, -Z] face order with left-handed cubemap conventions.
    0 => (@math.Vec3::new(1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    1 => (@math.Vec3::new(-1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    2 => (@math.Vec3::new(0.0F, 1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, 1.0F))
    3 =>
      (@math.Vec3::new(0.0F, -1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, -1.0F))
    4 => (@math.Vec3::new(0.0F, 0.0F, -1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    _ => (@math.Vec3::new(0.0F, 0.0F, 1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  @transform.Transform::from_xyz(
    light_position.x,
    light_position.y,
    light_position.z,
  ).looking_at(light_position.add(forward), up)
}
