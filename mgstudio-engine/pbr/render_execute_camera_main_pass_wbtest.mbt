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
test "render3d: main pass skips deferred opaque materials like bevy queue_material_meshes" {
  let deferred_opaque = @material.MaterialProperties::MaterialProperties()
    .with_render_phase_type(Opaque)
    .with_render_method(Deferred)
  let forward_opaque = @material.MaterialProperties::MaterialProperties()
    .with_render_phase_type(Opaque)
    .with_render_method(Forward)
  let deferred_alpha_mask = @material.MaterialProperties::MaterialProperties()
    .with_render_phase_type(AlphaMask)
    .with_render_method(Deferred)

  debug_inspect(
    render3d_main_pass_skips_deferred_opaque(deferred_opaque),
    content="true",
  )
  debug_inspect(
    render3d_main_pass_skips_deferred_opaque(forward_opaque),
    content="false",
  )
  debug_inspect(
    render3d_main_pass_skips_deferred_opaque(deferred_alpha_mask),
    content="false",
  )
}

///|
test "render3d: main transparent pass executes retained phase draw functions" {
  let world = @ecs.World::new()
  defer world.close()
  let main_view = world.spawn_empty()
  let render_entity = world.spawn_empty()
  let main_entity = world.spawn_empty()
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  let phases = @core_3d.Transparent3dPhase::Transparent3dPhase()
  phases.prepare_for_new_frame(retained_view)
  let draw_functions = @core_3d.Transparent3dDrawFunctions::Transparent3dDrawFunctions()
  let seen : Array[@core.Entity] = []
  let draw_function = draw_functions.register("DrawCustom", fn(_world, item) {
    seen.push(item.entity())
    Success
  })
  phases.add(
    retained_view,
    @core_3d.Transparent3d::new(
      distance=0.0F,
      pipeline=@material.CachedRenderPipelineId::new(4UL),
      entity=render_entity,
      main_entity=@render.MainEntity::new(main_entity),
      draw_function~,
    ),
  )
  world.insert_resource(@core_3d.Transparent3dPhase::resource(), phases)
  world.insert_resource(
    @core_3d.Transparent3dDrawFunctions::resource(),
    draw_functions,
  )
  let items = render3d_transparent_phase_items(world, main_view)
  debug_inspect(items.length(), content="1")
  debug_inspect(render3d_draw_transparent_phase(world, items), content="1")
  debug_inspect(seen.length(), content="1")
  debug_inspect(seen[0] == render_entity, content="true")
}
