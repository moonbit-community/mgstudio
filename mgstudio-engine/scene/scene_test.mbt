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
fn run_scene_test_app_with_gltf_plugin(
  gltf_plugin : @gltf.GltfPlugin,
  system : (@ecs.World) -> Unit,
) -> Unit {
  @app.App::new(@ecs.World::new())
  .add_plugins(@asset.AssetPlugin::default())
  .add_plugins(@mesh.MeshPlugin::default())
  .add_plugins(@render.RenderPlugin::default())
  .add_plugins(@shader.ShaderPlugin::default())
  .add_plugins(@pbr.PbrPlugin::default())
  .add_plugins(@animation.AnimationPlugin::default())
  .add_plugins(@scene.ScenePlugin::default())
  .add_plugins(gltf_plugin)
  .add_plugins(@time.TimePlugin::default())
  .add_system(system)
  .run_once()
  |> ignore
}

///|
fn run_scene_test_app(system : (@ecs.World) -> Unit) -> Unit {
  run_scene_test_app_with_gltf_plugin(@gltf.GltfPlugin::default(), system)
}

///|
fn run_scene_reload_frame(world : @ecs.World) -> Unit {
  @asset.asset_update_event_messages(world)
  @scene.scene_reload_modified_roots_system(world)
  @scene.scene_spawn_roots_system(world)
}

///|
fn scene_test_add_inverse_bindposes_asset(
  world : @ecs.World,
  inverse_bindposes : Array[@mesh.SkinningMat4],
) -> @asset.Handle[@mesh.SkinnedMeshInverseBindposes] {
  let key : @ecs.ResourceKey[@asset.Assets[@mesh.SkinnedMeshInverseBindposes]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets_ref) =>
      assets_ref.val.add(
        @mesh.SkinnedMeshInverseBindposes::new(inverse_bindposes),
      )
    None =>
      abort(
        "scene test requires Assets<SkinnedMeshInverseBindposes>; MeshPlugin must be installed",
      )
  }
}

///|
test "scene: load gltf animation keeps stable handle" {
  let same_handle = Ref(false)
  run_scene_test_app(fn(_world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Animation(1).from_asset(
      "models/Foo/Foo.gltf",
    )
    let first = @scene.scene_load_gltf_animation(asset_server, path)
    let second = @scene.scene_load_gltf_animation(asset_server, path)
    same_handle.val = first.id() == second.id()
  })
  debug_inspect(same_handle.val, content="true")
}

///|
test "scene: load gltf primitive mesh keeps stable handle" {
  let same_handle = Ref(false)
  run_scene_test_app(fn(_world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(
      "models/torus/torus.gltf",
    )
    let first : @asset.Handle[@mesh.Mesh] = asset_server.load(path)
    let second : @asset.Handle[@mesh.Mesh] = asset_server.load(path)
    same_handle.val = first.id() == second.id()
  })
  debug_inspect(same_handle.val, content="true")
}

///|
test "scene: load gltf primitive mesh stays pending in the issuing frame" {
  let asset_missing = Ref(false)
  run_scene_test_app(fn(world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(
      "models/torus/torus.gltf",
    )
    let handle : @asset.Handle[@mesh.Mesh] = asset_server.load(path)
    let key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
    let meshes = (try! world.get_resource(key)).unwrap()
    asset_missing.val = meshes.get(handle) is None
  })
  debug_inspect(asset_missing.val, content="true")
}

///|
test "scene: root gltf asset loads default scene through Assets<Gltf>" {
  let root_loaded = Ref(false)
  let scene_count = Ref(0)
  let named_scene_count = Ref(0)
  let named_scene_contains_scene = Ref(false)
  let has_default_scene = Ref(false)
  let first_scene_ready = Ref(false)
  let source_is_none = Ref(false)
  let gltf_handle_ref : Ref[@asset.Handle[Gltf]?] = Ref(None)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(@shader.ShaderPlugin::default())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(@pbr.PbrPlugin::default())
    .add_plugins(@animation.AnimationPlugin::default())
    .add_plugins(@scene.ScenePlugin::default())
    .add_plugins(@gltf.GltfPlugin::default())
    .add_plugins(@time.TimePlugin::default())
    .add_systems(
      @app.Startup,
      @app.system(fn(_world : @ecs.World) {
        gltf_handle_ref.val = Some(
          @asset.AssetServer::new().load("models/torus/torus.gltf"),
        )
      }),
    )
  let gltf_assets_key : @ecs.ResourceKey[@asset.Assets[Gltf]] = @asset.assets_resource_key()
  let scene_assets_key : @ecs.ResourceKey[@asset.Assets[Scene]] = @asset.assets_resource_key()

  for _ in 0..<120 {
    app = app.run_once()
    guard gltf_handle_ref.val is Some(handle) else { continue }
    let frame_world = app.world()
    let gltf_assets = match (try! frame_world.get_resource(gltf_assets_key)) {
      Some(assets) => assets
      None => abort("expected Assets<Gltf> resource")
    }
    let scene_assets = match (try! frame_world.get_resource(scene_assets_key)) {
      Some(assets) => assets
      None => abort("expected Assets<Scene> resource")
    }
    if gltf_assets.get(handle) is Some(gltf) {
      root_loaded.val = true
      scene_count.val = gltf.scenes.length()
      named_scene_count.val = gltf.named_scenes.length()
      named_scene_contains_scene.val = false
      for named_scene in gltf.named_scenes {
        if named_scene.0 == "Scene" {
          named_scene_contains_scene.val = true
          break
        }
      }
      has_default_scene.val = gltf.default_scene is Some(_)
      source_is_none.val = gltf.source is None
      if gltf.scenes.length() > 0 {
        first_scene_ready.val = match scene_assets.get(gltf.scenes[0]) {
          Some(scene) => scene.ready
          None => false
        }
      }
      break
    }
  }

  debug_inspect(root_loaded.val, content="true")
  debug_inspect(scene_count.val == 1, content="true")
  debug_inspect(named_scene_count.val == 1, content="true")
  debug_inspect(named_scene_contains_scene.val, content="true")
  debug_inspect(has_default_scene.val, content="true")
  debug_inspect(first_scene_ready.val, content="true")
  debug_inspect(source_is_none.val, content="true")
}

