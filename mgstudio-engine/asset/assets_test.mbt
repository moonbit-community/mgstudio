// Copyright 2025 International Digital Economy Academy
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
extend MissingLoaderAsset with Asset::{asset_debug_name}

///|
extend MultiLoaderAsset with Asset::{asset_debug_name}

///|
extend NamedProcessorScopeAsset with Asset::{asset_debug_name}

///|
extend ProcessorScopeAsset with Asset::{asset_debug_name}

///|
extend RegistryScopedLegacyAsset with Asset::{asset_debug_name}

///|
extend StoreTestAsset with Asset::{asset_debug_name}

///|
extend TestCustomAsset with Asset::{asset_debug_name}

///|
struct CountingLoadGuard {
  releases : Ref[Int]
}

///|
struct StoreTestAsset {
  value : Int
}

///|
pub impl AssetLoadGuard for CountingLoadGuard with fn release(self) {
  self.releases.val = self.releases.val + 1
}

///|
test "assets: insert/get/set/remove and events" {
  let assets : Assets[StoreTestAsset] = Assets::new()
  debug_inspect(assets.is_empty(), content="true")
  let h = assets.add(StoreTestAsset::{ value: 10 })
  debug_inspect(assets.get(h).unwrap().value, content="10")
  let ev1 = assets.drain_events()
  debug_inspect(ev1.length(), content="1")
  match ev1[0] {
    AssetEvent::Added(h1) => debug_inspect(h1.id() == h.id(), content="true")
    _ => debug_inspect(false, content="false")
  }
  debug_inspect(assets.set(h, StoreTestAsset::{ value: 11 }), content="true")
  debug_inspect(assets.get(h).unwrap().value, content="11")
  let ev2 = assets.drain_events()
  debug_inspect(ev2.length(), content="1")
  match ev2[0] {
    AssetEvent::Modified(h1) => debug_inspect(h1.id() == h.id(), content="true")
    _ => debug_inspect(false, content="false")
  }
  let removed = assets.remove(h).unwrap()
  debug_inspect(removed.value, content="11")
  debug_inspect(assets.contains(h), content="false")
  let ev3 = assets.drain_events()
  debug_inspect(ev3.length(), content="1")
  match ev3[0] {
    AssetEvent::Removed(h1) => debug_inspect(h1.id() == h.id(), content="true")
    _ => debug_inspect(false, content="false")
  }
}

///|
test "asset event: Bevy-shaped event id helpers" {
  let h0 : Handle[StoreTestAsset] = Handle::new(1)
  let h1 : Handle[StoreTestAsset] = Handle::new(2)
  let added : AssetEvent[StoreTestAsset] = AssetEvent::Added(h0)
  let modified : AssetEvent[StoreTestAsset] = AssetEvent::Modified(h0)
  let removed : AssetEvent[StoreTestAsset] = AssetEvent::Removed(h0)
  let unused : AssetEvent[StoreTestAsset] = AssetEvent::Unused(h0)
  let loaded : AssetEvent[StoreTestAsset] = AssetEvent::LoadedWithDependencies(
    h0,
  )

  debug_inspect(added.is_added(h0), content="true")
  debug_inspect(added.is_added(h1), content="false")
  debug_inspect(modified.is_modified(h0), content="true")
  debug_inspect(removed.is_removed(h0), content="true")
  debug_inspect(unused.is_unused(h0), content="true")
  debug_inspect(loaded.is_loaded_with_dependencies(h0), content="true")
  debug_inspect(loaded.is_modified(h0), content="false")
}

///|
test "assets: insert with explicit handle id grows storage" {
  let assets : Assets[StoreTestAsset] = Assets::new()
  let h = Handle::new(10)
  debug_inspect(assets.insert(h, StoreTestAsset::{ value: 42 }), content="true")
  debug_inspect(assets.get(h).unwrap().value, content="42")
  let ev = assets.drain_events()
  debug_inspect(ev.length(), content="1")
  match ev[0] {
    AssetEvent::Added(h1) => debug_inspect(h1.id() == 10, content="true")
    _ => debug_inspect(false, content="false")
  }
  debug_inspect(assets.insert(h, StoreTestAsset::{ value: 43 }), content="true")
  debug_inspect(assets.get(h).unwrap().value, content="43")
  let ev2 = assets.drain_events()
  debug_inspect(ev2.length(), content="1")
  match ev2[0] {
    AssetEvent::Modified(h1) => debug_inspect(h1.id() == 10, content="true")
    _ => debug_inspect(false, content="false")
  }
}

///|
test "assets: reserve handle stays empty until a later insert" {
  let assets : Assets[StoreTestAsset] = Assets::new()
  let reserved = assets.reserve_handle()
  debug_inspect(assets.get(reserved) is None, content="true")
  debug_inspect(
    assets.insert(reserved, StoreTestAsset::{ value: 7 }),
    content="true",
  )
  debug_inspect(assets.get(reserved).unwrap().value, content="7")
  let events = assets.drain_events()
  debug_inspect(events.length(), content="1")
  match events[0] {
    AssetEvent::Added(handle) =>
      debug_inspect(handle.id() == reserved.id(), content="true")
    _ => debug_inspect(false, content="false")
  }
}

///|
test "assets: iter_mut returns live assets and marks them modified" {
  let assets : Assets[StoreTestAsset] = Assets::new()
  let first = assets.add(StoreTestAsset::{ value: 10 })
  ignore(assets.reserve_handle())
  let third = assets.add(StoreTestAsset::{ value: 30 })
  ignore(assets.drain_events())
  let entries = assets.iter_mut()
  debug_inspect(entries.length(), content="2")
  debug_inspect(entries[0].0.id(), content="0")
  debug_inspect(entries[0].1.value, content="10")
  debug_inspect(entries[1].0.id(), content="2")
  debug_inspect(entries[1].1.value, content="30")
  let events = assets.drain_events()
  debug_inspect(events.length(), content="2")
  debug_inspect(assets.contains(first), content="true")
  debug_inspect(assets.contains(third), content="true")
}

///|
test "asset plugin initializes world-owned asset resources" {
  let lifecycle_world_142_0 = @ecs.World::new()
  defer lifecycle_world_142_0.close()
  let app = asset_plugin(@app.App::new(lifecycle_world_142_0))
  let world = app.world()
  debug_inspect(
    world.get_resource(asset_server_resource_key) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(loaded_folder_assets_resource_key) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(assets_resource_key_of(Image::new(1, 1, Bytes::new(4))))
    is Some(_),
    content="true",
  )
}

///|
test "asset app: registering loader does not initialize Assets resource" {
  let lifecycle_world_161_0 = @ecs.World::new()
  defer lifecycle_world_161_0.close()
  let app = init_asset_loader(
    asset_plugin(@app.App::new(lifecycle_world_161_0)),
    AssetLoader::new(["custom"], missing_loader_asset_loader),
  )
  let key : @ecs.ResourceKey[Assets[MissingLoaderAsset]] = assets_resource_key()
  debug_inspect(app.world().get_resource(key) is None, content="true")
}

///|
test "asset system stores loaded folders in Assets<LoadedFolder> resource" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key, Assets::new())
  world.insert_resource(image_assets_key, Assets::new())
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let folder_handle = asset_server.load_folder("textures/rpg")

  for _ in 0..<240 {
    asset_with_world(world, fn() { asset_system(world) })
    let loaded = match world.get_resource(loaded_folder_assets_resource_key) {
      Some(assets) => assets.get(folder_handle) is Some(_)
      None => false
    }
    if loaded {
      break
    }
  }

  let loaded_folders = match
    world.get_resource(loaded_folder_assets_resource_key) {
    Some(assets) => assets
    None => abort("expected Assets<LoadedFolder> resource")
  }
  debug_inspect(loaded_folders.get(folder_handle) is Some(_), content="true")
  let vendor_handle = match
    asset_server.get_handle("textures/rpg/chars/vendor/generic-rpg-vendor.png") {
    Some(handle) => handle
    None =>
      abort("expected folder-loaded vendor image handle to be path-addressable")
  }
  let loaded_folder = match loaded_folders.get(folder_handle) {
    Some(value) => value
    None => abort("expected LoadedFolder asset")
  }
  let mut found_vendor = false
  for handle in loaded_folder.handles {
    if handle.id() == vendor_handle.id() {
      found_vendor = true
      break
    }
  }
  debug_inspect(loaded_folder.handles.length() > 0, content="true")
  debug_inspect(found_vendor, content="true")
  debug_inspect(
    match world.get_resource(image_assets_key) {
      Some(images) => images.get(vendor_handle) is Some(_)
      None => false
    },
    content="true",
  )
}

