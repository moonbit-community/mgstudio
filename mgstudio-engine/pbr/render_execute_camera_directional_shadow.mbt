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
priv struct Render3dDirectionalCascadePass {
  transform : @transform.Transform
  projection : @pbr_render.Render3dPassProjection
  clip_from_world : @pbr_render.ProjectionMatrix3d
  texel_size : Float
  far_bound : Float
}

///|
fn render3d_directional_cascade_pass(
  light_transform : @transform.Transform,
  cascade : @light.Cascade,
  far_bound : Float,
) -> Render3dDirectionalCascadePass {
  let translation = cascade.world_from_cascade.w_axis()
  let clip_from_cascade = @pbr_render.ProjectionMatrix3d::from_mat4(
    cascade.clip_from_cascade,
  )
  let transform = @transform.Transform::new(
    @math.Vec3::new(translation.x, translation.y, translation.z),
    light_transform.rotation,
    @math.Vec3::splat(1.0F),
  )
  Render3dDirectionalCascadePass::{
    transform,
    projection: @pbr_render.render3d_pass_projection(
      clip_from_cascade, clip_from_cascade, 0.0F, far_bound,
    ),
    clip_from_world: @pbr_render.ProjectionMatrix3d::from_mat4(
      cascade.clip_from_world,
    ),
    texel_size: cascade.texel_size,
    far_bound,
  }
}

///|
fn render3d_directional_shadow_cascades(
  camera_entity : @core.Entity,
  pass_lighting : Render3dLightingState,
) -> Array[Render3dDirectionalCascadePass] {
  let cascades : Array[Render3dDirectionalCascadePass] = []
  let bounds = pass_lighting.directional_cascade_bounds
  let source_cascades = pass_lighting.directional_cascades.get(camera_entity)
  let requested_count = if bounds.length() < source_cascades.length() {
    bounds.length()
  } else {
    source_cascades.length()
  }
  let count = if requested_count < @pbr_render.MAX_CASCADES_PER_LIGHT {
    requested_count
  } else {
    @pbr_render.MAX_CASCADES_PER_LIGHT
  }
  for i in 0..<count {
    cascades.push(
      render3d_directional_cascade_pass(
        pass_lighting.directional_transform,
        source_cascades[i],
        bounds[i],
      ),
    )
  }
  cascades
}

///|
fn render3d_directional_shadow_cascade_data(
  cascades : Array[Render3dDirectionalCascadePass],
) -> Array[Float] {
  let values : Array[Float] = []
  for i in 0..<@pbr_render.MAX_CASCADES_PER_LIGHT {
    if i < cascades.length() {
      let cascade = cascades[i]
      let clip = cascade.clip_from_world
      values.push(clip.x_axis.x)
      values.push(clip.x_axis.y)
      values.push(clip.x_axis.z)
      values.push(clip.x_axis.w)
      values.push(clip.y_axis.x)
      values.push(clip.y_axis.y)
      values.push(clip.y_axis.z)
      values.push(clip.y_axis.w)
      values.push(clip.z_axis.x)
      values.push(clip.z_axis.y)
      values.push(clip.z_axis.z)
      values.push(clip.z_axis.w)
      values.push(clip.w_axis.x)
      values.push(clip.w_axis.y)
      values.push(clip.w_axis.z)
      values.push(clip.w_axis.w)
      values.push(cascade.texel_size)
      values.push(cascade.far_bound)
      values.push(0.0F)
      values.push(0.0F)
    } else {
      for _ in 0..<20 {
        values.push(0.0F)
      }
    }
  }
  values
}

