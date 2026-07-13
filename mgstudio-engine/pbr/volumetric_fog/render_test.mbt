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
fn volumetric_fog_test_identity_mat4() -> @volumetric_fog.VolumetricFogMat4 {
  @volumetric_fog.VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  )
}

///|
fn volumetric_fog_test_shader_defs_contain(
  shader_defs : Array[@render_resource.ShaderDefVal],
  name : String,
) -> Bool {
  for shader_def in shader_defs {
    match shader_def {
      @render_resource.ShaderDefVal::Flag(flag) if flag == name => return true
      _ => ()
    }
  }
  false
}

///|
test "pbr volumetric fog: pipeline key mirrors Bevy shader defs and layout bits" {
  let view_key = @mesh_view_layout.mesh_view_layout_key(
    true, false, false, false, false, false, true, false,
  )
  let key = @volumetric_fog.VolumetricFogPipelineKey::VolumetricFogPipelineKey(
    mesh_pipeline_view_key=view_key,
    target_format=80U,
    vertex_buffer_layout=@mesh.VertexBufferLayout::new(
      array_stride=12,
      step_mode=@mesh.MeshVertexStepMode::Vertex,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
      ],
    ),
    has_density_texture=true,
  )
  let layout_key = key.bind_group_layout_key()
  inspect(layout_key.layout_index(), content="3")
  inspect(
    layout_key.description(),
    content="volumetric lighting view bind group layout (density texture, multisampled)",
  )
  let expected_defs = "[\n  \"SHADOW_FILTER_METHOD_HARDWARE_2X2\",\n  \"MULTISAMPLED\",\n  \"ATMOSPHERE\",\n  \"DENSITY_TEXTURE\",\n]"
  debug_inspect(key.shader_defs(), content=expected_defs)
  let vertex_layout = key.vertex_buffer_layout()
  inspect(vertex_layout.array_stride(), content="12")
  inspect(vertex_layout.attributes().length(), content="1")
  inspect(vertex_layout.attributes()[0].offset(), content="0")
  inspect(vertex_layout.attributes()[0].shader_location(), content="0")
}

///|
test "pbr volumetric fog: bind group layout descriptors mirror Bevy variants" {
  let descriptors = @volumetric_fog.volumetric_fog_bind_group_layout_descriptors()
  inspect(descriptors.length(), content="4")
  inspect(
    descriptors[0].label(),
    content="volumetric lighting view bind group layout",
  )
  inspect(
    descriptors[3].label(),
    content="volumetric lighting view bind group layout (density texture, multisampled)",
  )
  inspect(descriptors[0].entries().length(), content="2")
  inspect(descriptors[1].entries().length(), content="2")
  inspect(descriptors[2].entries().length(), content="4")
  inspect(descriptors[3].entries().length(), content="4")
  inspect(descriptors[0].entries()[0].binding(), content="0")
  inspect(descriptors[0].entries()[0].visibility(), content="3")
  match descriptors[0].entries()[0].kind() {
    @render_resource.BindingType::BufferBinding(
      @render_resource.BufferBindingType::Uniform,
      true,
      size
    ) => inspect(size, content="288")
    _ => inspect("unexpected binding", content="uniform dynamic binding")
  }
  match descriptors[1].entries()[1].kind() {
    @render_resource.BindingType::TextureBinding(
      @render_resource.TextureSampleType::Depth,
      @render_resource.TextureViewDimension::D2,
      true
    ) => inspect("multisampled depth", content="multisampled depth")
    _ => inspect("unexpected binding", content="multisampled depth")
  }
  match descriptors[2].entries()[2].kind() {
    @render_resource.BindingType::TextureBinding(
      @render_resource.TextureSampleType::Float(true),
      @render_resource.TextureViewDimension::D3,
      false
    ) => inspect("density texture", content="density texture")
    _ => inspect("unexpected binding", content="density texture")
  }
  match descriptors[2].entries()[3].kind() {
    @render_resource.BindingType::SamplerBinding(
      @render_resource.SamplerBindingType::Filtering
    ) => inspect("density sampler", content="density sampler")
    _ => inspect("unexpected binding", content="density sampler")
  }
  let pipeline = @volumetric_fog.VolumetricFogPipeline::VolumetricFogPipeline()
  inspect(pipeline.volumetric_view_bind_group_layouts().length(), content="4")
}

