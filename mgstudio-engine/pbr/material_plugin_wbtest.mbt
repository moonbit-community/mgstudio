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
struct ParityCustomMaterial {
  color : Bytes
  texture : @asset.Handle[@asset.Image]?
  opaque_render_method : @material.OpaqueRendererMethod
}

///|
fn ParityCustomMaterial::ParityCustomMaterial() -> ParityCustomMaterial {
  ParityCustomMaterial::{
    color: Bytes::makei(4, fn(index) { (index + 1).to_byte() }),
    texture: Some(@asset.Handle::new(9)),
    opaque_render_method: @material.OpaqueRendererMethod::Forward,
  }
}

///|
fn ParityCustomMaterial::with_opaque_render_method(
  self : ParityCustomMaterial,
  opaque_render_method : @material.OpaqueRendererMethod,
) -> ParityCustomMaterial {
  ParityCustomMaterial::{ ..self, opaque_render_method, }
}

///|
impl @asset.Asset for ParityCustomMaterial with fn asset_debug_name() {
  "mgstudio_pbr_test::ParityCustomMaterial"
}

///|
impl @asset.Asset for ParityCustomMaterial with fn asset_as_image(_self) {
  None
}

///|
let parity_custom_material_asset_keys : @asset.AssetResourceKeys[
  ParityCustomMaterial,
] = @asset.register_asset_resource_keys(
  ParityCustomMaterial::asset_debug_name(),
)

///|
impl @asset.Asset for ParityCustomMaterial with fn asset_resource_keys() {
  parity_custom_material_asset_keys
}

///|
let parity_custom_material_keys : MaterialKeys[ParityCustomMaterial] = register_material_keys(
  ParityCustomMaterial::asset_debug_name(),
)

///|
impl Material for ParityCustomMaterial with fn material_debug_name() {
  "mgstudio_pbr_test::ParityCustomMaterial"
}

///|
impl Material for ParityCustomMaterial with fn material_keys() {
  parity_custom_material_keys
}

///|
impl Material for ParityCustomMaterial with fn vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ParityCustomMaterial with fn fragment_shader() {
  Some("shaders/tonemapping_test_patterns.wgsl")
}

///|
impl Material for ParityCustomMaterial with fn prepass_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ParityCustomMaterial with fn prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn deferred_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ParityCustomMaterial with fn deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn meshlet_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn meshlet_prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn meshlet_deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ParityCustomMaterial with fn register_shader_sources() {
  material_default_register_shader_sources()
}

///|
impl Material for ParityCustomMaterial with fn alpha_mode(self) {
  ignore(self)
  material_default_alpha_mode()
}

///|
impl Material for ParityCustomMaterial with fn opaque_render_method(self) {
  self.opaque_render_method
}

///|
impl Material for ParityCustomMaterial with fn depth_bias(self) {
  ignore(self)
  material_default_depth_bias()
}

///|
impl Material for ParityCustomMaterial with fn reads_view_transmission_texture(
  self,
) {
  ignore(self)
  material_default_reads_view_transmission_texture()
}

///|
impl Material for ParityCustomMaterial with fn draw_data(self) {
  ignore(self)
  material_default_draw_data()
}

///|
impl Material for ParityCustomMaterial with fn material_extension_metadata(self) {
  ignore(self)
  None
}

///|
impl Material for ParityCustomMaterial with fn enable_prepass() {
  material_default_enable_prepass()
}

///|
impl Material for ParityCustomMaterial with fn enable_shadows() {
  material_default_enable_shadows()
}

///|
impl Material for ParityCustomMaterial with fn bindless_supported(render_device) {
  material_default_bindless_supported(render_device)
}

///|
impl Material for ParityCustomMaterial with fn bindless_slot_count() {
  material_default_bindless_slot_count()
}

///|
impl Material for ParityCustomMaterial with fn bind_group(self, context) {
  ignore(context)
  MaterialBindGroup::new([
    MaterialBinding::uniform(0, self.color),
    MaterialBinding::texture(1, self.texture),
    MaterialBinding::sampler(2, self.texture),
  ])
}

