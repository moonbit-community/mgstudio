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

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) uv : vec2<f32>,
  @location(1) color : vec4<f32>,
  @location(2) world_pos : vec3<f32>,
};

struct Mesh3dUniform {
  model_pos : vec4<f32>,
  model_rot : vec4<f32>,
  model_scale : vec4<f32>,
  camera_pos : vec4<f32>,
  camera_rot : vec4<f32>,
  projection : vec4<f32>, // (fov_y, aspect, near, far)
  color : vec4<f32>,
  uv : vec4<f32>,
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
};

@group(0) @binding(0) var<uniform> u_mesh : Mesh3dUniform;
@group(1) @binding(0) var u_material_sampler : sampler;
@group(1) @binding(1) var u_base_color_texture : texture_2d<f32>;
@group(1) @binding(2) var u_normal_texture : texture_2d<f32>;
@group(1) @binding(3) var u_emissive_texture : texture_2d<f32>;
@group(1) @binding(4) var u_metallic_roughness_texture : texture_2d<f32>;
@group(1) @binding(5) var u_occlusion_texture : texture_2d<f32>;

fn quat_normalize(q : vec4<f32>) -> vec4<f32> {
  let n = max(dot(q, q), 1e-8);
  return q / sqrt(n);
}

fn quat_conjugate(q : vec4<f32>) -> vec4<f32> {
  return vec4<f32>(-q.xyz, q.w);
}

fn quat_rotate_vec3(q : vec4<f32>, v : vec3<f32>) -> vec3<f32> {
  let t = 2.0 * cross(q.xyz, v);
  return v + q.w * t + cross(q.xyz, t);
}

@vertex
fn vs_main(
  @location(0) position : vec3<f32>,
  @location(1) uv : vec2<f32>,
  @location(2) color : vec4<f32>,
) -> VertexOut {
  var out : VertexOut;

  let model_q = quat_normalize(u_mesh.model_rot);
  let camera_q = quat_normalize(u_mesh.camera_rot);
  let inv_camera_q = quat_conjugate(camera_q);

  let local_pos = position * u_mesh.model_scale.xyz;
  let world_pos = quat_rotate_vec3(model_q, local_pos) + u_mesh.model_pos.xyz;
  let camera_space = quat_rotate_vec3(
    inv_camera_q,
    world_pos - u_mesh.camera_pos.xyz,
  );

  let fov_y = max(u_mesh.projection.x, 0.001);
  let aspect = max(u_mesh.projection.y, 0.001);
  let near_z = max(u_mesh.projection.z, 0.0001);
  let far_z = max(u_mesh.projection.w, near_z + 0.0001);
  let f = 1.0 / tan(0.5 * fov_y);

  let clip_x = camera_space.x * f / aspect;
  let clip_y = camera_space.y * f;
  let clip_z = camera_space.z * (far_z / (near_z - far_z)) +
    (near_z * far_z) / (near_z - far_z);
  let clip_w = -camera_space.z;

  out.position = vec4<f32>(clip_x, clip_y, clip_z, clip_w);
  out.uv = vec2<f32>(
    u_mesh.uv.x + uv.x * u_mesh.uv.z,
    u_mesh.uv.y + uv.y * u_mesh.uv.w,
  );
  out.color = color * u_mesh.color;
  out.world_pos = world_pos;
  return out;
}

fn safe_normalize(v : vec3<f32>) -> vec3<f32> {
  let n2 = max(dot(v, v), 1e-8);
  return v * inverseSqrt(n2);
}