///|
test "scene: root gltf include_source keeps source payload" {
  let root_loaded = Ref(false)
  let source_included = Ref(false)
  let gltf_handle_ref : Ref[@asset.Handle[Gltf]?] = Ref(None)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(@shader.ShaderPlugin::default())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(@pbr.PbrPlugin::default())
    .add_plugins(@animation.AnimationPlugin::default())
    .add_plugins(@scene.ScenePlugin::default())
    .add_plugins(@gltf.GltfPlugin::default())
    .add_plugins(@time.TimePlugin::default())
    .add_systems(
      @app.Startup,
      @app.system(fn(_world : @ecs.World) {
        gltf_handle_ref.val = Some(
          @asset.AssetServer::new().load_with_settings(
            "models/torus/torus.gltf",
            fn(settings : @asset.ImageLoaderSettings) {
              settings.include_source = true
            },
          ),
        )
      }),
    )
  let gltf_assets_key : @ecs.ResourceKey[@asset.Assets[Gltf]] = @asset.assets_resource_key()
  for _ in 0..<120 {
    app = app.run_once()
    guard gltf_handle_ref.val is Some(handle) else { continue }
    let frame_world = app.world()
    let gltf_assets = match (try! frame_world.get_resource(gltf_assets_key)) {
      Some(assets) => assets
      None => abort("expected Assets<Gltf> resource")
    }
    if gltf_assets.get(handle) is Some(gltf) {
      root_loaded.val = true
      source_included.val = match gltf.source {
        Some(source) => source.contains("\"asset\"")
        None => false
      }
      break
    }
  }

  debug_inspect(root_loaded.val, content="true")
  debug_inspect(source_included.val, content="true")
}

///|
test "scene: root gltf asset collects materials and named_materials" {
  let root_loaded = Ref(false)
  let material_count = Ref(0)
  let named_material_count = Ref(0)
  let has_named_trunk = Ref(false)
  let trunk_material_loaded = Ref(false)
  let trunk_material_cull_none = Ref(false)
  let gltf_handle_ref : Ref[@asset.Handle[Gltf]?] = Ref(None)

  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(@mesh.MeshPlugin::default())
    .add_plugins(@shader.ShaderPlugin::default())
    .add_plugins(@render.RenderPlugin::default())
    .add_plugins(@pbr.PbrPlugin::default())
    .add_plugins(@animation.AnimationPlugin::default())
    .add_plugins(@scene.ScenePlugin::default())
    .add_plugins(@gltf.GltfPlugin::default())
    .add_plugins(@time.TimePlugin::default())
    .add_systems(
      @app.Startup,
      @app.system(fn(_world : @ecs.World) {
        gltf_handle_ref.val = Some(
          @asset.AssetServer::new().load("models/PalmTree/PalmTree.gltf"),
        )
      }),
    )
  let gltf_assets_key : @ecs.ResourceKey[@asset.Assets[Gltf]] = @asset.assets_resource_key()
  let material_assets_key : @ecs.ResourceKey[
    @asset.Assets[@pbr.StandardMaterial],
  ] = @asset.assets_resource_key()

  for _ in 0..<180 {
    app = app.run_once()
    guard gltf_handle_ref.val is Some(handle) else { continue }
    let frame_world = app.world()
    let gltf_assets = match (try! frame_world.get_resource(gltf_assets_key)) {
      Some(assets) => assets
      None => abort("expected Assets<Gltf> resource")
    }
    let material_assets = match
      (try! frame_world.get_resource(material_assets_key)) {
      Some(assets) => assets
      None => abort("expected Assets<StandardMaterial> resource")
    }
    if gltf_assets.get(handle) is Some(gltf) {
      root_loaded.val = true
      material_count.val = gltf.materials.length()
      named_material_count.val = gltf.named_materials.length()
      has_named_trunk.val = false
      trunk_material_loaded.val = false
      trunk_material_cull_none.val = false
      for named_material in gltf.named_materials {
        if named_material.0 == "Trunk" {
          has_named_trunk.val = true
          if material_assets.get(named_material.1) is Some(material) {
            trunk_material_loaded.val = true
            trunk_material_cull_none.val = material.cull_mode is None
          }
          break
        }
      }
      break
    }
  }

  debug_inspect(root_loaded.val, content="true")
  debug_inspect(material_count.val == 4, content="true")
  debug_inspect(named_material_count.val == 4, content="true")
  debug_inspect(has_named_trunk.val, content="true")
  debug_inspect(trunk_material_loaded.val, content="true")
  debug_inspect(trunk_material_cull_none.val, content="true")
}

///|
test "scene: register keeps stable handle" {
  let same_handle = Ref(false)
  let ready_scene = Ref(false)
  run_scene_test_app(fn(_world : @ecs.World) {
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
    let first_handle = @scene.scene_register_gltf_scene(
      path,
      @scene.Scene::new([]),
    )
    let second_handle = @scene.scene_register_gltf_scene(
      path,
      @scene.Scene::new([]),
    )
    same_handle.val = first_handle.id() == second_handle.id()
    ready_scene.val = @scene.scene_get(second_handle).unwrap().ready
  })
  debug_inspect(same_handle.val, content="true")
  debug_inspect(ready_scene.val, content="true")
}

///|
test "scene: spawn applies camera and light components from scene node payload" {
  let camera_count = Ref(0)
  let camera3d_count = Ref(0)
  let projection_count = Ref(0)
  let directional_count = Ref(0)
  let point_count = Ref(0)
  let spot_count = Ref(0)

  run_scene_test_app(fn(world : @ecs.World) {
    let scene_handle = @scene.scene_register_gltf_scene(
      "models/Foo/Foo.gltf#camera-lights",
      @scene.Scene::new([
        @scene.SceneNode3d::new_empty(
          @transform.Transform::identity(),
          None,
          None,
          camera=Some(@sprite.Camera::default()),
          camera3d=Some(@camera.Camera3d::default()),
          projection=Some(@camera.Projection::default()),
        ),
        @scene.SceneNode3d::new_empty(
          @transform.Transform::identity(),
          None,
          None,
          parent_node_index=Some(0),
          directional_light=Some(@light.DirectionalLight::default()),
        ),
        @scene.SceneNode3d::new_empty(
          @transform.Transform::identity(),
          None,
          None,
          parent_node_index=Some(0),
          point_light=Some(@light.PointLight::default()),
        ),
        @scene.SceneNode3d::new_empty(
          @transform.Transform::identity(),
          None,
          None,
          parent_node_index=Some(0),
          spot_light=Some(@light.SpotLight::default()),
        ),
      ]),
    )
    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    @scene.scene_spawn_roots_system(world)

    world.for_each_component(@sprite.Camera::component(), fn(_entity, _camera) {
      camera_count.val = camera_count.val + 1
    })
    world.for_each_component(@camera.Camera3d::component(), fn(
      _entity,
      _camera3d,
    ) {
      camera3d_count.val = camera3d_count.val + 1
    })
    world.for_each_component(@camera.Projection::component(), fn(
      _entity,
      _projection,
    ) {
      projection_count.val = projection_count.val + 1
    })
    world.for_each_component(@light.DirectionalLight::component(), fn(
      _entity,
      _light,
    ) {
      directional_count.val = directional_count.val + 1
    })
    world.for_each_component(@light.PointLight::component(), fn(
      _entity,
      _light,
    ) {
      point_count.val = point_count.val + 1
    })
    world.for_each_component(@light.SpotLight::component(), fn(
      _entity,
      _light,
    ) {
      spot_count.val = spot_count.val + 1
    })
  })

  debug_inspect(camera_count.val == 1, content="true")
  debug_inspect(camera3d_count.val == 1, content="true")
  debug_inspect(projection_count.val == 1, content="true")
  debug_inspect(directional_count.val == 1, content="true")
  debug_inspect(point_count.val == 1, content="true")
  debug_inspect(spot_count.val == 1, content="true")
}