///|
test "asset system forwards asset events to ECS messages" {
  let world = @ecs.World::new()
  defer world.close()
  let key : @ecs.ResourceKey[Assets[StoreTestAsset]] = assets_resource_key()
  world.insert_resource(key, Assets::new())

  match world.get_resource_mut(key) {
    Some(assets) => {
      ignore(
        assets.modify(fn(value) { value.add(StoreTestAsset::{ value: 42 }) }),
      )
      ignore(
        assets.modify(fn(value) { value.add(StoreTestAsset::{ value: 43 }) }),
      )
    }
    None => abort("expected Assets<Int> resource")
  }

  asset_update_event_messages(world)

  let cursor_ref : @ecs.MessageCursor[AssetEvent[StoreTestAsset]] = @ecs.MessageCursor::MessageCursor()
  let key : @ecs.MessageKey[AssetEvent[StoreTestAsset]] = @ecs.Message::message()
  let reader = world.message_reader(key, cursor=cursor_ref)
  let events = reader.read()
  debug_inspect(events.length(), content="2")
  match events[0] {
    AssetEvent::Added(handle) => debug_inspect(handle.id() == 0, content="true")
    _ => debug_inspect(false, content="false")
  }
  match events[1] {
    AssetEvent::Added(handle) => debug_inspect(handle.id() == 1, content="true")
    _ => debug_inspect(false, content="false")
  }
}

///|
struct MissingLoaderAsset {}

///|
fn missing_loader_asset_loader(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> MissingLoaderAsset {
  MissingLoaderAsset::{  }
}

///|
struct RegistryScopedLegacyAsset {}

///|
fn registry_scoped_legacy_loader(
  _asset_server : AssetServer,
  _path : String,
) -> Handle[RegistryScopedLegacyAsset] {
  Handle::new(42)
}

///|
fn registry_scoped_legacy_ready_checker(
  _world : @ecs.World,
  _handle : Handle[RegistryScopedLegacyAsset],
) -> Bool {
  true
}

///|
struct ProcessorScopeAsset {
  from_processor : Bool
}

///|
fn processor_scope_typed_loader(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> ProcessorScopeAsset {
  ProcessorScopeAsset::{ from_processor: false }
}

///|
fn processor_scope_run(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> ProcessedAsset[ProcessorScopeAsset] raise AssetProcessError {
  if false {
    raise AssetProcessError::Message("unreachable")
  }
  ProcessedAsset::new(ProcessorScopeAsset::{ from_processor: true })
}

///|
struct NamedProcessorScopeAsset {
  marker : Int
}

///|
fn named_processor_scope_typed_loader(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> NamedProcessorScopeAsset {
  NamedProcessorScopeAsset::{ marker: 0 }
}

///|
fn named_processor_scope_run_one(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> ProcessedAsset[NamedProcessorScopeAsset] raise AssetProcessError {
  if false {
    raise AssetProcessError::Message("unreachable")
  }
  ProcessedAsset::new(NamedProcessorScopeAsset::{ marker: 1 })
}

///|
fn named_processor_scope_run_two(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> ProcessedAsset[NamedProcessorScopeAsset] raise AssetProcessError {
  if false {
    raise AssetProcessError::Message("unreachable")
  }
  ProcessedAsset::new(NamedProcessorScopeAsset::{ marker: 2 })
}

///|
test "legacy loader, ready_checker and reload_hook are world-scoped per app world" {
  RegistryScopedLegacyAsset::{  } |> ignore
  let lifecycle_world_361_0 = @ecs.World::new()
  defer lifecycle_world_361_0.close()
  let app_a = init_asset(
    @app.App::new(lifecycle_world_361_0).add_plugins(
      AssetPlugin::AssetPlugin().with_unapproved_path_mode(
        UnapprovedPathMode::Allow,
      ),
    ),
    fn() { RegistryScopedLegacyAsset::{  } },
  )
  let world_a = app_a.world()
  let server_a = match world_a.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world A")
  }
  let reload_calls_a : Ref[Array[String]] = Ref([])
  asset_with_world(world_a, fn() {
    asset_register_loader(registry_scoped_legacy_loader)
    asset_register_ready_checker(registry_scoped_legacy_ready_checker)
    asset_register_reload_hook(fn(_world, _asset_server, path) {
      reload_calls_a.val.push(path)
    })
  })

  let releases_a : Ref[Int] = Ref(0)
  let handle_a : Handle[RegistryScopedLegacyAsset] = asset_with_world(world_a, fn() {
    server_a.load_acquire("scoped_registry.asset", CountingLoadGuard::{
      releases: releases_a,
    })
  })
  debug_inspect(handle_a.id() == 42, content="true")
  debug_inspect(releases_a.val, content="1")

  let reload_probe_path = "/tmp/mgstudio_reload_hook_scope_test.asset"
  host_asset_save_bytes(
    path=reload_probe_path,
    bytes=Bytes::from_array([(1).to_byte()]),
  )
  asset_with_world(world_a, fn() {
    ignore(server_a.load_bytes(reload_probe_path))
  })
  asset_with_world(world_a, fn() { asset_system(world_a) })
  debug_inspect(reload_calls_a.val.length(), content="0")
  host_asset_save_bytes(
    path=reload_probe_path,
    bytes=Bytes::from_array([(2).to_byte()]),
  )
  asset_with_world(world_a, fn() { server_a.reload(reload_probe_path) })
  asset_with_world(world_a, fn() { asset_system(world_a) })
  debug_inspect(reload_calls_a.val.length(), content="1")

  let lifecycle_world_361_1 = @ecs.World::new()
  defer lifecycle_world_361_1.close()
  let app_b = init_asset(
    @app.App::new(lifecycle_world_361_1).add_plugins(
      AssetPlugin::AssetPlugin().with_unapproved_path_mode(
        UnapprovedPathMode::Allow,
      ),
    ),
    fn() { RegistryScopedLegacyAsset::{  } },
  )
  let world_b = app_b.world()
  let server_b = match world_b.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world B")
  }
  let releases_b : Ref[Int] = Ref(0)
  let handle_b : Handle[RegistryScopedLegacyAsset] = asset_with_world(world_b, fn() {
    server_b.load_acquire("scoped_registry.asset", CountingLoadGuard::{
      releases: releases_b,
    })
  })
  debug_inspect(releases_b.val, content="1")
  asset_with_world(world_b, fn() { asset_system(world_b) })
  debug_inspect(releases_b.val, content="1")

  let cursor : @ecs.MessageCursor[
    AssetLoadFailedEvent[RegistryScopedLegacyAsset],
  ] = @ecs.MessageCursor::MessageCursor()
  let key : @ecs.MessageKey[AssetLoadFailedEvent[RegistryScopedLegacyAsset]] = @ecs.Message::message()
  let reader = world_b.message_reader(key, cursor~)
  let failures = reader.read()
  debug_inspect(failures.length(), content="1")
  debug_inspect(failures[0].id.index() == handle_b.id(), content="true")

  host_asset_save_bytes(
    path=reload_probe_path,
    bytes=Bytes::from_array([(3).to_byte()]),
  )
  asset_with_world(world_b, fn() {
    ignore(server_b.load_bytes(reload_probe_path))
  })
  asset_with_world(world_b, fn() { asset_system(world_b) })
  host_asset_save_bytes(
    path=reload_probe_path,
    bytes=Bytes::from_array([(4).to_byte()]),
  )
  asset_with_world(world_b, fn() { server_b.reload(reload_probe_path) })
  asset_with_world(world_b, fn() { asset_system(world_b) })
  debug_inspect(reload_calls_a.val.length(), content="1")
}

///|
test "asset processor registry is world-scoped per app world" {
  ProcessorScopeAsset::{ from_processor: false } |> ignore
  let probe_path = "/tmp/mgstudio_processor_scope_test.pscope"
  host_asset_save_bytes(
    path=probe_path,
    bytes=Bytes::from_array([(9).to_byte()]),
  )

  let processor = LoadTransformAndSave::new(["pscope"], processor_scope_run)
  let lifecycle_world_462_0 = @ecs.World::new()
  defer lifecycle_world_462_0.close()
  let app_a = set_default_asset_processor(
    register_asset_processor(
      init_asset_loader(
        init_asset(
          @app.App::new(lifecycle_world_462_0).add_plugins(
            @asset.AssetPlugin::AssetPlugin()
            .with_mode(AssetMode::Processed)
            .with_unapproved_path_mode(UnapprovedPathMode::Allow),
          ),
          fn() { ProcessorScopeAsset::{ from_processor: false } },
        ),
        AssetLoader::new(["pscope"], processor_scope_typed_loader),
      ),
      processor,
    ),
    "pscope",
  )
  let world_a = app_a.world()
  let server_a = match world_a.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world A")
  }
  let handle_a : Handle[ProcessorScopeAsset] = asset_with_world(world_a, fn() {
    server_a.load(probe_path)
  })
  for _ in 0..<8 {
    asset_with_world(world_a, fn() { asset_system(world_a) })
    match world_a.get_resource(assets_resource_key()) {
      Some(assets) => if assets.get(handle_a) is Some(_) { break }
      None => ()
    }
  }
  debug_inspect(
    match world_a.get_resource(assets_resource_key()) {
      Some(assets) =>
        match assets.get(handle_a) {
          Some(value) => value.from_processor
          None => false
        }
      None => false
    },
    content="true",
  )

  let lifecycle_world_462_1 = @ecs.World::new()
  defer lifecycle_world_462_1.close()
  let app_b = init_asset_loader(
    init_asset(
      @app.App::new(lifecycle_world_462_1).add_plugins(
        @asset.AssetPlugin::AssetPlugin()
        .with_mode(AssetMode::Processed)
        .with_unapproved_path_mode(UnapprovedPathMode::Allow),
      ),
      fn() { ProcessorScopeAsset::{ from_processor: false } },
    ),
    AssetLoader::new(["pscope"], processor_scope_typed_loader),
  )
  let world_b = app_b.world()
  let server_b = match world_b.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world B")
  }
  let handle_b : Handle[ProcessorScopeAsset] = asset_with_world(world_b, fn() {
    server_b.load(probe_path)
  })
  for _ in 0..<8 {
    asset_with_world(world_b, fn() { asset_system(world_b) })
    match world_b.get_resource(assets_resource_key()) {
      Some(assets) => if assets.get(handle_b) is Some(_) { break }
      None => ()
    }
  }
  debug_inspect(
    match world_b.get_resource(assets_resource_key()) {
      Some(assets) =>
        match assets.get(handle_b) {
          Some(value) => value.from_processor
          None => true
        }
      None => true
    },
    content="false",
  )
}

///|
test "asset processor default can be selected by processor name" {
  NamedProcessorScopeAsset::{ marker: 0 } |> ignore
  let probe_path = "/tmp/mgstudio_processor_named_default_scope_test.npscope"
  host_asset_save_bytes(
    path=probe_path,
    bytes=Bytes::from_array([(5).to_byte()]),
  )

  let lifecycle_world_555_0 = @ecs.World::new()
  defer lifecycle_world_555_0.close()
  let app = set_default_asset_processor_by_name(
    register_asset_processor_named(
      register_asset_processor_named(
        init_asset_loader(
          init_asset(
            @app.App::new(lifecycle_world_555_0).add_plugins(
              @asset.AssetPlugin::AssetPlugin()
              .with_mode(AssetMode::Processed)
              .with_unapproved_path_mode(UnapprovedPathMode::Allow),
            ),
            fn() { NamedProcessorScopeAsset::{ marker: 0 } },
          ),
          AssetLoader::new(["npscope"], named_processor_scope_typed_loader),
        ),
        "named.processor.one",
        LoadTransformAndSave::new(["npscope"], named_processor_scope_run_one),
      ),
      "named.processor.two",
      LoadTransformAndSave::new(["npscope"], named_processor_scope_run_two),
    ),
    "npscope",
    "named.processor.two",
  )

  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let handle : Handle[NamedProcessorScopeAsset] = asset_with_world(world, fn() {
    asset_server.load(probe_path)
  })
  for _ in 0..<8 {
    asset_with_world(world, fn() { asset_system(world) })
    match world.get_resource(assets_resource_key()) {
      Some(assets) => if assets.get(handle) is Some(_) { break }
      None => ()
    }
  }
  debug_inspect(
    match world.get_resource(assets_resource_key()) {
      Some(assets) =>
        match assets.get(handle) {
          Some(value) => value.marker
          None => -1
        }
      None => -1
    },
    content="2",
  )
}

///|
test "asset processor default by name keeps previous selection when name is ambiguous" {
  NamedProcessorScopeAsset::{ marker: 0 } |> ignore
  let probe_path = "/tmp/mgstudio_processor_named_ambiguous_scope_test.npscope"
  host_asset_save_bytes(
    path=probe_path,
    bytes=Bytes::from_array([(6).to_byte()]),
  )

  let lifecycle_world_616_0 = @ecs.World::new()
  defer lifecycle_world_616_0.close()
  let app = set_default_asset_processor_by_name(
    register_asset_processor_named(
      register_asset_processor_named(
        init_asset_loader(
          init_asset(
            @app.App::new(lifecycle_world_616_0).add_plugins(
              @asset.AssetPlugin::AssetPlugin()
              .with_mode(AssetMode::Processed)
              .with_unapproved_path_mode(UnapprovedPathMode::Allow),
            ),
            fn() { NamedProcessorScopeAsset::{ marker: 0 } },
          ),
          AssetLoader::new(["npscope"], named_processor_scope_typed_loader),
        ),
        "named.processor.dup",
        LoadTransformAndSave::new(["npscope"], named_processor_scope_run_two),
      ),
      "named.processor.dup",
      LoadTransformAndSave::new(["npscope"], named_processor_scope_run_one),
    ),
    "npscope",
    "named.processor.dup",
  )

  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let handle : Handle[NamedProcessorScopeAsset] = asset_with_world(world, fn() {
    asset_server.load(probe_path)
  })
  for _ in 0..<8 {
    asset_with_world(world, fn() { asset_system(world) })
    match world.get_resource(assets_resource_key()) {
      Some(assets) => if assets.get(handle) is Some(_) { break }
      None => ()
    }
  }
  // No default is set because the name is ambiguous; selection falls back to the first matching processor.
  debug_inspect(
    match world.get_resource(assets_resource_key()) {
      Some(assets) =>
        match assets.get(handle) {
          Some(value) => value.marker
          None => -1
        }
      None => -1
    },
    content="2",
  )
}

///|
test "asset source builder registration is world-scoped per app world" {
  let scoped_path = AssetPath::from_path("bevy_pixel_dark_with_meta.png").with_source(
    AssetSourceId::Named("scoped_source_builder"),
  )
  let lifecycle_world_678_0 = @ecs.World::new()
  defer lifecycle_world_678_0.close()
  let app_a = asset_plugin(
    register_asset_source(
      @app.App::new(lifecycle_world_678_0),
      AssetSourceId::Named("scoped_source_builder"),
      AssetSourceBuilder::platform_default("examples/asset/files", None),
    ),
  )
  let world_a = app_a.world()
  let server_a = match world_a.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world A")
  }
  server_a |> ignore
  let bytes_a = asset_with_world(world_a, fn() {
    load_asset_source_bytes(scoped_path)
  })
  debug_inspect(bytes_a.length() > 0, content="true")

  let lifecycle_world_678_1 = @ecs.World::new()
  defer lifecycle_world_678_1.close()
  let app_b = asset_plugin(@app.App::new(lifecycle_world_678_1))
  let world_b = app_b.world()
  let server_b = match world_b.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world B")
  }
  server_b |> ignore
  let bytes_b = asset_with_world(world_b, fn() {
    load_asset_source_bytes(scoped_path)
  })
  debug_inspect(bytes_b.length(), content="0")

  let bytes_a_after = asset_with_world(world_a, fn() {
    load_asset_source_bytes(scoped_path)
  })
  debug_inspect(bytes_a_after.length() > 0, content="true")
}

