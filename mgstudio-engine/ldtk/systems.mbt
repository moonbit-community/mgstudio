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
fn ldtk_find_tileset_definition_map(
  project : LdtkProject,
) -> @hashmap.HashMap[Int, TilesetDefinition] {
  let map : @hashmap.HashMap[Int, TilesetDefinition] = @hashmap.HashMap::new()
  for tileset_definition in project.json_data().defs.tilesets {
    map.set(tileset_definition.uid, tileset_definition)
  }
  map
}

///|
fn ldtk_level_selection_or_default(world : @ecs.World) -> LevelSelection {
  let key : @ecs.ResourceKey[LevelSelection] = LevelSelection::resource()
  match (try! world.get_resource(key)) {
    Some(value) => value
    None => LevelSelection::default()
  }
}

///|
fn ldtk_settings_or_default(world : @ecs.World) -> LdtkSettings {
  let key : @ecs.ResourceKey[LdtkSettings] = LdtkSettings::resource()
  match (try! world.get_resource(key)) {
    Some(value) => value
    None => LdtkSettings::default()
  }
}

///|
fn ldtk_runtime_state_ref_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[LdtkRuntimeState] {
  let key : @ecs.ResourceKey[LdtkRuntimeState] = LdtkRuntimeState::resource()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, LdtkRuntimeState::default())
  }
  match (try! world.get_resource_mut(key)) {
    Some(value) => value
    None => abort("Failed to initialize LdtkRuntimeState")
  }
}

///|
fn ldtk_project_assets_ref_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[@asset.Assets[LdtkProject]] {
  let key : @ecs.ResourceKey[@asset.Assets[LdtkProject]] = @asset.assets_resource_key()
  match (try! world.get_resource_mut(key)) {
    Some(value) => value
    None =>
      abort(
        "Missing Assets<LdtkProject>; ensure ldtk_init_assets ran before LdtkPlugin systems",
      )
  }
}

///|
fn ldtk_blob_assets_or_empty(world : @ecs.World) -> @asset.Assets[@asset.Blob]? {
  let key : @ecs.ResourceKey[@asset.Assets[@asset.Blob]] = @asset.assets_resource_key()
  try! world.get_resource(key)
}

///|
fn ldtk_asset_server_or_default(world : @ecs.World) -> @asset.AssetServer {
  let key : @ecs.ResourceKey[@asset.AssetServer] = @asset.AssetServer::resource()
  match (try! world.get_resource(key)) {
    Some(value) => value
    None => @asset.AssetServer::new()
  }
}

///|
fn ldtk_set_clear_color(world : @ecs.World, color : @sprite.Color) -> Unit {
  world.insert_resource(
    @sprite.ClearColor::resource(),
    @sprite.ClearColor::new(color),
  )
}

///|
fn ldtk_set_clear_color_from_editor_background(
  ldtk_settings : LdtkSettings,
) -> Bool {
  match ldtk_settings.set_clear_color {
    SetClearColor::FromEditorBackground => true
    _ => false
  }
}

///|
fn ldtk_set_clear_color_from_level_background(
  ldtk_settings : LdtkSettings,
) -> Bool {
  match ldtk_settings.set_clear_color {
    SetClearColor::FromLevelBackground => true
    _ => false
  }
}

///|
fn ldtk_level_set_equal(a : LevelSet, b : LevelSet) -> Bool {
  let a_iids = a.iids()
  let b_iids = b.iids()
  if a_iids.length() != b_iids.length() {
    return false
  }
  for i in 0..<a_iids.length() {
    if a_iids[i].get() != b_iids[i].get() {
      return false
    }
  }
  true
}

///|
fn ldtk_pre_spawn_level(
  world : @ecs.World,
  level : Level,
  ldtk_settings : LdtkSettings,
  parent_entity : @core.Entity,
) -> @core.Entity {
  let level_entity = world.spawn_empty()
  let transform = match ldtk_settings.level_spawn_behavior {
    UseWorldTranslation(_) =>
      @transform.Transform::from_xyz(
        Float::from_int(level.world_x),
        Float::from_int(level.world_y + level.px_hei),
        0.0F,
      )
    UseZeroTranslation => @transform.Transform::identity()
  }
  try! world.set_by_key(
    level_entity,
    ecs_key_level_iid,
    LevelIid::new(level.iid),
  )
  try! world.set_by_key(level_entity, ecs_key_respawn, Respawn::{  })
  try! world.set_by_key(level_entity, @transform.ecs_key_transform, transform)
  try! world.set_by_key(
    level_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(transform),
  )
  try! world.set_by_key(
    level_entity,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Inherited,
  )
  try! world.set_by_key(
    level_entity,
    @ecs.ecs_key_name,
    @ecs.Name::new(level.identifier),
  )
  try! world.set_by_key(
    level_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent_entity),
  )
  level_entity
}