///|
test "scene: skinned mesh joints map by gltf node index" {
  let skinned_present = Ref(false)
  let joint_count = Ref(0)
  let first_joint_ok = Ref(false)
  let second_joint_ok = Ref(false)
  let inverse_bindposes_count = Ref(0)
  let has_dynamic_bounds = Ref(false)
  let has_no_frustum_culling = Ref(false)

  run_scene_test_app(fn(world : @ecs.World) {
    let mesh = @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    )
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(@pbr.StandardMaterial::default()),
    )
    let inverse_bindposes_handle = scene_test_add_inverse_bindposes_asset(
      world,
      [@mesh.SkinningMat4::identity(), @mesh.SkinningMat4::identity()],
    )
    let scene_handle = @scene.scene_register_gltf_scene(
      "models/Foo/Foo.gltf#skinned-joint-remap",
      @scene.Scene::new([
        @scene.SceneNode3d::new_empty(
          @transform.Transform::identity(),
          None,
          None,
          parent_node_index=Some(1),
          gltf_node_index=Some(@gltf.GltfNodeIndex::new(42)),
        ),
        @scene.SceneNode3d::new(
          mesh,
          material,
          @transform.Transform::identity(),
          None,
          None,
          gltf_node_index=Some(@gltf.GltfNodeIndex::new(5)),
          skinned_joint_node_indices=Some([7, 42]),
          skinned_inverse_bindposes=Some(inverse_bindposes_handle),
        ),
        @scene.SceneNode3d::new_empty(
          @transform.Transform::identity(),
          None,
          None,
          parent_node_index=Some(1),
          gltf_node_index=Some(@gltf.GltfNodeIndex::new(7)),
        ),
      ]),
    )
    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    @scene.scene_spawn_roots_system(world)

    let mesh_entity : Ref[@core.Entity?] = Ref(None)
    let node7_entity : Ref[@core.Entity?] = Ref(None)
    let node42_entity : Ref[@core.Entity?] = Ref(None)
    world.for_each_component(@gltf.GltfNodeIndex::component(), fn(
      entity,
      node_index,
    ) {
      if node_index.index() == 5 {
        mesh_entity.val = Some(entity)
      } else if node_index.index() == 7 {
        node7_entity.val = Some(entity)
      } else if node_index.index() == 42 {
        node42_entity.val = Some(entity)
      }
    })

    guard mesh_entity.val is Some(mesh_node) else { return }
    guard (try! world.entity(mesh_node).get() : @mesh.SkinnedMesh?)
      is Some(skinned_mesh) else {
      return
    }
    skinned_present.val = true
    let joints = skinned_mesh.joints()
    joint_count.val = joints.length()
    if joints.length() >= 2 &&
      node7_entity.val is Some(node7) &&
      node42_entity.val is Some(node42) {
      first_joint_ok.val = joints[0].id == node7.id
      second_joint_ok.val = joints[1].id == node42.id
    }
    has_dynamic_bounds.val = (
        try! world.entity(mesh_node).get() : @mesh.DynamicSkinnedMeshBounds?)
      is Some(_)
    has_no_frustum_culling.val = (
        try! world.entity(mesh_node).get() : @visibility.NoFrustumCulling?)
      is Some(_)
    let inverse_bindposes_assets_key : @ecs.ResourceKey[
      @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
    ] = @asset.assets_resource_key()
    match (try! world.get_resource(inverse_bindposes_assets_key)) {
      Some(inverse_bindposes_assets) =>
        if inverse_bindposes_assets.get(skinned_mesh.inverse_bindposes())
          is Some(inverse_bindposes) {
          inverse_bindposes_count.val = inverse_bindposes.len()
        }
      None => ()
    }
  })

  debug_inspect(skinned_present.val, content="true")
  debug_inspect(joint_count.val, content="2")
  debug_inspect(first_joint_ok.val, content="true")
  debug_inspect(second_joint_ok.val, content="true")
  debug_inspect(inverse_bindposes_count.val, content="2")
  debug_inspect(has_dynamic_bounds.val, content="true")
  debug_inspect(has_no_frustum_culling.val, content="false")
}

///|
test "scene: skinned mesh skips when any gltf joint node is unresolved" {
  let skinned_present = Ref(false)

  run_scene_test_app(fn(world : @ecs.World) {
    let mesh = @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    )
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(@pbr.StandardMaterial::default()),
    )
    let inverse_bindposes_handle = scene_test_add_inverse_bindposes_asset(
      world,
      [@mesh.SkinningMat4::identity(), @mesh.SkinningMat4::identity()],
    )
    let scene_handle = @scene.scene_register_gltf_scene(
      "models/Foo/Foo.gltf#skinned-missing-joint",
      @scene.Scene::new([
        @scene.SceneNode3d::new(
          mesh,
          material,
          @transform.Transform::identity(),
          None,
          None,
          gltf_node_index=Some(@gltf.GltfNodeIndex::new(5)),
          skinned_joint_node_indices=Some([7, 42]),
          skinned_inverse_bindposes=Some(inverse_bindposes_handle),
        ),
        @scene.SceneNode3d::new_empty(
          @transform.Transform::identity(),
          None,
          None,
          parent_node_index=Some(0),
          gltf_node_index=Some(@gltf.GltfNodeIndex::new(7)),
        ),
      ]),
    )

    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    @scene.scene_spawn_roots_system(world)

    world.for_each_component(@gltf.GltfNodeIndex::component(), fn(
      entity,
      node_index,
    ) {
      if node_index.index() == 5 &&
        (try! world.entity(entity).get() : @mesh.SkinnedMesh?) is Some(_) {
        skinned_present.val = true
      }
    })
  })

  debug_inspect(skinned_present.val, content="false")
}

