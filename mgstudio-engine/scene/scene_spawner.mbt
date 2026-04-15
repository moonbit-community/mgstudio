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
// Bevy source: `bevy/crates/bevy_scene/src/scene_spawner.rs`.

///|
pub let scene_spawner_set_spawn : @app.SystemSet = @app.system_set(
  "mgstudio.scene.SceneSpawnerSystems.Spawn",
)

///|
priv struct SceneInstanceState {
  instance_id : Int
  scene_id : Int
  spawned_entities : Array[@core.Entity]
  ready : Bool
}

///|
priv struct SceneRuntimeState {
  mut next_instance_id : Int
  instances : Array[SceneInstanceState]
}

///|
fn SceneRuntimeState::default() -> SceneRuntimeState {
  SceneRuntimeState::{ next_instance_id: 1, instances: [] }
}

///|
fn scene_runtime_state_resource_key() -> @ecs.ResourceKey[SceneRuntimeState] {
  @ecs.register_resource(debug_name="mgstudio_scene::SceneRuntimeState")
}

///|
impl @app.Resource for SceneRuntimeState with resource() {
  scene_runtime_state_resource_key()
}

///|
fn scene_runtime_state_mut_or_abort(
  world : @ecs.World,
) -> Ref[SceneRuntimeState] {
  match (try! world.get_resource_ref_mut(scene_runtime_state_resource_key())) {
    Some(state) => state
    None =>
      abort(
        "scene runtime state is missing; ScenePlugin must initialize SceneRuntimeState before running SceneRoot lifecycle systems",
      )
  }
}

///|
fn scene_runtime_state_or_abort(world : @ecs.World) -> SceneRuntimeState {
  match (try! world.get_resource(scene_runtime_state_resource_key())) {
    Some(state) => state
    None =>
      abort(
        "scene runtime state is missing; ScenePlugin must initialize SceneRuntimeState before running SceneRoot lifecycle systems",
      )
  }
}

///|
fn scene_runtime_instance_index(
  state : SceneRuntimeState,
  instance_id : Int,
) -> Int? {
  for i in 0..<state.instances.length() {
    if state.instances[i].instance_id == instance_id {
      return Some(i)
    }
  }
  None
}

///|
fn scene_runtime_allocate_instance(
  world : @ecs.World,
  scene : @asset.Handle[Scene],
) -> Int {
  let state_ref = scene_runtime_state_mut_or_abort(world)
  let instance_id = state_ref.val.next_instance_id
  state_ref.val.next_instance_id = instance_id + 1
  state_ref.val.instances.push(SceneInstanceState::{
    instance_id,
    scene_id: scene.id(),
    spawned_entities: [],
    ready: false,
  })
  instance_id
}

///|
fn scene_runtime_get_instance(
  world : @ecs.World,
  instance_id : Int,
) -> SceneInstanceState? {
  let state = scene_runtime_state_or_abort(world)
  guard scene_runtime_instance_index(state, instance_id) is Some(index) else {
    return None
  }
  Some(state.instances[index])
}

///|
pub fn scene_instance_is_ready(world : @ecs.World, instance_id : Int) -> Bool {
  match scene_runtime_get_instance(world, instance_id) {
    Some(instance) => instance.ready
    None => false
  }
}

///|
pub fn scene_iter_instance_entities(
  world : @ecs.World,
  instance_id : Int,
) -> Array[@core.Entity] {
  match scene_runtime_get_instance(world, instance_id) {
    Some(instance) =>
      if instance.ready {
        instance.spawned_entities
      } else {
        []
      }
    None => []
  }
}

///|
fn scene_runtime_remove_instance(
  world : @ecs.World,
  instance_id : Int,
) -> SceneInstanceState? {
  let state_ref = scene_runtime_state_mut_or_abort(world)
  guard scene_runtime_instance_index(state_ref.val, instance_id) is Some(index) else {
    return None
  }
  Some(state_ref.val.instances.remove(index))
}

