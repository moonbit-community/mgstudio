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
test "assets: insert/get/set/remove and events" {
  let assets : Assets[Int] = Assets::new()
  inspect(assets.is_empty(), content="true")
  let h = assets.add(10)
  inspect(assets.get(h).unwrap(), content="10")
  let ev1 = assets.drain_events()
  inspect(ev1.length(), content="1")
  match ev1[0] {
    AssetEvent::Added(h1) => inspect(h1.id() == h.id(), content="true")
    _ => inspect(false, content="false")
  }
  inspect(assets.set(h, 11), content="true")
  inspect(assets.get(h).unwrap(), content="11")
  let ev2 = assets.drain_events()
  inspect(ev2.length(), content="1")
  match ev2[0] {
    AssetEvent::Modified(h1) => inspect(h1.id() == h.id(), content="true")
    _ => inspect(false, content="false")
  }
  let removed = assets.remove(h).unwrap()
  inspect(removed, content="11")
  inspect(assets.contains(h), content="false")
  let ev3 = assets.drain_events()
  inspect(ev3.length(), content="1")
  match ev3[0] {
    AssetEvent::Removed(h1) => inspect(h1.id() == h.id(), content="true")
    _ => inspect(false, content="false")
  }
}

///|
test "assets: insert with explicit handle id grows storage" {
  let assets : Assets[Int] = Assets::new()
  let h = Handle::new(10)
  inspect(assets.insert(h, 42), content="true")
  inspect(assets.get(h).unwrap(), content="42")
  let ev = assets.drain_events()
  inspect(ev.length(), content="1")
  match ev[0] {
    AssetEvent::Added(h1) => inspect(h1.id() == 10, content="true")
    _ => inspect(false, content="false")
  }
  inspect(assets.insert(h, 43), content="true")
  inspect(assets.get(h).unwrap(), content="43")
  let ev2 = assets.drain_events()
  inspect(ev2.length(), content="1")
  match ev2[0] {
    AssetEvent::Modified(h1) => inspect(h1.id() == 10, content="true")
    _ => inspect(false, content="false")
  }
}

///|
test "assets: reserve handle stays empty until a later insert" {
  let assets : Assets[Int] = Assets::new()
  let reserved = assets.reserve_handle()
  inspect(assets.get(reserved) is None, content="true")
  inspect(assets.insert(reserved, 7), content="true")
  inspect(assets.get(reserved).unwrap(), content="7")
  let events = assets.drain_events()
  inspect(events.length(), content="1")
  match events[0] {
    AssetEvent::Added(handle) =>
      inspect(handle.id() == reserved.id(), content="true")
    _ => inspect(false, content="false")
  }
}

///|
test "asset plugin initializes world-owned asset resources" {
  let app = asset_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()
  inspect(
    (try! world.get_resource(asset_server_resource_key())) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get_resource(loaded_folder_assets_resource_key())) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get_resource(
      assets_resource_key_of(Image::new(1, 1, Bytes::new(4))),
    ))
    is Some(_),
    content="true",
  )
}

///|
test "asset system stores loaded folders in Assets<LoadedFolder> resource" {
  let world = @ecs.World::new()
  world.insert_resource(asset_server_resource_key(), AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key(), Assets::new())
  let asset_server = match
    (try! world.get_resource(asset_server_resource_key())) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let folder_handle = asset_server.load_folder("textures/rpg")

  asset_system(world)

  let loaded_folders = match
    (try! world.get_resource(loaded_folder_assets_resource_key())) {
    Some(assets) => assets
    None => abort("expected Assets<LoadedFolder> resource")
  }
  inspect(loaded_folders.get(folder_handle) is Some(_), content="true")
}

