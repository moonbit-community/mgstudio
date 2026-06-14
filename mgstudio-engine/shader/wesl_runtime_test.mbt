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
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(@ecs.World::new())),
  )
  app = app.add_systems(
    @app.Startup,
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
    @app.Update,
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
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(@ecs.World::new())),
  )
  app = app.add_systems(
    @app.Startup,
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
    @app.Update,
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
