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

// Custom mgstudio forward 3D runtime shader.

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) uv : vec2<f32>,
  @location(1) color : vec4<f32>,
  @location(2) world_pos : vec3<f32>,
  @location(3) world_normal : vec3<f32>,
  @location(4) @interpolate(flat) draw_index : u32,
};

struct Mesh3dViewUniform {
  clip_from_world : mat4x4<f32>,
  unjittered_clip_from_world : mat4x4<f32>,
  world_from_clip : mat4x4<f32>,
  world_from_view : mat4x4<f32>,
  view_from_world : mat4x4<f32>,
  clip_from_view : mat4x4<f32>,
  view_from_clip : mat4x4<f32>,
  world_position : vec3<f32>,
  exposure : f32,
};

struct DirectionalCascade {
  clip_from_world : mat4x4<f32>,
  texel_size : f32,
  far_bound : f32,
};

struct DirectionalLight {
  cascades : array<DirectionalCascade, 4>,
  color : vec4<f32>,
  direction_to_light : vec3<f32>,
  flags : u32,
  soft_shadow_size : f32,
  shadow_depth_bias : f32,
  shadow_normal_bias : f32,
  num_cascades : u32,
  cascades_overlap_proportion : f32,
  depth_texture_base_index : u32,
  decal_index : u32,
  sun_disk_angular_size : f32,
  sun_disk_intensity : f32,
};

struct Lights {
  directional_lights : array<DirectionalLight, 10>,
  ambient_color : vec4<f32>,
  cluster_dimensions : vec4<u32>,
  cluster_factors : vec4<f32>,
  n_directional_lights : u32,
  spot_light_shadowmap_offset : i32,
  ambient_light_affects_lightmapped_meshes : u32,
};

struct Mesh3dLegacyLightsUniform {
  point_light_position_radius : vec4<f32>, // (pos.xyz, radius)
  point_light_color_inverse_square_range : vec4<f32>, // (premultiplied rgb, inverse_square_range)
  point_light_shadow_params : vec4<f32>, // (enabled, depth_bias, near_z, _)
  spot_light_position_radius : vec4<f32>, // (pos.xyz, radius)
  spot_light_direction_to_light : vec4<f32>, // (dir.xyz, _)
  spot_light_color_inverse_square_range : vec4<f32>, // (premultiplied rgb, inverse_square_range)
  spot_light_custom_data : vec4<f32>, // (spot_scale, spot_offset, transmission_blur_taps, transmission_steps)
};

struct Mesh3dDirectionalCascadeUniform {
  clip_from_world : mat4x4<f32>,
  data : vec4<f32>, // (texel_size, far_bound, _, _)
};

struct Mesh3dDirectionalShadowUniform {
  params : vec4<f32>, // (enabled, depth_bias, normal_bias, soft_size)
  counts : vec4<f32>, // (cascade_count, overlap, _, _)
  view_forward : vec4<f32>,
  cascades : array<Mesh3dDirectionalCascadeUniform, 4>,
};

struct Mesh3dLightBindings {
  lights : Lights,
  legacy : Mesh3dLegacyLightsUniform,
  environment : vec4<f32>, // (intensity, _, _, _)
  environment_rotation : vec4<f32>,
  directional_shadow : Mesh3dDirectionalShadowUniform,
};

struct StandardMaterial {
  base_color : vec4<f32>,
  emissive : vec4<f32>,
  attenuation_color : vec4<f32>,
  uv_transform : mat3x3<f32>,
  reflectance : vec3<f32>,
  perceptual_roughness : f32,
  metallic : f32,
  diffuse_transmission : f32,
  specular_transmission : f32,
  thickness : f32,
  ior : f32,
  attenuation_distance : f32,
  clearcoat : f32,
  clearcoat_perceptual_roughness : f32,
  anisotropy_strength : f32,
  anisotropy_rotation : vec2<f32>,
  flags : u32,
  alpha_cutoff : f32,
  parallax_depth_scale : f32,
  max_parallax_layer_count : f32,
  lightmap_exposure : f32,
  max_relief_mapping_search_steps : u32,
  deferred_lighting_pass_id : u32,
};

struct Mesh {
  world_from_local : mat3x4<f32>,
  previous_world_from_local : mat3x4<f32>,
  local_from_world_transpose_a : mat2x4<f32>,
  local_from_world_transpose_b : f32,
  flags : u32,
  lightmap_uv_rect : vec2<u32>,
  first_vertex_index : u32,
  current_skin_index : u32,
  material_and_lightmap_bind_group_slot : u32,
  tag : u32,
  pad : u32,
};

struct Mesh3dDrawUniformBuffer {
  data : array<Mesh>,
};

struct Mesh3dSkinningMatricesBuffer {
  matrices : array<mat4x4<f32>>,
};

const STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT: u32         = 1u << 0u;
const STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT: u32           = 1u << 1u;
const STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT: u32 = 1u << 2u;
const STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT: u32          = 1u << 3u;
const STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT: u32               = 1u << 4u;
const STANDARD_MATERIAL_FLAGS_UNLIT_BIT: u32                      = 1u << 5u;
const STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP: u32       = 1u << 6u;
const STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y: u32              = 1u << 7u;
const STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT: u32                  = 1u << 9u;
const STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT: u32         = 1u << 17u;
const STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT: u32      = 1u << 19u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_RESERVED_BITS: u32       = 7u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE: u32              = 0u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK: u32                = 1u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND: u32               = 2u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED: u32       = 3u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD: u32                 = 4u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY: u32            = 5u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE: u32   = 6u << 29u;
const MESH_FLAGS_SHADOW_RECEIVER_BIT: u32                         = 1u << 29u;

fn affine3_to_square(affine : mat3x4<f32>) -> mat4x4<f32> {
  return transpose(mat4x4<f32>(
    affine[0],
    affine[1],
    affine[2],
    vec4<f32>(0.0, 0.0, 0.0, 1.0),
  ));
}

fn mat2x4_f32_to_mat3x3_unpack(
  a : mat2x4<f32>,
  b : f32,
) -> mat3x3<f32> {
  return mat3x3<f32>(
    a[0].xyz,
    vec3<f32>(a[0].w, a[1].xy),
    vec3<f32>(a[1].zw, b),
  );
}