///|
fn scene_runtime_mark_ready(
  world : @ecs.World,
  instance_id : Int,
  spawned_entities : Array[@core.Entity],
) -> Bool {
  let state_ref = scene_runtime_state_mut_or_abort(world)
  guard scene_runtime_instance_index(state_ref.val, instance_id) is Some(index) else {
    return false
  }
  let state = state_ref.val.instances[index]
  state_ref.val.instances[index] = SceneInstanceState::{
    ..state,
    spawned_entities,
    ready: true,
  }
  true
}

///|
pub fn scene_load_pending_system(world : @ecs.World) -> Unit {
  scene_process_pending_requests(world, @asset.AssetServer::new())
}

///|
fn scene_instance_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> SceneInstance? {
  try world.get_by_key(entity, ecs_key_scene_instance) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn scene_remove_ready_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  ignore(
    try world.remove_by_key(entity, ecs_key_scene_instance_ready) catch {
      _ => false
    } noraise {
      value => value
    },
  )
}

///|
priv struct SceneRootRespawnRequested {}

///|
let ecs_key_scene_root_respawn_requested : @ecs.ComponentKey[
  SceneRootRespawnRequested,
] = @ecs.register_component(
  debug_name="mgstudio_scene::SceneRootRespawnRequested",
)

///|
fn scene_mark_root_respawn_requested(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  try! world.set_by_key(entity, ecs_key_scene_root_respawn_requested, SceneRootRespawnRequested::{

  })
}

///|
fn scene_clear_root_respawn_requested(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  ignore(
    try
      world.remove_by_key(entity, ecs_key_scene_root_respawn_requested)
    catch {
      _ => false
    } noraise {
      value => value
    },
  )
}

///|
fn scene_unregister_instance(world : @ecs.World, instance_id : Int) -> Unit {
  scene_runtime_remove_instance(world, instance_id) |> ignore
}

///|
fn scene_despawn_instance(world : @ecs.World, instance_id : Int) -> Unit {
  guard scene_runtime_remove_instance(world, instance_id) is Some(instance) else {
    return
  }
  for entity in instance.spawned_entities {
    if world.is_alive(entity) {
      try! world.despawn(entity)
    }
  }
}

///|
fn scene_clear_instance_components(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  scene_remove_ready_component(world, entity)
  ignore(
    try world.remove_by_key(entity, ecs_key_scene_instance) catch {
      _ => false
    } noraise {
      value => value
    },
  )
}

///|
fn scene_detach_root_instance(
  world : @ecs.World,
  entity : @core.Entity,
  despawn_entities? : Bool = false,
) -> Unit {
  guard scene_instance_component(world, entity) is Some(instance) else {
    return
  }
  if despawn_entities {
    scene_despawn_instance(world, instance.instance_id)
  } else {
    scene_unregister_instance(world, instance.instance_id)
  }
  scene_clear_instance_components(world, entity)
}

///|
fn scene_root_on_remove(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  scene_detach_root_instance(
    world.world(),
    context.entity,
    despawn_entities=true,
  )
}

///|
fn scene_root_on_insert(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  scene_mark_root_respawn_requested(world.world(), context.entity)
  if !world.contains_by_key(context.entity, @transform.ecs_key_transform) {
    try! world.set_by_key(
      context.entity,
      @transform.ecs_key_transform,
      @transform.Transform::identity(),
    )
  }
  if !world.contains_by_key(context.entity, @visibility.ecs_key_visibility) {
    try! world.set_by_key(
      context.entity,
      @visibility.ecs_key_visibility,
      @visibility.Visibility::Inherited,
    )
  }
}

///|
fn scene_root_on_replace(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  scene_mark_root_respawn_requested(world.world(), context.entity)
}

///|
fn scene_instance_on_remove(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  guard (try! world.get_by_key(context.entity, ecs_key_scene_instance))
    is Some(instance) else {
    return
  }
  scene_unregister_instance(world.world(), instance.instance_id)
}