///|
test "default asset source builder path override is world-scoped per app world" {
  let relative_path = "source_builder_default_scope_probe.bin"
  let dir_a = "/tmp/mgstudio_asset_default_source_scope_a"
  let dir_b = "/tmp/mgstudio_asset_default_source_scope_b"
  @fs.create_dir(dir_a) catch {
    _ => ()
  }
  @fs.create_dir(dir_b) catch {
    _ => ()
  }
  let file_a = @path.Path::join(dir_a, relative_path).normalize().to_string()
  let file_b = @path.Path::join(dir_b, relative_path).normalize().to_string()
  @fs.write_bytes_to_file(file_a, Bytes::from_array([(11).to_byte()]))
  @fs.write_bytes_to_file(file_b, Bytes::from_array([(22).to_byte()]))

  let lifecycle_world_719_0 = @ecs.World::new()
  defer lifecycle_world_719_0.close()
  let app_a = asset_plugin(
    register_asset_source(
      @app.App::new(lifecycle_world_719_0),
      AssetSourceId::Default,
      AssetSourceBuilder::platform_default(dir_a, None),
    ),
  )
  let world_a = app_a.world()
  let bytes_a = asset_with_world(world_a, fn() {
    load_asset_source_bytes(relative_path)
  })
  debug_inspect(
    bytes_a.length() == 1 && bytes_a[0].to_uint() == 11U,
    content="true",
  )

  let lifecycle_world_719_1 = @ecs.World::new()
  defer lifecycle_world_719_1.close()
  let app_b = asset_plugin(
    register_asset_source(
      @app.App::new(lifecycle_world_719_1),
      AssetSourceId::Default,
      AssetSourceBuilder::platform_default(dir_b, None),
    ),
  )
  let world_b = app_b.world()
  let bytes_b = asset_with_world(world_b, fn() {
    load_asset_source_bytes(relative_path)
  })
  debug_inspect(
    bytes_b.length() == 1 && bytes_b[0].to_uint() == 22U,
    content="true",
  )

  let bytes_a_after = asset_with_world(world_a, fn() {
    load_asset_source_bytes(relative_path)
  })
  debug_inspect(
    bytes_a_after.length() == 1 && bytes_a_after[0].to_uint() == 11U,
    content="true",
  )
}