@group(0) @binding(0) var<uniform> u_view : Mesh3dViewUniform;
@group(0) @binding(1) var<uniform> u_lights : Mesh3dLightBindings;
@group(0) @binding(25) var u_transmission_source_texture : texture_2d<f32>;
@group(0) @binding(26) var u_transmission_source_sampler : sampler;
@group(0) @binding(2) var u_point_shadow_texture : texture_depth_cube;
@group(0) @binding(3) var u_point_shadow_sampler : sampler_comparison;
@group(1) @binding(0) var u_environment_diffuse_texture : texture_cube<f32>;
@group(1) @binding(1) var u_environment_specular_texture : texture_cube<f32>;
@group(1) @binding(2) var u_environment_sampler : sampler;
@group(0) @binding(5) var u_directional_shadow_texture : texture_depth_2d_array;
@group(0) @binding(6) var u_directional_shadow_sampler : sampler_comparison;
@group(3) @binding(0) var<uniform> u_material : StandardMaterial;
@group(3) @binding(1) var u_base_color_texture : texture_2d<f32>;
@group(3) @binding(2) var u_base_color_sampler : sampler;
@group(3) @binding(3) var u_emissive_texture : texture_2d<f32>;
@group(3) @binding(4) var u_emissive_sampler : sampler;
@group(3) @binding(5) var u_metallic_roughness_texture : texture_2d<f32>;
@group(3) @binding(6) var u_metallic_roughness_sampler : sampler;
@group(3) @binding(7) var u_occlusion_texture : texture_2d<f32>;
@group(3) @binding(8) var u_occlusion_sampler : sampler;
@group(3) @binding(9) var u_normal_map_texture : texture_2d<f32>;
@group(3) @binding(10) var u_normal_map_sampler : sampler;
@group(3) @binding(11) var u_depth_map_texture : texture_2d<f32>;
@group(3) @binding(12) var u_depth_map_sampler : sampler;
@group(3) @binding(13) var u_anisotropy_texture : texture_2d<f32>;
@group(3) @binding(14) var u_anisotropy_sampler : sampler;
@group(3) @binding(29) var u_specular_tint_texture : texture_2d<f32>;
@group(3) @binding(30) var u_specular_tint_sampler : sampler;
@group(2) @binding(0) var<storage, read> u_draws : Mesh3dDrawUniformBuffer;
@group(2) @binding(1) var<storage, read> u_skinning_matrices : Mesh3dSkinningMatricesBuffer;

fn quat_normalize(q : vec4<f32>) -> vec4<f32> {
  let n = max(dot(q, q), 1e-8);
  return q / sqrt(n);
}

fn quat_rotate_vec3(q : vec4<f32>, v : vec3<f32>) -> vec3<f32> {
  let t = 2.0 * cross(q.xyz, v);
  return v + q.w * t + cross(q.xyz, t);
}

fn transform_normal_local_to_world(
  q : vec4<f32>,
  local_normal : vec3<f32>,
  scale : vec3<f32>,
) -> vec3<f32> {
  let safe_scale = vec3<f32>(
    select(scale.x, 1.0, abs(scale.x) <= 1.0e-8),
    select(scale.y, 1.0, abs(scale.y) <= 1.0e-8),
    select(scale.z, 1.0, abs(scale.z) <= 1.0e-8),
  );
  return safe_normalize(quat_rotate_vec3(q, local_normal / safe_scale));
}

fn skinning_row_count() -> u32 {
  return arrayLength(&u_skinning_matrices.matrices);
}

fn skinning_transform_point(
  skin_index : u32,
  joint_index : u32,
  local_point : vec3<f32>,
) -> vec3<f32> {
  if skin_index == 0xffffffffu {
    return local_point;
  }
  let matrix_index = skin_index + joint_index;
  if matrix_index >= skinning_row_count() {
    return local_point;
  }
  return (u_skinning_matrices.matrices[matrix_index] *
    vec4<f32>(local_point, 1.0)).xyz;
}

fn skinning_transform_normal(
  skin_index : u32,
  joint_index : u32,
  local_normal : vec3<f32>,
) -> vec3<f32> {
  if skin_index == 0xffffffffu {
    return local_normal;
  }
  let matrix_index = skin_index + joint_index;
  if matrix_index >= skinning_row_count() {
    return local_normal;
  }
  return (u_skinning_matrices.matrices[matrix_index] *
    vec4<f32>(local_normal, 0.0)).xyz;
}

@vertex
fn vs_main(
  @location(0) position : vec3<f32>,
  @location(1) normal : vec3<f32>,
  @location(2) uv : vec2<f32>,
  @location(5) color : vec4<f32>,
  @location(6) joint_indices : vec4<u32>,
  @location(7) joint_weights : vec4<f32>,
  @builtin(instance_index) instance_index : u32,
) -> VertexOut {
  var out : VertexOut;
  let mesh = u_draws.data[instance_index];
  let weight_sum = joint_weights.x + joint_weights.y + joint_weights.z + joint_weights.w;
  var world_pos = vec3<f32>(0.0, 0.0, 0.0);
  var world_normal = vec3<f32>(0.0, 0.0, 1.0);
  if weight_sum > 1.0e-6 {
    let skin_index = mesh.current_skin_index;
    let i0 = joint_indices.x;
    let i1 = joint_indices.y;
    let i2 = joint_indices.z;
    let i3 = joint_indices.w;
    world_pos =
      skinning_transform_point(skin_index, i0, position) * joint_weights.x +
      skinning_transform_point(skin_index, i1, position) * joint_weights.y +
      skinning_transform_point(skin_index, i2, position) * joint_weights.z +
      skinning_transform_point(skin_index, i3, position) * joint_weights.w;
    world_normal = normalize(
      skinning_transform_normal(skin_index, i0, normal) * joint_weights.x +
      skinning_transform_normal(skin_index, i1, normal) * joint_weights.y +
      skinning_transform_normal(skin_index, i2, normal) * joint_weights.z +
      skinning_transform_normal(skin_index, i3, normal) * joint_weights.w
    );
  } else {
    let world_from_local = affine3_to_square(mesh.world_from_local);
    world_pos = (world_from_local * vec4<f32>(position, 1.0)).xyz;
    world_normal = safe_normalize(
      mat2x4_f32_to_mat3x3_unpack(
        mesh.local_from_world_transpose_a,
        mesh.local_from_world_transpose_b,
      ) * normal,
    );
  }
  out.position = u_view.clip_from_world * vec4<f32>(world_pos, 1.0);
  let transformed_uv = u_material.uv_transform * vec3<f32>(uv, 1.0);
  out.uv = transformed_uv.xy;
  out.color = color * u_material.base_color;
  out.world_pos = world_pos;
  out.world_normal = world_normal;
  out.draw_index = instance_index;
  return out;
}

fn safe_normalize(v : vec3<f32>) -> vec3<f32> {
  let n2 = max(dot(v, v), 1e-8);
  return v * inverseSqrt(n2);
}

fn material_flag_enabled(flags : u32, bit : u32) -> bool {
  return (flags & bit) != 0u;
}