///|
fn scene_register_component_hooks() -> Bool {
  let scene_root_hooks = @ecs.register_component_hooks_for_key(
    ecs_key_scene_root,
  )
  ignore(
    try! scene_root_hooks
    .on_insert(scene_root_on_insert)
    .on_replace(scene_root_on_replace)
    .on_remove(scene_root_on_remove),
  )
  let scene_instance_hooks = @ecs.register_component_hooks_for_key(
    ecs_key_scene_instance,
  )
  ignore(try! scene_instance_hooks.on_remove(scene_instance_on_remove))
  true
}

///|
fn scene_attach_pending_instance(
  world : @ecs.World,
  root_entity : @core.Entity,
  root : SceneRoot,
) -> Int {
  let instance_id = scene_runtime_allocate_instance(world, root.scene)
  scene_remove_ready_component(world, root_entity)
  try! world.set_by_key(
    root_entity,
    ecs_key_scene_instance,
    SceneInstance::new(instance_id),
  )
  instance_id
}

///|
fn scene_spawn_instance_when_ready(
  world : @ecs.World,
  root_entity : @core.Entity,
  root : SceneRoot,
  instance_id : Int,
) -> Unit {
  guard scene_runtime_get_instance(world, instance_id) is Some(instance) else {
    return
  }
  if instance.ready {
    if (try! world.get_by_key(root_entity, ecs_key_scene_instance_ready))
      is None {
      try! world.set_by_key(
        root_entity,
        ecs_key_scene_instance_ready,
        SceneInstanceReady::new(instance_id, instance.spawned_entities.length()),
      )
    }
    return
  }
  guard scene_assets_from_world_or_abort(world).get(root.scene) is Some(scene) else {
    return
  }
  if !scene.ready {
    return
  }

  if scene.gltf_scene_extras is Some(scene_extras) &&
    (
      world.entity(root_entity).get() catch {
        _ => None
      } : @gltf.GltfSceneExtras?)
    is None {
    try! world.set_by_key(
      root_entity,
      @gltf.GltfSceneExtras::component(),
      scene_extras,
    )
  }

  if (try! world.get_by_key(root_entity, @animation.ecs_key_animation_player))
    is None {
    try! world.set_by_key(
      root_entity,
      @animation.ecs_key_animation_player,
      @animation.AnimationPlayer::default(),
    )
  }

  let spawned_entities : Array[@core.Entity] = []
  let pending_skinned_meshes : Array[
    (Int, Array[Int], @asset.Handle[@mesh.SkinnedMeshInverseBindposes]),
  ] = []
  let mesh_assets_ref = scene_mesh_assets_from_world_mut_or_abort(world)
  let gltf_scene_asset_path = match scene_registry_find_scene_path(root.scene) {
    Some(path) => path
    None => "scene#\{root.scene.id().to_string()}"
  }
  for node in scene.nodes3d {
    let child = world.spawn_empty()
    spawned_entities.push(child)
    if node.name is Some(name) {
      try! world.set_by_key(child, @ecs.Name::component(), name)
    }
    if node.gltf_scene_index is Some(scene_index) {
      try! world.set_by_key(
        child,
        @gltf.GltfSceneIndex::component(),
        scene_index,
      )
    }
    if node.gltf_node_index is Some(node_index) {
      try! world.set_by_key(child, @gltf.GltfNodeIndex::component(), node_index)
    }
    if node.gltf_mesh_index is Some(mesh_index) {
      try! world.set_by_key(child, @gltf.GltfMeshIndex::component(), mesh_index)
    }
    if node.gltf_primitive_index is Some(primitive_index) {
      try! world.set_by_key(
        child,
        @gltf.GltfPrimitiveIndex::component(),
        primitive_index,
      )
    }
    if node.gltf_skin_index is Some(skin_index) {
      try! world.set_by_key(child, @gltf.GltfSkinIndex::component(), skin_index)
    }
    if node.gltf_material_name is Some(material_name) {
      try! world.set_by_key(
        child,
        @gltf.GltfMaterialName::component(),
        material_name,
      )
    }
    if node.gltf_extras is Some(extras) {
      try! world.set_by_key(child, @gltf.GltfExtras::component(), extras)
    }
    if node.gltf_mesh_extras is Some(mesh_extras) {
      try! world.set_by_key(
        child,
        @gltf.GltfMeshExtras::component(),
        mesh_extras,
      )
    }
    if node.gltf_material_extras is Some(material_extras) {
      try! world.set_by_key(
        child,
        @gltf.GltfMaterialExtras::component(),
        material_extras,
      )
    }
    if node.camera is Some(camera) {
      try! world.set_by_key(child, @sprite.Camera::component(), camera)
    }
    if node.camera3d is Some(camera3d) {
      try! world.set_by_key(child, @pbr.Camera3d::component(), camera3d)
    }
    if node.projection is Some(projection) {
      try! world.set_by_key(child, @pbr.Projection::component(), projection)
    }
    if node.directional_light is Some(directional_light) {
      try! world.set_by_key(
        child,
        @light.DirectionalLight::component(),
        directional_light,
      )
    }
    if node.point_light is Some(point_light) {
      try! world.set_by_key(child, @light.PointLight::component(), point_light)
    }
    if node.spot_light is Some(spot_light) {
      try! world.set_by_key(child, @light.SpotLight::component(), spot_light)
    }
    if node.mesh is Some(mesh_component) {
      let source_mesh_handle = mesh_component.mesh()
      let source_mesh = mesh_assets_ref.val.get(source_mesh_handle)
      let source_geometry = match source_mesh {
        Some(mesh_asset) => mesh_asset.as_3d_geometry()
        None => None
      }
      let has_morph_targets = match source_geometry {
        Some(geometry) => geometry.morph_target_positions() is Some(_)
        None => false
      }
      let needs_instance_mesh = has_morph_targets
      let effective_mesh = if needs_instance_mesh {
        match source_mesh {
          Some(mesh_asset) => {
            let cloned_handle = mesh_assets_ref.val.add(
              scene_clone_mesh_asset(mesh_asset),
            )
            @pbr.Mesh3d::new(cloned_handle)
          }
          None => mesh_component
        }
      } else {
        mesh_component
      }
      try! world.set_by_key(child, @pbr.ecs_key_mesh3d, effective_mesh)
      if node.material is Some(material) {
        try! world.set_by_key(child, @pbr.ecs_key_mesh_material3d, material)
      }
      if has_morph_targets {
        try! world.set_by_key(
          child,
          @mesh.MorphTargetMesh::component(),
          @mesh.MorphTargetMesh::new(source_mesh_handle),
        )
        let default_morph_weights = match node.default_morph_weights {
          Some(weights) => weights
          None => []
        }
        try! world.set_by_key(
          child,
          @mesh.MorphWeights::component(),
          @mesh.MorphWeights::new(default_morph_weights),
        )
      }
      if node.skinned_joint_node_indices is Some(joint_node_indices) &&
        node.skinned_inverse_bindposes is Some(inverse_bindposes) {
        pending_skinned_meshes.push(
          (spawned_entities.length() - 1, joint_node_indices, inverse_bindposes),
        )
      }
    }
    try! world.set_by_key(child, @transform.ecs_key_transform, node.transform)
    if node.visibility_range is Some(range) {
      try! world.set_by_key(child, @visibility.ecs_key_visibility_range, range)
    }
    if node.animation_target is Some(target_id) {
      try! world.set_by_key(
        child, @animation.ecs_key_animation_target_id, target_id,
      )
      try! world.set_by_key(
        child,
        @animation.ecs_key_animated_by,
        @animation.AnimatedBy::new(root_entity),
      )
    }
    if node.gltf_node_index is Some(node_index) {
      @gltf_loader_extensions.gltf_extension_notify_node_spawned(
        gltf_scene_asset_path,
        node_index.index(),
        child,
        world,
      )
    }
    if node.gltf_mesh_index is Some(mesh_index) &&
      node.gltf_primitive_index is Some(primitive_index) {
      @gltf_loader_extensions.gltf_extension_notify_mesh_spawned(
        gltf_scene_asset_path,
        mesh_index.index(),
        primitive_index.primitive_index(),
        child,
        world,
      )
    }
  }

  for i in 0..<scene.nodes3d.length() {
    let node = scene.nodes3d[i]
    let child = spawned_entities[i]
    let parent_entity = match node.parent_node_index {
      Some(parent_index) =>
        if parent_index >= 0 && parent_index < spawned_entities.length() {
          spawned_entities[parent_index]
        } else {
          root_entity
        }
      None => root_entity
    }
    try! world.set_by_key(
      child,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(parent_entity),
    )
  }

  let spawned_scene_index_by_gltf_node : Array[Int?] = []
  for scene_index, node in scene.nodes3d {
    guard node.gltf_node_index is Some(gltf_node_index) else { continue }
    let gltf_node = gltf_node_index.index()
    if gltf_node < 0 {
      continue
    }
    while spawned_scene_index_by_gltf_node.length() <= gltf_node {
      spawned_scene_index_by_gltf_node.push(None)
    }
    spawned_scene_index_by_gltf_node[gltf_node] = Some(scene_index)
  }

  let skinned_mesh_bounds_policy = @gltf.gltf_default_skinned_mesh_bounds_policy()
  for pending in pending_skinned_meshes {
    let (entity_index, joint_node_indices, inverse_bindposes_handle) = pending
    if entity_index < 0 || entity_index >= spawned_entities.length() {
      continue
    }
    let joint_entities : Array[@core.Entity] = []
    let mut has_all_joints = true
    for joint_node_index in joint_node_indices {
      if joint_node_index >= 0 &&
        joint_node_index < spawned_scene_index_by_gltf_node.length() &&
        spawned_scene_index_by_gltf_node[joint_node_index] is Some(scene_index) &&
        scene_index >= 0 &&
        scene_index < spawned_entities.length() {
        joint_entities.push(spawned_entities[scene_index])
      } else {
        has_all_joints = false
        break
      }
    }
    if !has_all_joints || joint_entities.length() == 0 {
      continue
    }
    try! world.set_by_key(
      spawned_entities[entity_index],
      @mesh.SkinnedMesh::component(),
      @mesh.SkinnedMesh::new(inverse_bindposes_handle, joint_entities),
    )
    match skinned_mesh_bounds_policy {
      @gltf.GltfSkinnedMeshBoundsPolicy::Dynamic =>
        try! world.set_by_key(
          spawned_entities[entity_index],
          @mesh.DynamicSkinnedMeshBounds::component(),
          @mesh.DynamicSkinnedMeshBounds::new(),
        )
      @gltf.GltfSkinnedMeshBoundsPolicy::NoFrustumCulling =>
        try! world.set_by_key(
          spawned_entities[entity_index],
          @visibility.ecs_key_no_frustum_culling,
          @visibility.NoFrustumCulling::default(),
        )
      @gltf.GltfSkinnedMeshBoundsPolicy::BindPose => ()
    }
  }

  scene_runtime_mark_ready(world, instance_id, spawned_entities) |> ignore
  try! world.set_by_key(
    root_entity,
    ecs_key_scene_instance_ready,
    SceneInstanceReady::new(instance_id, spawned_entities.length()),
  )
  let spawned_scene_index = if scene.nodes3d.length() > 0 {
    match scene.nodes3d[0].gltf_scene_index {
      Some(scene_index) => scene_index.index()
      None => 0
    }
  } else {
    0
  }
  @gltf_loader_extensions.gltf_extension_notify_scene_completed(
    gltf_scene_asset_path, spawned_scene_index, root_entity, world,
  )
}

