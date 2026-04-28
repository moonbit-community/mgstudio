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

// Bevy-aligned opaque shadow caster path. This is the mgstudio runtime
// equivalent of Bevy's ShadowsDepthOnlyDrawFunction: transform vertices and
// write depth without evaluating PBR material shading.

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) uv : vec2<f32>,
  @location(1) @interpolate(flat) draw_index : u32,
};

struct Mesh3dViewUniform {
  world_position : vec4<f32>,
  clip_from_world : mat4x4<f32>,
  exposure : vec4<f32>,
};

struct Mesh3dViewBindings {
  view : Mesh3dViewUniform,
};

struct Mesh3dTransformUniform {
  model_translation : vec4<f32>,
  model_rotation : vec4<f32>,
  model_scale : vec4<f32>,
};

struct Mesh3dMaterialUniform {
  base_color : vec4<f32>,
  emissive : vec4<f32>,
  uv_transform : mat3x3<f32>,
  reflectance : vec3<f32>,
  perceptual_roughness : f32,
  metallic : f32,
  diffuse_transmission : f32,
  specular_transmission : f32,
  thickness : f32,
  ior : f32,
  anisotropy_strength : f32,
  anisotropy_rotation : vec2<f32>,
  flags : u32,
  alpha_cutoff : f32,
  parallax_depth_scale : f32,
  max_parallax_layer_count : f32,
  max_relief_mapping_search_steps : u32,
  uv_transform_mode : f32,
  _reserved0 : u32,
  _reserved1 : u32,
};

struct Mesh3dDrawUniform {
  transform : Mesh3dTransformUniform,
  material : Mesh3dMaterialUniform,
  current_skin_index : u32,
  _reserved2 : u32,
  _reserved3 : u32,
  _reserved4 : u32,
};

struct Mesh3dDrawUniformBuffer {
  data : array<Mesh3dDrawUniform>,
};

struct Mesh3dSkinningRowsBuffer {
  rows : array<vec4<f32>>,
};

@group(0) @binding(0) var<uniform> u_view : Mesh3dViewBindings;
@group(3) @binding(1) var u_base_color_texture : texture_2d<f32>;
@group(3) @binding(2) var u_base_color_sampler : sampler;
@group(2) @binding(0) var<storage, read> u_draws : Mesh3dDrawUniformBuffer;
@group(2) @binding(1) var<storage, read> u_skinning_rows : Mesh3dSkinningRowsBuffer;

const STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT: u32 = 1u << 0u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_RESERVED_BITS: u32 = 7u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK: u32 = 1u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND: u32 = 2u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED: u32 = 3u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD: u32 = 4u << 29u;
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE: u32 = 6u << 29u;
const PREMULTIPLIED_ALPHA_CUTOFF: f32 = 0.05;

fn quat_normalize(q : vec4<f32>) -> vec4<f32> {
  let n = max(dot(q, q), 1e-8);
  return q / sqrt(n);
}

fn quat_rotate_vec3(q : vec4<f32>, v : vec3<f32>) -> vec3<f32> {
  let t = 2.0 * cross(q.xyz, v);
  return v + q.w * t + cross(q.xyz, t);
}

fn skinning_row_count() -> u32 {
  return arrayLength(&u_skinning_rows.rows);
}

fn skinning_transform_point(
  skin_index : u32,
  joint_index : u32,
  local_point : vec3<f32>,
) -> vec3<f32> {
  let base = (skin_index + joint_index) * 4u;
  if base + 3u >= skinning_row_count() {
    return local_point;
  }
  let value = vec4<f32>(local_point, 1.0);
  return vec3<f32>(
    dot(u_skinning_rows.rows[base], value),
    dot(u_skinning_rows.rows[base + 1u], value),
    dot(u_skinning_rows.rows[base + 2u], value),
  );
}

@vertex
fn vertex(
  @location(0) position : vec3<f32>,
  @location(1) normal : vec3<f32>,
  @location(2) uv : vec2<f32>,
  @location(3) color : vec4<f32>,
  @location(4) joint_indices : vec4<f32>,
  @location(5) joint_weights : vec4<f32>,
  @builtin(instance_index) instance_index : u32,
) -> VertexOut {
  _ = normal;
  _ = uv;
  _ = color;
  var out : VertexOut;
  let draw = u_draws.data[instance_index];
  let weight_sum = joint_weights.x + joint_weights.y + joint_weights.z + joint_weights.w;
  var world_pos = vec3<f32>(0.0, 0.0, 0.0);
  if weight_sum > 1.0e-6 {
    let skin_index = draw.current_skin_index;
    let i0 = u32(max(joint_indices.x, 0.0));
    let i1 = u32(max(joint_indices.y, 0.0));
    let i2 = u32(max(joint_indices.z, 0.0));
    let i3 = u32(max(joint_indices.w, 0.0));
    world_pos =
      skinning_transform_point(skin_index, i0, position) * joint_weights.x +
      skinning_transform_point(skin_index, i1, position) * joint_weights.y +
      skinning_transform_point(skin_index, i2, position) * joint_weights.z +
      skinning_transform_point(skin_index, i3, position) * joint_weights.w;
  } else {
    let model_q = quat_normalize(draw.transform.model_rotation);
    world_pos = quat_rotate_vec3(
      model_q,
      position * draw.transform.model_scale.xyz,
    ) + draw.transform.model_translation.xyz;
  }
  out.position = u_view.view.clip_from_world * vec4<f32>(world_pos, 1.0);
  let transformed_uv = draw.material.uv_transform * vec3<f32>(uv, 1.0);
  out.uv = transformed_uv.xy;
  out.draw_index = instance_index;
  return out;
}

@fragment
fn fragment(in : VertexOut) -> @location(0) vec4<f32> {
  let material = u_draws.data[in.draw_index].material;
  let alpha_mode = material.flags & STANDARD_MATERIAL_FLAGS_ALPHA_MODE_RESERVED_BITS;
  var color = material.base_color;
  if (material.flags & STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT) != 0u {
    color = color * textureSample(
      u_base_color_texture,
      u_base_color_sampler,
      in.uv,
    );
  }
  if alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK {
    if color.a < material.alpha_cutoff {
      discard;
    }
  } else if alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND ||
    alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD ||
    alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE {
    if color.a < PREMULTIPLIED_ALPHA_CUTOFF {
      discard;
    }
  } else if alpha_mode == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED {
    if all(color < vec4<f32>(PREMULTIPLIED_ALPHA_CUTOFF)) {
      discard;
    }
  }
  return vec4<f32>(0.0, 0.0, 0.0, 0.0);
}