fn apply_normal_mapping(
  standard_material_flags : u32,
  geometric_normal : vec3<f32>,
  position : vec3<f32>,
  uv : vec2<f32>,
  double_sided : bool,
  is_front : bool,
  in_normal_map_sample : vec3<f32>,
) -> vec3<f32> {
  var tangent_space_normal = in_normal_map_sample;
  if material_flag_enabled(
    standard_material_flags,
    STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP,
  ) {
    tangent_space_normal = vec3<f32>(
      tangent_space_normal.xy * 2.0 - vec2<f32>(1.0, 1.0),
      0.0,
    );
    tangent_space_normal.z = sqrt(max(
      1.0 - tangent_space_normal.x * tangent_space_normal.x -
      tangent_space_normal.y * tangent_space_normal.y,
      0.0,
    ));
  } else {
    tangent_space_normal = tangent_space_normal * 2.0 - vec3<f32>(1.0, 1.0, 1.0);
  }
  if material_flag_enabled(
    standard_material_flags,
    STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y,
  ) {
    tangent_space_normal.y = -tangent_space_normal.y;
  }
  if double_sided && !is_front {
    tangent_space_normal = -tangent_space_normal;
  }
  return safe_normalize(
    cotangent_frame(geometric_normal, position, uv) * tangent_space_normal,
  );
}

const PI : f32 = 3.141592653589793;

fn lambert(normal : vec3<f32>, light_dir : vec3<f32>) -> f32 {
  return max(dot(normal, light_dir), 0.0);
}

fn get_distance_attenuation(
  distance_square : f32,
  inverse_range_squared : f32,
) -> f32 {
  let factor = distance_square * inverse_range_squared;
  let smooth_factor = clamp(1.0 - factor * factor, 0.0, 1.0);
  let attenuation = smooth_factor * smooth_factor;
  return attenuation / max(distance_square, 1.0e-4);
}

fn cotangent_frame(
  normal : vec3<f32>,
  position : vec3<f32>,
  uv : vec2<f32>,
) -> mat3x3<f32> {
  let dp1 = dpdx(position);
  let dp2 = dpdy(position);
  let duv1 = dpdx(uv);
  let duv2 = dpdy(uv);
  let dp2perp = cross(dp2, normal);
  let dp1perp = cross(normal, dp1);
  let tangent = dp2perp * duv1.x + dp1perp * duv2.x;
  let bitangent = dp2perp * duv1.y + dp1perp * duv2.y;
  let scale = inverseSqrt(
    max(max(dot(tangent, tangent), dot(bitangent, bitangent)), 1e-8),
  );
  return mat3x3<f32>(tangent * scale, bitangent * scale, normal);
}

fn sample_depth_map(uv : vec2<f32>) -> f32 {
  return textureSampleLevel(u_depth_map_texture, u_depth_map_sampler, uv, 0.0).r;
}

fn parallaxed_uv(
  depth_scale : f32,
  max_layer_count : f32,
  max_steps : u32,
  original_uv : vec2<f32>,
  view_dir_tangent : vec3<f32>,
) -> vec2<f32> {
  if max_layer_count < 1.0 {
    return original_uv;
  }
  let view_steepness = max(abs(view_dir_tangent.z), 1.0e-4);
  var uv = original_uv;
  let layer_count = mix(max_layer_count, 1.0, view_steepness);
  let layer_depth = 1.0 / layer_count;
  var delta_uv = depth_scale * layer_depth * view_dir_tangent.xy *
    vec2<f32>(1.0, -1.0) / view_steepness;
  var current_layer_depth = 0.0;
  var texture_depth = sample_depth_map(uv);
  for (var i: i32 = 0; texture_depth > current_layer_depth && i <= i32(layer_count); i++) {
    current_layer_depth += layer_depth;
    uv += delta_uv;
    texture_depth = sample_depth_map(uv);
  }
  if max_steps > 0u {
    delta_uv *= 0.5;
    var delta_depth = 0.5 * layer_depth;
    uv -= delta_uv;
    current_layer_depth -= delta_depth;
    for (var i: u32 = 0u; i < max_steps; i++) {
      texture_depth = sample_depth_map(uv);
      delta_uv *= 0.5;
      delta_depth *= 0.5;
      if texture_depth > current_layer_depth {
        uv += delta_uv;
        current_layer_depth += delta_depth;
      } else {
        uv -= delta_uv;
        current_layer_depth -= delta_depth;
      }
    }
    return uv;
  }
  let previous_uv = uv - delta_uv;
  let next_depth = texture_depth - current_layer_depth;
  let previous_depth = sample_depth_map(previous_uv) - current_layer_depth +
    layer_depth;
  let weight = next_depth / (next_depth - previous_depth);
  return mix(uv, previous_uv, weight);
}

fn D_GGX_anisotropic(
  at : f32,
  ab : f32,
  ndoth : f32,
  tdoth : f32,
  bdoth : f32,
) -> f32 {
  let a2 = at * ab;
  let f = vec3<f32>(ab * tdoth, at * bdoth, a2 * ndoth);
  let ff = max(dot(f, f), 1.0e-8);
  let w2 = a2 / ff;
  return a2 * w2 * w2 * (1.0 / 3.141592653589793);
}

fn V_GGX_anisotropic(
  at : f32,
  ab : f32,
  ndotl : f32,
  ndotv : f32,
  bdotv : f32,
  tdotv : f32,
  tdotl : f32,
  bdotl : f32,
) -> f32 {
  let ggx_v = ndotl * length(vec3<f32>(at * tdotv, ab * bdotv, ndotv));
  let ggx_l = ndotv * length(vec3<f32>(at * tdotl, ab * bdotl, ndotl));
  return clamp(0.5 / max(ggx_v + ggx_l, 1.0e-8), 0.0, 1.0);
}

fn fresnel_schlick_vec(f0 : vec3<f32>, ldoth : f32) -> vec3<f32> {
  return f0 + (vec3<f32>(1.0, 1.0, 1.0) - f0) * pow(1.0 - ldoth, 5.0);
}

fn F_Schlick(f0 : f32, f90 : f32, u : f32) -> f32 {
  return f0 + (f90 - f0) * pow(1.0 - u, 5.0);
}

fn Fd_Burley(
  roughness : f32,
  ndotv : f32,
  ndotl : f32,
  ldoth : f32,
) -> f32 {
  let f90 = 0.5 + 2.0 * roughness * ldoth * ldoth;
  let light_scatter = F_Schlick(1.0, f90, ndotl);
  let view_scatter = F_Schlick(1.0, f90, ndotv);
  return light_scatter * view_scatter * (1.0 / PI);
}

fn D_GGX(
  roughness : f32,
  ndoth : f32,
) -> f32 {
  let one_minus_ndoth_squared = 1.0 - ndoth * ndoth;
  let a = ndoth * roughness;
  let k = roughness / (one_minus_ndoth_squared + a * a);
  return k * k * (1.0 / PI);
}

fn V_SmithGGXCorrelated(
  roughness : f32,
  ndotv : f32,
  ndotl : f32,
) -> f32 {
  let a2 = roughness * roughness;
  let lambda_v = ndotl * sqrt((ndotv - a2 * ndotv) * ndotv + a2);
  let lambda_l = ndotv * sqrt((ndotl - a2 * ndotl) * ndotl + a2);
  return 0.5 / max(lambda_v + lambda_l, 1.0e-8);
}