///|
impl Material for ParityCustomMaterial with fn bind_group_layout_descriptor(
  self,
  context,
) {
  self
  .bind_group(context)
  .layout_descriptor("mgstudio_pbr_test::ParityCustomMaterialLayout")
}

///|
impl Material for ParityCustomMaterial with fn bind_group_data(self) {
  ignore(self)
  MaterialBindGroupKey::from_bytes(
    @utf8.encode("parity_custom_material_pipeline_key"),
  )
}

///|
impl Material for ParityCustomMaterial with fn renderer_extra_bind_group_data(
  self,
  context,
) {
  material_default_renderer_extra_bind_group_data(self, context)
}

///|
impl Material for ParityCustomMaterial with fn material_key(self) {
  material_default_material_key(self)
}

///|
impl Material for ParityCustomMaterial with fn specialize(
  descriptor,
  layout,
  key,
) {
  material_default_specialize(descriptor, layout, key)
}

///|
test "pbr material plugin: typed bind group owns uniform texture and sampler bindings" {
  let material = ParityCustomMaterial::ParityCustomMaterial()
  let bind_group = material.bind_group(
    MaterialBindGroupContext::MaterialBindGroupContext(),
  )
  inspect(
    bind_group.layout_key(),
    content="0:uniform;1:texture(float,2d);2:sampler",
  )
  inspect(
    bind_group.bind_group_data().debug_string(),
    content="0:uniform(len=4:1,2,3,4);1:texture(9,float,2d);2:sampler(9)",
  )
  let resolved = bind_group.resolved_data().entries()
  inspect(resolved.length(), content="3")
  debug_inspect(
    match resolved[0].resource() {
      @render_resource.MaterialBindGroupResolvedResource::Uniform(bytes) =>
        bytes.length() == 4
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match resolved[1].resource() {
      @render_resource.MaterialBindGroupResolvedResource::Texture(9) => true
      _ => false
    },
    content="true",
  )
  debug_inspect(
    match resolved[2].resource() {
      @render_resource.MaterialBindGroupResolvedResource::Sampler(9) => true
      _ => false
    },
    content="true",
  )
}

///|
test "pbr material plugin: prepared material carries shader hooks and typed bindings" {
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material = ParityCustomMaterial::ParityCustomMaterial()
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(7),
    material,
    material_pipeline_from_material_hooks(probe),
    @material.OpaqueRendererMethod::Forward,
  )
  debug_inspect(
    prepared.properties().get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"shaders/tonemapping_test_patterns.wgsl\")",
  )
  debug_inspect(
    prepared.material_draw_data() is MaterialDrawData3d::Custom,
    content="true",
  )
  inspect(
    prepared.properties().material_key.type_tag(),
    content="MaterialKey<mgstudio_pbr_test::ParityCustomMaterial>",
  )
  inspect(prepared.bind_group_data().entries().length(), content="3")
}

///|
test "pbr material plugin: prepared material uses material layout descriptor hook" {
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(7),
    ParityCustomMaterial::ParityCustomMaterial(),
    material_pipeline_from_material_hooks(probe),
    @material.OpaqueRendererMethod::Forward,
  )
  guard prepared.properties().material_layout is Some(layout) else {
    abort("missing prepared material layout")
  }
  inspect(
    layout.label(),
    content="mgstudio_pbr_test::ParityCustomMaterialLayout",
  )
}

///|
test "pbr material plugin: prepared material uses material bind group data hook" {
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material = ParityCustomMaterial::ParityCustomMaterial()
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(7),
    material,
    material_pipeline_from_material_hooks(probe),
    @material.OpaqueRendererMethod::Forward,
  )
  inspect(
    material
    .bind_group(MaterialBindGroupContext::MaterialBindGroupContext())
    .bind_group_data()
    .debug_string(),
    content="0:uniform(len=4:1,2,3,4);1:texture(9,float,2d);2:sampler(9)",
  )
  inspect(
    material.bind_group_data().debug_string(),
    content="parity_custom_material_pipeline_key",
  )
  inspect(
    prepared.key.bind_group_data().debug_string(),
    content="parity_custom_material_pipeline_key",
  )
  inspect(
    prepared.properties().material_key.bits() ==
    material_default_material_key(material).bits(),
    content="true",
  )
}