///|
test "scene: skinned mesh policy NoFrustumCulling inserts no-frustum component" {
  let has_dynamic_bounds = Ref(false)
  let has_no_frustum_culling = Ref(false)

  run_scene_test_app_with_gltf_plugin(
    @gltf.GltfPlugin::default().with_skinned_mesh_bounds_policy(
      @gltf.GltfSkinnedMeshBoundsPolicy::NoFrustumCulling,
    ),
    fn(world : @ecs.World) {
      let mesh = @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
          ),
        ),
      )
      let material = @pbr.MeshMaterial3d::new(
        @pbr.standard_material_add(@pbr.StandardMaterial::default()),
      )
      let inverse_bindposes_handle = scene_test_add_inverse_bindposes_asset(
        world,
        [@mesh.SkinningMat4::identity(), @mesh.SkinningMat4::identity()],
      )
      let scene_handle = @scene.scene_register_gltf_scene(
        "models/Foo/Foo.gltf#skinned-no-frustum-policy",
        @scene.Scene::new([
          @scene.SceneNode3d::new(
            mesh,
            material,
            @transform.Transform::identity(),
            None,
            None,
            gltf_node_index=Some(@gltf.GltfNodeIndex::new(5)),
            skinned_joint_node_indices=Some([7, 42]),
            skinned_inverse_bindposes=Some(inverse_bindposes_handle),
          ),
          @scene.SceneNode3d::new_empty(
            @transform.Transform::identity(),
            None,
            None,
            parent_node_index=Some(0),
            gltf_node_index=Some(@gltf.GltfNodeIndex::new(7)),
          ),
          @scene.SceneNode3d::new_empty(
            @transform.Transform::identity(),
            None,
            None,
            parent_node_index=Some(0),
            gltf_node_index=Some(@gltf.GltfNodeIndex::new(42)),
          ),
        ]),
      )

      let root = world.spawn_empty()
      try! world.set_by_key(
        root,
        @scene.ecs_key_scene_root,
        @scene.SceneRoot::new(scene_handle),
      )
      @scene.scene_spawn_roots_system(world)

      world.for_each_component(@gltf.GltfNodeIndex::component(), fn(
        entity,
        node_index,
      ) {
        if node_index.index() == 5 {
          has_dynamic_bounds.val = (
              try! world.entity(entity).get() : @mesh.DynamicSkinnedMeshBounds?)
            is Some(_)
          has_no_frustum_culling.val = (
              try! world.entity(entity).get() : @visibility.NoFrustumCulling?)
            is Some(_)
        }
      })
    },
  )

  debug_inspect(has_dynamic_bounds.val, content="false")
  debug_inspect(has_no_frustum_culling.val, content="true")
}

///|
test "scene: skinned mesh policy BindPose keeps static bounds components unset" {
  let has_dynamic_bounds = Ref(false)
  let has_no_frustum_culling = Ref(false)

  run_scene_test_app_with_gltf_plugin(
    @gltf.GltfPlugin::default().with_skinned_mesh_bounds_policy(
      @gltf.GltfSkinnedMeshBoundsPolicy::BindPose,
    ),
    fn(world : @ecs.World) {
      let mesh = @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
          ),
        ),
      )
      let material = @pbr.MeshMaterial3d::new(
        @pbr.standard_material_add(@pbr.StandardMaterial::default()),
      )
      let inverse_bindposes_handle = scene_test_add_inverse_bindposes_asset(
        world,
        [@mesh.SkinningMat4::identity(), @mesh.SkinningMat4::identity()],
      )
      let scene_handle = @scene.scene_register_gltf_scene(
        "models/Foo/Foo.gltf#skinned-bind-pose-policy",
        @scene.Scene::new([
          @scene.SceneNode3d::new(
            mesh,
            material,
            @transform.Transform::identity(),
            None,
            None,
            gltf_node_index=Some(@gltf.GltfNodeIndex::new(5)),
            skinned_joint_node_indices=Some([7, 42]),
            skinned_inverse_bindposes=Some(inverse_bindposes_handle),
          ),
          @scene.SceneNode3d::new_empty(
            @transform.Transform::identity(),
            None,
            None,
            parent_node_index=Some(0),
            gltf_node_index=Some(@gltf.GltfNodeIndex::new(7)),
          ),
          @scene.SceneNode3d::new_empty(
            @transform.Transform::identity(),
            None,
            None,
            parent_node_index=Some(0),
            gltf_node_index=Some(@gltf.GltfNodeIndex::new(42)),
          ),
        ]),
      )

      let root = world.spawn_empty()
      try! world.set_by_key(
        root,
        @scene.ecs_key_scene_root,
        @scene.SceneRoot::new(scene_handle),
      )
      @scene.scene_spawn_roots_system(world)

      world.for_each_component(@gltf.GltfNodeIndex::component(), fn(
        entity,
        node_index,
      ) {
        if node_index.index() == 5 {
          has_dynamic_bounds.val = (
              try! world.entity(entity).get() : @mesh.DynamicSkinnedMeshBounds?)
            is Some(_)
          has_no_frustum_culling.val = (
              try! world.entity(entity).get() : @visibility.NoFrustumCulling?)
            is Some(_)
        }
      })
    },
  )

  debug_inspect(has_dynamic_bounds.val, content="false")
  debug_inspect(has_no_frustum_culling.val, content="false")
}

///|
test "scene: SceneRoot propagates gltf extras metadata" {
  let root_scene_extras = Ref("")
  let child_name = Ref("")
  let child_scene_index = Ref(-1)
  let child_node_index = Ref(-1)
  let child_mesh_index = Ref(-1)
  let child_primitive_mesh_index = Ref(-1)
  let child_primitive_index = Ref(-1)
  let primitive_extras = Ref("")
  let mesh_extras = Ref("")
  let material_extras = Ref("")

  run_scene_test_app(fn(world : @ecs.World) {
    let scene_handle = @scene.scene_register_gltf_scene(
      "models/Foo/Foo.gltf#extras",
      @scene.Scene::new([
        SceneNode3d::new(
          @pbr.Mesh3d::new(
            @pbr.mesh_assets_mut_or_abort().val.add(
              @pbr.Mesh::from_3d_geometry(
                @pbr.mesh3d_geometry_triangle(
                  @math.Triangle3d::new(
                    @math.Vec3::new(0.0F, 0.0F, 0.0F),
                    @math.Vec3::new(1.0F, 0.0F, 0.0F),
                    @math.Vec3::new(0.0F, 1.0F, 0.0F),
                  ),
                ),
              ),
            ),
          ),
          @pbr.MeshMaterial3d::new(
            @pbr.standard_material_add(@pbr.StandardMaterial::default()),
          ),
          @transform.Transform::identity(),
          None,
          None,
          name=Some(@ecs.Name::new("NamedMesh.Top")),
          gltf_scene_index=Some(@gltf.GltfSceneIndex::new(2)),
          gltf_node_index=Some(@gltf.GltfNodeIndex::new(3)),
          gltf_mesh_index=Some(@gltf.GltfMeshIndex::new(4)),
          gltf_primitive_index=Some(@gltf.GltfPrimitiveIndex::new(4, 5)),
          gltf_material_name=Some(@gltf.GltfMaterialName::new("Top")),
          gltf_extras=Some(@gltf.GltfExtras::new("{\"primitive\":1}")),
          gltf_mesh_extras=Some(@gltf.GltfMeshExtras::new("{\"mesh\":true}")),
          gltf_material_extras=Some(
            @gltf.GltfMaterialExtras::new("{\"material\":\"value\"}"),
          ),
        ),
      ]).with_gltf_scene_extras(
        Some(@gltf.GltfSceneExtras::new("{\"scene\":\"root\"}")),
      ),
    )

    let root = world.spawn()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    @scene.scene_spawn_roots_system(world)

    if (try! world.entity(root).get() : @gltf.GltfSceneExtras?) is Some(extras) {
      root_scene_extras.val = extras.as_str()
    }

    if (try! world.entity(root).get() : @hierarchy.Children?) is Some(children) {
      for child in children.entities() {
        if (try! world.entity(child).get() : @ecs.Name?) is Some(name) {
          child_name.val = name.as_str()
        }
        if (try! world.entity(child).get() : @gltf.GltfSceneIndex?)
          is Some(scene_index) {
          child_scene_index.val = scene_index.index()
        }
        if (try! world.entity(child).get() : @gltf.GltfNodeIndex?)
          is Some(node_index) {
          child_node_index.val = node_index.index()
        }
        if (try! world.entity(child).get() : @gltf.GltfMeshIndex?)
          is Some(mesh_index) {
          child_mesh_index.val = mesh_index.index()
        }
        if (try! world.entity(child).get() : @gltf.GltfPrimitiveIndex?)
          is Some(primitive_index) {
          child_primitive_mesh_index.val = primitive_index.mesh_index()
          child_primitive_index.val = primitive_index.primitive_index()
        }
        if (try! world.entity(child).get() : @gltf.GltfExtras?) is Some(extras) {
          primitive_extras.val = extras.as_str()
        }
        if (try! world.entity(child).get() : @gltf.GltfMeshExtras?)
          is Some(extras) {
          mesh_extras.val = extras.as_str()
        }
        if (try! world.entity(child).get() : @gltf.GltfMaterialExtras?)
          is Some(extras) {
          material_extras.val = extras.as_str()
        }
      }
    }
  })

  debug_inspect(
    root_scene_extras.val,
    content="\"{\\\"scene\\\":\\\"root\\\"}\"",
  )
  debug_inspect(child_name.val, content="\"NamedMesh.Top\"")
  debug_inspect(child_scene_index.val, content="2")
  debug_inspect(child_node_index.val, content="3")
  debug_inspect(child_mesh_index.val, content="4")
  debug_inspect(child_primitive_mesh_index.val, content="4")
  debug_inspect(child_primitive_index.val, content="5")
  debug_inspect(primitive_extras.val, content="\"{\\\"primitive\\\":1}\"")
  debug_inspect(mesh_extras.val, content="\"{\\\"mesh\\\":true}\"")
  debug_inspect(
    material_extras.val,
    content="\"{\\\"material\\\":\\\"value\\\"}\"",
  )
}