fn lambert(normal : vec3<f32>, light_dir : vec3<f32>) -> f32 {
  return max(dot(normal, light_dir), 0.0);
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

fn specular_blinn(
  normal : vec3<f32>,
  light_dir : vec3<f32>,
  view_dir : vec3<f32>,
  roughness : f32,
) -> f32 {
  let half_dir = safe_normalize(light_dir + view_dir);
  let ndoth = max(dot(normal, half_dir), 0.0);
  let shininess = mix(8.0, 256.0, 1.0 - roughness);
  return pow(ndoth, shininess);
}

@fragment
fn fs_main(in : VertexOut) -> @location(0) vec4<f32> {
  let has_base_map = u_mesh.map_flags.x > 0.5;
  let has_emissive_map = u_mesh.map_flags.y > 0.5;
  let has_metallic_roughness_map = u_mesh.map_flags.z > 0.5;
  let has_occlusion_map = u_mesh.map_flags.w > 0.5;
  let has_normal_map = u_mesh.material_params.w > 0.5;
  let base_color = if !has_base_map || u_mesh.uv.z < 0.0 || u_mesh.uv.w < 0.0 {
    in.color
  } else {
    textureSample(u_base_color_texture, u_material_sampler, in.uv) * in.color
  };
  let emissive_tex = if has_emissive_map && u_mesh.uv.z >= 0.0 && u_mesh.uv.w >= 0.0 {
    textureSample(u_emissive_texture, u_material_sampler, in.uv).xyz
  } else {
    vec3<f32>(1.0, 1.0, 1.0)
  };
  let metallic_roughness_tex =
    if has_metallic_roughness_map && u_mesh.uv.z >= 0.0 && u_mesh.uv.w >= 0.0 {
      textureSample(u_metallic_roughness_texture, u_material_sampler, in.uv)
    } else {
      vec4<f32>(1.0, 1.0, 1.0, 1.0)
    };
  let occlusion_tex = if has_occlusion_map && u_mesh.uv.z >= 0.0 && u_mesh.uv.w >= 0.0 {
    textureSample(u_occlusion_texture, u_material_sampler, in.uv).r
  } else {
    1.0
  };
  let dp1 = dpdx(in.world_pos);
  let dp2 = dpdy(in.world_pos);
  var normal = safe_normalize(cross(dp1, dp2));
  if has_normal_map && u_mesh.uv.z >= 0.0 && u_mesh.uv.w >= 0.0 {
    let normal_texel = textureSample(u_normal_texture, u_material_sampler, in.uv).xyz;
    let tangent_space_normal = normal_texel * 2.0 - vec3<f32>(1.0, 1.0, 1.0);
    let tbn = cotangent_frame(normal, in.world_pos, in.uv);
    normal = safe_normalize(tbn * tangent_space_normal);
  }
  let view_dir = safe_normalize(u_mesh.camera_pos.xyz - in.world_pos);
  if dot(normal, view_dir) < 0.0 {
    normal = -normal;
  }
  let emissive = max(u_mesh.emissive_unlit.xyz * emissive_tex, vec3<f32>(0.0));
  let unlit_factor = clamp(u_mesh.emissive_unlit.w, 0.0, 1.0);
  let metallic = clamp(u_mesh.material_params.x * metallic_roughness_tex.b, 0.0, 1.0);
  let roughness = clamp(u_mesh.material_params.y * metallic_roughness_tex.g, 0.045, 1.0);
  let reflectance = clamp(u_mesh.material_params.z, 0.0, 1.0);
  let diffuse_color = base_color.xyz * (1.0 - metallic);
  let f0_scalar = clamp(0.04 + reflectance * 0.16, 0.0, 1.0);
  let f0 = mix(vec3<f32>(f0_scalar), base_color.xyz, metallic);

  let ambient_term = u_mesh.ambient.xyz * max(u_mesh.ambient.w, 0.0);

  let directional_dir = safe_normalize(u_mesh.directional_dir_illum.xyz);
  let directional_strength = max(u_mesh.directional_dir_illum.w, 0.0) / 10000.0;
  let directional_light_dir = -directional_dir;
  let directional_diff = lambert(normal, directional_light_dir);
  let directional_term = u_mesh.directional_color.xyz *
    directional_strength *
    directional_diff;
  let directional_spec = u_mesh.directional_color.xyz *
    directional_strength *
    directional_diff *
    specular_blinn(normal, directional_light_dir, view_dir, roughness);

  let to_point = u_mesh.point_pos_range.xyz - in.world_pos;
  let point_distance = length(to_point);
  let point_dir = safe_normalize(to_point);
  let point_range = max(u_mesh.point_pos_range.w, 1e-4);
  let point_atten = clamp(1.0 - point_distance / point_range, 0.0, 1.0);
  let point_strength = max(u_mesh.point_color_intensity.w, 0.0) / 100000.0;
  let point_diff = lambert(normal, point_dir);
  let point_term = u_mesh.point_color_intensity.xyz *
    point_strength *
    point_atten *
    point_atten *
    point_diff;
  let point_spec = u_mesh.point_color_intensity.xyz *
    point_strength *
    point_atten *
    point_atten *
    point_diff *
    specular_blinn(normal, point_dir, view_dir, roughness);

  let to_spot = u_mesh.spot_pos_range.xyz - in.world_pos;
  let spot_distance = length(to_spot);
  let spot_dir_to_fragment = safe_normalize(-to_spot);
  let spot_range = max(u_mesh.spot_pos_range.w, 1e-4);
  let spot_atten_base = clamp(1.0 - spot_distance / spot_range, 0.0, 1.0);
  let spot_light_dir = safe_normalize(u_mesh.spot_dir_inner.xyz);
  let inner_angle = max(u_mesh.spot_dir_inner.w, 0.0);
  let outer_angle = max(u_mesh.spot_outer.x, inner_angle + 1e-4);
  let inner_cos = cos(inner_angle);
  let outer_cos = cos(outer_angle);
  let spot_cos_theta = dot(spot_light_dir, spot_dir_to_fragment);
  let spot_cone = smoothstep(outer_cos, inner_cos, spot_cos_theta);
  let spot_strength = max(u_mesh.spot_color_intensity.w, 0.0) / 100000.0;
  let spot_light_to_fragment = safe_normalize(to_spot);
  let spot_diff = lambert(normal, spot_light_to_fragment);
  let spot_term = u_mesh.spot_color_intensity.xyz *
    spot_strength *
    spot_atten_base *
    spot_atten_base *
    spot_cone *
    spot_diff;
  let spot_spec = u_mesh.spot_color_intensity.xyz *
    spot_strength *
    spot_atten_base *
    spot_atten_base *
    spot_cone *
    spot_diff *
    specular_blinn(normal, spot_light_to_fragment, view_dir, roughness);

  let diffuse_lighting = (ambient_term +
    directional_term +
    point_term +
    spot_term +
    vec3<f32>(0.02, 0.02, 0.02)) * occlusion_tex;
  let specular_lighting = directional_spec + point_spec + spot_spec;
  let lit_rgb = diffuse_color * diffuse_lighting + f0 * specular_lighting + emissive;
  let unlit_rgb = base_color.xyz + emissive;
  let final_rgb = mix(lit_rgb, unlit_rgb, unlit_factor);
  return vec4<f32>(final_rgb, base_color.w);
}
