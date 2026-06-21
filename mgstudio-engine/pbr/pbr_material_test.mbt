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
test "pbr material: key encodes common standard material toggles" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_base_color_texture(Some(@asset.Handle::new(1)))
    .with_emissive_texture(Some(@asset.Handle::new(2)))
    .with_normal_map_texture(Some(@asset.Handle::new(3)))
    .with_diffuse_transmission(0.4)
    .with_specular_transmission(0.2)
    .with_depth_bias(7.0)
  let key = standard_material_key_from_material(material)
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_BASE_COLOR_TEXTURE),
    content="true",
  )
  inspect(key.contains(STANDARD_MATERIAL_KEY_EMISSIVE_TEXTURE), content="true")
  inspect(key.contains(STANDARD_MATERIAL_KEY_NORMAL_MAP), content="true")
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION),
    content="true",
  )
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION),
    content="true",
  )
  inspect(key.depth_bias(), content="7")
}

///|
test "pbr material: key depth bias roundtrips" {
  let key = StandardMaterialKey::empty().with_depth_bias(42U)
  inspect(key.depth_bias(), content="42")
}

///|
test "pbr material: auto opaque renderer method follows bevy diffuse transmission override" {
  let deferred_default = @material.OpaqueRendererMethod::Deferred
  let auto_material = @material.StandardMaterial::StandardMaterial()
  let auto_deferred = standard_material_opaque_render_method(
    auto_material, deferred_default,
  )
  inspect(
    auto_deferred is @material.OpaqueRendererMethod::Deferred,
    content="true",
  )
  let diffuse_transmissive_auto = @material.StandardMaterial::StandardMaterial().with_diffuse_transmission(
    0.5F,
  )
  let auto_forced_forward = standard_material_opaque_render_method(
    diffuse_transmissive_auto, deferred_default,
  )
  inspect(
    auto_forced_forward is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
}

///|
test "pbr material: reads_view_transmission_texture follows specular transmission only" {
  let diffuse_only = @material.StandardMaterial::StandardMaterial().with_diffuse_transmission(
    0.7F,
  )
  let specular_only = @material.StandardMaterial::StandardMaterial().with_specular_transmission(
    0.2F,
  )
  inspect(
    standard_material_reads_view_transmission_texture(diffuse_only),
    content="false",
  )
  inspect(
    standard_material_reads_view_transmission_texture(specular_only),
    content="true",
  )
}

///|
test "pbr material: render phase type matches bevy ordering" {
  let transparent = @material.StandardMaterial::StandardMaterial()
    .with_alpha_mode(@material.AlphaMode3d::Blend)
    .with_specular_transmission(1.0F)
  let transmissive = @material.StandardMaterial::StandardMaterial().with_specular_transmission(
    1.0F,
  )
  let alpha_mask = @material.StandardMaterial::StandardMaterial().with_alpha_mode(
    @material.AlphaMode3d::Mask(0.5F),
  )
  let opaque_material = @material.StandardMaterial::StandardMaterial()
  inspect(
    standard_material_render_phase_type(transparent)
    is @material.RenderPhaseType::Transparent,
    content="true",
  )
  inspect(
    standard_material_render_phase_type(transmissive)
    is @material.RenderPhaseType::Transmissive,
    content="true",
  )
  inspect(
    standard_material_render_phase_type(alpha_mask)
    is @material.RenderPhaseType::AlphaMask,
    content="true",
  )
  inspect(
    standard_material_render_phase_type(opaque_material)
    is @material.RenderPhaseType::Opaque,
    content="true",
  )
}

///|
test "pbr material: standard material plugin plan mirrors material plugin build surface" {
  let plan = standard_material_plugin_plan(
    StandardMaterialPlugin::StandardMaterialPlugin(),
  )
  inspect(plan.prepass_enabled(), content="true")
  inspect(
    plan.debug_flags().allow_copies_from_indirect_parameters(),
    content="false",
  )
  inspect(plan.shadows_enabled(), content="true")
  inspect(plan.main_world_steps().length(), content="4")
  inspect(plan.post_update_steps().length(), content="3")
  inspect(plan.render_startup_steps().length(), content="1")
  inspect(plan.extract_schedule_steps().length(), content="4")
  inspect(plan.main_world_steps()[0], content="init_asset<StandardMaterial>")
  inspect(
    plan.main_world_steps()[3],
    content="add_plugin<ErasedRenderAssetPlugin<MeshMaterial3d<StandardMaterial>>>",
  )
  inspect(
    plan.post_update_steps()[2],
    content="check_light_entities_needing_specialization<StandardMaterial>",
  )
  inspect(
    plan.render_startup_steps()[0],
    content="add_material_bind_group_allocator<StandardMaterial>",
  )
  inspect(
    plan.extract_schedule_steps()[3],
    content="sweep_entities_needing_specialization<StandardMaterial>",
  )
}

///|
test "pbr material: standard material plugin state retains build plan" {
  let plugin = StandardMaterialPlugin::StandardMaterialPlugin()
    .with_prepass_enabled(false)
    .with_debug_flags(
      @render.RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
        true,
      ),
    )
  let state = StandardMaterialPluginState::from_plugin(plugin)
  let plan = state.plan()
  inspect(
    state.debug_flags().allow_copies_from_indirect_parameters(),
    content="true",
  )
  inspect(plan.prepass_enabled(), content="false")
  inspect(
    plan.debug_flags().allow_copies_from_indirect_parameters(),
    content="true",
  )
  inspect(
    plan.extract_schedule_steps()[0],
    content="extract_mesh_materials<StandardMaterial>",
  )
}

///|
test "pbr material: standard material plugin installs render startup allocator" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(MaterialsPlugin::MaterialsPlugin())
    .add_plugins(StandardMaterialPlugin::StandardMaterialPlugin())
  let render_sub_app = app
    .sub_app(@app.RenderApp)
    .set_update_schedule(Some(@render.render_startup_schedule_stage()))
  let render_world = render_sub_app.world()
  match render_world.get_resource(ecs_key_material_bind_group_allocators) {
    Some(allocators) =>
      debug_inspect(allocators.contains("StandardMaterial"), content="false")
    None => debug_inspect(false, content="true")
  }
  ignore(render_sub_app.run_startup())
  match render_world.get_resource(ecs_key_material_bind_group_allocators) {
    Some(allocators) => {
      debug_inspect(allocators.contains("StandardMaterial"), content="true")
      match allocators.get("StandardMaterial") {
        Some(MaterialBindGroupAllocator::NonBindless(_)) =>
          debug_inspect(true, content="true")
        _ => debug_inspect(false, content="true")
      }
    }
    None => debug_inspect(false, content="true")
  }
}