///|
test "asset server load without registered loader emits typed/untyped AssetLoadFailedEvent instead of aborting" {
  MissingLoaderAsset::{  } |> ignore
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key, Assets::new())
  let missing_assets : Assets[MissingLoaderAsset] = Assets::new()
  world.insert_resource(assets_resource_key(), missing_assets)

  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }

  let handle : Handle[MissingLoaderAsset] = asset_with_world(world, fn() {
    asset_server.load("does_not_exist/missing_loader.asset")
  })

  let missing_assets_key : @ecs.ResourceKey[Assets[MissingLoaderAsset]] = assets_resource_key()
  debug_inspect(
    match world.get_resource(missing_assets_key) {
      Some(assets) => assets.get(handle) is None
      None => false
    },
    content="true",
  )

  asset_with_world(world, fn() { asset_system(world) })

  let untyped_cursor : @ecs.MessageCursor[UntypedAssetLoadFailedEvent] = @ecs.MessageCursor::MessageCursor()
  let untyped_key : @ecs.MessageKey[UntypedAssetLoadFailedEvent] = @ecs.Message::message()
  let untyped_reader = world.message_reader(untyped_key, cursor=untyped_cursor)
  let failures = untyped_reader.read()
  debug_inspect(failures.length(), content="1")
  let failure = failures[0]
  debug_inspect(failure.type_name.length() > 0, content="true")
  debug_inspect(
    asset_format_path(failure.path) == "does_not_exist/missing_loader.asset",
    content="true",
  )
  debug_inspect(failure.id == handle.id(), content="true")
  debug_inspect(
    failure.error.contains("No asset loader is registered"),
    content="true",
  )

  let typed_cursor : @ecs.MessageCursor[
    AssetLoadFailedEvent[MissingLoaderAsset],
  ] = @ecs.MessageCursor::MessageCursor()
  let typed_key : @ecs.MessageKey[AssetLoadFailedEvent[MissingLoaderAsset]] = @ecs.Message::message()
  let typed_reader = world.message_reader(typed_key, cursor=typed_cursor)
  let typed_failures = typed_reader.read()
  debug_inspect(typed_failures.length(), content="1")
  let typed_failure = typed_failures[0]
  debug_inspect(typed_failure.id.index() == handle.id(), content="true")
  debug_inspect(
    asset_format_path(typed_failure.path) ==
    "does_not_exist/missing_loader.asset",
    content="true",
  )
}

///|
test "asset path approval matches Bevy unapproved path shape" {
  debug_inspect(
    AssetPath::from_path("thingy.png").is_unapproved(),
    content="false",
  )
  debug_inspect(
    AssetPath::from_path("gui/thingy.png").is_unapproved(),
    content="false",
  )
  debug_inspect(
    asset_parse_path("embedded://thingy.png").is_unapproved(),
    content="false",
  )
  debug_inspect(
    AssetPath::from_path("../thingy.png").is_unapproved(),
    content="true",
  )
  debug_inspect(
    AssetPath::from_path("folder/../../thingy.png").is_unapproved(),
    content="true",
  )
  debug_inspect(
    AssetPath::from_path("/home/thingy.png").is_unapproved(),
    content="true",
  )
}

///|
test "asset plugin forbids unapproved paths by default and explicit Allow loads them" {
  let lifecycle_world_867_0 = @ecs.World::new()
  defer lifecycle_world_867_0.close()
  let forbidden_app = @app.App::new(lifecycle_world_867_0).add_plugins(
    AssetPlugin::AssetPlugin().with_file_path("assets/pixel"),
  )
  let forbidden_world = forbidden_app.world()
  let forbidden_server = match
    forbidden_world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  debug_inspect(
    forbidden_server.unapproved_path_mode() == UnapprovedPathMode::Forbid,
    content="true",
  )
  let forbidden_handle : Handle[Image] = asset_with_world(forbidden_world, fn() {
    forbidden_server.load("../pixel/bevy_pixel_dark.png")
  })
  debug_inspect(
    forbidden_server.load_state(forbidden_handle) is LoadState::Failed(_),
    content="true",
  )

  let lifecycle_world_867_1 = @ecs.World::new()
  defer lifecycle_world_867_1.close()
  let allowed_app = @app.App::new(lifecycle_world_867_1).add_plugins(
    AssetPlugin::AssetPlugin()
    .with_file_path("assets/pixel")
    .with_unapproved_path_mode(UnapprovedPathMode::Allow),
  )
  let allowed_world = allowed_app.world()
  let allowed_server = match
    allowed_world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  debug_inspect(
    allowed_server.unapproved_path_mode() == UnapprovedPathMode::Allow,
    content="true",
  )
  let allowed_handle : Handle[Image] = asset_with_world(allowed_world, fn() {
    allowed_server.load_image("../pixel/bevy_pixel_dark.png")
  })
  for _ in 0..<120 {
    asset_system(allowed_world)
    if asset_is_texture_loaded(allowed_handle) {
      break
    }
  }
  debug_inspect(asset_is_texture_loaded(allowed_handle), content="true")
  debug_inspect(asset_texture_width(allowed_handle), content="16")
  debug_inspect(asset_texture_height(allowed_handle), content="12")
}

///|
test "asset server retries failed typed loads with the same handle after loader registration" {
  let lifecycle_world_919_0 = @ecs.World::new()
  defer lifecycle_world_919_0.close()
  let app = init_asset(asset_plugin(@app.App::new(lifecycle_world_919_0)), fn() {
    MissingLoaderAsset::{  }
  })
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }

  let first : Handle[MissingLoaderAsset] = asset_with_world(world, fn() {
    asset_server.load("data/asset.custom")
  })
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.load_state(first) is LoadState::Failed(_)
    }),
    content="true",
  )
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.dependency_load_state(first)
      is DependencyLoadState::Failed(_)
    }),
    content="true",
  )
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.recursive_dependency_load_state(first)
      is RecursiveDependencyLoadState::Failed(_)
    }),
    content="true",
  )
  asset_with_world(world, fn() { asset_system(world) })

  let untyped_cursor : @ecs.MessageCursor[UntypedAssetLoadFailedEvent] = @ecs.MessageCursor::MessageCursor()
  let untyped_key : @ecs.MessageKey[UntypedAssetLoadFailedEvent] = @ecs.Message::message()
  let untyped_reader = world.message_reader(untyped_key, cursor=untyped_cursor)
  let failures = untyped_reader.read()
  debug_inspect(failures.length(), content="1")
  debug_inspect(failures[0].id == first.id(), content="true")

  let app = init_asset_loader(
    app,
    AssetLoader::new(["custom"], missing_loader_asset_loader),
  )
  let world = app.world()
  let second : Handle[MissingLoaderAsset] = asset_with_world(world, fn() {
    asset_server.load("data/asset.custom")
  })
  debug_inspect(first.id() == second.id(), content="true")
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.load_state(second) == LoadState::Loading
    }),
    content="true",
  )
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.dependency_load_state(second) == DependencyLoadState::Loading
    }),
    content="true",
  )
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.recursive_dependency_load_state(second) ==
      RecursiveDependencyLoadState::Loading
    }),
    content="true",
  )

  let key : @ecs.ResourceKey[Assets[MissingLoaderAsset]] = assets_resource_key()
  for _ in 0..<4 {
    asset_with_world(world, fn() { asset_system(world) })
    if (match world.get_resource(key) {
        Some(assets) => assets.contains(second)
        None => false
      }) {
      break
    }
  }
  debug_inspect(
    match world.get_resource(key) {
      Some(assets) => assets.contains(second)
      None => false
    },
    content="true",
  )
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.load_state(second) == LoadState::Loaded
    }),
    content="true",
  )
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.dependency_load_state(second) == DependencyLoadState::Loaded
    }),
    content="true",
  )
  debug_inspect(
    asset_with_world(world, fn() {
      asset_server.recursive_dependency_load_state(second) ==
      RecursiveDependencyLoadState::Loaded
    }),
    content="true",
  )

  asset_update_event_messages(world)
  let event_cursor : @ecs.MessageCursor[AssetEvent[MissingLoaderAsset]] = @ecs.MessageCursor::MessageCursor()
  let event_key : @ecs.MessageKey[AssetEvent[MissingLoaderAsset]] = @ecs.Message::message()
  let event_reader = world.message_reader(event_key, cursor=event_cursor)
  let events = event_reader.read()
  let loaded_count = Ref(0)
  let added_count = Ref(0)
  for event in events {
    match event {
      AssetEvent::LoadedWithDependencies(handle) =>
        if handle.id() == second.id() {
          loaded_count.val = loaded_count.val + 1
        }
      AssetEvent::Added(handle) =>
        if handle.id() == second.id() {
          added_count.val = added_count.val + 1
        }
      _ => ()
    }
  }
  debug_inspect(loaded_count.val, content="1")
  debug_inspect(added_count.val, content="1")
}