///|
fn render3d_directional_shadow_frustum_planes(
  clip_from_world : @pbr_render.ProjectionMatrix3d,
) -> Array[@render.HostMesh3dPreprocessFrustumPlane] {
  let planes = render3d_host_preprocess_view_frustum_planes_from_clip_from_world(
    clip_from_world,
  )
  if @pbr_render.VIEW_FRUSTUM_NEAR_PLANE_IDX < planes.length() {
    let near = planes[@pbr_render.VIEW_FRUSTUM_NEAR_PLANE_IDX]
    planes[@pbr_render.VIEW_FRUSTUM_NEAR_PLANE_IDX] = @render.HostMesh3dPreprocessFrustumPlane::{
      normal_x: near.normal_x,
      normal_y: near.normal_y,
      normal_z: near.normal_z,
      distance: @float.infinity,
    }
  }
  planes
}

///|
priv struct Render3dDirectionalShadowPassPlan {
  binding : Render3dDirectionalShadowBinding
  phase_views : Array[Render3dShadowPhaseExecutionView]
}

///|
fn render3d_prepare_camera_directional_shadow_pass(
  world : @ecs.World,
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  pass_lighting : Render3dLightingState,
  meshes : Array[ExtractedMesh3d],
  shadow_pass_kind : Int,
) -> Render3dDirectionalShadowPassPlan {
  let empty_phase_views : Array[Render3dShadowPhaseExecutionView] = []
  let shadow_map_size = match
    world.get_resource(@light.ecs_key_directional_light_shadow_map) {
    Some(v) => if v.size <= 0 { 1 } else { v.size }
    None => @light.DirectionalLightShadowMap::DirectionalLightShadowMap().size
  }
  let directional_enabled = pass_lighting.directional_shadow_maps_enabled &&
    pass_lighting.directional_entity is Some(_) &&
    pass_lighting.directional_render_entity is Some(_)
  let cascades = if directional_enabled {
    render3d_directional_shadow_cascades(camera_entity, pass_lighting)
  } else {
    []
  }
  let spot_enabled = pass_lighting.spot_shadow_maps_enabled &&
    pass_lighting.spot_entity is Some(_) &&
    pass_lighting.spot_render_entity is Some(_) &&
    pass_lighting.spot_range > 0.0F
  if cascades.length() == 0 && !spot_enabled {
    return {
      binding: render3d_directional_shadow_binding_none(),
      phase_views: empty_phase_views,
    }
  }
  let spot_shadow_layer_count = if spot_enabled {
    pass_lighting.spot_light_index + 1
  } else {
    0
  }
  let target_layers = render3d_directional_spot_shadow_target_layers(
    cascades.length(),
    spot_shadow_layer_count,
  )
  let target_id = render3d_directional_light_shadow_target_get_or_create(
    world, camera_entity, shadow_map_size, target_layers,
  )
  let shadow_phase_views : Array[Render3dShadowPhaseExecutionView] = []
  if pass_lighting.directional_entity is Some(light_entity) &&
    pass_lighting.directional_render_entity is Some(directional_render_entity) {
    for cascade_index in 0..<cascades.length() {
      let cascade = cascades[cascade_index]
      let shadow_phase_trace_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "render_3d_shadow_phase_construction",
      )
      let shadow_light_entity = Render3dLightEntity::Directional(
        light_entity=directional_render_entity,
        main_entity=light_entity,
        cascade_index~,
      )
      let retained_view_entity = shadow_light_entity.shadow_phase_retained_view(
        @render_view.RetainedViewEntity::new(camera_entity),
      )
      ignore(
        render3d_prepare_queued_shadow_phase_visible_view(
          world,
          shadow_light_entity,
          retained_view_entity,
          meshes,
          camera.layers,
          render3d_directional_shadow_frustum_planes(cascade.clip_from_world),
        ),
      )
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "render_3d_shadow_phase_construction",
        shadow_phase_trace_start_us,
      )
      let shadow_view = Render3dShadowView::{
        target_id,
        target_layer: cascade_index,
        width: shadow_map_size,
        height: shadow_map_size,
        transform: cascade.transform,
        projection: cascade.projection,
        clip_from_world: Some(cascade.clip_from_world),
        light_entity: shadow_light_entity,
        pass_name: render3d_directional_shadow_pass_name(0, cascade_index),
        occlusion_culling_subview: render3d_directional_shadow_occlusion_culling_subview(
          pass_lighting, target_id, shadow_map_size,
        ),
      }
      shadow_phase_views.push({
        phase_view: { shadow_view, },
        pass_kind: shadow_pass_kind,
        point_shadow_near: 0.1F,
      })
    }
  }
  if spot_enabled {
    match
      render3d_prepare_camera_spot_shadow_phase_view(
        world,
        camera_entity,
        camera,
        pass_lighting,
        meshes,
        target_id,
        render3d_spot_shadow_target_layer(
          cascades.length(),
          pass_lighting.spot_light_index,
        ),
        shadow_map_size,
        shadow_pass_kind,
      ) {
      Some(phase_view) => shadow_phase_views.push(phase_view)
      None => ()
    }
  }
  {
    binding: {
      texture_id: target_id,
      enabled: if cascades.length() > 0 {
        1.0F
      } else {
        0.0F
      },
      cascade_data: render3d_directional_shadow_cascade_data(cascades),
      cascade_count: cascades.length(),
    },
    phase_views: shadow_phase_views,
  }
}

