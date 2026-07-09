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
const SHADER_ASSET_PATH : String = "shaders/instancing.wgsl"

///|
const INSTANCE_VERTEX_BUFFER_ID : Int = 1

///|
struct InstanceData {
  position : @math.Vec3
  scale : Float
  color : @color.Color
}

///|
struct InstanceMaterialData {
  instances : Array[InstanceData]
}

///|
fn InstanceMaterialData::clone(
  self : InstanceMaterialData,
) -> InstanceMaterialData {
  InstanceMaterialData::{ instances: self.instances.copy() }
}

///|
struct CustomMaterialPlugin {}

///|
struct CustomPipeline {
  shader : @asset.Handle[@shader.Shader]
}

///|
pub fn CustomPipeline::shader(
  self : CustomPipeline,
) -> @asset.Handle[@shader.Shader] {
  self.shader
}

///|
fn CustomMaterialPlugin::CustomMaterialPlugin() -> CustomMaterialPlugin {
  CustomMaterialPlugin::{  }
}

///|
let custom_pipeline_key : @ecs.ResourceKey[CustomPipeline] = @ecs.register_resource(
  debug_name="examples.shader_advanced.custom_shader_instancing.CustomPipeline",
)

///|
impl @app.Resource for CustomPipeline with fn resource() {
  custom_pipeline_key
}

///|
let instance_material_data_key : @ecs.ComponentKey[InstanceMaterialData] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_shader_instancing.InstanceMaterialData",
)

///|
impl @ecs.Component for InstanceMaterialData with fn component() {
  instance_material_data_key
}

///|
fn instance_data_new(x : Float, y : Float) -> InstanceData {
  InstanceData::{
    position: @math.Vec3::new(x * 10.0F - 5.0F, y * 10.0F - 5.0F, 0.0F),
    scale: 1.0F,
    color: @color.Color::hsla(x * 360.0F, y, 0.5F, 1.0F).as_linear_rgba(),
  }
}

///|
fn instance_material_data() -> InstanceMaterialData {
  let instances : Array[InstanceData] = []
  for x_i in 1..<11 {
    for y_i in 1..<11 {
      instances.push(
        instance_data_new(
          Float::from_int(x_i) / 10.0F,
          Float::from_int(y_i) / 10.0F,
        ),
      )
    }
  }
  InstanceMaterialData::{ instances, }
}

///|
fn f32_bits(value : Float) -> UInt {
  value.reinterpret_as_uint()
}

///|
fn u32le_write(bytes : Array[Byte], byte_offset : Int, word : UInt) -> Unit {
  bytes[byte_offset] = (word & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 1] = ((word >> 8) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 2] = ((word >> 16) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 3] = ((word >> 24) & 0xFFU).reinterpret_as_int().to_byte()
}

///|
fn f32le_write(bytes : Array[Byte], byte_offset : Int, value : Float) -> Unit {
  u32le_write(bytes, byte_offset, f32_bits(value))
}

///|
fn instance_data_bytes(data : InstanceMaterialData) -> Bytes {
  let bytes = Array::make(data.instances.length() * 32, (0).to_byte())
  for index in 0..<data.instances.length() {
    let instance = data.instances[index]
    let base = index * 32
    f32le_write(bytes, base, instance.position.x)
    f32le_write(bytes, base + 4, instance.position.y)
    f32le_write(bytes, base + 8, instance.position.z)
    f32le_write(bytes, base + 12, instance.scale)
    f32le_write(bytes, base + 16, instance.color.r)
    f32le_write(bytes, base + 20, instance.color.g)
    f32le_write(bytes, base + 24, instance.color.b)
    f32le_write(bytes, base + 28, instance.color.a)
  }
  Bytes::from_array(bytes)
}

///|
fn instance_vertex_layout() -> @mesh.VertexBufferLayout {
  @mesh.VertexBufferLayout::new(
    array_stride=32,
    step_mode=@mesh.MeshVertexStepMode::Instance,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=0,
        format=@mesh.MeshVertexFormat::Float32x4,
        shader_location=3,
      ),
      @mesh.VertexAttribute::new(
        offset=16,
        format=@mesh.MeshVertexFormat::Float32x4,
        shader_location=4,
      ),
    ],
  )
}

