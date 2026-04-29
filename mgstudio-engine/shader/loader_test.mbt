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
test "shader plugin initializes Assets<Shader> resource" {
  let app = shader_plugin(@asset.asset_plugin(@app.App::new(@ecs.World::new())))
  let world = app.world()
  let shader_assets_key : @ecs.ResourceKey[@asset.Assets[Shader]] = @asset.assets_resource_key()
  debug_inspect(
    (try! world.get_resource(shader_assets_key)) is Some(_),
    content="true",
  )
}

///|
test "shader loader exposes wesl extension through the shared shader loader" {
  debug_inspect(
    ShaderLoader::default().extensions().contains("wesl"),
    content="true",
  )
}

///|
test "shader loader stores typed shader assets and direct file dependencies" {
  let dep_source =
    #|#define_import_path tests::shader_loader::dep
    #|const DEP_VALUE : f32 = 1.0;
    #|
    #|
  let root_source =
    #|#define_import_path tests::shader_loader::root
    #|
    #|#import "shader/tests/shader_loader/dep.wgsl"::DEP_VALUE
    #|
    #|fn root_value() -> f32 {
    #|  return DEP_VALUE;
    #|}
    #|
    #|
  @asset.register_embedded_asset_virtual_bytes(
    "shader/tests/shader_loader/dep.wgsl",
    @asset.asset_text_to_bytes(dep_source),
  )
  @asset.register_embedded_asset_virtual_bytes(
    "shader/tests/shader_loader/root.wgsl",
    @asset.asset_text_to_bytes(root_source),
  )
  let loaded_handle_ids : Array[Int] = []
  let root_dependency_lengths : Array[Int] = []
  let dep_dependency_lengths : Array[Int] = []
  let root_paths : Array[String] = []
  let dep_paths : Array[String] = []
  let mut app = shader_plugin(
    @asset.asset_plugin(@app.App::new(@ecs.World::new())),
  )
  app = app.add_systems(
    @app.Startup,
    @app.system(fn(world : @ecs.World) {
      let asset_server = @asset.AssetServer::new()
      let root_handle : @asset.Handle[Shader] = asset_server.load(
        "shader/tests/shader_loader/root.wgsl",
      )
      let dep_handle : @asset.Handle[Shader] = asset_server.load(
        "shader/tests/shader_loader/dep.wgsl",
      )
      loaded_handle_ids.push(root_handle.id())
      loaded_handle_ids.push(dep_handle.id())

      let shader_assets_key : @ecs.ResourceKey[@asset.Assets[Shader]] = @asset.assets_resource_key()
      let shader_assets = match (try! world.get_resource(shader_assets_key)) {
        Some(assets) => assets
        None => abort("expected Assets<Shader> resource")
      }

      let root_shader = match shader_assets.get(root_handle) {
        Some(shader) => shader
        None => abort("expected root shader asset")
      }
      let dep_shader = match shader_assets.get(dep_handle) {
        Some(shader) => shader
        None => abort("expected dependency shader asset")
      }

      root_paths.push(root_shader.path)
      dep_paths.push(dep_shader.path)
      root_dependency_lengths.push(root_shader.file_dependencies.length())
      dep_dependency_lengths.push(dep_shader.file_dependencies.length())
      loaded_handle_ids.push(root_shader.file_dependencies[0].id())
    }),
  )

  app = app.update()

  debug_inspect(loaded_handle_ids.length(), content="3")
  debug_inspect(loaded_handle_ids[0] == loaded_handle_ids[1], content="false")
  debug_inspect(loaded_handle_ids[1] == loaded_handle_ids[2], content="true")
  debug_inspect(
    root_paths[0],
    content="\"shader/tests/shader_loader/root.wgsl\"",
  )
  debug_inspect(dep_paths[0], content="\"shader/tests/shader_loader/dep.wgsl\"")
  debug_inspect(root_dependency_lengths[0], content="1")
  debug_inspect(dep_dependency_lengths[0], content="0")
}