///|
test "typed asset loaders are world-scoped per app world" {
  let lifecycle_world_1052_0 = @ecs.World::new()
  defer lifecycle_world_1052_0.close()
  let app_a = init_asset_loader(
    init_asset(asset_plugin(@app.App::new(lifecycle_world_1052_0)), fn() {
      MissingLoaderAsset::{  }
    }),
    AssetLoader::new(["custom"], missing_loader_asset_loader),
  )
  let world_a = app_a.world()
  let server_a = match world_a.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world A")
  }
  let handle_a : Handle[MissingLoaderAsset] = asset_with_world(world_a, fn() {
    server_a.load("data/asset.custom")
  })
  let assets_key : @ecs.ResourceKey[Assets[MissingLoaderAsset]] = assets_resource_key()
  for _ in 0..<4 {
    asset_with_world(world_a, fn() { asset_system(world_a) })
    if (match world_a.get_resource(assets_key) {
        Some(assets) => assets.contains(handle_a)
        None => false
      }) {
      break
    }
  }
  debug_inspect(
    match world_a.get_resource(assets_key) {
      Some(assets) => assets.contains(handle_a)
      None => false
    },
    content="true",
  )

  let lifecycle_world_1052_1 = @ecs.World::new()
  defer lifecycle_world_1052_1.close()
  let app_b = init_asset(asset_plugin(@app.App::new(lifecycle_world_1052_1)), fn() {
    MissingLoaderAsset::{  }
  })
  let world_b = app_b.world()
  let server_b = match world_b.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource for world B")
  }
  let handle_b : Handle[MissingLoaderAsset] = asset_with_world(world_b, fn() {
    server_b.load("data/asset.custom")
  })
  asset_with_world(world_b, fn() { asset_system(world_b) })
  debug_inspect(
    match world_b.get_resource(assets_key) {
      Some(assets) => assets.contains(handle_b)
      None => false
    },
    content="false",
  )
  let cursor : @ecs.MessageCursor[AssetLoadFailedEvent[MissingLoaderAsset]] = @ecs.MessageCursor::MessageCursor()
  let key : @ecs.MessageKey[AssetLoadFailedEvent[MissingLoaderAsset]] = @ecs.Message::message()
  let reader = world_b.message_reader(key, cursor~)
  let failures = reader.read()
  debug_inspect(failures.length(), content="1")
  debug_inspect(failures[0].id.index() == handle_b.id(), content="true")
}

///|
test "asset system forwards image load completion to ECS messages" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key, Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let image = asset_server.load_image("branding/bevy_logo_dark_big.png")
  debug_inspect(
    asset_server.load_state(image) == LoadState::Loading,
    content="true",
  )
  debug_inspect(
    asset_server.dependency_load_state(image) == DependencyLoadState::Loading,
    content="true",
  )
  debug_inspect(
    asset_server.recursive_dependency_load_state(image) ==
    RecursiveDependencyLoadState::Loading,
    content="true",
  )
  debug_inspect(
    match world.get_resource(image_assets_key) {
      Some(images) => images.get(image) is None
      None => false
    },
    content="true",
  )

  for _ in 0..<120 {
    asset_with_world(world, fn() { asset_system(world) })
    if host_asset_is_texture_loaded(image.id()) {
      break
    }
  }

  debug_inspect(host_asset_is_texture_loaded(image.id()), content="true")
  debug_inspect(
    match world.get_resource(image_assets_key) {
      Some(images) =>
        match images.get(image) {
          Some(stored) =>
            stored.width > 0 &&
            stored.height > 0 &&
            stored.format == TextureFormat::Rgba8UnormSrgb
          None => false
        }
      None => false
    },
    content="true",
  )
  debug_inspect(
    asset_server.load_state(image) == LoadState::Loaded,
    content="true",
  )
  debug_inspect(
    asset_server.dependency_load_state(image) == DependencyLoadState::Loaded,
    content="true",
  )
  debug_inspect(
    asset_server.recursive_dependency_load_state(image) ==
    RecursiveDependencyLoadState::Loaded,
    content="true",
  )
  // `asset_sync_loaded_image_assets` queues events; they are dispatched on the next
  // asset system tick.
  asset_with_world(world, fn() { asset_system(world) })
  asset_update_event_messages(world)

  let cursor_ref : @ecs.MessageCursor[AssetEvent[Image]] = @ecs.MessageCursor::MessageCursor()
  let message_key : @ecs.MessageKey[AssetEvent[Image]] = @ecs.Message::message()
  let reader = world.message_reader(message_key, cursor=cursor_ref)
  let events = reader.read()

  let found = Ref(false)
  let loaded_count = Ref(0)
  let added_count = Ref(0)
  for event in events {
    match event {
      AssetEvent::LoadedWithDependencies(handle) =>
        if handle.id() == image.id() {
          loaded_count.val = loaded_count.val + 1
        }
      AssetEvent::Added(handle) => {
        added_count.val = added_count.val + 1
        if handle.id() == image.id() {
          found.val = true
        }
      }
      _ => ()
    }
  }
  debug_inspect(loaded_count.val, content="1")
  debug_inspect(added_count.val, content="1")
  debug_inspect(found.val, content="true")
}

///|
test "asset system preserves image loader settings in stored image assets" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key, Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let image = asset_server.load_with_settings(
    "textures/fantasy_ui_borders/panel-border-010-repeated.png",
    fn(settings) {
      settings.is_srgb = false
      settings.array_layout = Some(RowCount(3))
    },
  )

  for _ in 0..<120 {
    asset_with_world(world, fn() { asset_system(world) })
    if host_asset_is_texture_loaded(image.id()) {
      break
    }
  }

  debug_inspect(
    match world.get_resource(image_assets_key) {
      Some(images) =>
        match images.get(image) {
          Some(stored) =>
            stored.format == TextureFormat::Rgba8Unorm &&
            stored.view_format is None
          None => false
        }
      None => false
    },
    content="true",
  )
  let metadata_ok = asset_with_world(world, fn() {
    (
      match asset_image_array_layout(image) {
        Some(RowCount(3)) => true
        _ => false
      },
      asset_image_is_srgb(image),
    )
  })
  debug_inspect(metadata_ok.0, content="true")
  debug_inspect(metadata_ok.1, content="false")
}

///|
test "asset system preserves texture bytes srgb setting" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key, Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let blob = asset_server.load_bytes(
    "textures/fantasy_ui_borders/panel-border-010-repeated.png",
  )
  let bytes = match asset_blob_read_bytes(blob) {
    Some(value) => value
    None => Bytes::new(0)
  }
  let image = asset_server.load_texture_bytes(bytes, false, is_srgb=false)

  for _ in 0..<120 {
    asset_with_world(world, fn() { asset_system(world) })
    if host_asset_is_texture_loaded(image.id()) {
      break
    }
  }

  debug_inspect(
    match world.get_resource(image_assets_key) {
      Some(images) =>
        match images.get(image) {
          Some(stored) => stored.format == TextureFormat::Rgba8Unorm
          None => false
        }
      None => false
    },
    content="true",
  )
  let metadata_ok = asset_with_world(world, fn() { asset_image_is_srgb(image) })
  debug_inspect(metadata_ok, content="false")
}

///|
test "asset system releases load_acquire guard after asset becomes ready" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key, Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let release_count = Ref(0)
  let handle : Handle[Image] = asset_with_world(world, fn() {
    asset_server.load_acquire("branding/bevy_logo_dark_big.png", CountingLoadGuard::{
      releases: release_count,
    })
  })

  debug_inspect(release_count.val, content="0")

  for _ in 0..<120 {
    asset_with_world(world, fn() { asset_system(world) })
    if release_count.val == 1 {
      break
    }
  }

  debug_inspect(release_count.val, content="1")
  debug_inspect(
    match world.get_resource(image_assets_key) {
      Some(images) => images.contains(handle)
      None => false
    },
    content="true",
  )
}