///|
test "pbr material plugin: prepared material resolves auto renderer method from default resource value" {
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material = ParityCustomMaterial::ParityCustomMaterial().with_opaque_render_method(
    @material.OpaqueRendererMethod::Auto,
  )
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(8),
    material,
    material_pipeline_from_material_hooks(probe),
    @material.OpaqueRendererMethod::Deferred,
  )
  debug_inspect(
    match prepared.properties().render_method {
      @material.OpaqueRendererMethod::Deferred => true
      _ => false
    },
    content="true",
  )
}

///|
test "pbr material plugin: prepared typed material carries bevy draw functions" {
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(9),
    ParityCustomMaterial::ParityCustomMaterial(),
    material_pipeline_from_material_hooks(probe),
    @material.OpaqueRendererMethod::Deferred,
  )
  let properties = prepared.properties()
  debug_inspect(
    properties
    .get_draw_function(DEFERRED_OPAQUE_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(7)",
  )
  debug_inspect(
    properties
    .get_draw_function(PREPASS_OPAQUE_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(4)",
  )
  debug_inspect(
    properties
    .get_draw_function(SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL)
    .map(fn(id) { id.id() }),
    content="Some(10)",
  )
}

///|
test "pbr material plugin: prepared custom material can specialize a mesh pipeline" {
  let world = @ecs.World::new()
  let pipeline_cache = @render_resource.PipelineCache::new()
  world.insert_resource(@render.pipeline_cache_resource_key, pipeline_cache)
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material = ParityCustomMaterial::ParityCustomMaterial()
  let prepared = PreparedMaterial::from_material(
    @asset.Handle::new(7),
    material,
    material_pipeline_from_material_hooks(probe),
    @material.OpaqueRendererMethod::Forward,
  )
  let properties = prepared.properties()
  guard properties.base_specialize is Some(base_specialize) else {
    abort("expected prepared custom material to carry Bevy base_specialize")
  }
  let render_mesh = pbr_material_specializer_test_render_mesh()
  let key = @material.ErasedMaterialPipelineKey::new(
    properties.mesh_pipeline_key_bits,
    properties.material_key,
    ParityCustomMaterial::material_debug_name(),
  )
  let pipeline_id = try! @material.material_specialize_base(
    base_specialize,
    world,
    key,
    render_mesh.layout(),
    properties,
  )
  pipeline_cache.process_queue()
  let descriptor = try! pipeline_cache.get_render_pipeline_descriptor(
    pipeline_id,
  )
  inspect(descriptor.layout.length(), content="4")
  inspect(
    descriptor.layout[3].label(),
    content="mgstudio_pbr_test::ParityCustomMaterialLayout",
  )
  inspect(descriptor.layout[3].entries().length(), content="3")
  inspect(descriptor.layout[3].entries()[0].binding(), content="0")
  debug_inspect(
    pbr_material_specializer_shader_defs_contain_uint(
      descriptor.vertex.shader_defs,
      "MATERIAL_BIND_GROUP",
      MATERIAL_BIND_GROUP_INDEX.reinterpret_as_uint(),
    ),
    content="true",
  )
  match descriptor.fragment {
    Some(fragment) =>
      debug_inspect(
        fragment.shader,
        content="Some(\"shaders/tonemapping_test_patterns.wgsl\")",
      )
    None => abort("expected prepared custom material fragment state")
  }
}

///|
test "pbr material plugin: plugin registers assets typed component and render resources" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial::ParityCustomMaterial()
    },
  )
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
  let main_assets_key : @ecs.ResourceKey[@asset.Assets[ParityCustomMaterial]] = @asset.assets_resource_key()
  let render_pipeline_key : @ecs.ResourceKey[
    MaterialPipeline[ParityCustomMaterial],
  ] = MaterialPipeline::resource()
  let render_instances_key : @ecs.ResourceKey[
    RenderMaterial3dInstances[ParityCustomMaterial],
  ] = RenderMaterial3dInstances::resource()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ParityCustomMaterial]],
  ] = @render.RenderAssets::resource()
  let component_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let render_world = app.sub_app(@app.RenderApp).world()
  debug_inspect(app.contains_resource(main_assets_key), content="true")
  debug_inspect(
    render_world.get_resource(render_pipeline_key) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(render_instances_key) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(prepared_assets_key) is Some(_),
    content="true",
  )
  inspect(
    component_key.debug_name(),
    content="mgstudio_pbr::MeshMaterial3d<mgstudio_pbr_test::ParityCustomMaterial>",
  )
}