///|
test "asset system forwards asset events to ECS messages" {
  let world = @ecs.World::new()
  let key : @ecs.ResourceKey[Assets[Int]] = assets_resource_key()
  world.insert_resource(key, Assets::new())

  match (try! world.get_resource_ref_mut(key)) {
    Some(assets) => {
      ignore(assets.val.add(42))
      ignore(assets.val.add(43))
    }
    None => abort("expected Assets<Int> resource")
  }

  asset_update_event_messages(world)

  let cursor_ref : Ref[Int] = Ref::new(0)
  let key : @ecs.MessageKey[AssetEvent[Int]] = @ecs.Message::message()
  let reader = world.message_reader(key, cursor_ref)
  let events = try! reader.read()
  inspect(events.length(), content="2")
  match events[0] {
    AssetEvent::Added(handle) => inspect(handle.id() == 0, content="true")
    _ => inspect(false, content="false")
  }
  match events[1] {
    AssetEvent::Added(handle) => inspect(handle.id() == 1, content="true")
    _ => inspect(false, content="false")
  }
}

///|
test "asset system forwards image load completion to ECS messages" {
  let world = @ecs.World::new()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key(), AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key(), Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match
    (try! world.get_resource(asset_server_resource_key())) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let image = asset_server.load_image("branding/bevy_logo_dark_big.png")
  inspect(
    match (try! world.get_resource(image_assets_key)) {
      Some(images) => images.get(image) is None
      None => false
    },
    content="true",
  )

  for _ in 0..<120 {
    asset_system(world)
    if host_asset_is_texture_loaded(image.id()) {
      break
    }
  }

  inspect(host_asset_is_texture_loaded(image.id()), content="true")
  inspect(
    match (try! world.get_resource(image_assets_key)) {
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

  let cursor_ref : Ref[Int] = Ref::new(0)
  let message_key : @ecs.MessageKey[AssetEvent[Image]] = @ecs.Message::message()
  let reader = world.message_reader(message_key, cursor_ref)
  let events = try! reader.read()

  let found = Ref::new(false)
  let added_count = Ref::new(0)
  for event in events {
    match event {
      AssetEvent::Added(handle) => {
        added_count.val = added_count.val + 1
        if handle.id() == image.id() {
          found.val = true
        }
      }
      _ => ()
    }
  }
  inspect(added_count.val, content="1")
  inspect(found.val, content="true")
}

///|
test "asset system preserves image loader settings in stored image assets" {
  let world = @ecs.World::new()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key(), AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key(), Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match
    (try! world.get_resource(asset_server_resource_key())) {
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
    asset_system(world)
    if host_asset_is_texture_loaded(image.id()) {
      break
    }
  }

  inspect(
    match (try! world.get_resource(image_assets_key)) {
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
  inspect(metadata_ok.0, content="true")
  inspect(metadata_ok.1, content="false")
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
  inspect(first.id() == second.id(), content="true")
}

///|
test "asset system skips MAIN_WORLD image asset sync when asset usage is render-only" {
  let world = @ecs.World::new()
  let image_assets_key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key(), AssetServer::new())
  world.insert_resource(loaded_folder_assets_resource_key(), Assets::new())
  world.insert_resource(image_assets_key, Assets::new())

  let asset_server = match
    (try! world.get_resource(asset_server_resource_key())) {
    Some(server) => server
    None => abort("expected AssetServer resource")
  }
  let image = asset_server.load_with_settings("branding/bevy_bird_dark.png", fn(
    settings,
  ) {
    settings.asset_usage = RenderAssetUsages::render_world()
  })

  for _ in 0..<120 {
    asset_system(world)
    if host_asset_is_texture_loaded(image.id()) {
      break
    }
  }

  inspect(host_asset_is_texture_loaded(image.id()), content="true")
  inspect(
    match (try! world.get_resource(image_assets_key)) {
      Some(images) => images.get(image) is None
      None => false
    },
    content="true",
  )
}

///|
test "asset server loads embedded image assets from in-memory source" {
  let app = embedded_asset(
    asset_plugin(@app.App::new(@ecs.World::new())),
    AssetPath::from_path("embedded_asset/files/bevy_pixel_light.png").with_source(
      AssetSourceId::from("embedded"),
    ),
    "examples/asset/files/bevy_pixel_light.png",
  )
  let asset_server : AssetServer = match
    (try! app.world().get_resource(asset_server_resource_key())) {
    Some(server) => server
    None => abort("missing asset server resource")
  }
  let handle : Handle[Image] = asset_server.load(
    asset_parse_path("embedded://embedded_asset/files/bevy_pixel_light.png"),
  )

  for _ in 0..<120 {
    asset_system(app.world())
    if host_asset_is_texture_loaded(handle.id()) {
      break
    }
  }

  inspect(host_asset_is_texture_loaded(handle.id()), content="true")
  inspect(asset_texture_width(handle), content="128")
  inspect(asset_texture_height(handle), content="96")
}

///|
test "Assets<Image>::get_mut exposes in-place mutation and emits a modified event" {
  let world = @ecs.World::new()
  let key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key(), AssetServer::new())
  world.insert_resource(key, Assets::new())

  let handle = asset_with_world(world, fn() {
    match (try! world.get_resource_ref_mut(key)) {
      Some(images) =>
        images.val.add(
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
      None => abort("expected image assets resource")
    }
  })

  asset_with_world(world, fn() {
    match (try! world.get_resource_ref_mut(key)) {
      Some(images) =>
        match images.val.get_mut(handle) {
          Some(image) =>
            image.pixels = Bytes::from_array([
              (255).to_byte(),
              (255).to_byte(),
              (255).to_byte(),
              (255).to_byte(),
            ])
          None => abort("expected image asset")
        }
      None => abort("expected image assets resource")
    }
  })

  let result = asset_with_world(world, fn() {
    match (try! world.get_resource_ref_mut(key)) {
      Some(images) => {
        let stored = images.val.get(handle)
        let events = images.val.drain_events()
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

  inspect(result.0.unwrap_or(-1), content="255")
  inspect(result.1, content="2")
  inspect(result.2, content="true")
}

///|
test "Image::new_target_texture preserves Bevy-style target texture descriptor" {
  let image = Image::new_target_texture(
    512,
    512,
    TextureFormat::Rgba8Unorm,
    Some(TextureFormat::Rgba8UnormSrgb),
  )
  inspect(image.width, content="512")
  inspect(image.height, content="512")
  inspect(image.pixels.length(), content="0")
  inspect(image.is_target_texture(), content="true")
  inspect(image.format == TextureFormat::Rgba8Unorm, content="true")
  inspect(
    image.view_format == Some(TextureFormat::Rgba8UnormSrgb),
    content="true",
  )
}

///|
test "Assets<Image>::add creates a target texture image asset" {
  let world = @ecs.World::new()
  let key : @ecs.ResourceKey[Assets[Image]] = assets_resource_key()
  world.insert_resource(asset_server_resource_key(), AssetServer::new())
  world.insert_resource(key, Assets::new())

  let result = asset_with_world(world, fn() {
    match (try! world.get_resource_ref_mut(key)) {
      Some(images) => {
        let handle = images.val.add(
          Image::new_target_texture(
            256,
            128,
            TextureFormat::Rgba8Unorm,
            Some(TextureFormat::Rgba8UnormSrgb),
          ),
        )
        let stored = images.val.get(handle)
        (
          stored.map(fn(image) { image.is_target_texture() }).unwrap_or(false),
          stored
          .map(fn(image) { image.width == 256 && image.height == 128 })
          .unwrap_or(false),
          asset_image_has_usage(handle, IMAGE_USAGE_RENDER_ATTACHMENT),
          asset_image_has_usage(handle, IMAGE_USAGE_TEXTURE_BINDING),
        )
      }
      None => (false, false, false, false)
    }
  })

  inspect(result.0, content="true")
  inspect(result.1, content="true")
  inspect(result.2, content="true")
  inspect(result.3, content="true")
}