///|
test "scene: gltf lod visibility policy set/get/reset" {
  let default_enabled = Ref(false)
  let default_step = Ref(0.0)
  let customized_enabled = Ref(true)
  let customized_start = Ref(0.0)
  let customized_end = Ref(0.0)
  let customized_step = Ref(0.0)
  let restored_enabled = Ref(false)
  let restored_end = Ref(0.0)
  let restored_step = Ref(0.0)
  run_scene_test_app(fn(_world : @ecs.World) {
    @scene.scene_reset_gltf_lod_visibility_policy()
    let default_policy = @scene.scene_get_gltf_lod_visibility_policy()
    default_enabled.val = default_policy.enabled
    default_step.val = default_policy.step.to_double()

    @scene.scene_set_gltf_lod_visibility_policy(
      default_policy
      .with_first_lod_range(1.0F, 2.0F, 6.0F, 7.0F)
      .with_step(3.0F)
      .with_enabled(false),
    )
    let customized = @scene.scene_get_gltf_lod_visibility_policy()
    customized_enabled.val = customized.enabled
    customized_start.val = customized.first_start_margin_min.to_double()
    customized_end.val = customized.first_end_margin_max.to_double()
    customized_step.val = customized.step.to_double()

    @scene.scene_reset_gltf_lod_visibility_policy()
    let restored = @scene.scene_get_gltf_lod_visibility_policy()
    restored_enabled.val = restored.enabled
    restored_end.val = restored.first_end_margin_min.to_double()
    restored_step.val = restored.step.to_double()
  })
  debug_inspect(default_enabled.val, content="true")
  debug_inspect(default_step.val, content="5")
  debug_inspect(customized_enabled.val, content="false")
  debug_inspect(customized_start.val, content="1")
  debug_inspect(customized_end.val, content="7")
  debug_inspect(customized_step.val, content="3")
  debug_inspect(restored_enabled.val, content="true")
  debug_inspect(restored_end.val, content="3")
  debug_inspect(restored_step.val, content="5")
}

///|
test "scene: SceneRoot inserts default transform and visibility" {
  let has_transform = Ref(false)
  let has_visibility = Ref(false)
  let inherited_visibility = Ref(false)
  run_scene_test_app(fn(world : @ecs.World) {
    let scene_handle = @scene.scene_register_gltf_scene(
      "models/Foo/Foo.gltf#scene-root-default-components",
      @scene.Scene::new([]),
    )
    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    has_transform.val = try! world.contains_by_key(
      root, @transform.ecs_key_transform,
    )
    has_visibility.val = try! world.contains_by_key(
      root, @visibility.ecs_key_visibility,
    )
    inherited_visibility.val = match
      (try! world.get_by_key(root, @visibility.ecs_key_visibility)) {
      Some(@visibility.Visibility::Inherited) => true
      _ => false
    }
  })
  debug_inspect(has_transform.val, content="true")
  debug_inspect(has_visibility.val, content="true")
  debug_inspect(inherited_visibility.val, content="true")
}

///|
test "scene: removing SceneRoot despawns spawned children" {
  let child_alive_after_remove = Ref(true)
  let has_instance_after_remove = Ref(true)
  let has_ready_after_remove = Ref(true)
  run_scene_test_app(fn(world : @ecs.World) {
    let scene_handle = @scene.scene_register_gltf_scene(
      "models/Foo/Foo.gltf#scene-root-remove-despawn",
      @scene.Scene::new([
        @scene.SceneNode3d::new(
          @pbr.Mesh3d::new(
            @pbr.mesh_assets_mut_or_abort().val.add(
              @pbr.Mesh::from_3d_geometry(
                @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
              ),
            ),
          ),
          @pbr.MeshMaterial3d::new(
            @pbr.standard_material_add(@pbr.StandardMaterial::default()),
          ),
          @transform.Transform::identity(),
          None,
          None,
        ),
      ]),
    )
    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    @scene.scene_spawn_roots_system(world)

    let child_entity : Ref[@core.Entity?] = Ref(None)
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        child_entity.val = Some(entity)
      }
    })
    guard child_entity.val is Some(child) else { return }
    ignore(try! world.remove_by_key(root, @scene.ecs_key_scene_root))

    child_alive_after_remove.val = world.is_alive(child)
    has_instance_after_remove.val = try! world.contains_by_key(
      root, @scene.ecs_key_scene_instance,
    )
    has_ready_after_remove.val = @scene.scene_components_has_scene_instance_ready(
      world, root,
    )
  })
  debug_inspect(child_alive_after_remove.val, content="false")
  debug_inspect(has_instance_after_remove.val, content="false")
  debug_inspect(has_ready_after_remove.val, content="false")
}

