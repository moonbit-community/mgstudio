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
};

struct Mesh3dUniform {
  model_pos : vec4<f32>,
  model_rot : vec4<f32>,
  model_scale : vec4<f32>,
  camera_pos : vec4<f32>,
  clip_from_world : mat4x4<f32>,
  color : vec4<f32>,
  uv_transform0 : vec4<f32>, // (a, b, c, tx)
  uv_transform1 : vec4<f32>, // (d, ty, mode, _)
  ambient : vec4<f32>, // (r, g, b, brightness)
  directional_dir_illum : vec4<f32>, // (dir.xyz, illuminance)
  directional_color : vec4<f32>, // (r, g, b, _)
  point_pos_range : vec4<f32>, // (pos.xyz, range)
  point_color_intensity : vec4<f32>, // (r, g, b, intensity)
  spot_pos_range : vec4<f32>, // (pos.xyz, range)
  spot_dir_inner : vec4<f32>, // (dir.xyz, inner_angle)
  spot_color_intensity : vec4<f32>, // (r, g, b, intensity)
  spot_outer : vec4<f32>, // (outer_angle, _, _, _)
  emissive_unlit : vec4<f32>, // (emissive.rgb, unlit)
  material_params : vec4<f32>, // (metallic, roughness, reflectance, _)
  map_flags : vec4<f32>, // (base, emissive, metallic_roughness, occlusion)
  parallax_params : vec4<f32>, // (depth_scale, max_layer_count, relief_steps, has_depth_map)
  anisotropy_params : vec4<f32>, // (strength, rot_cos, rot_sin, has_anisotropy_map)
  specular_tint : vec4<f32>, // (r, g, b, has_specular_tint_map)
  transmission_params : vec4<f32>, // (diffuse_transmission, specular_transmission, thickness, ior)
  point_shadow_params : vec4<f32>, // (enabled, depth_bias, near_z, exposure)
};

@group(0) @binding(0) var<uniform> u_mesh : Mesh3dUniform;
@group(1) @binding(0) var u_material_sampler : sampler;
@group(1) @binding(1) var u_base_color_texture : texture_2d<f32>;
@group(1) @binding(2) var u_normal_texture : texture_2d<f32>;
@group(1) @binding(3) var u_emissive_texture : texture_2d<f32>;
@group(1) @binding(4) var u_metallic_roughness_texture : texture_2d<f32>;
@group(1) @binding(5) var u_occlusion_texture : texture_2d<f32>;
@group(1) @binding(6) var u_depth_texture : texture_2d<f32>;
@group(1) @binding(7) var u_anisotropy_texture : texture_2d<f32>;
@group(1) @binding(8) var u_specular_tint_texture : texture_2d<f32>;
@group(1) @binding(9) var u_transmission_source_texture : texture_2d<f32>;
@group(1) @binding(10) var u_point_shadow_texture : texture_depth_cube;
@group(1) @binding(11) var u_point_shadow_sampler : sampler_comparison;

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

@vertex
fn vs_main(
  @location(0) position : vec3<f32>,
  @location(1) normal : vec3<f32>,
  @location(2) uv : vec2<f32>,
  @location(3) color : vec4<f32>,
) -> VertexOut {
  var out : VertexOut;

  let model_q = quat_normalize(u_mesh.model_rot);
  let local_pos = position * u_mesh.model_scale.xyz;
  let world_pos = quat_rotate_vec3(model_q, local_pos) + u_mesh.model_pos.xyz;
  out.position = u_mesh.clip_from_world * vec4<f32>(world_pos, 1.0);
  out.uv = vec2<f32>(
    u_mesh.uv_transform0.x * uv.x + u_mesh.uv_transform0.z * uv.y +
      u_mesh.uv_transform0.w,
    u_mesh.uv_transform0.y * uv.x + u_mesh.uv_transform1.x * uv.y +
      u_mesh.uv_transform1.y,
  );
  out.color = color * u_mesh.color;
  out.world_pos = world_pos;
  out.world_normal = transform_normal_local_to_world(
    model_q,
    normal,
    u_mesh.model_scale.xyz,
  );
  return out;
}

