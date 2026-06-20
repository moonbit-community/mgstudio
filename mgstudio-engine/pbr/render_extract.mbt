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
let early_sweep_material_instances_set : @app.SystemSet = @app.system_set(
  "mgstudio_pbr::early_sweep_material_instances",
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
  material_instances.modify(fn(instances) {
    for _, entity in changed_entities {
      match
        (
          try! source_world.get_by_key(
            entity, @visibility.ecs_key_view_visibility,
          ),
          try! source_world.get_by_key(entity, ecs_key_mesh_material3d),
        ) {
        (Some(view_visibility), Some(material)) =>
          instances.extract_mesh_material(
            entity,
            view_visibility.is_visible(),
            material,
          )
        _ => ()
      }
    }
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