///|
test "pbr material plugin: render startup installs typed bind group allocator" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial::ParityCustomMaterial()
    },
  )
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
  let render_sub_app = app
    .sub_app(@app.RenderApp)
    .set_update_schedule(Some(@render.render_startup_schedule_stage()))
  let render_world = render_sub_app.world()
  debug_inspect(
    render_world.resource(ecs_key_material_bind_group_allocators).is_present(),
    content="false",
  )
  ignore(render_sub_app.run_startup())
  match render_world.get_resource(ecs_key_material_bind_group_allocators) {
    Some(allocators) => {
      debug_inspect(
        allocators.contains("mgstudio_pbr_test::ParityCustomMaterial"),
        content="true",
      )
      match allocators.get("mgstudio_pbr_test::ParityCustomMaterial") {
        Some(MaterialBindGroupAllocator::NonBindless(_)) =>
          debug_inspect(true, content="true")
        _ => debug_inspect(false, content="true")
      }
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "pbr material plugin: typed material extraction fills Bevy render material tables" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  world.insert_resource(@asset.assets_resource_key(), material_assets)
  ensure_prepared_material_assets_resource_in_world(world, probe)
  ensure_material_pipeline_resource_in_world(
    world,
    material_pipeline_from_material_hooks(probe),
  )
  ensure_render_material_instances_resource_in_world(world, probe)
  world.insert_resource(
    ecs_key_render_material_instances,
    RenderMaterialInstances::RenderMaterialInstances(),
  )
  world.insert_resource(
    RenderMaterialBindings::resource(),
    RenderMaterialBindings::RenderMaterialBindings(),
  )
  let allocators = MaterialBindGroupAllocators::MaterialBindGroupAllocators()
  allocators.insert(
    ParityCustomMaterial::material_debug_name(),
    MaterialBindGroupAllocator::Bindless(
      MaterialBindGroupBindlessAllocator::with_slab_capacity(4),
    ),
  )
  world.insert_resource(ecs_key_material_bind_group_allocators, allocators)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    MeshMaterial3dTyped::component(),
    MeshMaterial3dTyped::new(material_handle),
  )
  world.increment_change_tick() |> ignore
  extract_mesh_materials_system(world, probe)
  match world.get_resource(ecs_key_render_material_shader_paths) {
    Some(paths) => {
      let shader_paths = paths.paths()
      debug_inspect(
        shader_paths.contains("shaders/tonemapping_test_patterns.wgsl"),
        content="true",
      )
    }
    None => abort("missing RenderMaterialShaderPaths")
  }
  prepare_material_assets_system(world, probe)
  match world.get_resource(ecs_key_render_material_instances) {
    Some(instances) =>
      match instances.get(entity) {
        Some(instance) =>
          debug_inspect(instance.asset_id(), content="\{material_handle.id()}")
        None =>
          abort("typed material was not inserted into RenderMaterialInstances")
      }
    None => abort("missing RenderMaterialInstances")
  }
  match world.get_resource(RenderMaterialBindings::resource()) {
    Some(bindings) =>
      match bindings.get(material_handle.id()) {
        Some(binding) => {
          debug_inspect(binding.group().to_int(), content="0")
          debug_inspect(binding.slot().to_int(), content="0")
        }
        None => abort("typed material binding was not allocated")
      }
    None => abort("missing RenderMaterialBindings")
  }
}