fn specular_isotropic(
  normal : vec3<f32>,
  light_dir : vec3<f32>,
  view_dir : vec3<f32>,
  roughness : f32,
  f0 : vec3<f32>,
) -> vec3<f32> {
  let half_dir = safe_normalize(light_dir + view_dir);
  let ndotv = max(dot(normal, view_dir), 1.0e-4);
  let ndotl = max(dot(normal, light_dir), 0.0);
  let ndoth = max(dot(normal, half_dir), 0.0);
  let ldoth = max(dot(light_dir, half_dir), 0.0);
  let d = D_GGX(roughness, ndoth);
  let v = V_SmithGGXCorrelated(roughness, ndotv, ndotl);
  let f = fresnel_schlick_vec(f0, ldoth);
  return d * v * f;
}

fn specular_anisotropic(
  normal : vec3<f32>,
  light_dir : vec3<f32>,
  view_dir : vec3<f32>,
  roughness : f32,
  f0 : vec3<f32>,
  anisotropy : f32,
  anisotropy_t : vec3<f32>,
  anisotropy_b : vec3<f32>,
) -> vec3<f32> {
  let half_dir = safe_normalize(light_dir + view_dir);
  let ndotl = max(dot(normal, light_dir), 0.0);
  let ndotv = max(dot(normal, view_dir), 1.0e-4);
  let ndoth = max(dot(normal, half_dir), 0.0);
  let ldoth = max(dot(light_dir, half_dir), 0.0);
  let tdotl = dot(anisotropy_t, light_dir);
  let bdotl = dot(anisotropy_b, light_dir);
  let tdoth = dot(anisotropy_t, half_dir);
  let bdoth = dot(anisotropy_b, half_dir);
  let tdotv = dot(anisotropy_t, view_dir);
  let bdotv = dot(anisotropy_b, view_dir);
  let ab = roughness * roughness;
  let at = mix(ab, 1.0, anisotropy * anisotropy);
  let d = D_GGX_anisotropic(at, ab, ndoth, tdoth, bdoth);
  let v = V_GGX_anisotropic(at, ab, ndotl, ndotv, bdotv, tdotv, tdotl, bdotl);
  let f = fresnel_schlick_vec(f0, ldoth);
  return d * v * f;
}

struct LightContribution {
  diffuse : vec3<f32>,
  transmitted : vec3<f32>,
  specular : vec3<f32>,
};

fn specular_light(
  normal : vec3<f32>,
  light_dir : vec3<f32>,
  view_dir : vec3<f32>,
  roughness : f32,
  f0 : vec3<f32>,
  anisotropy_strength : f32,
  anisotropy_t : vec3<f32>,
  anisotropy_b : vec3<f32>,
) -> vec3<f32> {
  if anisotropy_strength > 0.0 {
    return specular_anisotropic(
      normal,
      light_dir,
      view_dir,
      roughness,
      f0,
      anisotropy_strength,
      anisotropy_t,
      anisotropy_b,
    );
  }
  return specular_isotropic(normal, light_dir, view_dir, roughness, f0);
}

fn directional_light(
  normal : vec3<f32>,
  view_dir : vec3<f32>,
  ndotv : f32,
  roughness : f32,
  f0 : vec3<f32>,
  anisotropy_strength : f32,
  anisotropy_t : vec3<f32>,
  anisotropy_b : vec3<f32>,
  light_dir : vec3<f32>,
  light_color : vec3<f32>,
) -> LightContribution {
  let diffuse = lambert(normal, light_dir);
  let half_dir = safe_normalize(light_dir + view_dir);
  let ldoth = max(dot(light_dir, half_dir), 0.0);
  let diffuse_brdf = Fd_Burley(roughness, ndotv, diffuse, ldoth);
  let transmitted = lambert(-normal, light_dir);
  let specular = specular_light(
    normal,
    light_dir,
    view_dir,
    roughness,
    f0,
    anisotropy_strength,
    anisotropy_t,
    anisotropy_b,
  );
  return LightContribution(
    light_color * diffuse_brdf * diffuse,
    light_color * transmitted,
    light_color * diffuse * specular,
  );
}

fn directional_shadow_cascade_index(view_z : f32) -> u32 {
  let cascade_count = u32(max(u_lights.directional_shadow.counts.x, 0.0));
  for (var i : u32 = 0u; i < cascade_count; i = i + 1u) {
    if (-view_z < u_lights.directional_shadow.cascades[i].data.y) {
      return i;
    }
  }
  return cascade_count;
}

fn world_to_directional_light_local(
  cascade_index : u32,
  offset_position : vec4<f32>,
) -> vec4<f32> {
  let cascade = u_lights.directional_shadow.cascades[cascade_index];
  let offset_position_clip = cascade.clip_from_world * offset_position;
  if (offset_position_clip.w <= 0.0) {
    return vec4<f32>(0.0);
  }
  let offset_position_ndc = offset_position_clip.xyz / offset_position_clip.w;
  if (any(offset_position_ndc.xy < vec2<f32>(-1.0)) ||
      offset_position_ndc.z < 0.0 ||
      any(offset_position_ndc > vec3<f32>(1.0))) {
    return vec4<f32>(0.0);
  }
  let light_local = offset_position_ndc.xy * vec2<f32>(0.5, -0.5) + vec2<f32>(0.5, 0.5);
  return vec4<f32>(light_local, offset_position_ndc.z, 1.0);
}

fn sample_directional_cascade(
  cascade_index : u32,
  frag_position : vec4<f32>,
  surface_normal : vec3<f32>,
) -> f32 {
  let params = u_lights.directional_shadow.params;
  let cascade = u_lights.directional_shadow.cascades[cascade_index];
  let normal_offset = params.z * cascade.data.x * surface_normal;
  let depth_offset = params.y * safe_normalize(u_lights.lights.directional_lights[0].direction_to_light);
  let offset_position = vec4<f32>(
    frag_position.xyz + normal_offset + depth_offset,
    frag_position.w,
  );
  let light_local = world_to_directional_light_local(cascade_index, offset_position);
  if (light_local.w == 0.0) {
    return 1.0;
  }
  return textureSampleCompareLevel(
    u_directional_shadow_texture,
    u_directional_shadow_sampler,
    light_local.xy,
    i32(cascade_index),
    clamp(light_local.z, 0.0, 1.0),
  );
}