///|
test "pbr volumetric fog: pipeline specialize mirrors Bevy descriptor" {
  let view_key = @mesh_view_layout.mesh_view_layout_key(
    true, false, false, false, false, false, true, false,
  )
  let vertex_buffer_layout = @mesh.VertexBufferLayout::new(
    array_stride=12,
    step_mode=@mesh.MeshVertexStepMode::Vertex,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=0,
        format=@mesh.MeshVertexFormat::Float32x3,
        shader_location=0,
      ),
    ],
  )
  let key = @volumetric_fog.VolumetricFogPipelineKey::VolumetricFogPipelineKey(
    mesh_pipeline_view_key=view_key,
    target_format=80U,
    vertex_buffer_layout~,
    has_density_texture=true,
  )
  let pipeline = @volumetric_fog.VolumetricFogPipeline::VolumetricFogPipeline()
  let descriptor = pipeline.specialize(key)
  inspect(
    descriptor.label() == Some("volumetric lighting pipeline"),
    content="true",
  )
  let layout = descriptor.layout()
  inspect(layout.length(), content="2")
  inspect(
    layout[1].label(),
    content="volumetric lighting view bind group layout (density texture, multisampled)",
  )
  let vertex = descriptor.vertex()
  inspect(
    vertex.shader() == Some("pbr/volumetric_fog/volumetric_fog.wgsl"),
    content="true",
  )
  inspect(vertex.entry_point() == None, content="true")
  inspect(vertex.buffers().length(), content="1")
  inspect(vertex.buffers()[0].attributes().length(), content="1")
  inspect(vertex.buffers()[0].attributes()[0].shader_location(), content="0")
  inspect(
    volumetric_fog_test_shader_defs_contain(
      vertex.shader_defs(),
      "SHADOW_FILTER_METHOD_HARDWARE_2X2",
    ),
    content="true",
  )
  inspect(
    volumetric_fog_test_shader_defs_contain(
      vertex.shader_defs(),
      "MULTISAMPLED",
    ),
    content="true",
  )
  inspect(
    volumetric_fog_test_shader_defs_contain(vertex.shader_defs(), "ATMOSPHERE"),
    content="true",
  )
  inspect(
    volumetric_fog_test_shader_defs_contain(
      vertex.shader_defs(),
      "DENSITY_TEXTURE",
    ),
    content="true",
  )
  inspect(
    descriptor.primitive.cull_mode == Some(@wgpu.CULL_MODE_BACK),
    content="true",
  )
  inspect(descriptor.multisample.count(), content="1")
  match descriptor.fragment() {
    Some(fragment) => {
      inspect(
        fragment.shader() == Some("pbr/volumetric_fog/volumetric_fog.wgsl"),
        content="true",
      )
      inspect(fragment.entry_point() == None, content="true")
      let targets = fragment.targets()
      inspect(targets.length(), content="1")
      match targets[0] {
        Some(target) => {
          inspect(target.format(), content="80")
          inspect(target.write_mask(), content="15")
          match target.blend() {
            Some(blend) => {
              inspect(
                blend.color().src_factor() == @wgpu.BLEND_FACTOR_ONE,
                content="true",
              )
              inspect(
                blend.color().dst_factor() ==
                @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                content="true",
              )
              inspect(
                blend.color().operation() == @wgpu.BLEND_OPERATION_ADD,
                content="true",
              )
              inspect(
                blend.alpha().src_factor() == @wgpu.BLEND_FACTOR_ZERO,
                content="true",
              )
              inspect(
                blend.alpha().dst_factor() == @wgpu.BLEND_FACTOR_ONE,
                content="true",
              )
              inspect(
                blend.alpha().operation() == @wgpu.BLEND_OPERATION_ADD,
                content="true",
              )
            }
            None => abort("expected volumetric fog blend state")
          }
        }
        None => abort("expected volumetric fog color target")
      }
    }
    None => abort("expected volumetric fog fragment state")
  }
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
  let view_fog = @volumetric_fog.prepare_volumetric_fog_view_uniforms(
    buffer,
    fog,
    @math.Affine3::identity(),
    volumetric_fog_test_identity_mat4(),
    [(volume, @math.Affine3::identity())],
  )
  inspect(buffer.count(), content="1")
  inspect(view_fog.count(), content="1")
  inspect(view_fog.volumes()[0].exterior(), content="false")
  inspect(view_fog.volumes()[0].has_density_texture(), content="true")
  inspect(buffer.count(), content="1")
  inspect(buffer.bytes().length(), content="512")
}

///|
test "pbr volumetric fog: render-world storage uses typed synced components" {
  let render_world = @ecs.World::new()
  defer render_world.close()
  @volumetric_fog.register_volumetric_fog_render_world_components(render_world)

  let main_view_entity = @core.Entity::new(20, 1)
  let render_view_entity = render_world.spawn()
  try! render_world.set_by_key(
    render_view_entity,
    @render.ecs_key_main_entity,
    @render.MainEntity::new(main_view_entity),
  )
  try! render_world.set_by_key(
    render_view_entity,
    @light.ecs_key_volumetric_fog,
    @light.VolumetricFog::VolumetricFog(),
  )

  let volume_without_transform = render_world.spawn()
  try! render_world.set_by_key(
    volume_without_transform,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(2.0F),
  )

  let main_volume_entity = @core.Entity::new(21, 1)
  let render_volume_entity = render_world.spawn()
  try! render_world.set_by_key(
    render_volume_entity,
    @render.ecs_key_main_entity,
    @render.MainEntity::new(main_volume_entity),
  )
  try! render_world.set_by_key(
    render_volume_entity,
    @light.ecs_key_fog_volume,
    @light.FogVolume::FogVolume().with_density_factor(3.0F),
  )
  try! render_world.set_by_key(
    render_volume_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_translation(@math.Vec3::new(4.0F, 5.0F, 6.0F)),
    ),
  )

  let light_entity = render_world.spawn()
  try! render_world.set_by_key(
    light_entity,
    @light.ecs_key_volumetric_light,
    @light.VolumetricLight::VolumetricLight(),
  )

  let counts = @volumetric_fog.volumetric_fog_render_world_storage_counts(
    render_world,
  )
  inspect(counts.view_count(), content="1")
  inspect(counts.volume_count(), content="2")
  inspect(counts.transformed_volume_count(), content="1")
  inspect(counts.light_count(), content="1")

  match
    @volumetric_fog.volumetric_fog_render_world_entity(
      render_world, render_view_entity,
    ) {
    Some(identity) => {
      inspect(identity.render_entity() == render_view_entity, content="true")
      inspect(identity.main_entity().id() == main_view_entity, content="true")
    }
    None => fail("expected render-world entity identity")
  }

  let volume_inputs = @volumetric_fog.volumetric_fog_render_world_volume_inputs(
    render_world,
  )
  inspect(volume_inputs.length(), content="1")
  inspect(volume_inputs[0].0.density_factor, content="3")
  inspect(volume_inputs[0].1.translation.x, content="-4")
}