///|
test "pbr material plugin: removed typed material unloads prepared binding" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  world.insert_resource(@asset.assets_resource_key(), material_assets)
  @asset.asset_update_event_messages(world)
  ensure_prepared_material_assets_resource_in_world(world, probe)
  ensure_material_pipeline_resource_in_world(
    world,
    material_pipeline_from_material_hooks(probe),
  )
  ensure_render_material_instances_resource_in_world(world, probe)
  ensure_material_asset_event_cursor_resource_in_world(world, probe)
  world.insert_resource(
    ecs_key_render_material_instances,
    RenderMaterialInstances::RenderMaterialInstances(),
  )
  world.insert_resource(
    RenderMaterialBindings::resource(),
    RenderMaterialBindings::RenderMaterialBindings(),
  )
  let allocators = MaterialBindGroupAllocators::MaterialBindGroupAllocators()
  allocators.insert(
    ParityCustomMaterial::material_debug_name(),
    MaterialBindGroupAllocator::Bindless(
      MaterialBindGroupBindlessAllocator::with_slab_capacity(4),
    ),
  )
  world.insert_resource(ecs_key_material_bind_group_allocators, allocators)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    MeshMaterial3dTyped::component(),
    MeshMaterial3dTyped::new(material_handle),
  )
  world.increment_change_tick() |> ignore
  extract_mesh_materials_system(world, probe)
  prepare_material_assets_system(world, probe)
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ParityCustomMaterial]],
  ] = @render.RenderAssets::resource()
  match world.get_resource(prepared_assets_key) {
    Some(prepared_assets) =>
      debug_inspect(
        prepared_assets.contains(material_handle.id()),
        content="true",
      )
    None => abort("missing prepared material assets")
  }
  match world.get_resource(RenderMaterialBindings::resource()) {
    Some(bindings) => debug_inspect(bindings.len(), content="1")
    None => abort("missing RenderMaterialBindings")
  }
  match world.get_resource(ecs_key_material_bind_group_allocators) {
    Some(allocators) =>
      match allocators.get(ParityCustomMaterial::material_debug_name()) {
        Some(allocator) => debug_inspect(allocator.allocations(), content="1")
        None => abort("missing material bind group allocator")
      }
    None => abort("missing MaterialBindGroupAllocators")
  }
  match world.get_resource_mut(@asset.assets_resource_key()) {
    Some(assets) =>
      assets.modify(fn(value) { ignore(value.remove(material_handle)) })
    None => abort("missing material assets")
  }
  @asset.asset_update_event_messages(world)
  dirty_specializations_mut_or_init(world).modify(fn(value) { value.clear() })
  prepare_material_assets_system(world, probe)
  match world.get_resource(prepared_assets_key) {
    Some(prepared_assets) =>
      debug_inspect(
        prepared_assets.contains(material_handle.id()),
        content="false",
      )
    None => abort("missing prepared material assets")
  }
  match world.get_resource(RenderMaterialBindings::resource()) {
    Some(bindings) => debug_inspect(bindings.len(), content="0")
    None => abort("missing RenderMaterialBindings")
  }
  match world.get_resource(ecs_key_material_bind_group_allocators) {
    Some(allocators) =>
      match allocators.get(ParityCustomMaterial::material_debug_name()) {
        Some(allocator) => debug_inspect(allocator.allocations(), content="0")
        None => abort("missing material bind group allocator")
      }
    None => abort("missing MaterialBindGroupAllocators")
  }
  match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(dirty) => {
      debug_inspect(dirty.changed_len(), content="1")
      debug_inspect(
        dirty.changed_contains(@render.MainEntity::new(entity)),
        content="true",
      )
    }
    None => abort("missing DirtySpecializations")
  }
}