///|
test "scene: SceneRoot spawns children and marks ready" {
  let instance_id = Ref(0)
  let ready_instance_id = Ref(0)
  let spawned_entities = Ref(0)
  let child_count = Ref(0)
  let child_count_after_second_tick = Ref(0)
  ignore(child_count_after_second_tick)
  let has_mesh = Ref(false)
  let has_material = Ref(false)
  let has_transform = Ref(false)
  let has_visibility = Ref(false)
  let has_player = Ref(false)
  let root_has_player = Ref(true)
  let animated_by_points_to_player = Ref(false)
  let has_target = Ref(false)
  let has_animated_by = Ref(false)
  let instance_after_second_tick = Ref(0)
  ignore(instance_after_second_tick)
  let ready_after_second_tick = Ref(0)
  ignore(ready_after_second_tick)
  run_scene_test_app(fn(world : @ecs.World) {
    let tick = world.advance_sequence()
    ignore(tick)
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let node = @scene.SceneNode3d::new(
      @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(1.0F, 2.0F, 3.0F),
          ),
        ),
      ),
      material,
      @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
      Some(@visibility.VisibilityRange::new(0.0F, 0.0F, 4.0F, 5.0F, false)),
      Some(@animation.AnimationTargetId::from_name("Node")),
      animation_root=true,
    )
    let scene_handle = @scene.scene_register_gltf_scene(
      path,
      @scene.Scene::new([node]),
    )

    let root = world.spawn_empty()
    ignore(
      world.add_observer(fn(event : @ecs.On[@scene.SceneInstanceReady]) {
        guard event.entity() is Some(event_entity) else { return }
        if event_entity.id != root.id {
          return
        }
        let ready = event.event()
        ready_instance_id.val = ready.instance_id
        spawned_entities.val = @scene.scene_iter_instance_entities(
          world,
          ready.instance_id,
        ).length()
      }),
    )
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )

    @scene.scene_spawn_roots_system(world)

    let instance = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    instance_id.val = instance.instance_id

    let children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        children.push(entity)
      }
    })
    child_count.val = children.length()

    let child = children[0]
    has_mesh.val = try! world.contains_by_key(child, @pbr.ecs_key_mesh3d)
    has_material.val = try! world.contains_by_key(
      child, @pbr.ecs_key_mesh_material3d,
    )
    has_transform.val = try! world.contains_by_key(
      child, @transform.ecs_key_transform,
    )
    has_visibility.val = try! world.contains_by_key(
      child, @visibility.ecs_key_visibility_range,
    )
    has_player.val = try! world.contains_by_key(
      child, @animation.ecs_key_animation_player,
    )
    root_has_player.val = try! world.contains_by_key(
      root, @animation.ecs_key_animation_player,
    )
    has_target.val = try! world.contains_by_key(
      child, @animation.ecs_key_animation_target_id,
    )
    match (try! world.get_by_key(child, @animation.ecs_key_animated_by)) {
      Some(animated_by) => {
        has_animated_by.val = true
        animated_by_points_to_player.val = animated_by.player().id == child.id
      }
      None => ()
    }

    @scene.scene_spawn_roots_system(world)
    let instance_second = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    instance_after_second_tick.val = instance_second.instance_id
    ready_after_second_tick.val = spawned_entities.val

    let children_second : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        children_second.push(entity)
      }
    })
    child_count_after_second_tick.val = children_second.length()
  })
  debug_inspect(instance_id.val, content="1")
  debug_inspect(ready_instance_id.val, content="1")
  debug_inspect(spawned_entities.val, content="1")
  debug_inspect(child_count.val, content="1")
  debug_inspect(child_count_after_second_tick.val, content="1")
  debug_inspect(has_mesh.val, content="true")
  debug_inspect(has_material.val, content="true")
  debug_inspect(has_transform.val, content="true")
  debug_inspect(has_visibility.val, content="true")
  debug_inspect(has_player.val, content="true")
  debug_inspect(root_has_player.val, content="false")
  debug_inspect(has_target.val, content="true")
  debug_inspect(has_animated_by.val, content="true")
  debug_inspect(animated_by_points_to_player.val, content="true")
  debug_inspect(instance_after_second_tick.val, content="1")
  debug_inspect(ready_after_second_tick.val, content="1")
}

///|
test "scene: pending SceneInstance retries spawn after scene becomes ready" {
  let has_instance_before_register = Ref(false)
  let has_ready_before_register = Ref(false)
  let ready_after_register = Ref(false)
  let child_count_after_register = Ref(0)
  run_scene_test_app(fn(world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset(
      "models/Foo/Foo.gltf#pending-retry",
    )
    let pending_handle = @scene.scene_load_gltf_scene(asset_server, path)
    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(pending_handle),
    )

    @scene.scene_spawn_roots_system(world)
    has_instance_before_register.val = (try! world.get_by_key(
        root, @scene.ecs_key_scene_instance,
      ))
      is Some(_)
    has_ready_before_register.val = @scene.scene_components_has_scene_instance_ready(
      world, root,
    )

    ignore(
      @scene.scene_register_gltf_scene(
        path,
        @scene.Scene::new([
          @scene.SceneNode3d::new(
            @pbr.Mesh3d::new(
              @pbr.mesh_assets_mut_or_abort().val.add(
                @pbr.Mesh::from_3d_geometry(
                  @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
                ),
              ),
            ),
            @pbr.MeshMaterial3d::new(
              @pbr.standard_material_add(@pbr.StandardMaterial::default()),
            ),
            @transform.Transform::identity(),
            None,
            None,
          ),
        ]),
      ),
    )

    @scene.scene_spawn_roots_system(world)
    ready_after_register.val = @scene.scene_components_has_scene_instance_ready(
      world, root,
    )

    let child_count = Ref(0)
    world.for_each_component(@hierarchy.ecs_key_parent, fn(_entity, parent) {
      if parent.entity().id == root.id {
        child_count.val = child_count.val + 1
      }
    })
    child_count_after_register.val = child_count.val
  })
  debug_inspect(has_instance_before_register.val, content="true")
  debug_inspect(has_ready_before_register.val, content="false")
  debug_inspect(ready_after_register.val, content="true")
  debug_inspect(child_count_after_register.val, content="1")
}

