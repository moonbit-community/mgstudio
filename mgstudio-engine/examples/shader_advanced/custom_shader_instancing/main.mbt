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
extend CustomPipeline with @app.Resource::{resource}

///|
extend CustomSpecializedMeshPipelines with @app.Resource::{resource}

///|
extend InstanceBuffer with @ecs.Component::{component}

///|
const SHADER_ASSET_PATH : String = "shaders/instancing.wgsl"

///|
const INSTANCE_VERTEX_BUFFER_ID : Int = 1

///|
const DRAW_CUSTOM_LABEL : @material.DrawFunctionLabel = "DrawCustom"

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
  { instances: self.instances.copy() }
}

///|
struct InstanceBuffer {
  buffer_id : Int
  length : Int
}

///|
fn InstanceBuffer::new(buffer_id : Int, length : Int) -> InstanceBuffer {
  { buffer_id, length }
}

///|
struct CustomMaterialPlugin {}

///|
struct CustomPipeline {
  shader : @asset.Handle[@shader.Shader]
  mesh_pipeline : @pbr.MeshPipeline
}

///|
pub fn CustomPipeline::shader(
  self : CustomPipeline,
) -> @asset.Handle[@shader.Shader] {
  self.shader
}

///|
struct CustomSpecializedMeshPipelines {
  pipelines : @material.SpecializedMeshPipelines
}

///|
fn CustomSpecializedMeshPipelines::CustomSpecializedMeshPipelines() -> CustomSpecializedMeshPipelines {
  { pipelines: @material.SpecializedMeshPipelines::new() }
}

///|
#warnings("-unnecessary_annotation")
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
let custom_specialized_mesh_pipelines_key : @ecs.ResourceKey[
  CustomSpecializedMeshPipelines,
] = @ecs.register_resource(
  debug_name="examples.shader_advanced.custom_shader_instancing.SpecializedMeshPipelines<CustomPipeline>",
)

///|
impl @app.Resource for CustomSpecializedMeshPipelines with fn resource() {
  custom_specialized_mesh_pipelines_key
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
let instance_buffer_key : @ecs.ComponentKey[InstanceBuffer] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_shader_instancing.InstanceBuffer",
)

///|
impl @ecs.Component for InstanceBuffer with fn component() {
  instance_buffer_key
}