///|
test "pbr material plugin: typed material removal sweeps Bevy render material tables" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  world.insert_resource(@asset.assets_resource_key(), material_assets)
  ensure_render_material_instances_resource_in_world(world, probe)
  world.insert_resource(
    ecs_key_render_material_instances,
    RenderMaterialInstances::RenderMaterialInstances(),
  )
  let typed_instances_key : @ecs.ResourceKey[
    RenderMaterial3dInstances[ParityCustomMaterial],
  ] = RenderMaterial3dInstances::resource()
  let material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    material_key,
    MeshMaterial3dTyped::new(material_handle),
  )
  world.increment_change_tick() |> ignore
  extract_mesh_materials_system(world, probe)
  match world.get_resource(typed_instances_key) {
    Some(instances) =>
      debug_inspect(instances.get(entity) is Some(_), content="true")
    None => abort("missing typed RenderMaterial3dInstances")
  }
  match world.get_resource(ecs_key_render_material_instances) {
    Some(instances) =>
      debug_inspect(instances.get(entity) is Some(_), content="true")
    None => abort("missing RenderMaterialInstances")
  }
  late_sweep_material_instances(world)

  world.increment_change_tick() |> ignore
  ignore(try! world.remove_by_key(entity, material_key))
  world.increment_change_tick() |> ignore
  early_sweep_material_instances_system(world, probe)

  match world.get_resource(typed_instances_key) {
    Some(instances) =>
      debug_inspect(instances.get(entity) is None, content="true")
    None => abort("missing typed RenderMaterial3dInstances")
  }
  match world.get_resource(ecs_key_render_material_instances) {
    Some(instances) =>
      debug_inspect(instances.get(entity) is None, content="true")
    None => abort("missing RenderMaterialInstances")
  }
}

///|
test "pbr material plugin: typed material extraction marks specialization dirty" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  world.insert_resource(@asset.assets_resource_key(), material_assets)
  ensure_render_material_instances_resource_in_world(world, probe)
  world.insert_resource(
    ecs_key_render_material_instances,
    RenderMaterialInstances::RenderMaterialInstances(),
  )
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(3)),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    MeshMaterial3dTyped::component(),
    MeshMaterial3dTyped::new(material_handle),
  )
  world.increment_change_tick() |> ignore
  let material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let system_ticks = @core.SystemTicks::new(0, world.read_change_tick())
  debug_inspect(
    world.changed_components(@mesh.ecs_key_mesh3d, system_ticks).len(),
    content="1",
  )
  debug_inspect(
    world.changed_components(material_key, system_ticks).len(),
    content="1",
  )
  debug_inspect(
    collect_entities_needing_typed_material_specialization(
      world, material_key, system_ticks,
    ).length(),
    content="1",
  )
  ensure_entities_needing_specialization_resource_in_world(world, probe)
  let entities_needing_specialization_key : @ecs.ResourceKey[
    EntitiesNeedingSpecialization[ParityCustomMaterial],
  ] = EntitiesNeedingSpecialization::resource()
  match world.get_resource_mut(entities_needing_specialization_key) {
    Some(entities) =>
      entities.modify(fn(value) {
        check_typed_entities_needing_specialization_from_world(
          world, material_key, value, system_ticks,
        )
      })
    None => abort("missing EntitiesNeedingSpecialization")
  }
  match world.get_resource(entities_needing_specialization_key) {
    Some(entities) => {
      debug_inspect(entities.changed_len(), content="1")
      debug_inspect(entities.changed_contains(entity), content="true")
    }
    None => abort("missing EntitiesNeedingSpecialization")
  }
  extract_mesh_materials_system(world, probe)
  extract_typed_entities_needs_specialization_system(world, probe)
  match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(dirty) => {
      debug_inspect(dirty.changed_len(), content="1")
      debug_inspect(
        dirty.changed_contains(@render.MainEntity::new(entity)),
        content="true",
      )
    }
    None => abort("missing DirtySpecializations")
  }
}

///|
test "pbr material plugin: typed specialization collector ignores despawned mesh changes" {
  let world = @ecs.World::new()
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(4)),
  )
  let material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  try! world.set_by_key(
    entity,
    material_key,
    MeshMaterial3dTyped::new(material_handle),
  )
  ignore(try! world.despawn(entity))

  let changed = collect_entities_needing_typed_material_specialization(
    world,
    material_key,
    @core.SystemTicks::new(0, world.read_change_tick()),
  )
  debug_inspect(changed.length(), content="0")
}

