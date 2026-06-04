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
test "sprite: @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig can be accessed through ResMut" {
  let observed : Ref[Bool?] = Ref(None)
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(
      @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig::Wireframe2dConfig(),
    )
    .add_system_param(fn(
      config : @app.ResMut[@sprite_render_mesh2d_wireframe2d.Wireframe2dConfig],
    ) {
      observed.val = Some(config.get().global)
      config.update(fn(value) { value.with_global(true) })
    })

  app.run_once() |> ignore

  debug_inspect(observed.val, content="Some(false)")
  debug_inspect(
    app
    .world()
    .get_resource(
      @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig::resource(),
    )
    .map(fn(config) { config.global }),
    content="Some(true)",
  )
}

///|
test "sprite: @sprite_render_mesh2d_wireframe2d.Wireframe2dPlugin applies @sprite_render_mesh2d_wireframe2d.Mesh2dWireframe material handles" {
  let entity_ref : Ref[@core.Entity?] = Ref(None)
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(
      @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig::new(
        true,
        Color::white(),
      ),
    )
    .add_plugins(
      @sprite_render_mesh2d_wireframe2d.Wireframe2dPlugin::Wireframe2dPlugin(),
    )
    .add_system(fn(world : @ecs.World) {
      if entity_ref.val is Some(_) {
        return
      }
      let entity = world.spawn()
      entity_ref.val = Some(entity)
      try! (world.set_by_key(
        entity,
        @mesh.ecs_key_mesh2d,
        @mesh.Mesh2d::new(@asset.Handle::new(7)),
      )
      |> ignore)
    })

  app.run_once() |> ignore
  app.run_once() |> ignore

  let entity = entity_ref.val.unwrap()
  let wireframe = (try! app
  .world()
  .get_by_key(
    entity,
    @sprite_render_mesh2d_wireframe2d.Mesh2dWireframe::component(),
  )).unwrap()
  let material_key : @ecs.ResourceKey[
    @asset.Assets[@sprite_render_mesh2d_wireframe2d.Wireframe2dMaterial],
  ] = @asset.assets_resource_key()
  let materials = app.world().get_resource(material_key).unwrap()
  debug_inspect(wireframe.handle().id() >= 0, content="true")
  debug_inspect(materials.get(wireframe.handle()) is Some(_), content="true")
}