///|
fn render3d_prepare_camera_spot_shadow_phase_view(
  world : @ecs.World,
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  pass_lighting : Render3dLightingState,
  meshes : Array[ExtractedMesh3d],
  target_id : Int,
  target_layer : Int,
  shadow_map_size : Int,
  shadow_pass_kind : Int,
) -> Render3dShadowPhaseExecutionView? {
  guard pass_lighting.spot_entity is Some(light_entity) else { return None }
  guard pass_lighting.spot_render_entity is Some(spot_render_entity) else {
    return None
  }
  let spot_near = if pass_lighting.spot_shadow_map_near_z > 0.0001F {
    pass_lighting.spot_shadow_map_near_z
  } else {
    0.0001F
  }
  let spot_projection = @pbr_render.render3d_pass_projection(
    @pbr_render.render3d_spot_light_clip_from_view(
      pass_lighting.spot_outer_angle,
      spot_near,
    ),
    @pbr_render.render3d_spot_light_clip_from_view(
      pass_lighting.spot_outer_angle,
      spot_near,
    ),
    spot_near,
    pass_lighting.spot_range,
  )
  let clip_from_world = @pbr_render.render3d_spot_light_clip_from_world(
    pass_lighting.spot_transform,
    pass_lighting.spot_outer_angle,
    spot_near,
  )
  let shadow_phase_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_shadow_phase_construction",
  )
  let shadow_light_entity = Render3dLightEntity::Spot(
    light_entity=spot_render_entity,
    main_entity=light_entity,
  )
  let retained_view_entity = shadow_light_entity.shadow_phase_retained_view(
    @render_view.RetainedViewEntity::new(camera_entity),
  )
  ignore(
    render3d_prepare_queued_shadow_phase_visible_view(
      world,
      shadow_light_entity,
      retained_view_entity,
      meshes,
      camera.layers,
      render3d_directional_shadow_frustum_planes(clip_from_world),
    ),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_shadow_phase_construction",
    shadow_phase_trace_start_us,
  )
  let shadow_view = Render3dShadowView::{
    target_id,
    target_layer,
    width: shadow_map_size,
    height: shadow_map_size,
    transform: pass_lighting.spot_transform,
    projection: spot_projection,
    clip_from_world: Some(clip_from_world),
    light_entity: shadow_light_entity,
    pass_name: render3d_spot_shadow_pass_name(pass_lighting.spot_light_index),
    occlusion_culling_subview: None,
  }
  Some({
    phase_view: { shadow_view, },
    pass_kind: shadow_pass_kind,
    point_shadow_near: spot_near,
  })
}