///|
test "pbr material plugin: first prepared typed material marks specialization dirty" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  world.insert_resource(@asset.assets_resource_key(), material_assets)
  ensure_prepared_material_assets_resource_in_world(world, probe)
  ensure_material_pipeline_resource_in_world(
    world,
    material_pipeline_from_material_hooks(probe),
  )
  ensure_render_material_instances_resource_in_world(world, probe)
  world.insert_resource(
    ecs_key_render_material_instances,
    RenderMaterialInstances::RenderMaterialInstances(),
  )
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    MeshMaterial3dTyped::component(),
    MeshMaterial3dTyped::new(material_handle),
  )
  world.increment_change_tick() |> ignore
  extract_mesh_materials_system(world, probe)
  dirty_specializations_mut_or_init(world).modify(fn(value) { value.clear() })
  prepare_material_assets_system(world, probe)
  match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(dirty) => {
      debug_inspect(dirty.changed_len(), content="1")
      debug_inspect(
        dirty.changed_contains(@render.MainEntity::new(entity)),
        content="true",
      )
    }
    None => abort("missing DirtySpecializations")
  }
}

///|
test "pbr material plugin: changed typed material asset marks specialization dirty once" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  world.insert_resource(@asset.assets_resource_key(), material_assets)
  @asset.asset_update_event_messages(world)
  ensure_prepared_material_assets_resource_in_world(world, probe)
  ensure_material_pipeline_resource_in_world(
    world,
    material_pipeline_from_material_hooks(probe),
  )
  ensure_render_material_instances_resource_in_world(world, probe)
  ensure_material_asset_event_cursor_resource_in_world(world, probe)
  world.insert_resource(
    ecs_key_render_material_instances,
    RenderMaterialInstances::RenderMaterialInstances(),
  )
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! world.set_by_key(
    entity,
    MeshMaterial3dTyped::component(),
    MeshMaterial3dTyped::new(material_handle),
  )
  world.increment_change_tick() |> ignore
  extract_mesh_materials_system(world, probe)
  prepare_material_assets_system(world, probe)
  dirty_specializations_mut_or_init(world).modify(fn(value) { value.clear() })
  prepare_material_assets_system(world, probe)
  match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(dirty) => debug_inspect(dirty.changed_len(), content="0")
    None => abort("missing DirtySpecializations")
  }
  match world.get_resource_mut(@asset.assets_resource_key()) {
    Some(assets) =>
      assets.modify(fn(value) {
        ignore(
          value.set(material_handle, ParityCustomMaterial::{
            color: Bytes::makei(4, fn(index) { (index + 5).to_byte() }),
            texture: Some(@asset.Handle::new(11)),
            opaque_render_method: @material.OpaqueRendererMethod::Forward,
          }),
        )
      })
    None => abort("missing material assets")
  }
  @asset.asset_update_event_messages(world)
  prepare_material_assets_system(world, probe)
  match
    world.get_resource(@render_visibility.DirtySpecializations::resource()) {
    Some(dirty) => {
      debug_inspect(dirty.changed_len(), content="1")
      debug_inspect(
        dirty.changed_contains(@render.MainEntity::new(entity)),
        content="true",
      )
    }
    None => abort("missing DirtySpecializations")
  }
}

///|
test "pbr material plugin: typed extraction writes resolved material slots" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material_assets : @asset.Assets[ParityCustomMaterial] = @asset.Assets::new()
  let material_handle = material_assets.add(
    ParityCustomMaterial::ParityCustomMaterial(),
  )
  world.insert_resource(@asset.assets_resource_key(), material_assets)
  ensure_prepared_material_assets_resource_in_world(world, probe)
  ensure_material_pipeline_resource_in_world(
    world,
    material_pipeline_from_material_hooks(probe),
  )
  ensure_render_material_instances_resource_in_world(world, probe)
  ensure_render_material3d_resolved_slots_resource_in_world(world)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    MeshMaterial3dTyped::component(),
    MeshMaterial3dTyped::new(material_handle),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  world.increment_change_tick() |> ignore
  extract_mesh_materials_system(world, probe)
  match world.get_resource(RenderMaterial3dResolvedSlots::resource()) {
    Some(slots) =>
      debug_inspect(slots.get(entity) is Some(Pending), content="true")
    None => abort("missing RenderMaterial3dResolvedSlots")
  }
  prepare_material_assets_system(world, probe)
  let slots = match
    world.get_resource(RenderMaterial3dResolvedSlots::resource()) {
    Some(value) => value
    None => abort("missing RenderMaterial3dResolvedSlots")
  }
  let resolved = match slots.get(entity) {
    Some(Resolved(value)) => value
    Some(Pending) => abort("typed material slot stayed pending")
    None => abort("typed material slot missing")
  }
  debug_inspect(
    resolved
    .material_properties()
    .get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL),
    content="Some(\"shaders/tonemapping_test_patterns.wgsl\")",
  )
  inspect(resolved.material_bind_group_data().entries().length(), content="3")
  inspect(
    resolved.material_type_tag(),
    content="mgstudio_pbr_test::ParityCustomMaterial",
  )
}