///|
pub fn scene_reload_modified_roots_system(world : @ecs.World) -> Unit {
  let debounced_scene_asset_ages = scene_debounced_scene_asset_ages_ref_or_abort(
    world,
  )
  let modified_scene_ids : Array[Int] = []
  let message_key : @ecs.MessageKey[@asset.AssetEvent[Scene]] = @ecs.Message::message()
  let cursor_ref = scene_modified_events_cursor_ref_or_abort(world)
  let reader = world.message_reader(message_key, cursor_ref)
  for event in (try! reader.read()) {
    match event {
      Added(handle) => debounced_scene_asset_ages.val.set(handle.id(), 0)
      Modified(handle) => {
        let scene_id = handle.id()
        if !debounced_scene_asset_ages.val.contains(scene_id) {
          modified_scene_ids.push(scene_id)
        }
        debounced_scene_asset_ages.val.set(scene_id, 0)
      }
      _ => ()
    }
  }

  if modified_scene_ids.length() > 0 {
    let roots : Array[(@core.Entity, SceneRoot)] = []
    let scene_root_query : @ecs.Query[@ecs.Comp[SceneRoot], @ecs.All] = @ecs.query(
      world,
    )
    try! scene_root_query.view(fn(entity, root) {
      roots.push((entity, root.value()))
    })

    for entry in roots {
      let root_entity = entry.0
      let root = entry.1
      let mut should_reload = false
      for scene_id in modified_scene_ids {
        if scene_id == root.scene.id() {
          should_reload = true
          break
        }
      }
      if !should_reload {
        continue
      }
      if scene_instance_component(world, root_entity) is Some(instance) {
        scene_despawn_instance(world, instance.instance_id)
      }
      scene_attach_pending_instance(world, root_entity, root) |> ignore
    }
  }

  let next_debounced_scene_asset_ages : Map[Int, Int] = {}
  for entry in debounced_scene_asset_ages.val.iter() {
    let (scene_id, age) = entry
    if age <= 2 {
      next_debounced_scene_asset_ages.set(scene_id, age + 1)
    }
  }
  debounced_scene_asset_ages.val = next_debounced_scene_asset_ages
}

