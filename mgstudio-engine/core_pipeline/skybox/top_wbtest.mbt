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
fn skybox_test_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn skybox_test_approx(a : Float, b : Float) -> Bool {
  skybox_test_abs(a - b) < 0.0001F
}

///|
test "skybox: render sub app configuration installs Bevy-shaped resources" {
  let render_sub_app = @app.SubApp::new(@ecs.World::new()).set_update_schedule(
    Some(@render.render_schedule_stage()),
  )
  let render_sub_app = configure_skybox_render_sub_app(render_sub_app)
  let world = render_sub_app.world()

  debug_inspect(
    world.resource(SkyboxPipelineState::resource()).is_present(),
    content="true",
  )
  debug_inspect(
    world.resource(ExtractedSkyboxes::resource()).is_present(),
    content="true",
  )
}

///|
test "skybox: uniforms match Bevy brightness and inverse-rotation transform" {
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(7)
  let skybox = @light.Skybox::new(image, 2.0F).with_rotation(
    @math.Quat::identity(),
  )
  let uniforms = SkyboxUniforms::from_skybox(skybox, 3.0F)

  debug_inspect(skybox_test_approx(uniforms.brightness, 6.0F), content="true")
  debug_inspect(uniforms.transform.length(), content="16")
  debug_inspect(
    skybox_test_approx(uniforms.transform[0], 1.0F) &&
    skybox_test_approx(uniforms.transform[5], 1.0F) &&
    skybox_test_approx(uniforms.transform[10], 1.0F) &&
    skybox_test_approx(uniforms.transform[15], 1.0F),
    content="true",
  )
}

///|
test "skybox: draw params come from extracted uniforms and inverse rotation" {
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(11)
  let skybox = @light.Skybox::new(image, 4.0F).with_rotation(
    @math.Quat::new(0.25F, 0.0F, 0.0F, 1.0F),
  )
  let entry = ExtractedSkybox::new(
    render_entity=@core.Entity::new(2, 1),
    skybox~,
    uniforms=SkyboxUniforms::from_skybox(skybox, 0.5F),
  )
  guard skybox_draw_params_from_extracted(entry) is Some(params) else {
    abort("expected skybox draw params")
  }

  debug_inspect(params.texture_id, content="11")
  debug_inspect(skybox_test_approx(params.brightness, 2.0F), content="true")
  debug_inspect(skybox_test_approx(params.rotation.x, -0.25F), content="true")
  debug_inspect(skybox_test_approx(params.rotation.w, 1.0F), content="true")
}

///|
test "skybox: prepare pipelines writes render-world view component" {
  let world = @ecs.World::new()
  let render_entity = world.spawn()
  try! world.set_by_key(
    render_entity,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(render_entity),
      target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    ),
  )
  try! world.set_by_key(
    render_entity,
    @render_view.Msaa::component(),
    @render_view.Msaa::Sample4,
  )
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(17)
  let skybox = @light.Skybox::new(image, 1.0F)
  let extracted = ExtractedSkyboxes::ExtractedSkyboxes()
  extracted.push(
    ExtractedSkybox::new(
      render_entity~,
      skybox~,
      uniforms=SkyboxUniforms::from_skybox(skybox, 1.0F),
    ),
  )
  world.insert_resource(ExtractedSkyboxes::resource(), extracted)
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )

  prepare_skybox_pipelines(world)

  debug_inspect(view_has_skybox_pipeline(world, render_entity), content="true")
  guard (try! world.get_by_key(render_entity, ecs_key_skybox_pipeline_id))
    is Some(pipeline_id) else {
    abort("expected SkyboxPipelineId")
  }
  debug_inspect(pipeline_id.pipeline_id().id(), content="0")
  let pipeline_cache = world
    .get_resource(@render.pipeline_cache_resource_key)
    .unwrap()
  debug_inspect(pipeline_cache.queued_pipeline_count(), content="1")
}

///|
test "skybox: prepare pipelines requires Bevy render-view components" {
  let world = @ecs.World::new()
  let render_entity = world.spawn()
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(19)
  let skybox = @light.Skybox::new(image, 1.0F)
  let extracted = ExtractedSkyboxes::ExtractedSkyboxes()
  extracted.push(
    ExtractedSkybox::new(
      render_entity~,
      skybox~,
      uniforms=SkyboxUniforms::from_skybox(skybox, 1.0F),
    ),
  )
  world.insert_resource(ExtractedSkyboxes::resource(), extracted)
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )

  prepare_skybox_pipelines(world)

  debug_inspect(view_has_skybox_pipeline(world, render_entity), content="false")
  let pipeline_cache = world
    .get_resource(@render.pipeline_cache_resource_key)
    .unwrap()
  debug_inspect(pipeline_cache.queued_pipeline_count(), content="0")
}