fn directional_shadow(
  world_pos : vec3<f32>,
  surface_normal : vec3<f32>,
  view_z : f32,
) -> f32 {
  if (u_lights.directional_shadow.params.x <= 0.5) {
    return 1.0;
  }
  let cascade_count = u32(max(u_lights.directional_shadow.counts.x, 0.0));
  let cascade_index = directional_shadow_cascade_index(view_z);
  if (cascade_index >= cascade_count) {
    return 1.0;
  }
  var shadow = sample_directional_cascade(
    cascade_index,
    vec4<f32>(world_pos, 1.0),
    surface_normal,
  );
  let next_cascade_index = cascade_index + 1u;
  if (next_cascade_index < cascade_count) {
    let this_far_bound = u_lights.directional_shadow.cascades[cascade_index].data.y;
    let next_near_bound = (1.0 - u_lights.directional_shadow.counts.y) * this_far_bound;
    if (-view_z >= next_near_bound) {
      let next_shadow = sample_directional_cascade(
        next_cascade_index,
        vec4<f32>(world_pos, 1.0),
        surface_normal,
      );
      shadow = mix(shadow, next_shadow, (-view_z - next_near_bound) / (this_far_bound - next_near_bound));
    }
  }
  return shadow;
}

fn point_light_shadow(
  world_pos : vec3<f32>,
  light_position : vec3<f32>,
  light_radius : f32,
  shadow_params : vec4<f32>,
) -> f32 {
  if shadow_params.x <= 0.5 {
    return 1.0;
  }
  // Match Bevy's cubemap shadow sampling convention:
  // sample direction is transformed to cubemap LH space by flipping Z.
  let point_shadow_dir = safe_normalize(vec3<f32>(
    world_pos.x - light_position.x,
    world_pos.y - light_position.y,
    -(world_pos.z - light_position.z),
  ));
  // Cubemap shadow projections are axis-aligned 90-degree frusta.
  // The projected depth can be reconstructed from the largest axis magnitude.
  let to_light = world_pos - light_position;
  let major_axis_magnitude = max(
    abs(to_light.x),
    max(abs(to_light.y), abs(to_light.z)),
  );
  let point_near = max(shadow_params.z, 1.0e-4);
  let point_far = max(light_radius, point_near + 1.0e-4);
  var point_linear_depth = 0.0;
  if major_axis_magnitude > point_near {
    point_linear_depth = point_far / (point_far - point_near) -
      (point_far * point_near) / ((point_far - point_near) * major_axis_magnitude);
  }
  let point_depth_bias = max(shadow_params.y, 0.0);
  return textureSampleCompare(
    u_point_shadow_texture,
    u_point_shadow_sampler,
    point_shadow_dir,
    clamp(point_linear_depth - point_depth_bias, 0.0, 1.0),
  );
}

fn point_light(
  normal : vec3<f32>,
  world_pos : vec3<f32>,
  view_dir : vec3<f32>,
  ndotv : f32,
  roughness : f32,
  f0 : vec3<f32>,
  anisotropy_strength : f32,
  anisotropy_t : vec3<f32>,
  anisotropy_b : vec3<f32>,
  light_position_radius : vec4<f32>,
  light_color_inverse_square_range : vec4<f32>,
  shadow_factor : f32,
) -> LightContribution {
  let light_to_frag = light_position_radius.xyz - world_pos;
  let light_dir = safe_normalize(light_to_frag);
  let distance_square = max(dot(light_to_frag, light_to_frag), 1.0e-4);
  let attenuation = get_distance_attenuation(
    distance_square,
    light_color_inverse_square_range.w,
  ) * shadow_factor;
  let light_color = light_color_inverse_square_range.xyz;
  let diffuse = lambert(normal, light_dir);
  let half_dir = safe_normalize(light_dir + view_dir);
  let ldoth = max(dot(light_dir, half_dir), 0.0);
  let diffuse_brdf = Fd_Burley(roughness, ndotv, diffuse, ldoth);
  let transmitted = lambert(-normal, light_dir);
  let specular = specular_light(
    normal,
    light_dir,
    view_dir,
    roughness,
    f0,
    anisotropy_strength,
    anisotropy_t,
    anisotropy_b,
  );
  return LightContribution(
    light_color * attenuation * diffuse_brdf * diffuse,
    light_color * attenuation * transmitted,
    light_color * attenuation * diffuse * specular,
  );
}

fn spot_light(
  normal : vec3<f32>,
  world_pos : vec3<f32>,
  view_dir : vec3<f32>,
  ndotv : f32,
  roughness : f32,
  f0 : vec3<f32>,
  anisotropy_strength : f32,
  anisotropy_t : vec3<f32>,
  anisotropy_b : vec3<f32>,
  light_position_radius : vec4<f32>,
  light_direction_to_light : vec4<f32>,
  light_color_inverse_square_range : vec4<f32>,
  light_custom_data : vec4<f32>,
) -> LightContribution {
  let point = point_light(
    normal,
    world_pos,
    view_dir,
    ndotv,
    roughness,
    f0,
    anisotropy_strength,
    anisotropy_t,
    anisotropy_b,
    light_position_radius,
    light_color_inverse_square_range,
    1.0,
  );
  let light_to_frag = light_position_radius.xyz - world_pos;
  let spot_dir_to_fragment = safe_normalize(-light_to_frag);
  let spot_light_dir = safe_normalize(light_direction_to_light.xyz);
  let spot_cos_theta = dot(spot_light_dir, spot_dir_to_fragment);
  let spot_attenuation = clamp(
    spot_cos_theta * light_custom_data.x + light_custom_data.y,
    0.0,
    1.0,
  );
  let spot_cone = spot_attenuation * spot_attenuation;
  return LightContribution(
    point.diffuse * spot_cone,
    point.transmitted * spot_cone,
    point.specular * spot_cone,
  );
}

fn cubemap_stacked_vertical_uv(direction : vec3<f32>) -> vec2<f32> {
  let dir = safe_normalize(direction);
  let abs_dir = abs(dir);
  var face = 0.0;
  var face_uv = vec2<f32>(0.0, 0.0);
  if abs_dir.x >= abs_dir.y && abs_dir.x >= abs_dir.z {
    if dir.x > 0.0 {
      // +X (posx)
      face = 0.0;
      face_uv = vec2<f32>(-dir.z, -dir.y) / max(abs_dir.x, 1.0e-8);
    } else {
      // -X (negx)
      face = 1.0;
      face_uv = vec2<f32>(dir.z, -dir.y) / max(abs_dir.x, 1.0e-8);
    }
  } else if abs_dir.y >= abs_dir.x && abs_dir.y >= abs_dir.z {
    if dir.y > 0.0 {
      // +Y (posy)
      face = 2.0;
      face_uv = vec2<f32>(dir.x, dir.z) / max(abs_dir.y, 1.0e-8);
    } else {
      // -Y (negy)
      face = 3.0;
      face_uv = vec2<f32>(dir.x, -dir.z) / max(abs_dir.y, 1.0e-8);
    }
  } else {
    if dir.z > 0.0 {
      // +Z (posz)
      face = 4.0;
      face_uv = vec2<f32>(dir.x, -dir.y) / max(abs_dir.z, 1.0e-8);
    } else {
      // -Z (negz)
      face = 5.0;
      face_uv = vec2<f32>(-dir.x, -dir.y) / max(abs_dir.z, 1.0e-8);
    }
  }
  let u = clamp(face_uv.x * 0.5 + 0.5, 0.0, 1.0);
  let v_local = clamp(face_uv.y * 0.5 + 0.5, 0.0, 1.0);
  let v = (face + v_local) / 6.0;
  return vec2<f32>(u, v);
}