///|
fn ldtk_apply_level_set_for_world(
  world : @ecs.World,
  world_entity : @core.Entity,
  project_handle : LdtkProjectHandle,
  level_set : LevelSet,
  ldtk_settings : LdtkSettings,
  project_assets : @asset.Assets[LdtkProject],
  blob_assets : @asset.Assets[@asset.Blob]?,
) -> Bool {
  guard project_assets.get(project_handle.handle()) is Some(project) else {
    return false
  }
  let runtime_ref = ldtk_runtime_state_ref_or_init(world)
  runtime_ref.set_changed()
  let spawned = runtime_ref.peek().world_spawned_levels(world_entity)
  let mut spawned_any = false
  let desired_iid_lookup : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for level_iid in level_set.iids() {
    desired_iid_lookup.set(level_iid.get(), true)
  }

  let spawnable_levels : Array[Level] = []
  for level_iid in level_set.iids() {
    let level = match blob_assets {
      Some(loaded_blob_assets) =>
        project.get_loaded_level_by_iid(loaded_blob_assets, level_iid.get())
      None => project.get_raw_level_by_iid(level_iid.get())
    }
    if level is Some(value) {
      spawnable_levels.push(value)
    }
  }

  for level in spawnable_levels {
    if spawned.contains(level.iid) {
      continue
    }
    ldtk_send_level_event(world, SpawnTriggered(LevelIid::new(level.iid)))
    let level_entity = ldtk_pre_spawn_level(
      world, level, ldtk_settings, world_entity,
    )
    spawned.set(level.iid, level_entity)
    spawned_any = true
  }

  let to_remove_iids : Array[String] = []
  for entry in spawned.iter() {
    let (iid, level_entity) = entry
    if !desired_iid_lookup.contains(iid) {
      if world.is_alive(level_entity) {
        try! world.despawn(level_entity)
      }
      to_remove_iids.push(iid)
      ldtk_send_level_event(world, Despawned(LevelIid::new(iid)))
    }
  }
  for iid in to_remove_iids {
    spawned.remove(iid)
  }
  spawned_any
}

///|
pub fn process_ldtk_assets(world : @ecs.World) -> Unit {
  let ldtk_settings = ldtk_settings_or_default(world)
  let assets_ref = ldtk_project_assets_ref_or_abort(world)
  assets_ref.set_changed()
  let assets = assets_ref.peek()
  let changed_handles = @utils.IntBitSet::new()
  for event in assets.drain_events() {
    match event {
      @asset.AssetEvent::Added(handle) => changed_handles.insert(handle.id())
      @asset.AssetEvent::Modified(handle) =>
        changed_handles.insert(handle.id())
      @asset.AssetEvent::LoadedWithDependencies(handle) =>
        changed_handles.insert(handle.id())
      @asset.AssetEvent::Removed(handle) => changed_handles.remove(handle.id())
    }
  }
  if changed_handles.is_empty() {
    return
  }
  let query : @ecs.Query[@ecs.Comp[LdtkProjectHandle], @ecs.All] = @ecs.query(
    world,
  )
  let respawn_entities : Array[@core.Entity] = []
  try! query.view(fn(entity, handle) {
    if changed_handles.contains(handle.value().id()) {
      if !(try! world.contains_by_key(entity, ecs_key_respawn)) {
        respawn_entities.push(entity)
      }
      if ldtk_set_clear_color_from_editor_background(ldtk_settings) {
        if assets.get(handle.value().handle()) is Some(project) {
          ldtk_set_clear_color(world, project.json_data().bg_color)
        }
      }
    }
  })
  for entity in respawn_entities {
    try! world.set_by_key(entity, ecs_key_respawn, Respawn::{  })
  }
}

