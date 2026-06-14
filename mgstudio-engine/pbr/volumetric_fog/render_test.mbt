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
fn volumetric_fog_test_abs(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn volumetric_fog_test_approx_eq(lhs : Float, rhs : Float) -> Bool {
  volumetric_fog_test_abs(lhs - rhs) < 0.0001F
}

///|
fn volumetric_fog_test_u32_at(bytes : Bytes, byte_offset : Int) -> UInt {
  (bytes[byte_offset].to_uint() & 0xFFU) |
  ((bytes[byte_offset + 1].to_uint() & 0xFFU) << 8) |
  ((bytes[byte_offset + 2].to_uint() & 0xFFU) << 16) |
  ((bytes[byte_offset + 3].to_uint() & 0xFFU) << 24)
}

///|
fn volumetric_fog_test_f32_bits_at(bytes : Bytes, byte_offset : Int) -> UInt {
  volumetric_fog_test_u32_at(bytes, byte_offset)
}

///|
fn volumetric_fog_test_vertex_layout_ref(
  stride? : Int = 32,
  position_offset? : Int = 4,
  position_shader_location? : Int = 7,
) -> @mesh.MeshVertexBufferLayoutRef {
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  layouts.insert(
    @mesh.MeshVertexBufferLayout::new(
      attribute_ids=[@mesh.MeshVertexAttribute::position().id()],
      layout=@mesh.VertexBufferLayout::new(
        array_stride=stride,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=position_offset,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=position_shader_location,
          ),
        ],
      ),
    ),
  )
}

///|
test "pbr volumetric fog: pipeline selection by density texture flag" {
  let pipelines = view_volumetric_fog_pipelines(11, 29)
  let key_without_texture = VolumetricFogPipelineKey::new(
    @mesh_view_layout.mesh_view_layout_key_from_msaa(1),
    volumetric_fog_test_vertex_layout_ref(),
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    false,
  )
  let key_with_texture = VolumetricFogPipelineKey::new(
    @mesh_view_layout.mesh_view_layout_key(
      true, false, false, false, false, false, true, false,
    ),
    volumetric_fog_test_vertex_layout_ref(),
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT),
    true,
  )
  inspect(
    volumetric_fog_select_pipeline(pipelines, key_without_texture),
    content="11",
  )
  inspect(
    volumetric_fog_select_pipeline(pipelines, key_with_texture),
    content="29",
  )
  let descriptor = volumetric_fog_specialize_pipeline(key_with_texture)
  let shader_defs = descriptor.shader_defs()
  inspect(shader_defs.length(), content="4")
  inspect(shader_defs[0], content="SHADOW_FILTER_METHOD_HARDWARE_2X2")
  inspect(shader_defs[1], content="MULTISAMPLED")
  inspect(shader_defs[2], content="ATMOSPHERE")
  inspect(shader_defs[3], content="DENSITY_TEXTURE")
  inspect(descriptor.bind_group_layout_index(), content="3")
  inspect(
    descriptor.target_format().to_u32(),
    content="\{@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT}",
  )
  let vertex_layout = descriptor.vertex_buffer_layout()
  inspect(vertex_layout.array_stride(), content="32")
  let vertex_attributes = vertex_layout.attributes()
  inspect(vertex_attributes.length(), content="1")
  inspect(vertex_attributes[0].offset(), content="4")
  inspect(vertex_attributes[0].shader_location(), content="0")
  inspect(descriptor.uses_bevy_blend_state(), content="true")
}

///|
test "pbr volumetric fog: pipeline shader label matches embedded owner path" {
  let pipeline = VolumetricFogPipeline::VolumetricFogPipeline()
  inspect(
    pipeline.shader_label,
    content="pbr/volumetric_fog/volumetric_fog.wgsl",
  )
  inspect(pipeline.bind_group_layout_count, content="4")
}

///|
test "pbr volumetric fog: bind group layout description follows Bevy flags" {
  inspect(
    volumetric_fog_bind_group_layout_description(
      VolumetricFogBindGroupLayoutKey::VolumetricFogBindGroupLayoutKey(),
    ),
    content="volumetric lighting view bind group layout",
  )
  inspect(
    volumetric_fog_bind_group_layout_description(
      VolumetricFogBindGroupLayoutKey::new(
        multisampled=false,
        density_texture=true,
      ),
    ),
    content="volumetric lighting view bind group layout (density texture)",
  )
  inspect(
    volumetric_fog_bind_group_layout_description(
      VolumetricFogBindGroupLayoutKey::new(
        multisampled=true,
        density_texture=false,
      ),
    ),
    content="volumetric lighting view bind group layout (multisampled)",
  )
  inspect(
    volumetric_fog_bind_group_layout_description(
      VolumetricFogBindGroupLayoutKey::new(
        multisampled=true,
        density_texture=true,
      ),
    ),
    content="volumetric lighting view bind group layout (density texture, multisampled)",
  )
}

///|
test "pbr volumetric fog: uniform buffer push and clear" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let offset0 = buffer.push(
    @volumetric_fog.VolumetricFogUniform::VolumetricFogUniform(),
  )
  let offset1 = buffer.push(
    @volumetric_fog.VolumetricFogUniform::VolumetricFogUniform(),
  )
  inspect(offset0, content="0")
  inspect(offset1, content="512")
  inspect(buffer.count(), content="2")
  inspect(buffer.bytes().length(), content="1024")
  buffer.clear()
  inspect(buffer.count(), content="0")
}

