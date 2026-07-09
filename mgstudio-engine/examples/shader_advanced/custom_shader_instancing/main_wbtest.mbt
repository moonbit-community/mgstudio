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
fn custom_instancing_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn custom_instancing_approx(a : Float, b : Float) -> Bool {
  custom_instancing_abs(a - b) < 0.0001F
}

///|
fn custom_instancing_read_u32_le(bytes : Bytes, offset : Int) -> UInt {
  let b0 = bytes.get(offset).unwrap().to_int() & 0xFF
  let b1 = bytes.get(offset + 1).unwrap().to_int() & 0xFF
  let b2 = bytes.get(offset + 2).unwrap().to_int() & 0xFF
  let b3 = bytes.get(offset + 3).unwrap().to_int() & 0xFF
  (b0 & 0xFF).reinterpret_as_uint() |
  ((b1 & 0xFF).reinterpret_as_uint() << 8) |
  ((b2 & 0xFF).reinterpret_as_uint() << 16) |
  ((b3 & 0xFF).reinterpret_as_uint() << 24)
}

///|
fn custom_instancing_read_f32_le(bytes : Bytes, offset : Int) -> Float {
  Float::reinterpret_from_uint(custom_instancing_read_u32_le(bytes, offset))
}

///|
test "custom shader instancing: Bevy instance data shape is preserved" {
  let data = instance_material_data()
  debug_inspect(data.instances.length(), content="100")
  let first = data.instances[0]
  let last = data.instances[data.instances.length() - 1]

  debug_inspect(
    custom_instancing_approx(first.position.x, -4.0F) &&
    custom_instancing_approx(first.position.y, -4.0F) &&
    custom_instancing_approx(first.position.z, 0.0F),
    content="true",
  )
  debug_inspect(
    custom_instancing_approx(last.position.x, 5.0F) &&
    custom_instancing_approx(last.position.y, 5.0F) &&
    custom_instancing_approx(last.position.z, 0.0F),
    content="true",
  )
}

///|
test "custom shader instancing: instance vertex payload uses Bevy stride" {
  let bytes = instance_data_bytes(instance_material_data())
  debug_inspect(bytes.length(), content="3200")
  debug_inspect(
    custom_instancing_read_f32_le(bytes, 0).to_double(),
    content="-4",
  )
  debug_inspect(
    custom_instancing_read_f32_le(bytes, 4).to_double(),
    content="-4",
  )
  debug_inspect(
    custom_instancing_read_f32_le(bytes, 8).to_double(),
    content="0",
  )
  debug_inspect(
    custom_instancing_read_f32_le(bytes, 12).to_double(),
    content="1",
  )
  debug_inspect(
    custom_instancing_read_f32_le(bytes, 32).to_double(),
    content="-4",
  )
}

///|
test "custom shader instancing: extraction clones instance array for render world" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(CustomMaterialPlugin::CustomMaterialPlugin())
  let source_world = app.world()
  let source_entity = source_world.spawn()
  let source_data = instance_material_data()
  try! source_world.set_by_key(
    source_entity,
    @render.SyncToRenderWorld::component(),
    @render.SyncToRenderWorld::SyncToRenderWorld(),
  )
  try! source_world.set_by_key(
    source_entity,
    InstanceMaterialData::component(),
    source_data,
  )

  @render.mark_renderer_ready(app.sub_app(@app.RenderApp).world())
  let app = app.run_once()
  source_data.instances[0] = instance_data_new(1.0F, 1.0F)

  let render_entity = (try! app
    .world()
    .get_by_key(source_entity, @render.RenderEntity::component()))
    .unwrap()
    .id()
  let render_world = app.sub_app(@app.RenderApp).world()
  guard (try! render_world.get_by_key(
      render_entity,
      InstanceMaterialData::component(),
    ))
    is Some(render_data) else {
    abort("expected extracted InstanceMaterialData on render entity")
  }
  debug_inspect(render_data.instances.length(), content="100")
  debug_inspect(
    custom_instancing_approx(render_data.instances[0].position.x, -4.0F) &&
    custom_instancing_approx(render_data.instances[0].position.y, -4.0F),
    content="true",
  )
}

///|
test "custom shader instancing: main-world bridge prepares instance vertex buffer" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .add_plugins(CustomMaterialPlugin::CustomMaterialPlugin())
    .add_systems_param3(@app.Startup, setup)
    .run_once()
  let query : @ecs.Query[
    (
      @ecs.Read[InstanceMaterialData],
      @ecs.Read[@render.Mesh3dInstanceVertexBufferData],
    ),
    @ecs.All,
  ] = @ecs.query(app.world())
  let mut count = 0
  let mut length = 0
  try! query.view(fn(_entity, data) {
    count = count + 1
    let (_instance_material, instance_buffer) = data
    length = instance_buffer.value().length()
  })
  debug_inspect(count, content="1")
  debug_inspect(length, content="100")
}

///|
test "custom shader instancing: custom pipeline startup loads shader asset" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
    .add_plugins(CustomMaterialPlugin::CustomMaterialPlugin())
    .run_once()
    .run_once()
  guard app.world().get_resource(CustomPipeline::resource()) is Some(pipeline) else {
    abort("expected CustomPipeline resource")
  }
  let shader_assets_key : @ecs.ResourceKey[@asset.Assets[@shader.Shader]] = @asset.assets_resource_key()
  let shader_assets = app.world().get_resource(shader_assets_key).unwrap()
  let shader = shader_assets.get(pipeline.shader()).unwrap()
  debug_inspect(shader.path, content="\"shaders/instancing.wgsl\"")
}