///|
fn instance_data_new(x : Float, y : Float) -> InstanceData {
  {
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
  { instances, }
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
  @mesh.VertexBufferLayout::new(array_stride=32, step_mode=Instance, attributes=[
    @mesh.VertexAttribute::new(offset=0, format=Float32x4, shader_location=3),
    @mesh.VertexAttribute::new(offset=16, format=Float32x4, shader_location=4),
  ])
}

///|
fn custom_pipeline_override_descriptor(
  descriptor : @material.RenderPipelineDescriptor,
) -> @material.RenderPipelineDescriptor {
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
fn CustomPipeline::specialize(
  self : CustomPipeline,
  key : @material.ErasedMeshPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  custom_pipeline_override_descriptor(
    self.mesh_pipeline.specialize(key, layout),
  )
}

///|
// Bevy source: `DrawMeshInstanced::render`.
fn draw_mesh_instanced(
  world : @ecs.World,
  item : @core_3d.Transparent3d,
) -> @core_3d.Transparent3dRenderCommandResult {
  guard world.get_resource(@render_mesh.RenderMeshAssets::resource())
    is Some(meshes) else {
    return Skip
  }
  guard world.get_resource(@pbr.RenderMeshInstances::resource())
    is Some(render_mesh_instances) else {
    return Skip
  }
  guard world.get_resource(@render_mesh.MeshAllocator::resource())
    is Some(mesh_allocator) else {
    return Skip
  }
  if !world.is_alive(item.entity()) {
    return Skip
  }
  guard (try! world.get_by_key(item.entity(), InstanceBuffer::component()))
    is Some(instance_buffer) else {
    return Skip
  }
  guard render_mesh_instances.render_mesh_queue_data(item.main_entity())
    is Some(mesh_instance) else {
    return Skip
  }
  let mesh_asset_id = mesh_instance.mesh_asset_id()
  guard meshes.get(mesh_asset_id) is Some(mesh) else { return Skip }
  guard mesh_allocator.mesh_vertex_slice(mesh_asset_id) is Some(_) else {
    return Skip
  }
  match mesh.buffer_info() {
    Indexed(_, _) => {
      guard mesh_allocator.mesh_index_slice(mesh_asset_id) is Some(_) else {
        return Skip
      }
    }
    NonIndexed => ()
  }
  if instance_buffer.length == 0 {
    return Success
  }
  guard world.get_resource(@pbr_render.Render3dMeshRuntimeState::resource())
    is Some(mesh_runtime_state) else {
    return Skip
  }
  guard @pbr_render.render3d_uploaded_mesh_id(mesh_runtime_state, mesh_asset_id)
    is Some(mesh_id) else {
    return Skip
  }
  let world_from_local = @pbr.get_mesh_instance_world_from_local(
    item.main_entity(),
    mesh_instance.current_uniform_index(),
    render_mesh_instances,
    world.get_resource(
      @pbr.RenderMeshInstanceGpuBatchedInstanceBuffers::resource(),
    ),
  )
  @pbr_render.render3d_draw_mesh_instanced(
    mesh_id~,
    pipeline=item.pipeline(),
    instance_vertex_buffer_id=instance_buffer.buffer_id,
    world_from_local~,
  )
  Success
}

///|
fn queue_custom(world : @ecs.World) -> Unit {
  guard world.get_resource(@core_3d.Transparent3dDrawFunctions::resource())
    is Some(draw_functions) else {
    return
  }
  guard draw_functions.id(DRAW_CUSTOM_LABEL) is Some(draw_custom) else {
    return
  }
  guard world.get_resource(CustomPipeline::resource()) is Some(custom_pipeline) else {
    return
  }
  guard world.get_resource(CustomSpecializedMeshPipelines::resource())
    is Some(specialized_pipelines) else {
    return
  }
  guard world.get_resource(@render.pipeline_cache_resource_key)
    is Some(pipeline_cache) else {
    return
  }
  guard world.get_resource(@render_mesh.RenderMeshAssets::resource())
    is Some(meshes) else {
    return
  }
  guard world.get_resource(@pbr.RenderMeshInstances::resource())
    is Some(render_mesh_instances) else {
    return
  }
  guard world.get_resource(@core_3d.Transparent3dPhase::resource())
    is Some(transparent_render_phases) else {
    return
  }
  guard world.get_resource(@pbr.ViewKeyCache::resource())
    is Some(view_key_cache) else {
    return
  }
  let maybe_batched_instance_buffers = world.get_resource(
    @pbr.RenderMeshInstanceGpuBatchedInstanceBuffers::resource(),
  )
  let material_meshes : @ecs.Query[
    (
      @core.Entity,
      @ecs.Read[@render.MainEntity],
      @ecs.Read[InstanceMaterialData],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  let views : @ecs.Query[@ecs.Read[@render_view.ExtractedView], @ecs.All] = @ecs.query(
    world,
  )
  try! views.view(fn(_view_entity, extracted_view_ref) {
    let retained_view_entity = extracted_view_ref.value().retained_view_entity()
    guard transparent_render_phases.view(retained_view_entity) is Some(_) else {
      return
    }
    guard view_key_cache.get(retained_view_entity) is Some(view_key) else {
      return
    }
    try! material_meshes.view(fn(_query_entity, data) {
      let (entity, main_entity_ref, _instance_material_data) = data
      let main_entity = main_entity_ref.value()
      guard render_mesh_instances.render_mesh_queue_data(main_entity)
        is Some(mesh_instance) else {
        return
      }
      guard meshes.get(mesh_instance.mesh_asset_id()) is Some(mesh) else {
        return
      }
      let mesh_key = @material.ErasedMeshPipelineKey::new(
        view_key.bits() | mesh.key_bits().bits(),
        "MeshPipelineKey",
      )
      let key = @material.ErasedMaterialPipelineKey::new(
        mesh_key,
        @material.ErasedMaterialKey::new(0UL, "CustomPipeline"),
        "CustomPipeline",
      )
      let pipeline = specialized_pipelines.pipelines.specialize(
        pipeline_cache,
        fn(key, layout) raise @material.SpecializedMeshPipelineError {
          custom_pipeline.specialize(key.mesh_key(), layout)
        },
        key,
        mesh.layout(),
      ) catch {
        _ =>
          abort("custom_shader_instancing: failed to specialize CustomPipeline")
      }
      let mesh_center = @pbr.get_mesh_instance_world_from_local(
        main_entity,
        mesh_instance.current_uniform_index(),
        render_mesh_instances,
        maybe_batched_instance_buffers,
      ).transform_point3(mesh.aabb_center())
      transparent_render_phases.add(
        retained_view_entity,
        @core_3d.Transparent3d::new(
          sorting_info=@core_3d.TransparentSortingInfo3d::sorted(
            mesh_center~,
            depth_bias=0.0F,
          ),
          distance=0.0F,
          pipeline~,
          entity~,
          main_entity~,
          draw_function=draw_custom,
          batch_range_start=0,
          batch_range_end=1,
          extra_index=0,
          indexed=true,
        ),
      )
    })
  })
}

///|
fn prepare_instance_buffers(world : @ecs.World) -> Unit {
  let query : @ecs.Query[
    (@core.Entity, @ecs.Read[InstanceMaterialData]),
    @ecs.All,
  ] = @ecs.query(world)
  let prepared : Array[(@core.Entity, Bytes, Int)] = []
  try! query.view(fn(_query_entity, data) {
    let (entity, instance_material) = data
    let value = instance_material.value()
    prepared.push(
      (entity, instance_data_bytes(value), value.instances.length()),
    )
  })
  for entry in prepared {
    let (entity, bytes, length) = entry
    @render.host_gpu_prepare_mesh3d_instance_vertex_buffer(
      buffer_id=INSTANCE_VERTEX_BUFFER_ID,
      bytes~,
      length~,
    )
    world.set_by_key(
      entity,
      InstanceBuffer::component(),
      InstanceBuffer::new(INSTANCE_VERTEX_BUFFER_ID, length),
    ) catch {
      _ => abort("custom_shader_instancing: failed to insert InstanceBuffer")
    }
  }
}

///|
fn init_custom_pipeline(world : @ecs.World) -> Unit {
  let asset_server = match world.get_resource(@asset.AssetServer::resource()) {
    Some(asset_server) => asset_server
    None => abort("custom_shader_instancing: expected AssetServer resource")
  }
  let shader : @asset.Handle[@shader.Shader] = asset_server.load(
    SHADER_ASSET_PATH,
  )
  let mesh_pipeline = match world.get_resource(@pbr.MeshPipeline::resource()) {
    Some(mesh_pipeline) => mesh_pipeline
    None => abort("custom_shader_instancing: expected MeshPipeline resource")
  }
  world.insert_resource(CustomPipeline::resource(), { shader, mesh_pipeline })
}

///|
fn register_custom_shader_source(world : @ecs.World) -> Unit {
  @shader_runtime_render.shader_register_wgsl_runtime_source(
    @render.render_source_world(world),
    SHADER_ASSET_PATH,
  )
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
  @render.with_render_app(next, fn(render_app) {
    let render_world = render_app.world()
    let draw_functions = match
      render_world.get_resource(@core_3d.Transparent3dDrawFunctions::resource()) {
      Some(draw_functions) => draw_functions
      None => {
        let draw_functions = @core_3d.Transparent3dDrawFunctions::Transparent3dDrawFunctions()
        render_world.insert_resource(
          @core_3d.Transparent3dDrawFunctions::resource(),
          draw_functions,
        )
        draw_functions
      }
    }
    ignore(draw_functions.register(DRAW_CUSTOM_LABEL, draw_mesh_instanced))
    if render_world.get_resource(CustomSpecializedMeshPipelines::resource())
      is None {
      render_world.insert_resource(
        CustomSpecializedMeshPipelines::resource(),
        CustomSpecializedMeshPipelines(),
      )
    }
    render_app
    .add_systems(
      @render.render_startup_schedule_stage(),
      @app.system(init_custom_pipeline)
      .named("custom_shader_instancing::init_custom_pipeline")
      .after("mgstudio_pbr::init_mesh_pipeline"),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(register_custom_shader_source)
      .named("custom_shader_instancing::register_custom_shader_source")
      .in_set(@render.render_system_set_prepare_assets),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(queue_custom)
      .named("custom_shader_instancing::queue_custom")
      .in_set(@render.render_system_set_queue_meshes),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(prepare_instance_buffers)
      .named("custom_shader_instancing::prepare_instance_buffers")
      .in_set(@render.render_system_set_prepare_resources),
    )
  })
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  let mesh_handle = meshes.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(0.5F, 0.5F, 0.5F))
  let instance_material = instance_material_data()
  commands.spawn(
    (
      @mesh.Mesh3d::new(mesh_handle),
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
  .add_systems_param2(Startup, setup)
  .run()
}