///|
fn render3d_directional_spot_shadow_target_layers(
  directional_cascade_count : Int,
  spot_shadow_layer_count : Int,
) -> Int {
  let directional_layers = if directional_cascade_count <= 0 {
    0
  } else {
    directional_cascade_count
  }
  let spot_layers = if spot_shadow_layer_count <= 0 {
    0
  } else {
    spot_shadow_layer_count
  }
  let total = directional_layers + spot_layers
  if total <= 0 {
    1
  } else {
    total
  }
}

///|
fn render3d_spot_shadow_target_layer(
  directional_cascade_count : Int,
  spot_light_index : Int,
) -> Int {
  let directional_layers = if directional_cascade_count <= 0 {
    0
  } else {
    directional_cascade_count
  }
  let safe_spot_light_index = if spot_light_index < 0 {
    0
  } else {
    spot_light_index
  }
  directional_layers + safe_spot_light_index
}

///|
fn render3d_directional_shadow_occlusion_culling_subview(
  lighting : Render3dLightingState,
  target_id : Int,
  shadow_map_size : Int,
) -> @render_occlusion_culling.OcclusionCullingSubview? {
  if !lighting.directional_occlusion_culling {
    return None
  }
  Some(
    @render_occlusion_culling.OcclusionCullingSubview::new(
      depth_texture_view_id=target_id,
      depth_texture_size=shadow_map_size,
    ),
  )
}

///|
priv struct DirectionalLightShadowTargetsEntry {
  camera_entity : @core.Entity
  size : Int
  layers : Int
  target_id : Int
}

///|
priv struct Render3dDirectionalLightShadowTargets {
  mut entries : Array[DirectionalLightShadowTargetsEntry]
}

///|
let render3d_directional_light_shadow_targets_key : @ecs.ResourceKey[
  Render3dDirectionalLightShadowTargets,
] = @ecs.register_resource(
  debug_name="mgstudio.render3d.directional_light_shadow_targets",
)

///|
impl @app.Resource for Render3dDirectionalLightShadowTargets with fn resource() {
  render3d_directional_light_shadow_targets_key
}

///|
fn render3d_directional_light_shadow_targets_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dDirectionalLightShadowTargets] {
  if world.get_resource(Render3dDirectionalLightShadowTargets::resource())
    is None {
    world.insert_resource(Render3dDirectionalLightShadowTargets::resource(), {
      entries: [],
    })
  }
  match
    world.get_resource_mut(Render3dDirectionalLightShadowTargets::resource()) {
    Some(state) => state
    None => abort("Missing Render3dDirectionalLightShadowTargets resource")
  }
}

///|
fn render3d_directional_light_shadow_target_get_or_create(
  world : @ecs.World,
  camera_entity : @core.Entity,
  size : Int,
  layers : Int,
) -> Int {
  let shadow_targets_mut = render3d_directional_light_shadow_targets_mut_or_init(
    world,
  )
  let shadow_targets = shadow_targets_mut.peek().entries
  let safe_size = if size <= 0 { 1 } else { size }
  let safe_layers = if layers <= 0 { 1 } else { layers }
  for item in shadow_targets {
    if item.camera_entity.id == camera_entity.id &&
      item.camera_entity.generation == camera_entity.generation &&
      item.size == safe_size &&
      item.layers == safe_layers {
      return item.target_id
    }
  }
  let target_id = @render.host_gpu_create_directional_light_shadow_target(
    size=safe_size,
    layers=safe_layers,
  )
  let next : Array[DirectionalLightShadowTargetsEntry] = []
  let mut replaced = false
  for item in shadow_targets {
    if item.camera_entity.id == camera_entity.id &&
      item.camera_entity.generation == camera_entity.generation {
      if !replaced {
        next.push({
          camera_entity,
          size: safe_size,
          layers: safe_layers,
          target_id,
        })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ camera_entity, size: safe_size, layers: safe_layers, target_id })
  }
  shadow_targets_mut.modify(fn(state) { state.entries = next })
  target_id
}