///|
test "asset system releases load_acquire guard when load fails" {
  MissingLoaderAsset::{  } |> ignore
  let lifecycle_world_1353_0 = @ecs.World::new()
  defer lifecycle_world_1353_0.close()
  let app = init_asset(asset_plugin(@app.App::new(lifecycle_world_1353_0)), fn() {
    MissingLoaderAsset::{  }
  })
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let release_count = Ref(0)
  let handle : Handle[MissingLoaderAsset] = asset_with_world(world, fn() {
    asset_server.load_acquire("asset/tests/missing_loader_for_acquire.test", CountingLoadGuard::{
      releases: release_count,
    })
  })

  debug_inspect(release_count.val, content="1")
  asset_with_world(world, fn() { asset_system(world) })
  debug_inspect(release_count.val, content="1")
  debug_inspect(
    match asset_server.load_state(handle) {
      LoadState::Failed(_) => true
      _ => false
    },
    content="true",
  )
}

///|
test "asset load_acquire releases guard for Blob loads without Assets<Blob> storage" {
  let lifecycle_world_1383_0 = @ecs.World::new()
  defer lifecycle_world_1383_0.close()
  let app = asset_plugin(@app.App::new(lifecycle_world_1383_0))
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let release_count = Ref(0)
  let handle : Handle[Blob] = asset_with_world(world, fn() {
    asset_server.load_acquire("branding/bevy_bird_dark.png", CountingLoadGuard::{
      releases: release_count,
    })
  })

  debug_inspect(release_count.val, content="1")
  debug_inspect(
    asset_server.load_state(handle) is LoadState::Loaded,
    content="true",
  )
}

///|
test "asset server reuses the first handle for repeated image loads" {
  let asset_server = AssetServer::new()
  let first = asset_server.load_image("branding/bevy_bird_dark.png")
  let second : Handle[Image] = asset_server.load_with_settings(
    "branding/bevy_bird_dark.png",
    fn(settings) {
      settings.sampler = ImageSampler::nearest()
      settings.is_srgb = false
    },
  )
  debug_inspect(first.id() == second.id(), content="true")
}

///|
test "asset system skips MAIN_WORLD image asset sync when asset usage is render-only" {
  let world = @ecs.World::new()
  defer world.close()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key, Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let image = asset_server.load_with_settings("branding/bevy_bird_dark.png", fn(
    settings,
  ) {
    settings.asset_usage = RenderAssetUsages::render_world()
  })

  for _ in 0..<120 {
    asset_with_world(world, fn() { asset_system(world) })
    if host_asset_is_texture_loaded(image.id()) {
      break
    }
  }

  debug_inspect(host_asset_is_texture_loaded(image.id()), content="true")
  debug_inspect(
    match world.get_resource(image_assets_key) {
      Some(images) => images.get(image) is None
      None => false
    },
    content="true",
  )
}

///|
test "asset server loads embedded image assets from in-memory source" {
  let lifecycle_world_1455_0 = @ecs.World::new()
  defer lifecycle_world_1455_0.close()
  let app = embedded_asset(
    asset_plugin(@app.App::new(lifecycle_world_1455_0)),
    AssetPath::from_path("embedded_asset/files/bevy_pixel_light.png").with_source(
      AssetSourceId::from("embedded"),
    ),
    "examples/asset/files/bevy_pixel_light.png",
  )
  let asset_server : AssetServer = match
    app.world().get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("missing asset server resource")
  }
  let handle : Handle[Image] = asset_server.load(
    asset_parse_path("embedded://embedded_asset/files/bevy_pixel_light.png"),
  )

  for _ in 0..<120 {
    asset_with_world(app.world(), fn() { asset_system(app.world()) })
    if host_asset_is_texture_loaded(handle.id()) {
      break
    }
  }

  debug_inspect(host_asset_is_texture_loaded(handle.id()), content="true")
  debug_inspect(asset_texture_width(handle), content="128")
  debug_inspect(asset_texture_height(handle), content="96")
}

///|
test "web asset reader fetches remote PNG bytes" {
  if !@asset.web_asset_http_runtime_supported() {
    debug_inspect(true, content="true")
    return
  }
  let lifecycle_world_1485_0 = @ecs.World::new()
  defer lifecycle_world_1485_0.close()
  let app = asset_plugin(
    web_asset_plugin(@app.App::new(lifecycle_world_1485_0), plugin=WebAssetPlugin::{
      silence_startup_warning: true,
    }),
  )
  let url = "https://raw.githubusercontent.com/bevyengine/bevy/refs/heads/main/assets/branding/bevy_bird_dark.png"
  let asset_server = match app.world().get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("missing asset server resource")
  }
  let handle = asset_server.load_image(url)
  for _ in 0..<240 {
    asset_with_world(app.world(), fn() { asset_system(app.world()) })
    if host_asset_is_texture_loaded(handle.id()) {
      break
    }
  }
  debug_inspect(host_asset_is_texture_loaded(handle.id()), content="true")
  debug_inspect(asset_texture_width(handle) > 1, content="true")
  debug_inspect(asset_texture_height(handle) > 1, content="true")
}

///|
test "web asset reader fetches remote Blob bytes through AssetServer::load_bytes" {
  if !@asset.web_asset_http_runtime_supported() {
    debug_inspect(true, content="true")
    return
  }
  let lifecycle_world_1513_0 = @ecs.World::new()
  defer lifecycle_world_1513_0.close()
  let app = asset_plugin(
    web_asset_plugin(@app.App::new(lifecycle_world_1513_0), plugin=WebAssetPlugin::{
      silence_startup_warning: true,
    }),
  )
  let url = "https://github.com/bevyengine/bevy_asset_files/raw/main/pccm_example/outer_cube.glb"
  let asset_server = match app.world().get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("missing asset server resource")
  }
  let handle = asset_server.load_bytes(url)
  let bytes = match asset_blob_read_bytes(handle) {
    Some(bytes) => bytes
    None => Bytes::new(0)
  }
  debug_inspect(bytes.length() > 12, content="true")
  debug_inspect(bytes[0].to_uint(), content="103")
  debug_inspect(bytes[1].to_uint(), content="108")
  debug_inspect(bytes[2].to_uint(), content="84")
  debug_inspect(bytes[3].to_uint(), content="70")
}

///|
test "Assets<Image>::get_mut exposes in-place mutation and emits a modified event" {
  let world = @ecs.World::new()
  defer world.close()
  let key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(key, Assets::new())

  let handle = asset_with_world(world, fn() {
    match world.get_resource_mut(key) {
      Some(images) =>
        images.modify(fn(value) {
          value.add(
            Image::new(
              1,
              1,
              Bytes::from_array([
                (0).to_byte(),
                (0).to_byte(),
                (0).to_byte(),
                (255).to_byte(),
              ]),
            ),
          )
        })
      None => abort("expected image assets resource")
    }
  })

  asset_with_world(world, fn() {
    match world.get_resource_mut(key) {
      Some(images) =>
        images.modify(fn(value) {
          match value.get_mut(handle) {
            Some(image) =>
              image.pixels = Bytes::from_array([
                (255).to_byte(),
                (255).to_byte(),
                (255).to_byte(),
                (255).to_byte(),
              ])
            None => abort("expected image asset")
          }
        })
      None => abort("expected image assets resource")
    }
  })

  let result = asset_with_world(world, fn() {
    match world.get_resource_mut(key) {
      Some(images) => {
        let (stored, events) = images.modify(fn(value) {
          (value.get(handle), value.drain_events())
        })
        (
          stored.map(fn(image) {
            match image.pixels.get(0) {
              Some(value) => value.to_int() & 0xFF
              None => -1
            }
          }),
          events.length(),
          match events[1] {
            AssetEvent::Modified(modified_handle) =>
              modified_handle.id() == handle.id()
            _ => false
          },
        )
      }
      None => (None, 0, false)
    }
  })

  debug_inspect(result.0.unwrap_or(-1), content="255")
  debug_inspect(result.1, content="2")
  debug_inspect(result.2, content="true")
}

///|
test "Image::new_target_texture preserves Bevy-style target texture descriptor" {
  let image = Image::new_target_texture(
    512,
    512,
    TextureFormat::Bgra8UnormSrgb,
    None,
  )
  debug_inspect(image.width, content="512")
  debug_inspect(image.height, content="512")
  debug_inspect(image.pixels.length(), content="0")
  debug_inspect(image.is_target_texture(), content="true")
  debug_inspect(image.format == TextureFormat::Bgra8UnormSrgb, content="true")
  debug_inspect(image.view_format == None, content="true")
  debug_inspect(image.mip_level_count(), content="1")
  debug_inspect(
    asset_usage_has_bits(
      image.texture_usage_bits(),
      IMAGE_USAGE_RENDER_ATTACHMENT,
    ),
    content="true",
  )
  debug_inspect(
    asset_usage_has_bits(image.texture_usage_bits(), IMAGE_USAGE_COPY_SRC),
    content="false",
  )
}

///|
fn asset_usage_has_bits(usage_bits : Int, required_bits : Int) -> Bool {
  let usage = usage_bits.reinterpret_as_uint()
  let required = required_bits.reinterpret_as_uint()
  (usage & required) == required
}