///|
pub fn scene_spawn_roots_system(world : @ecs.World) -> Unit {
  let sequence = world.get_sequence_context().sequence()
  let seen : Map[UInt64, Bool] = {}
  let roots_to_process : Array[@core.Entity] = []
  fn push_root_if_needed(
    world : @ecs.World,
    seen : Map[UInt64, Bool],
    roots_to_process : Array[@core.Entity],
    entity : @core.Entity,
  ) -> Unit {
    guard world.is_alive(entity) else { return }
    let key = entity.to_bits()
    if seen.contains(key) {
      return
    }
    if (try! world.contains_by_key(entity, ecs_key_scene_root)) {
      seen.set(key, true)
      roots_to_process.push(entity)
    }
  }
  for entity in world.added_components(ecs_key_scene_root, sequence).read() {
    push_root_if_needed(world, seen, roots_to_process, entity)
  }
  for entity in world.changed_components(ecs_key_scene_root, sequence).read() {
    push_root_if_needed(world, seen, roots_to_process, entity)
  }
  let scene_instance_query : @ecs.Query[@ecs.Comp[SceneInstance], @ecs.All] = @ecs.query(
    world,
  )
  try! scene_instance_query.view(fn(entity, scene_instance_ref) {
    guard (try! world.get_by_key(entity, ecs_key_scene_root)) is Some(root) else {
      return
    }
    let needs_retry = match
      scene_runtime_get_instance(world, scene_instance_ref.value().instance_id) {
      Some(instance_state) =>
        !instance_state.ready || instance_state.scene_id != root.scene.id()
      None => true
    }
    if needs_retry {
      push_root_if_needed(world, seen, roots_to_process, entity)
    }
  })
  if world.component_count(ecs_key_scene_root) >
    world.component_count(ecs_key_scene_instance) {
    let scene_root_query : @ecs.Query[@ecs.Comp[SceneRoot], @ecs.All] = @ecs.query(
      world,
    )
    try! scene_root_query.view(fn(entity, _root_ref) {
      if !(try! world.contains_by_key(entity, ecs_key_scene_instance)) {
        push_root_if_needed(world, seen, roots_to_process, entity)
      }
    })
  }

  for root_entity in roots_to_process {
    guard (try! world.get_by_key(root_entity, ecs_key_scene_root)) is Some(root) else {
      continue
    }
    let force_respawn = try! world.contains_by_key(
      root_entity, ecs_key_scene_root_respawn_requested,
    )
    let instance_id = match scene_instance_component(world, root_entity) {
      Some(instance) =>
        if force_respawn {
          scene_despawn_instance(world, instance.instance_id)
          scene_attach_pending_instance(world, root_entity, root)
        } else {
          match scene_runtime_get_instance(world, instance.instance_id) {
            Some(current) =>
              if current.scene_id == root.scene.id() {
                instance.instance_id
              } else {
                scene_despawn_instance(world, instance.instance_id)
                scene_attach_pending_instance(world, root_entity, root)
              }
            None => scene_attach_pending_instance(world, root_entity, root)
          }
        }
      None => scene_attach_pending_instance(world, root_entity, root)
    }
    scene_spawn_instance_when_ready(world, root_entity, root, instance_id)
    scene_clear_root_respawn_requested(world, root_entity)
  }
}

