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
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::prepare_lights`.

///|
fn prepare_lights_view_has_camera3d(
  render_world : @ecs.World,
  source_world : @ecs.World,
  view_entity : @core.Entity,
) -> Bool {
  match
    (render_world.get_by_key(view_entity, ecs_key_camera3d) catch {
      _ => abort("prepare_lights: failed to read render-world Camera3d")
    }) {
    Some(_) => true
    None =>
      match
        (render_world.get_by_key(view_entity, @render.ecs_key_main_entity) catch {
          _ => abort("prepare_lights: failed to read MainEntity")
        }) {
        Some(main_entity) =>
          (source_world.get_by_key(main_entity.id(), ecs_key_camera3d) catch {
            _ => abort("prepare_lights: failed to read source-world Camera3d")
          })
          is Some(_)
        None => false
      }
  }
}

///|
pub fn prepare_lights(world : @ecs.World) -> Unit {
  let render_device = match
    world.get_resource(@render.render_device_resource_key) {
    Some(value) => value
    None => return
  }
  let render_queue = match
    world.get_resource(@render.render_queue_resource_key) {
    Some(value) => value
    None => return
  }
  let light_meta = match world.get_resource(@pbr_render.LightMeta::resource()) {
    Some(value) => value
    None => return
  }
  let source_world = @render.render_source_world(world)
  let gpu_lights = @pbr_render.render3d_collect_gpu_lights(world)
  light_meta.clear_view_gpu_lights()
  world.for_each_component(@render_view.ExtractedView::component(), fn(
    view_entity,
    _view,
  ) {
    if !prepare_lights_view_has_camera3d(world, source_world, view_entity) {
      return
    }
    let offset = light_meta.push_view_gpu_lights(gpu_lights)
    world.set_by_key(
      view_entity,
      @pbr_render.ViewLightsUniformOffset::component(),
      @pbr_render.ViewLightsUniformOffset::new(offset),
    ) catch {
      _ => abort("prepare_lights: failed to insert ViewLightsUniformOffset")
    }
  })
  light_meta.write_view_gpu_lights_buffer(
    render_device.wgpu_device(),
    render_queue.wgpu_queue(),
  )
}
