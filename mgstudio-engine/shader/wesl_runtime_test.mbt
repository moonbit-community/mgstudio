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
fn wesl_runtime_try_register(
  world : @ecs.World,
  path : String,
  shader_defs : Array[@shader.ShaderDefVal],
) -> String? {
  ignore(@shader.shader_runtime_compile_wesl_source(world, path, shader_defs)) catch {
    err => return Some(err.message())
  }
  None
}

///|
test "shader runtime wesl registration fails until imported module is explicitly loaded" {
  let failures : Array[String] = []
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(@ecs.World::new())),
  )
  app = app.add_systems(
    @app.Startup,
    @app.system(fn(world : @ecs.World) {
      let failure = wesl_runtime_try_register(
        world,
        "shaders/custom_material.wesl",
        [],
      )
      match failure {
        Some(message) => failures.push(message)
        None =>
          abort("expected wesl registration to fail before util.wesl is loaded")
      }
    }),
  )

  app = app.update()

  debug_inspect(failures.length(), content="1")
  debug_inspect(failures[0].contains("module not found"), content="true")
  debug_inspect(failures[0].contains("package::shaders::util"), content="true")
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
        (try! world.get_resource(@asset.AssetServer::resource())) {
        Some(asset_server) => asset_server
        None => abort("expected AssetServer resource for wesl runtime test")
      }
      let utility_handle : @asset.Handle[Shader] = asset_server.load(
        "shaders/util.wesl",
      )
      ignore(utility_handle)
      let compiled = @shader.shader_runtime_compile_wesl_source(
        world,
        "shaders/custom_material.wesl",
        [@shader.shader_def("PARTY_MODE")],
      ) catch {
        err => abort(err.message())
      }
      match compiled {
        Some(source) => registered_sources.push(source)
        None => abort("expected compiled WESL shader source")
      }
    }),
  )

  app = app.update()

  debug_inspect(registered_sources.length(), content="1")
  debug_inspect(
    registered_sources[0].contains("package_shaders_util__2make_polka_dots"),
    content="true",
  )
  debug_inspect(registered_sources[0].contains("wave_speed"), content="true")
}