///|
test "pbr volumetric fog: uniform bytes match WGSL host layout" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_step_count(96)
    .with_jitter(0.25F)
  let volume = @light.FogVolume::FogVolume().with_density_factor(0.75F)
  ignore(
    @volumetric_fog.prepare_volumetric_fog_view_uniforms(
      buffer,
      fog,
      @math.Affine3::identity(),
      @volumetric_fog.VolumetricFogMat4::identity(),
      [
        (
          volume,
          @math.Affine3::from_translation(@math.Vec3::new(10.0F, 0.0F, 0.0F)),
        ),
      ],
    ),
  )
  let uniform = buffer.uniform_at(0).unwrap()
  let bytes = uniform.bytes()
  inspect(bytes.length(), content="288")
  inspect(
    volumetric_fog_test_f32_bits_at(bytes, 0),
    content="\{1.0F.reinterpret_as_uint()}",
  )
  inspect(volumetric_fog_test_u32_at(bytes, 224), content="\{96U}")
  inspect(
    volumetric_fog_test_f32_bits_at(bytes, 240),
    content="\{0.75F.reinterpret_as_uint()}",
  )
  inspect(
    volumetric_fog_test_f32_bits_at(bytes, 276),
    content="\{0.25F.reinterpret_as_uint()}",
  )
}

///|
test "pbr volumetric fog: matrices pack in WGSL column order" {
  let matrix = @volumetric_fog.VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 2.0F, 3.0F, 4.0F),
    @math.Vec4::new(5.0F, 6.0F, 7.0F, 8.0F),
    @math.Vec4::new(9.0F, 10.0F, 11.0F, 12.0F),
    @math.Vec4::new(13.0F, 14.0F, 15.0F, 16.0F),
  )
  debug_inspect(
    matrix.to_cols_array(),
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]",
  )
}

///|
test "pbr volumetric fog: camera inside volume follows Bevy local cube test" {
  inspect(
    @volumetric_fog.volumetric_fog_camera_is_inside(@math.Affine3::identity()),
    content="true",
  )
  inspect(
    @volumetric_fog.volumetric_fog_camera_is_inside(
      @math.Affine3::from_translation(@math.Vec3::new(0.6F, 0.0F, 0.0F)),
    ),
    content="false",
  )
}

///|
test "pbr volumetric fog: far planes keep only view-facing cube faces" {
  let far_planes = @volumetric_fog.volumetric_fog_far_planes(
    @math.Affine3::identity(),
  )
  inspect(far_planes.length(), content="3")
  inspect(
    volumetric_fog_test_approx_eq(far_planes[0].x, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[0].y, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[0].z, 1.0F) &&
    volumetric_fog_test_approx_eq(far_planes[0].w, 0.5F),
    content="true",
  )
  inspect(
    volumetric_fog_test_approx_eq(far_planes[1].x, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[1].y, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[1].z, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[1].w, 0.0F),
    content="true",
  )
  inspect(
    volumetric_fog_test_approx_eq(far_planes[2].x, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[2].y, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[2].z, 0.0F) &&
    volumetric_fog_test_approx_eq(far_planes[2].w, 0.0F),
    content="true",
  )
}

///|
test "pbr volumetric fog: prepares view volume metadata and uniforms" {
  let buffer = @volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_step_count(96)
    .with_jitter(0.25F)
  let density_texture : @asset.Handle[@asset.Image] = @asset.Handle::new(42)
  let volume = @light.FogVolume::FogVolume()
    .with_density_factor(0.75F)
    .with_density_texture(Some(density_texture))
    .with_density_texture_offset(@math.Vec3::new(0.0F, 0.0F, 1.25F))
  let prepared = @volumetric_fog.prepare_volumetric_fog_view_uniforms(
    buffer,
    fog,
    @math.Affine3::identity(),
    @volumetric_fog.VolumetricFogMat4::identity(),
    [(volume, @math.Affine3::identity())],
  )
  inspect(prepared.uniform_count, content="1")
  inspect(prepared.view_fog.count(), content="1")
  inspect(prepared.view_fog.volumes[0].exterior, content="false")
  inspect(prepared.view_fog.volumes[0].has_density_texture(), content="true")
  match buffer.uniform_at(0) {
    Some(uniform) => {
      inspect(uniform.step_count, content="96")
      inspect(uniform.density, content="0.75")
      inspect(
        volumetric_fog_test_approx_eq(uniform.density_texture_offset.x, 0.0F) &&
        volumetric_fog_test_approx_eq(uniform.density_texture_offset.y, 0.0F) &&
        volumetric_fog_test_approx_eq(uniform.density_texture_offset.z, 1.25F),
        content="true",
      )
      inspect(uniform.jitter_strength, content="0.25")
      inspect(
        volumetric_fog_test_approx_eq(uniform.bounding_radius, 0.8660254F),
        content="true",
      )
    }
    None => inspect("missing", content="uniform")
  }
}
