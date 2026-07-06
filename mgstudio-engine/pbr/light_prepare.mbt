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
fn prepare_lights_view_main_entity(
  render_world : @ecs.World,
  view_entity : @core.Entity,
) -> @core.Entity {
  match
    (render_world.get_by_key(view_entity, @render.ecs_key_main_entity) catch {
      _ => abort("prepare_lights: failed to read MainEntity")
    }) {
    Some(main_entity) => main_entity.id()
    None => view_entity
  }
}

///|
fn prepare_lights_view_render_layers(
  render_world : @ecs.World,
  source_world : @ecs.World,
  view_entity : @core.Entity,
) -> @camera_render_layers.RenderLayers {
  match
    (render_world.get_by_key(
      view_entity, @camera_render_layers.ecs_key_render_layers,
    ) catch {
      _ => abort("prepare_lights: failed to read render-world RenderLayers")
    }) {
    Some(layers) => layers
    None => {
      let main_entity = prepare_lights_view_main_entity(
        render_world, view_entity,
      )
      match
        (source_world.get_by_key(
          main_entity, @camera_render_layers.ecs_key_render_layers,
        ) catch {
          _ => abort("prepare_lights: failed to read source-world RenderLayers")
        }) {
        Some(layers) => layers
        None => @camera_render_layers.RenderLayers::RenderLayers()
      }
    }
  }
}

///|
fn prepare_lights_view_is_orthographic(
  render_world : @ecs.World,
  source_world : @ecs.World,
  view_entity : @core.Entity,
) -> Bool {
  match
    (render_world.get_by_key(
      view_entity,
      @light_cluster.ClusterCameraProjection::component(),
    ) catch {
      _ =>
        abort(
          "prepare_lights: failed to read render-world ClusterCameraProjection",
        )
    }) {
    Some(projection) => projection.is_orthographic()
    None => {
      let main_entity = prepare_lights_view_main_entity(
        render_world, view_entity,
      )
      match
        (source_world.get_by_key(
          main_entity,
          @light_cluster.ClusterCameraProjection::component(),
        ) catch {
          _ =>
            abort(
              "prepare_lights: failed to read source-world ClusterCameraProjection",
            )
        }) {
        Some(projection) => projection.is_orthographic()
        None => false
      }
    }
  }
}

///|
fn prepare_lights_gpu_lights_for_view(
  render_world : @ecs.World,
  source_world : @ecs.World,
  view_entity : @core.Entity,
) -> @pbr_render.GpuLights3d {
  guard (render_world.get_by_key(
      view_entity,
      @render_view.ExtractedView::component(),
    ) catch {
      _ => abort("prepare_lights: failed to read ExtractedView")
    })
    is Some(extracted_view) else {
    return @pbr_render.render3d_collect_gpu_lights(render_world)
  }
  guard (render_world.get_by_key(
      view_entity,
      ExtractedClusterConfig::component(),
    ) catch {
      _ => abort("prepare_lights: failed to read ExtractedClusterConfig")
    })
    is Some(cluster_config) else {
    return @pbr_render.render3d_collect_gpu_lights(render_world)
  }
  let viewport_width = extracted_view.viewport_z()
  let viewport_height = extracted_view.viewport_w()
  if viewport_width <= 0 || viewport_height <= 0 {
    return @pbr_render.render3d_collect_gpu_lights(render_world)
  }
  let (cluster_dimensions_x, cluster_dimensions_y, cluster_dimensions_z) = cluster_config.dimensions()
  @pbr_render.render3d_collect_gpu_lights_for_view_config(
    render_world,
    viewport_width~,
    viewport_height~,
    cluster_dimensions_x~,
    cluster_dimensions_y~,
    cluster_dimensions_z~,
    cluster_near=cluster_config.near(),
    cluster_far=cluster_config.far(),
    cluster_is_orthographic=prepare_lights_view_is_orthographic(
      render_world, source_world, view_entity,
    ),
    render_layers=prepare_lights_view_render_layers(
      render_world, source_world, view_entity,
    ),
  )
}