fn sample_environment_diffuse(
  direction : vec3<f32>,
  rotation : vec4<f32>,
) -> vec3<f32> {
  var sample_dir = quat_rotate_vec3(rotation, safe_normalize(direction));
  sample_dir.z = -sample_dir.z;
  return textureSampleLevel(
    u_environment_diffuse_texture,
    u_environment_sampler,
    sample_dir,
    0.0,
  ).rgb;
}

fn sample_environment_specular(
  direction : vec3<f32>,
  rotation : vec4<f32>,
  perceptual_roughness : f32,
) -> vec3<f32> {
  var sample_dir = quat_rotate_vec3(rotation, safe_normalize(direction));
  sample_dir.z = -sample_dir.z;
  let smallest_mip = f32(textureNumLevels(u_environment_specular_texture) - 1u);
  let lod = clamp(perceptual_roughness * smallest_mip, 0.0, smallest_mip);
  return textureSampleLevel(
    u_environment_specular_texture,
    u_environment_sampler,
    sample_dir,
    lod,
  ).rgb;
}

fn sample_transmission_source(
  base_uv : vec2<f32>,
  blur_taps : i32,
  roughness : f32,
  thickness : f32,
) -> vec3<f32> {
  let texture_size = vec2<f32>(textureDimensions(u_transmission_source_texture));
  let safe_height = max(texture_size.y, 1.0);
  let aspect = max(texture_size.x / safe_height, 1.0e-4);
  let blur_intensity = roughness * roughness * (0.002 + thickness * 0.02);
  let clamped_taps = clamp(blur_taps, 1, 32);
  var sum = vec3<f32>(0.0, 0.0, 0.0);
  var weight_sum = 0.0;
  for (var i: i32 = 0; i < 32; i = i + 1) {
    if i >= clamped_taps {
      break;
    }
    let fi = f32(i);
    let taps_f = max(f32(clamped_taps), 1.0);
    let angle = 6.283185307179586 * (fi / taps_f);
    let radius = (fi + 0.5) / taps_f;
    let dir = vec2<f32>(cos(angle), sin(angle));
    let offset = dir * radius * blur_intensity * vec2<f32>(1.0 / aspect, 1.0);
    let sample_uv = clamp(
      base_uv + offset,
      vec2<f32>(0.0, 0.0),
      vec2<f32>(1.0, 1.0),
    );
    let weight = 1.0 - radius * 0.8;
    let sample_color = textureSampleLevel(
      u_transmission_source_texture,
      u_transmission_source_sampler,
      sample_uv,
      0.0,
    ).rgb;
    sum += sample_color * weight;
    weight_sum += weight;
  }
  if weight_sum <= 0.0 {
    return textureSampleLevel(
      u_transmission_source_texture,
      u_transmission_source_sampler,
      clamp(base_uv, vec2<f32>(0.0, 0.0), vec2<f32>(1.0, 1.0)),
      0.0,
    ).rgb;
  }
  return sum / weight_sum;
}

fn direct_diffuse_light(
  directional : LightContribution,
  point : LightContribution,
  spot : LightContribution,
  occlusion_tex : f32,
) -> vec3<f32> {
  return (directional.diffuse +
    point.diffuse +
    spot.diffuse) * occlusion_tex;
}

fn indirect_diffuse_light(
  ambient_term : vec3<f32>,
  occlusion_tex : f32,
) -> vec3<f32> {
  return ambient_term * occlusion_tex;
}

fn direct_specular_light(
  directional : LightContribution,
  point : LightContribution,
  spot : LightContribution,
) -> vec3<f32> {
  return directional.specular + point.specular + spot.specular;
}

fn direct_diffuse_transmissive_light(
  directional : LightContribution,
  point : LightContribution,
  spot : LightContribution,
  occlusion_tex : f32,
) -> vec3<f32> {
  return (directional.transmitted +
    point.transmitted +
    spot.transmitted) * occlusion_tex;
}

fn indirect_diffuse_transmissive_light(
  ambient_term : vec3<f32>,
  occlusion_tex : f32,
) -> vec3<f32> {
  return ambient_term * occlusion_tex;
}

fn specular_transmissive_incident_light(
  ambient_term : vec3<f32>,
  directional : LightContribution,
  point : LightContribution,
  spot : LightContribution,
) -> vec3<f32> {
  return ambient_term +
    directional.diffuse +
    point.diffuse +
    spot.diffuse;
}

fn transmission_source_uv(
  position_xy : vec2<f32>,
  texture_size : vec2<f32>,
  normal : vec3<f32>,
  view_dir : vec3<f32>,
  ior : f32,
  thickness : f32,
  transmission_steps : f32,
) -> vec2<f32> {
  var screen_uv = position_xy / max(texture_size, vec2<f32>(1.0, 1.0));
  let eta = 1.0 / ior;
  let incident = -view_dir;
  let ndoti = dot(normal, incident);
  let k = 1.0 - eta * eta * (1.0 - ndoti * ndoti);
  if k > 0.0 {
    let refracted = eta * incident - (eta * ndoti + sqrt(k)) * normal;
    let refraction_scale = transmission_steps * thickness * 0.0025;
    screen_uv += refracted.xy * refraction_scale;
  }
  return screen_uv;
}

fn specular_transmissive_light(
  incident_light : vec3<f32>,
  position_xy : vec2<f32>,
  normal : vec3<f32>,
  view_dir : vec3<f32>,
  specular_transmission : f32,
  perceptual_roughness : f32,
  thickness : f32,
  ior : f32,
  transmission_blur_taps : i32,
  transmission_steps : f32,
) -> vec3<f32> {
  let ior_f0 = pow((ior - 1.0) / max(ior + 1.0, 1.0e-4), 2.0);
  let thickness_factor = clamp(thickness / 5.0, 0.0, 1.0);
  var transmitted_light = incident_light *
    (0.35 + 0.65 * (1.0 - perceptual_roughness * perceptual_roughness)) *
    (1.0 - 0.4 * thickness_factor) *
    (0.2 + 0.8 * (1.0 - ior_f0));
  if specular_transmission > 0.0 &&
    transmission_blur_taps > 0 &&
    transmission_steps > 0.0 {
    let texture_size = vec2<f32>(textureDimensions(u_transmission_source_texture));
    let screen_uv = transmission_source_uv(
      position_xy,
      texture_size,
      normal,
      view_dir,
      ior,
      thickness,
      transmission_steps,
    );
    let transmission_scene = sample_transmission_source(
      screen_uv,
      transmission_blur_taps,
      perceptual_roughness,
      thickness,
    );
    let transmission_scene_weight = clamp(
      0.25 + 0.75 * (1.0 - ior_f0),
      0.0,
      1.0,
    );
    transmitted_light = mix(
      transmitted_light,
      transmission_scene,
      transmission_scene_weight,
    );
  }
  return transmitted_light;
}