///|
test "Assets<Image>::add creates a target texture image asset" {
  let world = @ecs.World::new()
  defer world.close()
  let key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(key, Assets::new())

  let result = asset_with_world(world, fn() {
    match world.get_resource_mut(key) {
      Some(images) => {
        let (handle, stored) = images.modify(fn(value) {
          let handle = value.add(
            Image::new_target_texture(
              256,
              128,
              TextureFormat::Rgba8Unorm,
              Some(TextureFormat::Rgba8UnormSrgb),
            ),
          )
          (handle, value.get(handle))
        })
        (
          stored.map(fn(image) { image.is_target_texture() }).unwrap_or(false),
          stored
          .map(fn(image) { image.width == 256 && image.height == 128 })
          .unwrap_or(false),
          asset_image_has_usage(handle, IMAGE_USAGE_RENDER_ATTACHMENT),
          asset_image_has_usage(handle, IMAGE_USAGE_TEXTURE_BINDING),
          asset_image_is_srgb(handle),
        )
      }
      None => (false, false, false, false, false)
    }
  })

  debug_inspect(result.0, content="true")
  debug_inspect(result.1, content="true")
  debug_inspect(result.2, content="true")
  debug_inspect(result.3, content="true")
  debug_inspect(result.4, content="true")
}

///|
test "Assets<Image>::add preserves explicit storage texture usage" {
  let world = @ecs.World::new()
  defer world.close()
  let key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key, AssetServer::new())
  world.insert_resource(key, Assets::new())

  let result = asset_with_world(world, fn() {
    match world.get_resource_mut(key) {
      Some(images) => {
        let handle = images.modify(fn(value) {
          value.add(
            Image::new(4, 4, Bytes::new(4 * 4 * 4))
            .with_added_texture_usage(IMAGE_USAGE_STORAGE_BINDING)
            .with_mip_level_count(3),
          )
        })
        (
          asset_image_has_usage(handle, IMAGE_USAGE_TEXTURE_BINDING),
          asset_image_has_usage(handle, IMAGE_USAGE_COPY_DST),
          asset_image_has_usage(handle, IMAGE_USAGE_COPY_SRC),
          asset_image_has_usage(handle, IMAGE_USAGE_STORAGE_BINDING),
        )
      }
      None => (false, false, false, false)
    }
  })

  debug_inspect(result.0, content="true")
  debug_inspect(result.1, content="true")
  debug_inspect(result.2, content="true")
  debug_inspect(result.3, content="true")
}

///|
struct TestCustomAsset {
  value : Int
}

///|
struct MultiLoaderAsset {
  loader_tag : Int
}

///|
impl Asset for StoreTestAsset with fn asset_debug_name() {
  "mgstudio_asset_test::StoreTestAsset"
}

///|
impl Asset for StoreTestAsset with fn asset_as_image(_self) {
  None
}

///|
let store_test_asset_resource_keys : AssetResourceKeys[StoreTestAsset] = register_asset_resource_keys(
  StoreTestAsset::asset_debug_name(),
)

///|
impl Asset for StoreTestAsset with fn asset_resource_keys() {
  store_test_asset_resource_keys
}

///|
impl Asset for MissingLoaderAsset with fn asset_debug_name() {
  "mgstudio_asset_test::MissingLoaderAsset"
}

///|
impl Asset for MissingLoaderAsset with fn asset_as_image(_self) {
  None
}

///|
let missing_loader_asset_resource_keys : AssetResourceKeys[MissingLoaderAsset] = register_asset_resource_keys(
  MissingLoaderAsset::asset_debug_name(),
)

///|
impl Asset for MissingLoaderAsset with fn asset_resource_keys() {
  missing_loader_asset_resource_keys
}

///|
impl Asset for RegistryScopedLegacyAsset with fn asset_debug_name() {
  "mgstudio_asset_test::RegistryScopedLegacyAsset"
}

///|
impl Asset for RegistryScopedLegacyAsset with fn asset_as_image(_self) {
  None
}

///|
let registry_scoped_legacy_asset_resource_keys : AssetResourceKeys[
  RegistryScopedLegacyAsset,
] = register_asset_resource_keys(RegistryScopedLegacyAsset::asset_debug_name())

///|
impl Asset for RegistryScopedLegacyAsset with fn asset_resource_keys() {
  registry_scoped_legacy_asset_resource_keys
}

///|
impl Asset for ProcessorScopeAsset with fn asset_debug_name() {
  "mgstudio_asset_test::ProcessorScopeAsset"
}

///|
impl Asset for ProcessorScopeAsset with fn asset_as_image(_self) {
  None
}

///|
let processor_scope_asset_resource_keys : AssetResourceKeys[ProcessorScopeAsset] = register_asset_resource_keys(
  ProcessorScopeAsset::asset_debug_name(),
)

///|
impl Asset for ProcessorScopeAsset with fn asset_resource_keys() {
  processor_scope_asset_resource_keys
}

///|
impl Asset for NamedProcessorScopeAsset with fn asset_debug_name() {
  "mgstudio_asset_test::NamedProcessorScopeAsset"
}

///|
impl Asset for NamedProcessorScopeAsset with fn asset_as_image(_self) {
  None
}

///|
let named_processor_scope_asset_resource_keys : AssetResourceKeys[
  NamedProcessorScopeAsset,
] = register_asset_resource_keys(NamedProcessorScopeAsset::asset_debug_name())

///|
impl Asset for NamedProcessorScopeAsset with fn asset_resource_keys() {
  named_processor_scope_asset_resource_keys
}

///|
impl Asset for TestCustomAsset with fn asset_debug_name() {
  "mgstudio_asset_test::TestCustomAsset"
}

///|
impl Asset for TestCustomAsset with fn asset_as_image(_self) {
  None
}

///|
let test_custom_asset_resource_keys : AssetResourceKeys[TestCustomAsset] = register_asset_resource_keys(
  TestCustomAsset::asset_debug_name(),
)

///|
impl Asset for TestCustomAsset with fn asset_resource_keys() {
  test_custom_asset_resource_keys
}

///|
impl Asset for MultiLoaderAsset with fn asset_debug_name() {
  "mgstudio_asset_test::MultiLoaderAsset"
}

///|
impl Asset for MultiLoaderAsset with fn asset_as_image(_self) {
  None
}

///|
let multi_loader_asset_resource_keys : AssetResourceKeys[MultiLoaderAsset] = register_asset_resource_keys(
  MultiLoaderAsset::asset_debug_name(),
)

///|
impl Asset for MultiLoaderAsset with fn asset_resource_keys() {
  multi_loader_asset_resource_keys
}

///|
fn multi_loader_full_extension_loader(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> MultiLoaderAsset {
  MultiLoaderAsset::{ loader_tag: 11 }
}

///|
fn multi_loader_secondary_extension_loader(
  _asset_server : AssetServer,
  _path : AssetPath,
  _bytes : Bytes,
) -> MultiLoaderAsset {
  MultiLoaderAsset::{ loader_tag: 22 }
}

///|
fn find_substring_or_abort(content : String, pattern : String) -> Int {
  guard pattern.length() > 0 else {
    abort("Expected a non-empty substring pattern")
  }
  let limit = content.length() - pattern.length()
  guard limit >= 0 else {
    abort("Expected substring is missing from custom asset payload")
  }
  for start in 0..<=limit {
    let mut matches = true
    for offset in 0..<pattern.length() {
      if content.code_unit_at(start + offset) != pattern.code_unit_at(offset) {
        matches = false
        break
      }
    }
    if matches {
      return start
    }
  }
  abort("Expected substring is missing from custom asset payload")
}

///|
fn parse_decimal_or_abort(digits : Array[Char]) -> Int {
  guard digits.length() > 0 else {
    abort("Expected at least one decimal digit")
  }
  let mut index = 0
  let mut sign = 1
  if digits[0] == '-' {
    sign = -1
    index = 1
  }
  guard index < digits.length() else {
    abort("Expected at least one decimal digit")
  }
  let mut value = 0
  for i in index..<digits.length() {
    let code = digits[i].to_int()
    guard code >= 48 && code <= 57 else {
      abort("Expected only decimal digits")
    }
    value = value * 10 + (code - 48)
  }
  sign * value
}

///|
fn test_custom_asset_loader(
  _asset_server : AssetServer,
  _path : AssetPath,
  bytes : Bytes,
) -> TestCustomAsset {
  let chars : Array[Char] = []
  for byte in bytes {
    chars.push(Int::unsafe_to_char(byte.to_int() & 0xFF))
  }
  let content = String::from_array(chars)
  let marker = "value:"
  let start = find_substring_or_abort(content, marker) + marker.length()
  let digits : Array[Char] = []
  let mut seen_digit = false
  for i in start..<content.length() {
    let code = content.code_unit_at(i).to_int()
    let is_digit = code >= 48 && code <= 57
    if is_digit || (!seen_digit && code == 45) {
      digits.push(Int::unsafe_to_char(code))
      seen_digit = true
    } else if seen_digit {
      break
    }
  }
  TestCustomAsset::{ value: parse_decimal_or_abort(digits) }
}

///|
test "asset server loads typed custom assets into Assets<T> and reuses handles" {
  let lifecycle_world_1977_0 = @ecs.World::new()
  defer lifecycle_world_1977_0.close()
  let app = init_asset_loader(
    init_asset(asset_plugin(@app.App::new(lifecycle_world_1977_0)), fn() {
      TestCustomAsset::{ value: 0 }
    }),
    AssetLoader::new(["custom"], test_custom_asset_loader),
  )
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }

  let handle : Handle[TestCustomAsset] = asset_with_world(world, fn() {
    asset_server.load("data/asset.custom")
  })
  let second : Handle[TestCustomAsset] = asset_with_world(world, fn() {
    asset_server.load("data/asset.custom")
  })

  debug_inspect(handle.id() == second.id(), content="true")
  let key : @ecs.ResourceKey[Assets[TestCustomAsset]] = assets_resource_key()
  asset_with_world(world, fn() { asset_system(world) })
  debug_inspect(
    match world.get_resource(key) {
      Some(assets) =>
        match assets.get(handle) {
          Some(asset) => asset.value == 42
          None => false
        }
      None => false
    },
    content="true",
  )
}

