///|
type AlphaMode2d = @sprite_render_mesh2d_material.AlphaMode2d

///|
type RenderMaterial2dInstances[M] = @sprite_render_mesh2d_material.RenderMaterial2dInstances[
  M,
]

///|
type Material2dBinding = @sprite_render_mesh2d_material.Material2dBinding

///|
type Material2dBindGroup = @sprite_render_mesh2d_material.Material2dBindGroup

///|
type Material2dPipeline[M] = @sprite_render_mesh2d_material.Material2dPipeline[
  M,
]

///|
type Material2dKeys[M] = @sprite_render_mesh2d_material.Material2dKeys[M]

///|
type PreparedMaterial2d[M] = @sprite_render_mesh2d_material.PreparedMaterial2d[
  M,
]

///|
type MeshMaterial2d[M] = @sprite_render_mesh2d_material.MeshMaterial2d[M]

///|
fn[M] register_material2d_keys(
  material_debug_name : String,
) -> Material2dKeys[M] {
  @sprite_render_mesh2d_material.register_material2d_keys(material_debug_name)
}

///|
fn material2d_u32le_pack(xs : Array[UInt]) -> Bytes {
  @sprite_render_mesh2d_material.material2d_u32le_pack(xs)
}

///|
fn material2d_f32_bits(x : Float) -> UInt {
  @sprite_render_mesh2d_material.material2d_f32_bits(x)
}

///|
fn material2d_alpha_mode_kind_bits(alpha_mode : AlphaMode2d) -> UInt {
  @sprite_render_mesh2d_material.material2d_alpha_mode_kind_bits(alpha_mode)
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] material2d_runtime_type_name(
  probe : @asset.Handle[M],
) -> String {
  @sprite_render_mesh2d_material.material2d_runtime_type_name(probe)
}

///|
fn mesh_alpha_cutoff(alpha_mode : AlphaMode2d) -> Float {
  @sprite_render_mesh2d_material.mesh_alpha_cutoff(alpha_mode)
}

///|
fn[M] prepared_material2d_alpha_phase(material : PreparedMaterial2d[M]) -> Int? {
  @sprite_render_mesh2d_material.prepared_material2d_alpha_phase(material)
}

///|
fn[M] prepared_material2d_get(
  prepared_assets : @render.RenderAssets[PreparedMaterial2d[M]],
  handle : @asset.Handle[PreparedMaterial2d[M]],
) -> PreparedMaterial2d[M]? {
  @sprite_render_mesh2d_material.prepared_material2d_get(
    prepared_assets, handle,
  )
}

///|
fn[M] prepared_material2d_handle_for_mesh(
  mesh : ExtractedMesh2d,
  material_instances : RenderMaterial2dInstances[M],
) -> @asset.Handle[PreparedMaterial2d[M]]? {
  @sprite_render_mesh2d_material.prepared_material2d_handle_for_mesh(
    mesh, material_instances,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] prepared_material2d_assets_or_empty(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> @render.RenderAssets[PreparedMaterial2d[M]] {
  @sprite_render_mesh2d_material.prepared_material2d_assets_or_empty(
    world, probe,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] render_material2d_instances_or_empty(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> RenderMaterial2dInstances[M] {
  @sprite_render_mesh2d_material.render_material2d_instances_or_empty(
    world, probe,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] material2d_pipeline_or_default(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> Material2dPipeline[M] {
  @sprite_render_mesh2d_material.material2d_pipeline_or_default(world, probe)
}

///|
type Material2dRuntimeRegistry = @sprite_render_mesh2d_material.Material2dRuntimeRegistry

///|
type Material2dPlugin[M] = @sprite_render_mesh2d_material.Material2dPlugin[M]

///|
fn material2d_runtime_registry_or_empty(
  world : @ecs.World,
) -> Material2dRuntimeRegistry {
  @sprite_render_mesh2d_material.material2d_runtime_registry_or_empty(world)
}

///|
fn material2d_runtime_registry_contains_entity(
  source_world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  entity : @core.Entity,
) -> Bool {
  @sprite_render_mesh2d_material.material2d_runtime_registry_contains_entity(
    source_world, registry, entity,
  )
}

///|
fn material2d_runtime_phase_for_draw(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  mesh : ExtractedMesh2d,
) -> (Int, Int)? {
  @sprite_render_mesh2d_material.material2d_runtime_phase_for_draw(
    world, registry, mesh,
  )
}

///|
fn draw_registered_material2d_mesh_item(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  runtime_index : Int,
  mesh : ExtractedMesh2d,
) -> Unit {
  @sprite_render_mesh2d_material.draw_registered_material2d_mesh_item(
    world, registry, runtime_index, mesh,
  )
}

///|
fn[M] draw_material2d_mesh_item(
  mesh : ExtractedMesh2d,
  prepared_assets : @render.RenderAssets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  pipeline : Material2dPipeline[M],
) -> Unit {
  @sprite_render_mesh2d_material.draw_material2d_mesh_item(
    mesh, prepared_assets, material_instances, pipeline,
  )
}

///|
fn[M] draw_material2d_mesh_item_with_prepared_material(
  mesh : ExtractedMesh2d,
  material : PreparedMaterial2d[M],
  pipeline : Material2dPipeline[M],
) -> Unit {
  @sprite_render_mesh2d_material.draw_material2d_mesh_item_with_prepared_material(
    mesh, material, pipeline,
  )
}

///|
fn[M] render_material2d_instances_for_tests(
  instances_info : Array[(@core.Entity, @asset.Handle[M])],
) -> RenderMaterial2dInstances[M] {
  let instances = RenderMaterial2dInstances::new()
  for info in instances_info {
    let (entity, material) = info
    instances.set(entity, material)
  }
  instances
}