///|
test "pbr material plugin: prepared typed material prewarms and queues mesh draw" {
  let world = @ecs.World::new()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let material = ParityCustomMaterial::ParityCustomMaterial()
  let material_handle : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(
    701,
  )
  let prepared = PreparedMaterial::from_material(
    material_handle,
    material,
    material_pipeline_from_material_hooks(probe),
    @material.OpaqueRendererMethod::Forward,
  )
  let resolved = prepared.resolved_material()
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )
  world.insert_resource(
    @pbr_render.Render3dMeshRuntimeState::resource(),
    @pbr_render.Render3dMeshRuntimeState::new(),
  )
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache(),
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  let main_view = @core.Entity::new(711, 1)
  let render_view = world.spawn()
  let main_mesh = @core.Entity::new(712, 1)
  let render_mesh = @core.Entity::new(713, 1)
  let visible_entity = @render.MainEntity::new(main_mesh)
  dirty_specializations.insert_changed(visible_entity)
  world.insert_resource(
    @render_visibility.DirtySpecializations::resource(),
    dirty_specializations,
  )
  world.insert_resource(
    PendingMeshMaterialQueues::resource(),
    PendingMeshMaterialQueues::PendingMeshMaterialQueues(),
  )
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([(render_mesh, visible_entity)])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    render_view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )
  let render_material_instances = RenderMaterialInstances::RenderMaterialInstances()
  render_material_instances.extract_mesh_material_id(
    main_mesh,
    true,
    material_handle.id(),
  )
  world.insert_resource(
    ecs_key_render_material_instances, render_material_instances,
  )
  let mesh_instances = RenderMeshInstances::new()
  mesh_instances.insert(visible_entity, RenderMeshQueueData::new(777, 0U, true))
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(777, @render_mesh.RenderMesh::new(vertex_count=3))
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )
  let material_slots = RenderMaterial3dResolvedSlots::new()
  material_slots.set_resolved(main_mesh, resolved)
  world.insert_resource(
    RenderMaterial3dResolvedSlots::resource(),
    material_slots,
  )
  let extracted_mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d(main_mesh, render_mesh),
    payload: Mesh3dExtractedPayload::{
      ..material_test_extracted_mesh_payload(
        777,
        resolved.material_properties(),
      ),
      material_bind_group_data: resolved.material_bind_group_data(),
    },
  }
  let camera = ExtractedCamera3d::{
    entity: phase_entity_ref3d(main_view, render_view),
    payload: material_test_camera_payload(),
  }
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  render3d_prewarm_mesh_pipelines(world, [camera])
  let pipeline_id = match
    world.get_resource(ecs_key_specialized_material_pipeline_cache) {
    Some(cache) => cache.pipeline_id(retained_view, main_mesh)
    None => abort("missing SpecializedMaterialPipelineCache")
  }
  debug_inspect(pipeline_id is Some(_), content="true")
  let items = render3d_queue_mesh_phase_items(
    [extracted_mesh],
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=retained_view,
    specialized_material_pipeline_cache=world
      .get_resource(ecs_key_specialized_material_pipeline_cache)
      .unwrap(),
  )
  inspect(items.length(), content="1")
  debug_inspect(
    items[0].pipeline_id.id() == pipeline_id.unwrap().id(),
    content="true",
  )
}

///|
test "pbr material plugin: debug flags mirror Bevy plugin configuration" {
  let default_plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin()
  inspect(
    default_plugin.debug_flags().allow_copies_from_indirect_parameters(),
    content="false",
  )
  let plugin = default_plugin.with_debug_flags(
    @render.RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
      true,
    ),
  )
  inspect(
    plugin.debug_flags().allow_copies_from_indirect_parameters(),
    content="true",
  )
}