///|
test "typed asset loaders resolve by full extension, secondary extension, then latest fallback" {
  let lifecycle_world_2014_0 = @ecs.World::new()
  defer lifecycle_world_2014_0.close()
  let app = init_asset_loader(
    init_asset_loader(
      init_asset(asset_plugin(@app.App::new(lifecycle_world_2014_0)), fn() {
        MultiLoaderAsset::{ loader_tag: 0 }
      }),
      AssetLoader::new(["bar"], multi_loader_secondary_extension_loader),
    ),
    AssetLoader::new(["foo.bar"], multi_loader_full_extension_loader),
  )
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }

  let full_ext_handle : Handle[MultiLoaderAsset] = asset_with_world(world, fn() {
    asset_server.load("data/asset.foo.bar")
  })
  let secondary_ext_handle : Handle[MultiLoaderAsset] = asset_with_world(
    world,
    fn() { asset_server.load("data/asset.bar") },
  )
  let fallback_handle : Handle[MultiLoaderAsset] = asset_with_world(world, fn() {
    asset_server.load("data/asset.unknown_ext")
  })

  asset_with_world(world, fn() { asset_system(world) })

  let key : @ecs.ResourceKey[Assets[MultiLoaderAsset]] = assets_resource_key()
  debug_inspect(
    match world.get_resource(key) {
      Some(assets) =>
        match assets.get(full_ext_handle) {
          Some(asset) => asset.loader_tag == 11
          None => false
        }
      None => false
    },
    content="true",
  )
  debug_inspect(
    match world.get_resource(key) {
      Some(assets) =>
        match assets.get(secondary_ext_handle) {
          Some(asset) => asset.loader_tag == 22
          None => false
        }
      None => false
    },
    content="true",
  )
  debug_inspect(
    match world.get_resource(key) {
      Some(assets) =>
        match assets.get(fallback_handle) {
          Some(asset) => asset.loader_tag == 11
          None => false
        }
      None => false
    },
    content="true",
  )
}

///|
test "asset server add inserts a typed asset into Assets<T>" {
  let lifecycle_world_2080_0 = @ecs.World::new()
  defer lifecycle_world_2080_0.close()
  let app = init_asset(asset_plugin(@app.App::new(lifecycle_world_2080_0)), fn() {
    TestCustomAsset::{ value: 0 }
  })
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let handle = asset_with_world(world, fn() {
    asset_server.add(TestCustomAsset::{ value: 7 })
  })
  let key : @ecs.ResourceKey[Assets[TestCustomAsset]] = assets_resource_key()
  debug_inspect(
    match world.get_resource(key) {
      Some(assets) =>
        match assets.get(handle) {
          Some(asset) => asset.value == 7
          None => false
        }
      None => false
    },
    content="true",
  )
}

///|
test "gzip helper decompresses the Bevy sample image payload" {
  let decoded = gzip_decompress(
    try! @fs.read_file_to_bytes("assets/data/compressed_image.png.gz"),
  )
  debug_inspect(
    decoded.map(fn(bytes) { bytes.length() }).unwrap_or(-1),
    content="15860",
  )
  debug_inspect(
    decoded.map(fn(bytes) {
      bytes.length() >= 8 &&
      bytes[0].to_int() == 0x89 &&
      bytes[1].to_int() == 0x50 &&
      bytes[2].to_int() == 0x4E &&
      bytes[3].to_int() == 0x47
    }),
    content="Some(true)",
  )
}

///|
test "asset server load_direct decodes decompressed image bytes" {
  let lifecycle_world_2128_0 = @ecs.World::new()
  defer lifecycle_world_2128_0.close()
  let app = asset_plugin(@app.App::new(lifecycle_world_2128_0))
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let decoded = gzip_decompress(
    try! @fs.read_file_to_bytes("assets/data/compressed_image.png.gz"),
  )
  debug_inspect(
    decoded.map(fn(bytes) {
      let image : Image = asset_with_world(world, fn() {
        asset_server.load_image_direct("data/compressed_image.png", bytes)
      })
      image.width == 256 && image.height == 256
    }),
    content="Some(true)",
  )
}

///|
test "asset server stores gltf loader settings per asset path" {
  let lifecycle_world_2150_0 = @ecs.World::new()
  defer lifecycle_world_2150_0.close()
  let app = asset_plugin(@app.App::new(lifecycle_world_2150_0))
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let path = "models/Foo/Foo.gltf#Scene0"
  let _ : Handle[Blob] = asset_with_world(world, fn() {
    asset_server.load_with_settings(path, fn(settings) {
      settings.load_meshes = RenderAssetUsages::main_world()
      settings.load_materials = RenderAssetUsages::render_world()
      settings.load_animations = false
      settings.override_sampler = true
      let sampler = ImageSamplerDescriptor::nearest()
      sampler.set_address_mode(ImageAddressMode::ClampToEdge) |> ignore
      settings.sampler = ImageSampler::Descriptor(sampler)
    })
  })

  let stored = asset_server.gltf_loader_settings_for_asset_path(path)
  debug_inspect(
    stored.load_meshes == RenderAssetUsages::main_world(),
    content="true",
  )
  debug_inspect(
    stored.load_materials == RenderAssetUsages::render_world(),
    content="true",
  )
  debug_inspect(!stored.load_animations, content="true")
  debug_inspect(stored.override_sampler, content="true")
  match stored.sampler {
    ImageSampler::Descriptor(descriptor) => {
      debug_inspect(
        descriptor.min_filter == ImageFilterMode::Nearest,
        content="true",
      )
      debug_inspect(
        descriptor.address_mode_u == ImageAddressMode::ClampToEdge,
        content="true",
      )
      debug_inspect(
        descriptor.address_mode_v == ImageAddressMode::ClampToEdge,
        content="true",
      )
    }
    _ => abort("expected descriptor sampler")
  }
}

///|
test "asset server gltf loader settings are shared across sub asset labels" {
  let lifecycle_world_2201_0 = @ecs.World::new()
  defer lifecycle_world_2201_0.close()
  let app = asset_plugin(@app.App::new(lifecycle_world_2201_0))
  let world = app.world()
  let asset_server = match world.get_resource(asset_server_resource_key) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let root_path = "models/Foo/Foo.gltf"
  let labeled_path = "models/Foo/Foo.gltf#Scene0"

  let _ : Handle[Blob] = asset_with_world(world, fn() {
    asset_server.load_with_settings(root_path, fn(settings) {
      settings.load_meshes = RenderAssetUsages::main_world()
      settings.load_materials = RenderAssetUsages::render_world()
      settings.load_animations = false
      settings.load_cameras = false
      settings.load_lights = false
    })
  })

  let from_label = asset_server.gltf_loader_settings_for_asset_path(
    labeled_path,
  )
  debug_inspect(
    from_label.load_meshes == RenderAssetUsages::main_world(),
    content="true",
  )
  debug_inspect(
    from_label.load_materials == RenderAssetUsages::render_world(),
    content="true",
  )
  debug_inspect(!from_label.load_animations, content="true")
  debug_inspect(!from_label.load_cameras, content="true")
  debug_inspect(!from_label.load_lights, content="true")

  let _ : Handle[Blob] = asset_with_world(world, fn() {
    asset_server.load_with_settings(labeled_path, fn(settings) {
      settings.include_source = true
      settings.override_sampler = true
    })
  })
  let from_root = asset_server.gltf_loader_settings_for_asset_path(root_path)
  debug_inspect(from_root.include_source, content="true")
  debug_inspect(from_root.override_sampler, content="true")
}