///|
pub fn apply_level_selection(world : @ecs.World) -> Unit {
  let level_selection = ldtk_level_selection_or_default(world)
  let ldtk_settings = ldtk_settings_or_default(world)
  let project_assets_key : @ecs.ResourceKey[@asset.Assets[LdtkProject]] = @asset.assets_resource_key()
  guard (try! world.get_resource(project_assets_key)) is Some(project_assets) else {
    return
  }
  let query : @ecs.Query[
    (@ecs.Comp[LdtkProjectHandle], @ecs.Mut[LevelSet]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(_entity, data) {
    let (project_handle, level_set_mut) = data
    guard project_assets.get(project_handle.value().handle()) is Some(project) else {
      return
    }
    guard project.find_raw_level_by_level_selection(level_selection)
      is Some(level) else {
      return
    }
    let iids : Array[LevelIid] = [LevelIid::new(level.iid)]
    match ldtk_settings.level_spawn_behavior {
      UseWorldTranslation(load_level_neighbors) =>
        if load_level_neighbors {
          for neighbor in level.neighbours {
            iids.push(LevelIid::new(neighbor.level_iid))
          }
        }
      UseZeroTranslation => ()
    }
    let new_level_set = LevelSet::new(iids)
    if !ldtk_level_set_equal(level_set_mut.value(), new_level_set) {
      level_set_mut.set(new_level_set)
      if ldtk_set_clear_color_from_level_background(ldtk_settings) {
        ldtk_set_clear_color(world, level.bg_color)
      }
    }
  })
}

///|
pub fn apply_level_set(world : @ecs.World) -> Unit {
  let ldtk_settings = ldtk_settings_or_default(world)
  let project_assets_key : @ecs.ResourceKey[@asset.Assets[LdtkProject]] = @asset.assets_resource_key()
  guard (try! world.get_resource(project_assets_key)) is Some(project_assets) else {
    return
  }
  let blob_assets = ldtk_blob_assets_or_empty(world)
  let query : @ecs.Query[
    (@ecs.Comp[LdtkProjectHandle], @ecs.Comp[LevelSet]),
    @ecs.All,
  ] = @ecs.query(world)
  let level_set_entries : Array[(@core.Entity, LdtkProjectHandle, LevelSet)] = []
  try! query.view(fn(world_entity, data) {
    let (project_handle, level_set) = data
    level_set_entries.push(
      (world_entity, project_handle.value(), level_set.value()),
    )
  })
  for entry in level_set_entries {
    let (world_entity, project_handle, level_set) = entry
    let spawned_any = ldtk_apply_level_set_for_world(
      world, world_entity, project_handle, level_set, ldtk_settings, project_assets,
      blob_assets,
    )
    if spawned_any &&
      (try! world.contains_by_key(world_entity, ecs_key_respawn)) {
      ignore(try! world.remove_by_key(world_entity, ecs_key_respawn))
    }
  }
}

///|
pub fn clean_respawn_entities(world : @ecs.World) -> Unit {
  let worlds_query : @ecs.Query[
    @ecs.Comp[@hierarchy.Children],
    (@ecs.With[LdtkProjectHandle], @ecs.With[Respawn]),
  ] = @ecs.query_filtered(
    world,
    (
      @ecs.With::new(ecs_key_ldtk_project_handle),
      @ecs.With::new(ecs_key_respawn),
    ),
  )
  let despawn_entities : Array[@core.Entity] = []
  let despawned_level_events : Array[LevelIid] = []
  try! worlds_query.view(fn(_world_entity, children) {
    for child in children.value().entities() {
      let is_level = try! world.contains_by_key(child, ecs_key_level_iid)
      let is_worldly = try! world.contains_by_key(child, ecs_key_worldly)
      let child_has_respawn = try! world.contains_by_key(child, ecs_key_respawn)
      if (is_level && !child_has_respawn) || is_worldly {
        if (try! world.get_by_key(child, ecs_key_level_iid)) is Some(level_iid) {
          despawned_level_events.push(level_iid)
        }
        if world.is_alive(child) {
          despawn_entities.push(child)
        }
      }
    }
  })

  let levels_query : @ecs.Query[
    (@ecs.Comp[LevelIid], @ecs.Comp[@hierarchy.Children]),
    @ecs.With[Respawn],
  ] = @ecs.query_filtered(world, @ecs.With::new(ecs_key_respawn))
  try! levels_query.view(fn(_level_entity, data) {
    let (level_iid, children) = data
    despawned_level_events.push(level_iid.value())
    for child in children.value().entities() {
      if world.is_alive(child) {
        despawn_entities.push(child)
      }
    }
  })
  for level_iid in despawned_level_events {
    ldtk_send_level_event(world, Despawned(level_iid))
  }
  for entity in despawn_entities {
    if world.is_alive(entity) {
      try! world.despawn(entity)
    }
  }
}

///|
pub fn process_ldtk_levels(world : @ecs.World) -> Unit {
  let ldtk_settings = ldtk_settings_or_default(world)
  let project_assets_key : @ecs.ResourceKey[@asset.Assets[LdtkProject]] = @asset.assets_resource_key()
  guard (try! world.get_resource(project_assets_key)) is Some(project_assets) else {
    return
  }
  let blob_assets = ldtk_blob_assets_or_empty(world)
  let asset_server = ldtk_asset_server_or_default(world)
  let query : @ecs.Query[
    (@ecs.Comp[LevelIid], @ecs.Comp[@hierarchy.Parent], @ecs.Comp[Respawn]),
    @ecs.All,
  ] = @ecs.query(world)
  let respawn_levels : Array[(@core.Entity, LevelIid, @core.Entity)] = []
  try! query.view(fn(level_entity, data) {
    let (level_iid, parent, _respawn) = data
    respawn_levels.push(
      (level_entity, level_iid.value(), parent.value().entity()),
    )
  })
  for entry in respawn_levels {
    let (level_entity, level_iid, world_entity) = entry
    guard (try! world.get_by_key(world_entity, ecs_key_ldtk_project_handle))
      is Some(project_handle) else {
      continue
    }
    guard project_assets.get(project_handle.handle()) is Some(project) else {
      continue
    }
    let level_opt = match blob_assets {
      Some(loaded_blob_assets) =>
        project.get_loaded_level_by_iid(loaded_blob_assets, level_iid.get())
      None => project.get_raw_level_by_iid(level_iid.get())
    }
    guard level_opt is Some(level) else { continue }
    let metadata = project.get_level_metadata_by_iid(level.iid)
    let background_image = match metadata {
      Some(info) => info.bg_image
      None => None
    }
    let entity_definition_map = create_entity_definition_map(
      project.json_data().defs.entities,
    )
    let layer_definition_map = create_layer_definition_map(
      project.json_data().defs.layers,
    )
    spawn_level(
      level,
      background_image,
      world,
      asset_server,
      project.tileset_map(),
      project.int_grid_image_handle(),
      level_entity,
      ldtk_settings,
      entity_definition_map,
      layer_definition_map,
      ldtk_find_tileset_definition_map(project),
    )
    ldtk_send_level_event(world, Spawned(LevelIid::new(level.iid)))
    ignore(try! world.remove_by_key(level_entity, ecs_key_respawn))
  }
}

///|
pub fn detect_level_spawned_events(
  level_events : @ecs.MessageReader[LevelEvent],
  spawned_level_iids : @app.ResMut[LdtkSpawnedLevelIids],
) -> Unit {
  let spawned_iids : Array[LevelIid] = []
  let events = try! level_events.read()
  for event in events {
    match event {
      Spawned(iid) => spawned_iids.push(iid)
      _ => ()
    }
  }
  spawned_level_iids.set(LdtkSpawnedLevelIids::{ iids: spawned_iids })
}

///|
pub fn fire_level_transformed_events(
  spawned_level_iids : @app.ResMut[LdtkSpawnedLevelIids],
  level_events : @ecs.MessageWriter[LevelEvent],
) -> Unit {
  for iid in spawned_level_iids.peek().iids() {
    ignore(level_events.write(Transformed(iid)))
  }
  spawned_level_iids.set(LdtkSpawnedLevelIids::default())
}

///|
pub fn worldly_adoption(world : @ecs.World) -> Unit {
  let query : @ecs.Query[@ecs.Comp[Worldly], @ecs.Added[Worldly]] = @ecs.query_filtered(
    world,
    @ecs.Added::new(ecs_key_worldly),
  )
  let parent_updates : Array[(@core.Entity, @hierarchy.Parent?)] = []
  try! query.view(fn(worldly_entity, _worldly) {
    let mut ancestor : @core.Entity? = Some(worldly_entity)
    for _ in 0..<3 {
      ancestor = match ancestor {
        Some(entity) =>
          match (try! world.get_by_key(entity, @hierarchy.ecs_key_parent)) {
            Some(parent_component) => Some(parent_component.entity())
            None => None
          }
        None => None
      }
    }
    match ancestor {
      Some(world_entity) =>
        parent_updates.push(
          (worldly_entity, Some(@hierarchy.Parent::new(world_entity))),
        )
      None =>
        if (try! world.contains_by_key(
            worldly_entity, @hierarchy.ecs_key_parent,
          )) {
          parent_updates.push((worldly_entity, None))
        }
    }
  })
  for update in parent_updates {
    let (entity, parent) = update
    match parent {
      Some(parent_component) =>
        try! world.set_by_key(
          entity, @hierarchy.ecs_key_parent, parent_component,
        )
      None =>
        ignore(try! world.remove_by_key(entity, @hierarchy.ecs_key_parent))
    }
  }
}