///|
fn custom_pipeline_specialize(
  _pipeline : String,
  descriptor : @material.RenderPipelineDescriptor,
  layout : @material.MaterialMeshVertexLayout,
  _key : @material.ErasedMaterialPipelineKey,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  if layout.index() < 0 {
    raise @material.missing_vertex_attribute_error(
      "custom instancing mesh layout",
    )
  }
  let buffers = descriptor.vertex.buffers.copy()
  buffers.push(instance_vertex_layout())
  let vertex = @render_resource.VertexState::new(
    Some(SHADER_ASSET_PATH),
    descriptor.vertex.shader_defs,
    Some("vertex"),
    buffers,
  )
  let fragment = match descriptor.fragment {
    Some(fragment) =>
      Some(
        @render_resource.FragmentState::new(
          Some(SHADER_ASSET_PATH),
          fragment.shader_defs,
          Some("fragment"),
          fragment.targets,
        ),
      )
    None => None
  }
  descriptor.with_vertex(vertex).with_fragment(fragment)
}

///|
fn custom_material_metadata() -> @material.ExtendedMaterialMetadata3d {
  @material.ExtendedMaterialMetadata3d::new(1)
  .with_vertex_shader_path(Some(SHADER_ASSET_PATH))
  .with_fragment_shader_path(Some(SHADER_ASSET_PATH))
  .with_alpha_mode_override(Some(@material.AlphaMode3d::Blend))
  .with_disable_shadows(true)
  .with_user_specialize(Some(custom_pipeline_specialize))
}

///|
fn prepare_instance_buffers(
  commands : @app.Commands,
  query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Read[InstanceMaterialData],
      @ecs.Optional[@render.Mesh3dInstanceVertexBufferData],
    ),
    @ecs.All,
  ],
) -> Unit {
  try! query.view(fn(_query_entity, data) {
    let (entity, instance_material, current_buffer) = data
    if !instance_material.is_changed() && current_buffer.value() is Some(_) {
      return
    }
    let value = instance_material.value()
    commands
    .entity(entity)
    .insert_component(
      @render.Mesh3dInstanceVertexBufferData::new(
        buffer_id=INSTANCE_VERTEX_BUFFER_ID,
        bytes=instance_data_bytes(value),
        length=value.instances.length(),
      ),
    )
  })
}

///|
fn init_custom_pipeline(world : @ecs.World) -> Unit {
  let asset_server = match world.get_resource(@asset.AssetServer::resource()) {
    Some(asset_server) => asset_server
    None => abort("custom_shader_instancing: expected AssetServer resource")
  }
  let shader : @asset.Handle[@shader.Shader] = @asset.asset_with_world(world, fn() {
    asset_server.load(SHADER_ASSET_PATH)
  })
  world.insert_resource(CustomPipeline::resource(), CustomPipeline::{ shader, })
}

///|
pub impl @app.Plugin for CustomMaterialPlugin with fn name(_self) {
  "mgstudio.examples.shader_advanced.CustomMaterialPlugin"
}

///|
pub impl @app.Plugin for CustomMaterialPlugin with fn build(_self, app) {
  let extract_plugin : @render.ExtractComponentPlugin[
    InstanceMaterialData,
    Unit,
  ] = @render.ExtractComponentPlugin::ExtractComponentPlugin().with_extract_component(fn(
      value,
    ) {
      value.clone()
    },
  )
  let next = @render.extract_component_plugin_with(app, extract_plugin)
  next
  .add_systems_world(@app.Startup, init_custom_pipeline)
  .add_systems_param2(@app.PostUpdate, prepare_instance_buffers)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_handle = meshes.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(0.5F, 0.5F, 0.5F))
  let material_handle = materials
    .peek()
    .add(@pbr.StandardMaterial::from_color(@color.Color::white()))
  let instance_material = instance_material_data()
  commands.spawn(
    (
      @mesh.Mesh3d::new(mesh_handle),
      @pbr.MeshMaterial3d::new(material_handle).with_extended_material(
        Some(custom_material_metadata()),
      ),
      @transform.Transform::identity(),
      instance_material,
      @visibility.NoFrustumCulling::NoFrustumCulling(),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 15.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      @pbr.NoIndirectDrawing::NoIndirectDrawing(),
    ),
  )
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(CustomMaterialPlugin::CustomMaterialPlugin())
  .add_systems_param3(@app.Startup, setup)
  .run()
}