///|
test "scene: instance readiness and entity iteration follow Bevy semantics" {
  let ready_before_register = Ref(false)
  let iter_count_before_register = Ref(0)
  let ready_after_register = Ref(false)
  let iter_count_after_register = Ref(0)
  let iterated_entity_alive = Ref(false)
  run_scene_test_app(fn(world : @ecs.World) {
    let asset_server = @asset.AssetServer::new()
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset(
      "models/Foo/Foo.gltf#instance-iter-ready",
    )
    let pending_handle = @scene.scene_load_gltf_scene(asset_server, path)
    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(pending_handle),
    )

    @scene.scene_spawn_roots_system(world)
    let pending_instance = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    ready_before_register.val = @scene.scene_instance_is_ready(
      world,
      pending_instance.instance_id,
    )
    iter_count_before_register.val = @scene.scene_iter_instance_entities(
      world,
      pending_instance.instance_id,
    ).length()

    ignore(
      @scene.scene_register_gltf_scene(
        path,
        @scene.Scene::new([
          @scene.SceneNode3d::new(
            @pbr.Mesh3d::new(
              @pbr.mesh_assets_mut_or_abort().val.add(
                @pbr.Mesh::from_3d_geometry(
                  @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
                ),
              ),
            ),
            @pbr.MeshMaterial3d::new(
              @pbr.standard_material_add(@pbr.StandardMaterial::default()),
            ),
            @transform.Transform::identity(),
            None,
            None,
          ),
        ]),
      ),
    )

    @scene.scene_spawn_roots_system(world)
    let ready_instance = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    ready_after_register.val = @scene.scene_instance_is_ready(
      world,
      ready_instance.instance_id,
    )
    let iterated_entities = @scene.scene_iter_instance_entities(
      world,
      ready_instance.instance_id,
    )
    iter_count_after_register.val = iterated_entities.length()
    if iterated_entities.length() > 0 {
      iterated_entity_alive.val = world.is_alive(iterated_entities[0])
    }
  })
  debug_inspect(ready_before_register.val, content="false")
  debug_inspect(iter_count_before_register.val, content="0")
  debug_inspect(ready_after_register.val, content="true")
  debug_inspect(iter_count_after_register.val, content="1")
  debug_inspect(iterated_entity_alive.val, content="true")
}

///|
test "scene: unknown scene instance id reports not ready and empty entities" {
  let ready = Ref(true)
  let iter_count = Ref(-1)
  run_scene_test_app(fn(world : @ecs.World) {
    ready.val = @scene.scene_instance_is_ready(world, 999999)
    iter_count.val = @scene.scene_iter_instance_entities(world, 999999).length()
  })
  debug_inspect(ready.val, content="false")
  debug_inspect(iter_count.val, content="0")
}

///|
test "scene: SceneRoot propagates gltf material name" {
  let material_name = Ref("")
  run_scene_test_app(fn(world : @ecs.World) {
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let scene_handle = @scene.scene_register_gltf_scene(
      path,
      @scene.Scene::new([
        @scene.SceneNode3d::new(
          @pbr.Mesh3d::new(
            @pbr.mesh_assets_mut_or_abort().val.add(
              @pbr.Mesh::from_3d_geometry(
                @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
              ),
            ),
          ),
          material,
          @transform.Transform::identity(),
          None,
          None,
          gltf_material_name=Some(
            @gltf.GltfMaterialName::new("LeatherPartsMat"),
          ),
        ),
      ]),
    )

    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    @scene.scene_spawn_roots_system(world)

    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        if (try! world.entity(entity).get() : @gltf.GltfMaterialName?)
          is Some(name) {
          material_name.val = name.as_str()
        }
      }
    })
  })
  debug_inspect(material_name.val, content="\"LeatherPartsMat\"")
}

///|
test "scene: SceneRoot change respawns children and updates SceneInstance" {
  let old_instance_id = Ref(0)
  let new_instance_id = Ref(0)
  let ready_instance_id = Ref(0)
  let spawned_entities = Ref(0)
  let old_child_alive = Ref(true)
  let new_child_count = Ref(0)
  let new_child_x = Ref(0.0)
  run_scene_test_app(fn(world : @ecs.World) {
    let first_tick = world.advance_sequence()
    ignore(first_tick)
    let first_path = @gltf.GltfAssetLabel::Scene(1).from_asset(
      "models/Foo/Foo.gltf",
    )
    let second_path = @gltf.GltfAssetLabel::Scene(2).from_asset(
      "models/Foo/Foo.gltf",
    )
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let first_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(1.0F, 2.0F, 3.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
        None,
        None,
      ),
    ])
    let second_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(4.0F, 5.0F, 6.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(9.0F, 8.0F, 7.0F),
        None,
        None,
      ),
    ])
    let first_handle = @scene.scene_register_gltf_scene(first_path, first_scene)
    let second_handle = @scene.scene_register_gltf_scene(
      second_path, second_scene,
    )

    let root = world.spawn_empty()
    ignore(
      world.add_observer(fn(event : @ecs.On[@scene.SceneInstanceReady]) {
        guard event.entity() is Some(event_entity) else { return }
        if event_entity.id != root.id {
          return
        }
        let ready = event.event()
        ready_instance_id.val = ready.instance_id
        spawned_entities.val = @scene.scene_iter_instance_entities(
          world,
          ready.instance_id,
        ).length()
      }),
    )
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(first_handle),
    )

    @scene.scene_spawn_roots_system(world)
    let first_instance = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    old_instance_id.val = first_instance.instance_id

    let first_children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        first_children.push(entity)
      }
    })
    let first_child = first_children[0]

    try! (world.replace(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(second_handle),
    )
    |> ignore)

    @scene.scene_spawn_roots_system(world)

    let second_instance = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    new_instance_id.val = second_instance.instance_id
    old_child_alive.val = world.is_alive(first_child)

    let second_children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        second_children.push(entity)
      }
    })
    new_child_count.val = second_children.length()
    let new_child = second_children[0]
    let transform = (try! world.get_by_key(
      new_child, @transform.ecs_key_transform,
    )).unwrap()
    new_child_x.val = transform.translation.x.to_double()
  })
  debug_inspect(old_instance_id.val == new_instance_id.val, content="false")
  debug_inspect(ready_instance_id.val == new_instance_id.val, content="true")
  debug_inspect(spawned_entities.val, content="1")
  debug_inspect(old_child_alive.val, content="false")
  debug_inspect(new_child_count.val, content="1")
  debug_inspect(new_child_x.val, content="9")
}

///|
test "scene: changed SceneRoot with same handle still respawns instance" {
  let old_instance_id = Ref(0)
  let new_instance_id = Ref(0)
  let old_child_alive = Ref(true)
  let new_child_count = Ref(0)
  run_scene_test_app(fn(world : @ecs.World) {
    let scene_path = @gltf.GltfAssetLabel::Scene(3).from_asset(
      "models/Foo/Foo.gltf",
    )
    let scene_handle = @scene.scene_register_gltf_scene(
      scene_path,
      @scene.Scene::new([
        @scene.SceneNode3d::new(
          @pbr.Mesh3d::new(
            @pbr.mesh_assets_mut_or_abort().val.add(
              @pbr.Mesh::from_3d_geometry(
                @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
              ),
            ),
          ),
          @pbr.MeshMaterial3d::new(
            @pbr.standard_material_add(@pbr.StandardMaterial::default()),
          ),
          @transform.Transform::identity(),
          None,
          None,
        ),
      ]),
    )
    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )

    @scene.scene_spawn_roots_system(world)
    let first_instance = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    old_instance_id.val = first_instance.instance_id

    let first_children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        first_children.push(entity)
      }
    })
    let first_child = first_children[0]

    try! (world.replace(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(scene_handle),
    )
    |> ignore)
    @scene.scene_spawn_roots_system(world)

    let second_instance = try! world
      .get_by_key(root, @scene.ecs_key_scene_instance)
      .unwrap()
    new_instance_id.val = second_instance.instance_id
    old_child_alive.val = world.is_alive(first_child)

    let second_children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        second_children.push(entity)
      }
    })
    new_child_count.val = second_children.length()
  })
  debug_inspect(old_instance_id.val == new_instance_id.val, content="false")
  debug_inspect(old_child_alive.val, content="false")
  debug_inspect(new_child_count.val, content="1")
}