fn safe_normalize(v : vec3<f32>) -> vec3<f32> {
  let n2 = max(dot(v, v), 1e-8);
  return v * inverseSqrt(n2);
}

const PI : f32 = 3.141592653589793;

fn lambert(normal : vec3<f32>, light_dir : vec3<f32>) -> f32 {
  return max(dot(normal, light_dir), 0.0);
}

fn get_distance_attenuation(distance_square : f32, range : f32) -> f32 {
  let safe_range = max(range, 1.0e-4);
  let inverse_range_squared = 1.0 / (safe_range * safe_range);
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
  return textureSampleLevel(u_depth_texture, u_material_sampler, uv, 0.0).r;
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
      u_material_sampler,
      sample_uv,
      0.0,
    ).rgb;
    sum += sample_color * weight;
    weight_sum += weight;
  }
  if weight_sum <= 0.0 {
    return textureSampleLevel(
      u_transmission_source_texture,
      u_material_sampler,
      clamp(base_uv, vec2<f32>(0.0, 0.0), vec2<f32>(1.0, 1.0)),
      0.0,
    ).rgb;
  }
  return sum / weight_sum;
}

@fragment
fn fs_main(in : VertexOut) -> @location(0) vec4<f32> {
  let has_base_map = u_mesh.map_flags.x > 0.5;
  let has_emissive_map = u_mesh.map_flags.y > 0.5;
  let has_metallic_roughness_map = u_mesh.map_flags.z > 0.5;
  let has_occlusion_map = u_mesh.map_flags.w > 0.5;
  let has_normal_map = u_mesh.material_params.w > 0.5;
  let has_depth_map = u_mesh.parallax_params.w > 0.5;
  let has_anisotropy_map = u_mesh.anisotropy_params.w > 0.5;
  let has_specular_tint_map = u_mesh.specular_tint.w > 0.5;
  let use_stacked_cubemap = u_mesh.uv_transform1.z < 0.0;
  let has_uv = u_mesh.uv_transform1.z > 0.0;
  let geometric_normal = safe_normalize(in.world_normal);
  let view_dir = safe_normalize(u_mesh.camera_pos.xyz - in.world_pos);
  var uv = in.uv;
  if has_depth_map && has_uv && u_mesh.parallax_params.x > 0.0 {
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
      u_mesh.parallax_params.x,
      u_mesh.parallax_params.y,
      u32(max(u_mesh.parallax_params.z, 0.0)),
      uv,
      -view_dir_tangent,
    );
  }
  var anisotropy_strength = clamp(u_mesh.anisotropy_params.x, 0.0, 1.0);
  var anisotropy_direction = vec2<f32>(
    u_mesh.anisotropy_params.y,
    u_mesh.anisotropy_params.z,
  );
  if has_anisotropy_map && has_uv {
    let anisotropy_texel = textureSample(
      u_anisotropy_texture,
      u_material_sampler,
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
      let cubemap_uv = cubemap_stacked_vertical_uv(in.world_pos - u_mesh.camera_pos.xyz);
      base_color = textureSample(
        u_base_color_texture,
        u_material_sampler,
        cubemap_uv,
      ) * in.color;
    } else if has_uv {
      base_color = textureSample(u_base_color_texture, u_material_sampler, uv) * in.color;
    }
  }
  var emissive_tex = vec3<f32>(1.0, 1.0, 1.0);
  if has_emissive_map && has_uv {
    emissive_tex = textureSample(u_emissive_texture, u_material_sampler, uv).xyz;
  }
  var metallic_roughness_tex = vec4<f32>(1.0, 1.0, 1.0, 1.0);
  if has_metallic_roughness_map && has_uv {
    metallic_roughness_tex = textureSample(
      u_metallic_roughness_texture,
      u_material_sampler,
      uv,
    );
  }
  var specular_tint = max(u_mesh.specular_tint.xyz, vec3<f32>(0.0, 0.0, 0.0));
  if has_specular_tint_map && has_uv {
    specular_tint = specular_tint * textureSample(
      u_specular_tint_texture,
      u_material_sampler,
      uv,
    ).xyz;
  }
  var occlusion_tex = 1.0;
  if has_occlusion_map && has_uv {
    occlusion_tex = textureSample(u_occlusion_texture, u_material_sampler, uv).r;
  }
  var normal = geometric_normal;
  if has_normal_map && has_uv {
    let normal_texel = textureSample(u_normal_texture, u_material_sampler, uv).xyz;
    let tangent_space_normal = normal_texel * 2.0 - vec3<f32>(1.0, 1.0, 1.0);
    let tbn = cotangent_frame(geometric_normal, in.world_pos, uv);
    normal = safe_normalize(tbn * tangent_space_normal);
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
  let emissive = max(u_mesh.emissive_unlit.xyz * emissive_tex, vec3<f32>(0.0));
  let unlit_factor = clamp(u_mesh.emissive_unlit.w, 0.0, 1.0);
  let metallic = clamp(u_mesh.material_params.x * metallic_roughness_tex.b, 0.0, 1.0);
  let perceptual_roughness = clamp(
    u_mesh.material_params.y * metallic_roughness_tex.g,
    0.045,
    1.0,
  );
  let roughness = perceptual_roughness * perceptual_roughness;
  let reflectance = max(u_mesh.material_params.z, 0.0);
  let diffuse_transmission = clamp(u_mesh.transmission_params.x, 0.0, 1.0);
  let specular_transmission = clamp(u_mesh.transmission_params.y, 0.0, 1.0);
  let thickness = max(u_mesh.transmission_params.z, 0.0);
  let ior = max(u_mesh.transmission_params.w, 1.0);
  let transmission_blur_taps = i32(max(u_mesh.spot_outer.y, 0.0));
  let transmission_steps = max(u_mesh.spot_outer.z, 0.0);
  let reflectance_rgb = max(
    specular_tint * reflectance,
    vec3<f32>(0.0, 0.0, 0.0),
  );
  let diffuse_color = base_color.xyz * (1.0 - metallic) *
    (1.0 - specular_transmission) *
    (1.0 - diffuse_transmission);
  let diffuse_transmissive_color = base_color.xyz * (1.0 - metallic) *
    (1.0 - specular_transmission) * diffuse_transmission;
  let specular_transmissive_color = base_color.xyz * specular_transmission;
  let f0 = 0.16 * reflectance_rgb * reflectance_rgb * (1.0 - metallic) +
    base_color.xyz * metallic;

  let ambient_term = u_mesh.ambient.xyz * max(u_mesh.ambient.w, 0.0);

  let directional_dir = safe_normalize(u_mesh.directional_dir_illum.xyz);
  let directional_color = u_mesh.directional_color.xyz *
    max(u_mesh.directional_dir_illum.w, 0.0);
  let directional_light_dir = -directional_dir;
  let directional_diff = lambert(normal, directional_light_dir);
  let directional_half_dir = safe_normalize(directional_light_dir + view_dir);
  let directional_ldoth = max(dot(directional_light_dir, directional_half_dir), 0.0);
  let directional_diffuse_brdf = Fd_Burley(
    roughness,
    ndotv,
    directional_diff,
    directional_ldoth,
  );
  let directional_back_diff = lambert(-normal, directional_light_dir);
  let directional_term = directional_color * directional_diffuse_brdf * directional_diff;
  let directional_transmitted_term = directional_color * directional_back_diff;
  var directional_specular = vec3<f32>(0.0, 0.0, 0.0);
  if anisotropy_strength > 0.0 {
    directional_specular = specular_anisotropic(
      normal,
      directional_light_dir,
      view_dir,
      roughness,
      f0,
      anisotropy_strength,
      anisotropy_t,
      anisotropy_b,
    );
  } else {
    directional_specular = specular_isotropic(
      normal,
      directional_light_dir,
      view_dir,
      roughness,
      f0,
    );
  }
  let directional_spec = directional_color *
    directional_diff *
    directional_specular;

  let to_point = u_mesh.point_pos_range.xyz - in.world_pos;
  let point_distance_square = max(dot(to_point, to_point), 1.0e-4);
  let point_dir = safe_normalize(to_point);
  let point_range = max(u_mesh.point_pos_range.w, 1e-4);
  let point_atten = get_distance_attenuation(point_distance_square, point_range);
  let point_color = u_mesh.point_color_intensity.xyz *
    max(u_mesh.point_color_intensity.w, 0.0);
  let point_diff = lambert(normal, point_dir);
  let point_half_dir = safe_normalize(point_dir + view_dir);
  let point_ldoth = max(dot(point_dir, point_half_dir), 0.0);
  let point_diffuse_brdf = Fd_Burley(roughness, ndotv, point_diff, point_ldoth);
  let point_back_diff = lambert(-normal, point_dir);
  let point_shadow_enabled = u_mesh.point_shadow_params.x > 0.5;
  var point_shadow_factor = 1.0;
  if point_shadow_enabled {
    // Match Bevy's cubemap shadow sampling convention:
    // sample direction is transformed to cubemap LH space by flipping Z.
    let point_shadow_dir = safe_normalize(vec3<f32>(
      in.world_pos.x - u_mesh.point_pos_range.x,
      in.world_pos.y - u_mesh.point_pos_range.y,
      -(in.world_pos.z - u_mesh.point_pos_range.z),
    ));
    // Cubemap shadow projections are axis-aligned 90-degree frusta.
    // The projected depth can be reconstructed from the largest axis magnitude.
    let to_light = in.world_pos - u_mesh.point_pos_range.xyz;
    let major_axis_magnitude = max(
      abs(to_light.x),
      max(abs(to_light.y), abs(to_light.z)),
    );
    let point_near = max(u_mesh.point_shadow_params.z, 1.0e-4);
    let point_far = max(point_range, point_near + 1.0e-4);
    var point_linear_depth = 0.0;
    if major_axis_magnitude <= point_near {
      point_linear_depth = 0.0;
    } else {
      point_linear_depth = point_far / (point_far - point_near) -
        (point_far * point_near) / ((point_far - point_near) * major_axis_magnitude);
    }
    let point_depth_bias = max(u_mesh.point_shadow_params.y, 0.0);
    point_shadow_factor = textureSampleCompare(
      u_point_shadow_texture,
      u_point_shadow_sampler,
      point_shadow_dir,
      clamp(point_linear_depth - point_depth_bias, 0.0, 1.0),
    );
  }
  let point_term = point_color *
    point_atten *
    point_diffuse_brdf *
    point_diff *
    point_shadow_factor;
  let point_transmitted_term = point_color *
    point_atten *
    point_back_diff *
    point_shadow_factor;
  var point_specular = vec3<f32>(0.0, 0.0, 0.0);
  if anisotropy_strength > 0.0 {
    point_specular = specular_anisotropic(
      normal,
      point_dir,
      view_dir,
      roughness,
      f0,
      anisotropy_strength,
      anisotropy_t,
      anisotropy_b,
    );
  } else {
    point_specular = specular_isotropic(
      normal,
      point_dir,
      view_dir,
      roughness,
      f0,
    );
  }
  let point_spec = point_color *
    point_atten *
    point_diff *
    point_specular *
    point_shadow_factor;

  let to_spot = u_mesh.spot_pos_range.xyz - in.world_pos;
  let spot_dir_to_fragment = safe_normalize(-to_spot);
  let spot_range = max(u_mesh.spot_pos_range.w, 1e-4);
  let spot_distance_square = max(dot(to_spot, to_spot), 1.0e-4);
  let spot_atten_base = get_distance_attenuation(spot_distance_square, spot_range);
  let spot_light_dir = safe_normalize(u_mesh.spot_dir_inner.xyz);
  let inner_angle = max(u_mesh.spot_dir_inner.w, 0.0);
  let outer_angle = max(u_mesh.spot_outer.x, inner_angle + 1e-4);
  let inner_cos = cos(inner_angle);
  let outer_cos = cos(outer_angle);
  let spot_cos_theta = dot(spot_light_dir, spot_dir_to_fragment);
  let spot_scale = 1.0 / max(inner_cos - outer_cos, 1.0e-4);
  let spot_offset = -outer_cos * spot_scale;
  let spot_attenuation = clamp(
    spot_cos_theta * spot_scale + spot_offset,
    0.0,
    1.0,
  );
  let spot_cone = spot_attenuation * spot_attenuation;
  let spot_color = u_mesh.spot_color_intensity.xyz *
    max(u_mesh.spot_color_intensity.w, 0.0);
  let spot_light_to_fragment = safe_normalize(to_spot);
  let spot_diff = lambert(normal, spot_light_to_fragment);
  let spot_half_dir = safe_normalize(spot_light_to_fragment + view_dir);
  let spot_ldoth = max(dot(spot_light_to_fragment, spot_half_dir), 0.0);
  let spot_diffuse_brdf = Fd_Burley(roughness, ndotv, spot_diff, spot_ldoth);
  let spot_back_diff = lambert(-normal, spot_light_to_fragment);
  let spot_term = spot_color *
    spot_atten_base *
    spot_cone *
    spot_diffuse_brdf *
    spot_diff;
  let spot_transmitted_term = spot_color *
    spot_atten_base *
    spot_cone *
    spot_back_diff;
  var spot_specular = vec3<f32>(0.0, 0.0, 0.0);
  if anisotropy_strength > 0.0 {
    spot_specular = specular_anisotropic(
      normal,
      spot_light_to_fragment,
      view_dir,
      roughness,
      f0,
      anisotropy_strength,
      anisotropy_t,
      anisotropy_b,
    );
  } else {
    spot_specular = specular_isotropic(
      normal,
      spot_light_to_fragment,
      view_dir,
      roughness,
      f0,
    );
  }
  let spot_spec = spot_color *
    spot_atten_base *
    spot_cone *
    spot_diff *
    spot_specular;

  let diffuse_lighting = (ambient_term +
    directional_term +
    point_term +
    spot_term) * occlusion_tex;
  let diffuse_transmitted_lighting = (ambient_term +
    directional_transmitted_term +
    point_transmitted_term +
    spot_transmitted_term) * occlusion_tex;
  let specular_lighting = directional_spec + point_spec + spot_spec;
  let ior_f0 = pow((ior - 1.0) / max(ior + 1.0, 1.0e-4), 2.0);
  let thickness_factor = clamp(thickness / 5.0, 0.0, 1.0);
  var specular_transmitted_lighting = (ambient_term +
    directional_term +
    point_term +
    spot_term) *
    (0.35 + 0.65 * (1.0 - perceptual_roughness * perceptual_roughness)) *
    (1.0 - 0.4 * thickness_factor) *
    (0.2 + 0.8 * (1.0 - ior_f0));
  if specular_transmission > 0.0 &&
    transmission_blur_taps > 0 &&
    transmission_steps > 0.0 {
    let texture_size = vec2<f32>(textureDimensions(u_transmission_source_texture));
    var screen_uv = in.position.xy / max(texture_size, vec2<f32>(1.0, 1.0));
    let eta = 1.0 / ior;
    let incident = -view_dir;
    let ndoti = dot(normal, incident);
    let k = 1.0 - eta * eta * (1.0 - ndoti * ndoti);
    if k > 0.0 {
      let refracted = eta * incident - (eta * ndoti + sqrt(k)) * normal;
      let refraction_scale = transmission_steps * thickness * 0.0025;
      screen_uv += refracted.xy * refraction_scale;
    }
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
    specular_transmitted_lighting = mix(
      specular_transmitted_lighting,
      transmission_scene,
      transmission_scene_weight,
    );
  }
  let transmitted_light = diffuse_transmissive_color * diffuse_transmitted_lighting +
    specular_transmissive_color * specular_transmitted_lighting;
  let exposure = max(u_mesh.point_shadow_params.w, 0.0);
  let lighting_rgb = diffuse_color * diffuse_lighting +
    specular_lighting +
    transmitted_light;
  let lit_rgb = lighting_rgb * exposure + emissive;
  let unlit_rgb = base_color.xyz + emissive;
  let final_rgb = mix(lit_rgb, unlit_rgb, unlit_factor);
  return vec4<f32>(final_rgb, base_color.w);
}

@fragment
fn fs_shadow(in : VertexOut) -> @location(0) vec4<f32> {
  let point_range = max(u_mesh.point_pos_range.w, 1.0e-4);
  let point_distance = length(in.world_pos - u_mesh.point_pos_range.xyz);
  let depth01 = clamp(point_distance / point_range, 0.0, 1.0);
  return vec4<f32>(depth01, depth01, depth01, 1.0);
}
