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
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::extract_shadow_filtering_method`.
fn insert_extracted_shadow_filtering_method(
  render_world : @ecs.World,
  component_column : @ecs.ComponentColumn[ShadowFilteringMethod]?,
  render_entity : @core.Entity,
  shadow_filtering_method : ShadowFilteringMethod,
) -> Unit {
  match component_column {
    Some(column) =>
      if column.set_tick_only(render_entity, shadow_filtering_method) {
        return
      }
    None => ()
  }
  render_world.set_by_key(
    render_entity, ecs_key_shadow_filtering_method, shadow_filtering_method,
  ) catch {
    _ =>
      abort(
        "extract_shadow_filtering_method: failed to write extracted component to render world",
      )
  }
}

///|
fn extract_shadow_filtering_method(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  ignore(
    render_world
    .components_registrator()
    .register_component_by_key(ecs_key_shadow_filtering_method),
  )
  let values : Array[(@core.Entity, ShadowFilteringMethod)] = []
  let query : @ecs.Query[
    (@ecs.Read[@render.RenderEntity], @ecs.Read[ShadowFilteringMethod]),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! query.view(fn(_entity, data) {
    let (render_entity, shadow_filtering_method) = data
    values.push((render_entity.value().id(), shadow_filtering_method.value()))
  })
  let component_column = render_world.component_column(
    ecs_key_shadow_filtering_method,
  )
  for value in values {
    insert_extracted_shadow_filtering_method(
      render_world,
      component_column,
      value.0,
      value.1,
    )
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::extract_ambient_light`.
fn insert_extracted_ambient_light(
  render_world : @ecs.World,
  component_column : @ecs.ComponentColumn[AmbientLight]?,
  render_entity : @core.Entity,
  ambient_light : AmbientLight,
) -> Unit {
  match component_column {
    Some(column) =>
      if column.set_tick_only(render_entity, ambient_light) {
        return
      }
    None => ()
  }
  render_world.set_by_key(render_entity, ecs_key_ambient_light, ambient_light) catch {
    _ =>
      abort(
        "extract_ambient_light: failed to write extracted component to render world",
      )
  }
}