///|
test "scene: modified scene asset respawns SceneRoot children" {
  let handle_stable = Ref(false)
  let old_child_alive = Ref(true)
  let new_child_count = Ref(0)
  let new_child_x = Ref(0.0)
  run_scene_test_app(fn(world : @ecs.World) {
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset("models/Foo/Foo.gltf")
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let first_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(1.0F, 2.0F, 3.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
        None,
        None,
      ),
    ])
    let second_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(4.0F, 5.0F, 6.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(9.0F, 8.0F, 7.0F),
        None,
        None,
      ),
    ])
    let handle = @scene.scene_register_gltf_scene(path, first_scene)

    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(handle),
    )

    @scene.scene_spawn_roots_system(world)

    for _ in 0..<4 {
      run_scene_reload_frame(world)
    }

    let first_children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        first_children.push(entity)
      }
    })
    let first_child = first_children[0]

    let updated_handle = @scene.scene_register_gltf_scene(path, second_scene)
    handle_stable.val = handle.id() == updated_handle.id()

    run_scene_reload_frame(world)

    old_child_alive.val = world.is_alive(first_child)
    let second_children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        second_children.push(entity)
      }
    })
    new_child_count.val = second_children.length()
    let new_child = second_children[0]
    let transform = (try! world.get_by_key(
      new_child, @transform.ecs_key_transform,
    )).unwrap()
    new_child_x.val = transform.translation.x.to_double()
  })

  debug_inspect(handle_stable.val, content="true")
  debug_inspect(old_child_alive.val, content="false")
  debug_inspect(new_child_count.val, content="1")
  debug_inspect(new_child_x.val, content="9")
}

///|
test "scene: modified scene asset debounce suppresses rapid respawns" {
  let handle_stable = Ref(false)
  let child_count_after_first_reload = Ref(0)
  let child_alive_after_debounced_update = Ref(false)
  let child_count_after_debounced_update = Ref(0)
  let child_x_after_debounced_update = Ref(0.0)
  let child_alive_after_rearmed_update = Ref(true)
  let child_count_after_rearmed_update = Ref(0)
  let child_x_after_rearmed_update = Ref(0.0)
  run_scene_test_app(fn(world : @ecs.World) {
    let path = @gltf.GltfAssetLabel::Scene(0).from_asset(
      "models/Foo/Foo.gltf#debounced-reload",
    )
    let material = @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::white()),
      ),
    )
    let first_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(1.0F, 2.0F, 3.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
        None,
        None,
      ),
    ])
    let second_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(4.0F, 5.0F, 6.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(9.0F, 8.0F, 7.0F),
        None,
        None,
      ),
    ])
    let third_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(7.0F, 8.0F, 9.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(17.0F, 16.0F, 15.0F),
        None,
        None,
      ),
    ])
    let fourth_scene = @scene.Scene::new([
      @scene.SceneNode3d::new(
        @pbr.Mesh3d::new(
          @pbr.mesh_assets_mut_or_abort().val.add(
            @pbr.Mesh::from_3d_geometry(
              @pbr.mesh3d_geometry_cuboid(10.0F, 11.0F, 12.0F),
            ),
          ),
        ),
        material,
        @transform.Transform::from_xyz(25.0F, 24.0F, 23.0F),
        None,
        None,
      ),
    ])
    let handle = @scene.scene_register_gltf_scene(path, first_scene)

    let root = world.spawn_empty()
    try! world.set_by_key(
      root,
      @scene.ecs_key_scene_root,
      @scene.SceneRoot::new(handle),
    )
    @scene.scene_spawn_roots_system(world)

    for _ in 0..<4 {
      run_scene_reload_frame(world)
    }

    let second_handle = @scene.scene_register_gltf_scene(path, second_scene)
    handle_stable.val = handle.id() == second_handle.id()
    run_scene_reload_frame(world)

    let first_reloaded_children : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        first_reloaded_children.push(entity)
      }
    })
    child_count_after_first_reload.val = first_reloaded_children.length()
    let first_reloaded_child = first_reloaded_children[0]

    ignore(@scene.scene_register_gltf_scene(path, third_scene))
    run_scene_reload_frame(world)

    child_alive_after_debounced_update.val = world.is_alive(
      first_reloaded_child,
    )
    let children_after_debounced_update : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        children_after_debounced_update.push(entity)
      }
    })
    child_count_after_debounced_update.val = children_after_debounced_update.length()
    let debounced_child = children_after_debounced_update[0]
    let debounced_transform = (try! world.get_by_key(
      debounced_child, @transform.ecs_key_transform,
    )).unwrap()
    child_x_after_debounced_update.val = debounced_transform.translation.x.to_double()

    for _ in 0..<3 {
      run_scene_reload_frame(world)
    }

    ignore(@scene.scene_register_gltf_scene(path, fourth_scene))
    run_scene_reload_frame(world)

    child_alive_after_rearmed_update.val = world.is_alive(first_reloaded_child)
    let children_after_rearmed_update : Array[@core.Entity] = []
    world.for_each_component(@hierarchy.ecs_key_parent, fn(entity, parent) {
      if parent.entity().id == root.id {
        children_after_rearmed_update.push(entity)
      }
    })
    child_count_after_rearmed_update.val = children_after_rearmed_update.length()
    let rearmed_child = children_after_rearmed_update[0]
    let rearmed_transform = (try! world.get_by_key(
      rearmed_child, @transform.ecs_key_transform,
    )).unwrap()
    child_x_after_rearmed_update.val = rearmed_transform.translation.x.to_double()
  })

  debug_inspect(handle_stable.val, content="true")
  debug_inspect(child_count_after_first_reload.val, content="1")
  debug_inspect(child_alive_after_debounced_update.val, content="true")
  debug_inspect(child_count_after_debounced_update.val, content="1")
  debug_inspect(child_x_after_debounced_update.val, content="9")
  debug_inspect(child_alive_after_rearmed_update.val, content="false")
  debug_inspect(child_count_after_rearmed_update.val, content="1")
  debug_inspect(child_x_after_rearmed_update.val, content="25")
}