fn transmitted_light(
  diffuse_transmissive_color : vec3<f32>,
  diffuse_transmitted_light : vec3<f32>,
  specular_transmissive_color : vec3<f32>,
  specular_transmitted_light : vec3<f32>,
) -> vec3<f32> {
  return diffuse_transmissive_color * diffuse_transmitted_light +
    specular_transmissive_color * specular_transmitted_light;
}

@fragment
fn fs_main(
  in : VertexOut,
  @builtin(front_facing) is_front : bool,
) -> @location(0) vec4<f32> {
  let mesh = u_draws.data[in.draw_index];
  let material_flags = u_material.flags;
  let has_base_map = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT,
  );
  let has_emissive_map = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT,
  );
  let has_metallic_roughness_map = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT,
  );
  let has_occlusion_map = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT,
  );
  let has_depth_map = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT,
  );
  let has_anisotropy_map = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT,
  );
  let has_specular_tint_map = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT,
  );
  let use_stacked_cubemap = false;
  let has_uv = has_base_map || has_emissive_map || has_metallic_roughness_map ||
    has_occlusion_map || has_depth_map || has_anisotropy_map ||
    has_specular_tint_map;
  let double_sided = material_flag_enabled(
    material_flags,
    STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT,
  );
  let geometric_normal = safe_normalize(in.world_normal);
  let view_dir = safe_normalize(u_view.world_position.xyz - in.world_pos);
  var uv = in.uv;
  if has_depth_map && has_uv && u_material.parallax_depth_scale > 0.0 {
    let tbn = cotangent_frame(geometric_normal, in.world_pos, uv);
    let tangent = tbn[0];
    let bitangent = tbn[1];
    let basis_normal = tbn[2];
    let view_dir_tangent = vec3<f32>(
      dot(view_dir, tangent),
      dot(view_dir, bitangent),
      dot(view_dir, basis_normal),
    );
    uv = parallaxed_uv(
      u_material.parallax_depth_scale,
      u_material.max_parallax_layer_count,
      u_material.max_relief_mapping_search_steps,
      uv,
      -view_dir_tangent,
    );
  }
  var anisotropy_strength = clamp(u_material.anisotropy_strength, 0.0, 1.0);
  var anisotropy_direction = u_material.anisotropy_rotation;
  if has_anisotropy_map && has_uv {
    let anisotropy_texel = textureSample(
      u_anisotropy_texture,
      u_anisotropy_sampler,
      uv,
    ).rgb;
    let tex_dir_raw = anisotropy_texel.rg * 2.0 - vec2<f32>(1.0, 1.0);
    let tex_dir_len2 = dot(tex_dir_raw, tex_dir_raw);
    if tex_dir_len2 > 1.0e-8 {
      let tex_dir = tex_dir_raw * inverseSqrt(tex_dir_len2);
      let rot = mat2x2<f32>(
        vec2<f32>(anisotropy_direction.x, anisotropy_direction.y),
        vec2<f32>(-anisotropy_direction.y, anisotropy_direction.x),
      );
      anisotropy_direction = rot * tex_dir;
    }
    anisotropy_strength = clamp(
      anisotropy_strength * anisotropy_texel.b,
      0.0,
      1.0,
    );
  }
  var base_color = in.color;
  if has_base_map {
    if use_stacked_cubemap {
      let cubemap_uv = cubemap_stacked_vertical_uv(
        in.world_pos - u_view.world_position.xyz,
      );
      base_color = textureSampleLevel(
        u_base_color_texture,
        u_base_color_sampler,
        cubemap_uv,
        0.0,
      ) * in.color;
    } else if has_uv {
      base_color = textureSample(u_base_color_texture, u_base_color_sampler, uv) * in.color;
    }
  }
  let alpha_mode = material_flags & STANDARD_MATERIAL_FLAGS_ALPHA_MODE_RESERVED_BITS;
  if alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK &&
    base_color.a < u_material.alpha_cutoff {
    discard;
  }
  var emissive_tex = vec3<f32>(1.0, 1.0, 1.0);
  if has_emissive_map && has_uv {
    emissive_tex = textureSample(u_emissive_texture, u_emissive_sampler, uv).xyz;
  }
  var metallic_roughness_tex = vec4<f32>(1.0, 1.0, 1.0, 1.0);
  if has_metallic_roughness_map && has_uv {
    metallic_roughness_tex = textureSample(
      u_metallic_roughness_texture,
      u_metallic_roughness_sampler,
      uv,
    );
  }
  var specular_tint = vec3<f32>(1.0, 1.0, 1.0);
  if has_specular_tint_map && has_uv {
    specular_tint = specular_tint * textureSample(
      u_specular_tint_texture,
      u_specular_tint_sampler,
      uv,
    ).xyz;
  }
  var occlusion_tex = 1.0;
  if has_occlusion_map && has_uv {
    occlusion_tex = textureSample(u_occlusion_texture, u_occlusion_sampler, uv).r;
  }
  var normal = geometric_normal;
  if has_uv {
    let normal_texel = textureSample(u_normal_map_texture, u_normal_map_sampler, uv).xyz;
    normal = apply_normal_mapping(
      material_flags,
      geometric_normal,
      in.world_pos,
      uv,
      double_sided,
      is_front,
      normal_texel,
    );
  }
  if dot(normal, view_dir) < 0.0 {
    normal = -normal;
  }
  let anisotropy_basis = cotangent_frame(geometric_normal, in.world_pos, uv);
  let anisotropy_t = safe_normalize(
    anisotropy_basis *
    vec3<f32>(anisotropy_direction.x, anisotropy_direction.y, 0.0),
  );
  let anisotropy_b = safe_normalize(cross(normal, anisotropy_t));
  let ndotv = max(dot(normal, view_dir), 1.0e-4);
  let emissive = max(u_material.emissive.xyz * emissive_tex, vec3<f32>(0.0));
  let unlit_factor = select(
    0.0,
    1.0,
    material_flag_enabled(material_flags, STANDARD_MATERIAL_FLAGS_UNLIT_BIT),
  );
  let metallic = clamp(u_material.metallic * metallic_roughness_tex.b, 0.0, 1.0);
  let perceptual_roughness = clamp(
    u_material.perceptual_roughness * metallic_roughness_tex.g,
    0.045,
    1.0,
  );
  let roughness = perceptual_roughness * perceptual_roughness;
  let diffuse_transmission = clamp(u_material.diffuse_transmission, 0.0, 1.0);
  let specular_transmission = clamp(u_material.specular_transmission, 0.0, 1.0);
  let thickness = max(u_material.thickness, 0.0);
  let ior = max(u_material.ior, 1.0);
  let transmission_blur_taps = i32(max(u_lights.legacy.spot_light_custom_data.z, 0.0));
  let transmission_steps = max(u_lights.legacy.spot_light_custom_data.w, 0.0);
  let reflectance_rgb = max(specular_tint * u_material.reflectance, vec3<f32>(0.0));
  let diffuse_color = base_color.xyz * (1.0 - metallic) *
    (1.0 - specular_transmission) *
    (1.0 - diffuse_transmission);
  let diffuse_transmissive_color = base_color.xyz * (1.0 - metallic) *
    (1.0 - specular_transmission) * diffuse_transmission;
  let specular_transmissive_color = base_color.xyz * specular_transmission;
  let f0 = 0.16 * reflectance_rgb * reflectance_rgb * (1.0 - metallic) +
    base_color.xyz * metallic;
  let environment_map_intensity = max(u_lights.environment.x, 0.0);
  let environment_map_rotation = quat_normalize(u_lights.environment_rotation);
  let draw_point_shadow_enabled = select(
    0.0,
    1.0,
    (mesh.flags & MESH_FLAGS_SHADOW_RECEIVER_BIT) != 0u,
  );
  let draw_point_shadow_depth_bias = 0.0;
  let point_shadow_params = vec4<f32>(
    u_lights.legacy.point_light_shadow_params.x * draw_point_shadow_enabled,
    max(u_lights.legacy.point_light_shadow_params.y, draw_point_shadow_depth_bias),
    u_lights.legacy.point_light_shadow_params.z,
    u_lights.legacy.point_light_shadow_params.w,
  );

  let ambient_term = u_lights.lights.ambient_color.xyz;

  let view_z = -dot(
    in.world_pos - u_view.world_position.xyz,
    safe_normalize(u_lights.directional_shadow.view_forward.xyz),
  );
  let directional_shadow_factor = directional_shadow(
    in.world_pos,
    normal,
    view_z,
  );

  let directional = directional_light(
    normal,
    view_dir,
    ndotv,
    roughness,
    f0,
    anisotropy_strength,
    anisotropy_t,
    anisotropy_b,
    safe_normalize(u_lights.lights.directional_lights[0].direction_to_light),
    u_lights.lights.directional_lights[0].color.xyz * directional_shadow_factor,
  );
  let point_shadow_factor = point_light_shadow(
    in.world_pos,
    u_lights.legacy.point_light_position_radius.xyz,
    max(u_lights.legacy.point_light_position_radius.w, 1e-4),
    point_shadow_params,
  );
  let point = point_light(
    normal,
    in.world_pos,
    view_dir,
    ndotv,
    roughness,
    f0,
    anisotropy_strength,
    anisotropy_t,
    anisotropy_b,
    u_lights.legacy.point_light_position_radius,
    u_lights.legacy.point_light_color_inverse_square_range,
    point_shadow_factor,
  );
  let spot = spot_light(
    normal,
    in.world_pos,
    view_dir,
    ndotv,
    roughness,
    f0,
    anisotropy_strength,
    anisotropy_t,
    anisotropy_b,
    u_lights.legacy.spot_light_position_radius,
    u_lights.legacy.spot_light_direction_to_light,
    u_lights.legacy.spot_light_color_inverse_square_range,
    u_lights.legacy.spot_light_custom_data,
  );

  let direct_diffuse = direct_diffuse_light(
    directional,
    point,
    spot,
    occlusion_tex,
  );
  var environment_diffuse = sample_environment_diffuse(
    normal,
    environment_map_rotation,
  );
  var environment_specular = sample_environment_specular(
    reflect(-view_dir, normal),
    environment_map_rotation,
    perceptual_roughness,
  );
  if environment_map_intensity > 0.0 {
    environment_diffuse = environment_diffuse * environment_map_intensity;
    environment_specular = environment_specular * environment_map_intensity;
  } else {
    environment_diffuse = vec3<f32>(0.0, 0.0, 0.0);
    environment_specular = vec3<f32>(0.0, 0.0, 0.0);
  }
  let indirect_diffuse = indirect_diffuse_light(ambient_term, occlusion_tex) +
    environment_diffuse * occlusion_tex;
  let direct_specular = direct_specular_light(directional, point, spot) +
    environment_specular;
  let direct_diffuse_transmitted = direct_diffuse_transmissive_light(
    directional,
    point,
    spot,
    occlusion_tex,
  );
  let indirect_diffuse_transmitted = indirect_diffuse_transmissive_light(
    ambient_term,
    occlusion_tex,
  );
  let diffuse_transmitted_lighting = direct_diffuse_transmitted +
    indirect_diffuse_transmitted;
  let specular_transmissive_incident = specular_transmissive_incident_light(
    ambient_term,
    directional,
    point,
    spot,
  ) + environment_diffuse;
  let specular_transmitted_lighting = specular_transmissive_light(
    specular_transmissive_incident,
    in.position.xy,
    normal,
    view_dir,
    specular_transmission,
    perceptual_roughness,
    thickness,
    ior,
    transmission_blur_taps,
    transmission_steps,
  );
  let direct_light = diffuse_color * direct_diffuse + direct_specular;
  let indirect_light = diffuse_color * indirect_diffuse;
  let transmitted = transmitted_light(
    diffuse_transmissive_color,
    diffuse_transmitted_lighting,
    specular_transmissive_color,
    specular_transmitted_lighting,
  );
  let exposure = max(u_view.exposure, 0.0);
  let lighting_rgb = direct_light + indirect_light + transmitted;
  let lit_rgb = lighting_rgb * exposure + emissive;
  let unlit_rgb = base_color.xyz + emissive;
  let final_rgb = mix(lit_rgb, unlit_rgb, unlit_factor);
  var output_color = vec4<f32>(final_rgb, base_color.w);
  if alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE ||
    alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK {
    output_color.a = 1.0;
  } else if alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD {
    output_color = vec4<f32>(output_color.rgb * output_color.a, 0.0);
  } else if alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY {
    output_color = vec4<f32>(output_color.rgb * output_color.a, output_color.a);
  }
  return output_color;
}

@fragment
fn fs_shadow(in : VertexOut) -> @location(0) vec4<f32> {
  let point_range = max(u_lights.legacy.point_light_position_radius.w, 1.0e-4);
  let point_distance = length(
    in.world_pos - u_lights.legacy.point_light_position_radius.xyz,
  );
  let depth01 = clamp(point_distance / point_range, 0.0, 1.0);
  return vec4<f32>(depth01, depth01, depth01, 1.0);
}