///|
fn prepare_lights_maxf(left : Float, right : Float) -> Float {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn prepare_lights_tan(value : Float) -> Float {
  @math.sin(value) / @math.cos(value)
}

///|
fn prepare_lights_clustered_decal_index(
  world : @ecs.World,
  entity : @core.Entity,
) -> UInt {
  match world.get_resource(@pbr_decal.RenderClusteredDecals::resource()) {
    Some(decals) =>
      match decals.get_decal_index(entity) {
        Some(index) => index.reinterpret_as_uint()
        None => 0xFFFF_FFFFU
      }
    None => 0xFFFF_FFFFU
  }
}

///|
fn prepare_lights_gpu_clustered_light(
  world : @ecs.World,
  item : @pbr_render.ExtractedClusterablePointLight3d,
) -> GpuClusteredLight {
  let light = item.light()
  let (light_custom_data, spot_light_tan_angle) = match
    light.spot_light_angles {
    Some((inner, outer)) => {
      let direction = light.transform.forward()
      let cos_outer = @math.cos(outer)
      let spot_scale = 1.0F /
        prepare_lights_maxf(@math.cos(inner) - cos_outer, 1.0e-4F)
      let spot_offset = 0.0F - cos_outer * spot_scale
      (
        @math.Vec4::new(direction.x, direction.z, spot_scale, spot_offset),
        prepare_lights_tan(outer),
      )
    }
    None => {
      let projection = @pbr_render.render3d_point_shadow_pass_projection(
          light.shadow_map_near_z,
          light.range,
        ).clip_from_view
      (
        @math.Vec4::new(
          projection.z_axis.z,
          projection.z_axis.w,
          projection.w_axis.z,
          projection.w_axis.w,
        ),
        0.0F,
      )
    }
  }
  GpuClusteredLight::{
    light_custom_data,
    color_inverse_square_range: @math.Vec4::new(
      light.color.r * light.intensity,
      light.color.g * light.intensity,
      light.color.b * light.intensity,
      1.0F / (light.range * light.range),
    ),
    position_radius: @math.Vec4::new(
      light.transform.translation.x,
      light.transform.translation.y,
      light.transform.translation.z,
      light.radius,
    ),
    flags: @pbr_render.render3d_point_light_flags(light),
    shadow_depth_bias: light.shadow_depth_bias,
    shadow_normal_bias: light.shadow_normal_bias,
    spot_light_tan_angle,
    soft_shadow_size: if light.soft_shadows_enabled {
      light.radius
    } else {
      0.0F
    },
    shadow_map_near_z: light.shadow_map_near_z,
    decal_index: prepare_lights_clustered_decal_index(world, light.entity),
    range: light.range,
  }
}

///|
fn prepare_lights_global_clusterable_object_meta(
  world : @ecs.World,
  render_device : @render.RenderDevice,
  render_queue : @render.RenderQueue,
) -> Unit {
  match world.get_resource(GlobalClusterableObjectMeta::resource()) {
    Some(global_clusterable_object_meta) => {
      global_clusterable_object_meta.clear()
      let clusterable_lights = @pbr_render.render3d_collect_extracted_clusterable_point_lights(
        world,
      )
      for index in 0..<clusterable_lights.length() {
        let item = clusterable_lights[index]
        global_clusterable_object_meta.add_gpu_clustered_light(
          prepare_lights_gpu_clustered_light(world, item),
        )
        global_clusterable_object_meta.insert_entity_index(
          item.render_entity(),
          index,
        )
      }
      global_clusterable_object_meta.write_gpu_clustered_lights_buffer(
        render_device, render_queue,
      )
    }
    None => ()
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
  prepare_lights_global_clusterable_object_meta(
    world, render_device, render_queue,
  )
  light_meta.clear_view_gpu_lights()
  world.for_each_component(@render_view.ExtractedView::component(), fn(
    view_entity,
    _view,
  ) {
    if !prepare_lights_view_has_camera3d(world, source_world, view_entity) {
      return
    }
    let gpu_lights = prepare_lights_gpu_lights_for_view(
      world, source_world, view_entity,
    )
    let offset = light_meta.push_view_gpu_lights(gpu_lights)
    world.set_by_key(
      view_entity,
      @pbr_render.ViewLightsUniformOffset::component(),
      @pbr_render.ViewLightsUniformOffset::new(offset),
    ) catch {
      _ => abort("prepare_lights: failed to insert ViewLightsUniformOffset")
    }
    world.set_by_key(
      view_entity,
      @pbr_render.ViewLightEntities::component(),
      @pbr_render.ViewLightEntities::ViewLightEntities(),
    ) catch {
      _ => abort("prepare_lights: failed to insert ViewLightEntities")
    }
  })
  light_meta.write_view_gpu_lights_buffer(
    render_device.wgpu_device(),
    render_queue.wgpu_queue(),
  )
}
