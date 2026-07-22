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
test "shader runtime wesl registration defers until imported wesl modules are loaded" {
  let registered_sources : Array[String] = []
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(lifecycle_world_15_0)),
  )
  app = app.add_systems(
    Startup,
    @app.system(fn(world : @ecs.World) {
      let asset_server = match
        world.get_resource(@asset.AssetServer::resource()) {
        Some(asset_server) => asset_server
        None => abort("expected AssetServer resource for wesl runtime test")
      }
      let handle : @asset.Handle[Shader] = @asset.asset_with_world(world, fn() {
        asset_server.load("shaders/custom_material.wesl")
      })
      ignore(handle)
    }),
  )
  app = app.add_systems(
    Update,
    @app.system(fn(world : @ecs.World) {
      if registered_sources.length() > 0 {
        return
      }
      let compiled = @shader.shader_runtime_compile_wesl_source(
        world,
        "shaders/custom_material.wesl",
        [],
      ) catch {
        err => abort(err.message())
      }
      match compiled {
        Some(source) => registered_sources.push(source)
        None => return
      }
    }),
  )

  app = app.update()
  app = app.update()
  app = app.update()

  debug_inspect(registered_sources.length(), content="0")
}

///|
test "shader runtime wesl registration compiles after imported module is loaded as shader asset" {
  let registered_sources : Array[String] = []
  let lifecycle_world_62_0 = @ecs.World::new()
  defer lifecycle_world_62_0.close()
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(lifecycle_world_62_0)),
  )
  app = app.add_systems(
    Startup,
    @app.system(fn(world : @ecs.World) {
      let asset_server = match
        world.get_resource(@asset.AssetServer::resource()) {
        Some(asset_server) => asset_server
        None => abort("expected AssetServer resource for wesl runtime test")
      }
      let utility_handle : @asset.Handle[Shader] = @asset.asset_with_world(
        world,
        fn() { asset_server.load("shaders/util.wesl") },
      )
      let material_handle : @asset.Handle[Shader] = @asset.asset_with_world(
        world,
        fn() { asset_server.load("shaders/custom_material.wesl") },
      )
      ignore(utility_handle)
      ignore(material_handle)
    }),
  )
  app = app.add_systems(
    Update,
    @app.system(fn(world : @ecs.World) {
      if registered_sources.length() > 0 {
        return
      }
      let compiled = @shader.shader_runtime_compile_wesl_source(
        world,
        "shaders/custom_material.wesl",
        [@shader.shader_def("PARTY_MODE")],
      ) catch {
        err => abort(err.message())
      }
      match compiled {
        Some(source) => registered_sources.push(source)
        None => return
      }
    }),
  )

  app = app.update()
  app = app.update()
  app = app.update()

  debug_inspect(registered_sources.length(), content="1")
  debug_inspect(
    registered_sources[0].contains("package_shaders_util__2make_polka_dots"),
    content="true",
  )
  debug_inspect(registered_sources[0].contains("wave_speed"), content="true")
}

///|
test "shader runtime loaded wgsl sources include quoted file import dependencies" {
  let dep_source =
    #|const COLOR_MULTIPLIER: vec4<f32> = vec4<f32>(1.0, 1.0, 1.0, 0.5);
    #|
  let root_source =
    #|#import "shader/runtime/dep.wgsl"::COLOR_MULTIPLIER
    #|
    #|fn root_value() -> vec4<f32> {
    #|  return COLOR_MULTIPLIER;
    #|}
    #|
  @asset.register_embedded_asset_virtual_bytes(
    "shader/runtime/dep.wgsl",
    @asset.asset_text_to_bytes(dep_source),
  )
  @asset.register_embedded_asset_virtual_bytes(
    "shader/runtime/root.wgsl",
    @asset.asset_text_to_bytes(root_source),
  )
  let source_paths : Array[String] = []
  let source_texts : Array[String] = []
  let lifecycle_world_120_0 = @ecs.World::new()
  defer lifecycle_world_120_0.close()
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(lifecycle_world_120_0)),
  )
  app = app.add_systems(
    Startup,
    @app.system(fn(world : @ecs.World) {
      let asset_server = match
        world.get_resource(@asset.AssetServer::resource()) {
        Some(asset_server) => asset_server
        None => abort("expected AssetServer resource")
      }
      let root_handle : @asset.Handle[Shader] = @asset.asset_with_world(world, fn() {
        asset_server.load("shader/runtime/root.wgsl")
      })
      ignore(root_handle)
    }),
  )
  app = app.add_systems(
    Update,
    @app.system(fn(world : @ecs.World) {
      if source_paths.length() > 0 {
        return
      }
      let _ = shader_runtime_load_wgsl_sources(
        world, "shader/runtime/root.wgsl",
      )
      let sources = shader_runtime_loaded_wgsl_sources(world)
      if sources.length() == 0 {
        return
      }
      for source in sources {
        source_paths.push(source.0)
        source_texts.push(source.1)
      }
    }),
  )

  app = app.update()
  app = app.update()
  app = app.update()

  debug_inspect(
    source_paths.contains("shader/runtime/root.wgsl"),
    content="true",
  )
  debug_inspect(
    source_paths.contains("shader/runtime/dep.wgsl"),
    content="true",
  )
  let mut dep_has_import_path = false
  for i in 0..<source_paths.length() {
    if source_paths[i] == "shader/runtime/dep.wgsl" {
      dep_has_import_path = source_texts[i].contains(
        "#define_import_path shader/runtime/dep.wgsl",
      )
    }
  }
  debug_inspect(dep_has_import_path, content="true")
}

///|
test "shader runtime loads Bevy-style custom material file import dependencies" {
  let source_paths : Array[String] = []
  let lifecycle_world_202_0 = @ecs.World::new()
  defer lifecycle_world_202_0.close()
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(lifecycle_world_202_0)),
  )
  app = app.add_systems(
    Startup,
    @app.system(fn(world : @ecs.World) {
      let asset_server = match
        world.get_resource(@asset.AssetServer::resource()) {
        Some(asset_server) => asset_server
        None => abort("expected AssetServer resource")
      }
      let handle : @asset.Handle[Shader] = @asset.asset_with_world(world, fn() {
        asset_server.load("shaders/custom_material_2d.wgsl")
      })
      ignore(handle)
    }),
  )
  app = app.add_systems(
    Update,
    @app.system(fn(world : @ecs.World) {
      if source_paths.length() > 0 {
        return
      }
      let sources = shader_runtime_load_wgsl_sources(
        world, "shaders/custom_material_2d.wgsl",
      )
      if sources.length() == 0 {
        return
      }
      for source in sources {
        source_paths.push(source.0)
      }
    }),
  )

  app = app.update()
  app = app.update()
  app = app.update()

  debug_inspect(
    source_paths.contains("shaders/custom_material_2d.wgsl"),
    content="true",
  )
  debug_inspect(
    source_paths.contains("shaders/custom_material_import.wgsl"),
    content="true",
  )
}