///|
fn scene_runtime_plugin_base(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { SceneRuntimeState::default() })
  .init_resource(fn() { SceneModifiedEventsCursorState::default() })
  .init_resource(fn() { SceneGltfPendingRequestsState::default() })
  .add_systems(
    @app.PreUpdate,
    (
      @app.system(scene_load_pending_system).in_set(scene_spawner_set_spawn),
      @app.system(scene_reload_modified_roots_system).in_set(
        scene_spawner_set_spawn,
      ),
      @app.system(scene_spawn_roots_system).in_set(scene_spawner_set_spawn),
    )
    |> @app.chain(),
  )
  .configure_set(@app.PreUpdate, scene_spawner_set_spawn, before=[
    @transform.transform_set_mark_dirty_trees,
  ])
}

///|
pub(all) struct ScenePlugin {
  lod_visibility_policy : GltfLodVisibilityPolicy
}

///|
const SCENE_PLUGIN_NAME : String = "mgstudio.scene.ScenePlugin"

///|
pub fn ScenePlugin::default() -> ScenePlugin {
  ScenePlugin::{ lod_visibility_policy: GltfLodVisibilityPolicy::default() }
}

///|
pub fn ScenePlugin::with_gltf_lod_visibility_policy(
  self : ScenePlugin,
  policy : GltfLodVisibilityPolicy,
) -> ScenePlugin {
  ignore(self)
  ScenePlugin::{ lod_visibility_policy: policy }
}

///|
pub impl @app.Plugin for ScenePlugin with name(_self) {
  SCENE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ScenePlugin with build(self, app) {
  scene_plugin_with(app, self)
}

///|
pub fn scene_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  scene_plugin_with(app, ScenePlugin::default())
}

///|
pub fn scene_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ScenePlugin,
) -> @app.App[@ecs.World] {
  @gltf.gltf_install_loader_registration(scene_register_gltf_asset_loaders)
  scene_runtime_plugin_base(
    scene_init_gltf_assets(app)
    .init_resource(fn() {
      let assets : @asset.Assets[Scene] = @asset.Assets::new()
      assets
    })
    .init_resource(fn() {
      SceneAssetRegistryState::{
        scene_registry: [],
        animation_registry: [],
        mesh_registry: [],
        lod_visibility_policy: plugin.lod_visibility_policy,
      }
    }),
  )
}