///|
fn extract_ambient_light(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  ignore(
    render_world
    .components_registrator()
    .register_component_by_key(ecs_key_ambient_light),
  )
  let values : Array[(@core.Entity, AmbientLight)] = []
  let query : @ecs.Query[
    (@ecs.Read[@render.RenderEntity], @ecs.Read[AmbientLight]),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! query.view(fn(_entity, data) {
    let (render_entity, ambient_light) = data
    values.push((render_entity.value().id(), ambient_light.value()))
  })
  let component_column = render_world.component_column(ecs_key_ambient_light)
  for value in values {
    insert_extracted_ambient_light(
      render_world,
      component_column,
      value.0,
      value.1,
    )
  }
}

///|
let material_extraction_systems : @app.SystemSet = @app.system_set(
  "mgstudio_pbr::MaterialExtractionSystems",
)

///|
let material_dirty_specializations_clear_set : @app.SystemSet = @app.system_set(
  "mgstudio_pbr::clear_dirty_specializations",
)

///|
let early_sweep_material_instances_set : @app.SystemSet = @app.system_set(
  "mgstudio_pbr::early_sweep_material_instances",
)

///|
let material_dirty_specializations_removed_set : @app.SystemSet = @app.system_set(
  "mgstudio_pbr::extract_entities_that_need_specializations_removed",
)

///|
let late_sweep_material_instances_set : @app.SystemSet = @app.system_set(
  "mgstudio_pbr::late_sweep_material_instances",
)

///|
fn collect_changed_mesh_material_entities(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Map[UInt64, @core.Entity] {
  let changed_entities : Map[UInt64, @core.Entity] = {}
  for
    entity in source_world
    .changed_components(@visibility.ecs_key_view_visibility, system_ticks)
    .read() {
    changed_entities.set(entity.to_bits(), entity)
  }
  for
    entity in source_world
    .changed_components(ecs_key_mesh_material3d, system_ticks)
    .read() {
    changed_entities.set(entity.to_bits(), entity)
  }
  changed_entities
}

///|
fn collect_removed_mesh_material_entities(
  source_world : @ecs.World,
  key : @ecs.ComponentKey[MeshMaterial3d],
  system_ticks : @core.SystemTicks,
) -> Array[@core.Entity] {
  let removed_entities : Map[UInt64, @core.Entity] = {}
  for entity in source_world.removed_components(key, system_ticks).read() {
    removed_entities.set(entity.to_bits(), entity)
  }
  let values : Array[@core.Entity] = []
  for _, entity in removed_entities {
    values.push(entity)
  }
  values
}

///|
fn collect_removed_mesh3d_entities(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Array[@core.Entity] {
  let removed_entities : Map[UInt64, @core.Entity] = {}
  for
    entity in source_world
    .removed_components(ecs_key_mesh3d, system_ticks)
    .read() {
    removed_entities.set(entity.to_bits(), entity)
  }
  let values : Array[@core.Entity] = []
  for _, entity in removed_entities {
    values.push(entity)
  }
  values
}

///|
fn collect_unique_material_specialization_entity(
  entities : Array[@core.Entity],
  seen : Map[UInt64, Bool],
  entity : @core.Entity,
) -> Unit {
  let key = entity.to_bits()
  if !seen.contains(key) {
    seen.set(key, true)
    entities.push(entity)
  }
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/material.rs::check_entities_needing_specialization`.
fn collect_entities_needing_material_specialization(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let seen : Map[UInt64, Bool] = {}
  for
    entity in source_world
    .changed_components(ecs_key_mesh3d, system_ticks)
    .read() {
    if (try! source_world.get_by_key(entity, ecs_key_mesh_material3d))
      is Some(_) {
      collect_unique_material_specialization_entity(entities, seen, entity)
    }
  }
  for
    entity in source_world
    .changed_components(ecs_key_mesh_material3d, system_ticks)
    .read() {
    if source_world.is_alive(entity) &&
      (try! source_world.get_by_key(entity, ecs_key_mesh_material3d)) is Some(_) {
      collect_unique_material_specialization_entity(entities, seen, entity)
    }
  }
  entities
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/material.rs::check_entities_needing_specialization`.
fn collect_entities_needing_material_specialization_removed(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  let seen : Map[UInt64, Bool] = {}
  for
    entity in source_world
    .removed_components(ecs_key_mesh3d, system_ticks)
    .read() {
    collect_unique_material_specialization_entity(entities, seen, entity)
  }
  for
    entity in source_world
    .removed_components(ecs_key_mesh_material3d, system_ticks)
    .read() {
    collect_unique_material_specialization_entity(entities, seen, entity)
  }
  entities
}

///|
test "pbr render extract: material specialization collector follows mesh and material changes" {
  let source_world = @ecs.World::new()
  let changed_with_material = source_world.spawn()
  let mesh_without_material = source_world.spawn()

  try! source_world.set_by_key(
    changed_with_material,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(10)),
  )
  try! source_world.set_by_key(
    changed_with_material,
    ecs_key_mesh_material3d,
    MeshMaterial3d::new(@asset.Handle::new(20)),
  )
  try! source_world.set_by_key(
    mesh_without_material,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(30)),
  )

  let first_changed = collect_entities_needing_material_specialization(
    source_world,
    @core.SystemTicks::new(0, 1),
  )
  debug_inspect(first_changed.length(), content="1")
  debug_inspect(first_changed.contains(changed_with_material), content="true")
  debug_inspect(first_changed.contains(mesh_without_material), content="false")

  source_world.increment_change_tick() |> ignore
  source_world.increment_change_tick() |> ignore
  let material_only_changed = source_world.spawn()
  try! source_world.set_by_key(
    material_only_changed,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(40)),
  )
  try! source_world.set_by_key(
    material_only_changed,
    ecs_key_mesh_material3d,
    MeshMaterial3d::new(@asset.Handle::new(50)),
  )
  source_world.increment_change_tick() |> ignore
  source_world.increment_change_tick() |> ignore
  ignore(
    try! source_world.replace(
      material_only_changed,
      ecs_key_mesh_material3d,
      MeshMaterial3d::new(@asset.Handle::new(51)),
    ),
  )

  let second_changed = collect_entities_needing_material_specialization(
    source_world,
    @core.SystemTicks::new(2, source_world.read_change_tick()),
  )
  debug_inspect(second_changed.length(), content="1")
  debug_inspect(second_changed.contains(material_only_changed), content="true")
}

///|
test "pbr render extract: material specialization collector follows mesh and material removals" {
  let source_world = @ecs.World::new()
  let mesh_removed = source_world.spawn()
  let material_removed = source_world.spawn()
  let duplicate_removed = source_world.spawn()

  for entity in [mesh_removed, material_removed, duplicate_removed] {
    try! source_world.set_by_key(
      entity,
      ecs_key_mesh3d,
      @mesh.Mesh3d::new(@asset.Handle::new(100)),
    )
    try! source_world.set_by_key(
      entity,
      ecs_key_mesh_material3d,
      MeshMaterial3d::new(@asset.Handle::new(200)),
    )
  }

  source_world.increment_change_tick() |> ignore
  ignore(try! source_world.remove_by_key(mesh_removed, ecs_key_mesh3d))
  ignore(
    try! source_world.remove_by_key(material_removed, ecs_key_mesh_material3d),
  )
  ignore(try! source_world.remove_by_key(duplicate_removed, ecs_key_mesh3d))
  ignore(
    try! source_world.remove_by_key(duplicate_removed, ecs_key_mesh_material3d),
  )

  let removed = collect_entities_needing_material_specialization_removed(
    source_world,
    @core.SystemTicks::new(0, source_world.read_change_tick()),
  )
  debug_inspect(removed.length(), content="3")
  debug_inspect(removed.contains(mesh_removed), content="true")
  debug_inspect(removed.contains(material_removed), content="true")
  debug_inspect(removed.contains(duplicate_removed), content="true")
}

///|
fn dirty_specializations_mut_or_init(
  render_world : @ecs.World,
) -> @ecs.ResourceMut[@render_visibility.DirtySpecializations] {
  if render_world.get_resource(
      @render_visibility.DirtySpecializations::resource(),
    )
    is None {
    render_world.insert_resource(
      @render_visibility.DirtySpecializations::resource(),
      @render_visibility.DirtySpecializations::DirtySpecializations(),
    )
  }
  match
    render_world.get_resource_mut(
      @render_visibility.DirtySpecializations::resource(),
    ) {
    Some(value) => value
    None => abort("missing DirtySpecializations resource")
  }
}

///|
fn entity_specialization_ticks_mut_or_init(
  render_world : @ecs.World,
) -> @ecs.ResourceMut[EntitySpecializationTicks] {
  if render_world.get_resource(ecs_key_entity_specialization_ticks) is None {
    render_world.insert_resource(
      ecs_key_entity_specialization_ticks,
      EntitySpecializationTicks::EntitySpecializationTicks(),
    )
  }
  match render_world.get_resource_mut(ecs_key_entity_specialization_ticks) {
    Some(value) => value
    None => abort("missing EntitySpecializationTicks resource")
  }
}

///|
// Bevy source:
// - `bevy/crates/bevy_render/src/camera.rs::clear_dirty_specializations`.
fn clear_dirty_specializations_system(render_world : @ecs.World) -> Unit {
  dirty_specializations_mut_or_init(render_world).modify(fn(dirty) {
    @render_visibility.clear_dirty_specializations(dirty)
  })
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/material.rs::extract_entities_needs_specialization`.
fn extract_entities_needs_specialization(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  let system_ticks = match
    render_world.get_resource(ecs_key_render_material_instances) {
    Some(instances) => instances.source_system_ticks(source_world)
    None => @core.SystemTicks::new(0, source_world.read_change_tick())
  }
  let entities = collect_entities_needing_material_specialization(
    source_world, system_ticks,
  )
  let material_instances = match
    render_world.get_resource(ecs_key_render_material_instances) {
    Some(value) => value
    None => abort("missing RenderMaterialInstances resource")
  }
  let entity_ticks = entity_specialization_ticks_mut_or_init(render_world)
  let dirty_specializations = dirty_specializations_mut_or_init(render_world)
  entity_ticks.modify(fn(ticks) {
    dirty_specializations.modify(fn(dirty) {
      for entity in entities {
        ticks.extract_entity_needs_specialization(
          entity,
          system_ticks.this_run,
          material_instances,
          dirty,
        )
      }
    })
  })
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/material.rs::extract_entities_that_need_specializations_removed`.
fn extract_entities_that_need_specializations_removed(
  render_world : @ecs.World,
) -> Unit {
  let source_world = @render.render_source_world(render_world)
  let system_ticks = match
    render_world.get_resource(ecs_key_render_material_instances) {
    Some(instances) => instances.source_system_ticks(source_world)
    None => @core.SystemTicks::new(0, source_world.read_change_tick())
  }
  let entities = collect_entities_needing_material_specialization_removed(
    source_world, system_ticks,
  )
  dirty_specializations_mut_or_init(render_world).modify(fn(dirty) {
    for entity in entities {
      dirty.insert_removed(@render.MainEntity::new(entity))
    }
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::extract_mesh_materials`.
fn extract_mesh_materials(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  let system_ticks = match
    render_world.get_resource(ecs_key_render_material_instances) {
    Some(instances) => instances.source_system_ticks(source_world)
    None => @core.SystemTicks::new(0, source_world.read_change_tick())
  }
  let changed_entities = collect_changed_mesh_material_entities(
    source_world, system_ticks,
  )
  let material_instances = match
    render_world.get_resource_mut(ecs_key_render_material_instances) {
    Some(value) => value
    None => abort("missing RenderMaterialInstances resource")
  }
  if render_world.get_resource(ecs_key_render_material_shader_paths) is None {
    render_world.insert_resource(
      ecs_key_render_material_shader_paths,
      RenderMaterialShaderPaths::RenderMaterialShaderPaths(),
    )
  }
  let material_shader_paths = match
    render_world.get_resource_mut(ecs_key_render_material_shader_paths) {
    Some(value) => value
    None => abort("missing RenderMaterialShaderPaths resource")
  }
  material_instances.modify(fn(instances) {
    material_shader_paths.modify(fn(shader_paths) {
      for _, entity in changed_entities {
        if !source_world.is_alive(entity) {
          continue
        }
        match
          (
            try! source_world.get_by_key(
              entity, @visibility.ecs_key_view_visibility,
            ),
            try! source_world.get_by_key(entity, ecs_key_mesh_material3d),
          ) {
          (Some(view_visibility), Some(material)) => {
            instances.extract_mesh_material(
              entity,
              view_visibility.is_visible(),
              material,
            )
            if view_visibility.is_visible() {
              shader_paths.extract_mesh_material(material)
            }
          }
          _ => ()
        }
      }
    })
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::early_sweep_material_instances`.
fn early_sweep_material_instances(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  let system_ticks = match
    render_world.get_resource(ecs_key_render_material_instances) {
    Some(instances) => instances.source_system_ticks(source_world)
    None => @core.SystemTicks::new(0, source_world.read_change_tick())
  }
  let material_instances = match
    render_world.get_resource_mut(ecs_key_render_material_instances) {
    Some(value) => value
    None => abort("missing RenderMaterialInstances resource")
  }
  let removed_materials = collect_removed_mesh_material_entities(
    source_world, ecs_key_mesh_material3d, system_ticks,
  )
  material_instances.modify(fn(instances) {
    for entity in removed_materials {
      ignore(instances.early_sweep_removed_mesh_material(entity))
    }
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::late_sweep_material_instances`.
fn late_sweep_material_instances(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  let source_this_run = source_world.read_change_tick()
  let system_ticks = match
    render_world.get_resource(ecs_key_render_material_instances) {
    Some(instances) =>
      @core.SystemTicks::new(instances.last_source_change_tick, source_this_run)
    None => @core.SystemTicks::new(0, source_this_run)
  }
  let material_instances = match
    render_world.get_resource_mut(ecs_key_render_material_instances) {
    Some(value) => value
    None => abort("missing RenderMaterialInstances resource")
  }
  let removed_meshes = collect_removed_mesh3d_entities(
    source_world, system_ticks,
  )
  material_instances.modify(fn(instances) {
    for entity in removed_meshes {
      ignore(instances.late_sweep_removed_mesh3d(entity))
    }
    instances.advance_change_tick()
    instances.set_last_source_change_tick(source_this_run)
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::extract_shadow_lod_origin`.
fn extract_shadow_lod_origin(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  let next_origin = match @light.get_shadow_lod_origin(source_world) {
    Some(entity) =>
      match
        (try! source_world.get_by_key(
          entity, @transform.ecs_key_global_transform,
        )) {
        Some(global_transform) => global_transform.translation()
        None => @math.Vec3::zero()
      }
    None => @math.Vec3::zero()
  }
  match
    render_world.get_resource_mut(
      @render_view.RenderShadowLodOrigin::resource(),
    ) {
    Some(origin) =>
      origin.set(@render_view.RenderShadowLodOrigin::new(next_origin))
    None =>
      render_world.insert_resource(
        @render_view.RenderShadowLodOrigin::resource(),
        @render_view.RenderShadowLodOrigin::new(next_origin),
      )
  }
}
