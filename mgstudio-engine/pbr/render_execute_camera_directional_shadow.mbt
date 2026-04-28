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
fn render3d_vec3_min(a : @math.Vec3, b : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(
    @pbr_render.minf(a.x, b.x),
    @pbr_render.minf(a.y, b.y),
    @pbr_render.minf(a.z, b.z),
  )
}

///|
fn render3d_vec3_max(a : @math.Vec3, b : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(
    @pbr_render.maxf(a.x, b.x),
    @pbr_render.maxf(a.y, b.y),
    @pbr_render.maxf(a.z, b.z),
  )
}

///|
fn render3d_world_from_light_axes(
  transform : @transform.Transform,
) -> (@math.Vec3, @math.Vec3, @math.Vec3) {
  (
    @pbr_render.quat_rotate_vec3(
      transform.rotation,
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
    ),
    @pbr_render.quat_rotate_vec3(
      transform.rotation,
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    @pbr_render.quat_rotate_vec3(
      transform.rotation,
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
    ),
  )
}

///|
fn render3d_light_from_world_point(
  point : @math.Vec3,
  light_x : @math.Vec3,
  light_y : @math.Vec3,
  light_z : @math.Vec3,
) -> @math.Vec3 {
  @math.Vec3::new(point.dot(light_x), point.dot(light_y), point.dot(light_z))
}

///|
fn render3d_camera_view_point_to_world(
  camera_transform : @transform.Transform,
  point : @math.Vec3,
) -> @math.Vec3 {
  @pbr_render.quat_rotate_vec3(camera_transform.rotation, point).add(
    camera_transform.translation,
  )
}

///|
fn render3d_directional_clip_from_cascade(
  cascade_diameter : Float,
  min_z : Float,
  max_z : Float,
) -> @pbr_render.ProjectionMatrix3d {
  let safe_diameter = if cascade_diameter <= 0.0001F {
    0.0001F
  } else {
    cascade_diameter
  }
  let depth = max_z - min_z
  let r = if depth <= 0.0001F { 1.0F / 0.0001F } else { 1.0F / depth }
  @pbr_render.ProjectionMatrix3d::from_cols(
    @math.Vec4::new(2.0F / safe_diameter, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 2.0F / safe_diameter, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, r, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
  )
}

///|
fn render3d_directional_cascade_from_world(
  light_x : @math.Vec3,
  light_y : @math.Vec3,
  light_z : @math.Vec3,
  near_plane_center : @math.Vec3,
) -> @pbr_render.ProjectionMatrix3d {
  @pbr_render.ProjectionMatrix3d::from_cols(
    @math.Vec4::new(light_x.x, light_y.x, light_z.x, 0.0F),
    @math.Vec4::new(light_x.y, light_y.y, light_z.y, 0.0F),
    @math.Vec4::new(light_x.z, light_y.z, light_z.z, 0.0F),
    @math.Vec4::new(
      -near_plane_center.x,
      -near_plane_center.y,
      -near_plane_center.z,
      1.0F,
    ),
  )
}

///|
fn render3d_directional_cascade_world_translation(
  light_x : @math.Vec3,
  light_y : @math.Vec3,
  light_z : @math.Vec3,
  near_plane_center : @math.Vec3,
) -> @math.Vec3 {
  light_x
  .mul_scalar(near_plane_center.x)
  .add(light_y.mul_scalar(near_plane_center.y))
  .add(light_z.mul_scalar(near_plane_center.z))
}

///|
fn render3d_calculate_directional_cascade(
  camera_transform : @transform.Transform,
  light_transform : @transform.Transform,
  frustum_corners : Array[@math.Vec3],
  far_bound : Float,
  shadow_map_size : Int,
) -> Render3dDirectionalCascadePass {
  let (light_x, light_y, light_z) = render3d_world_from_light_axes(
    light_transform,
  )
  let mut min_light = @math.Vec3::splat(3.402823e38F)
  let mut max_light = @math.Vec3::splat(-3.402823e38F)
  for corner_view in frustum_corners {
    let corner_world = render3d_camera_view_point_to_world(
      camera_transform, corner_view,
    )
    let corner_light = render3d_light_from_world_point(
      corner_world, light_x, light_y, light_z,
    )
    min_light = render3d_vec3_min(min_light, corner_light)
    max_light = render3d_vec3_max(max_light, corner_light)
  }
  let body_diagonal = frustum_corners[0]
    .sub(frustum_corners[6])
    .length_squared()
  let far_plane_diagonal = frustum_corners[4]
    .sub(frustum_corners[6])
    .length_squared()
  let cascade_diameter = @pbr_render.maxf(body_diagonal, far_plane_diagonal)
    .sqrt()
    .ceil()
  let safe_size = if shadow_map_size <= 0 { 1 } else { shadow_map_size }
  let cascade_texel_size = cascade_diameter /
    Float::from_double(safe_size.to_double())
  let safe_texel_size = if cascade_texel_size <= 0.000001F {
    0.000001F
  } else {
    cascade_texel_size
  }
  let near_plane_center = @math.Vec3::new(
    (0.5F * (min_light.x + max_light.x) / safe_texel_size).floor() *
    safe_texel_size,
    (0.5F * (min_light.y + max_light.y) / safe_texel_size).floor() *
    safe_texel_size,
    max_light.z,
  )
  let clip_from_cascade = render3d_directional_clip_from_cascade(
    cascade_diameter,
    min_light.z,
    max_light.z,
  )
  let cascade_from_world = render3d_directional_cascade_from_world(
    light_x, light_y, light_z, near_plane_center,
  )
  let clip_from_world = clip_from_cascade.mul(cascade_from_world)
  let translation = render3d_directional_cascade_world_translation(
    light_x, light_y, light_z, near_plane_center,
  )
  let transform = @transform.Transform::new(
    translation,
    light_transform.rotation,
    @math.Vec3::splat(1.0F),
  )
  Render3dDirectionalCascadePass::{
    transform,
    projection: @pbr_render.render3d_pass_projection(
      clip_from_cascade, clip_from_cascade, 0.0F, far_bound,
    ),
    clip_from_world,
    texel_size: safe_texel_size,
    far_bound,
  }
}

///|
fn render3d_directional_shadow_cascades(
  camera : Camera3dViewPayload,
  pass_lighting : Render3dLightingState,
  shadow_map_size : Int,
) -> Array[Render3dDirectionalCascadePass] {
  let cascades : Array[Render3dDirectionalCascadePass] = []
  let bounds = pass_lighting.directional_cascade_bounds
  let count = if bounds.length() < @pbr_render.MAX_CASCADES_PER_LIGHT {
    bounds.length()
  } else {
    @pbr_render.MAX_CASCADES_PER_LIGHT
  }
  let overlap_factor = 1.0F -
    pass_lighting.directional_cascade_overlap_proportion
  for i in 0..<count {
    let near_bound = if i == 0 { 0.1F } else { overlap_factor * bounds[i - 1] }
    let far_bound = bounds[i]
    let corners = camera.projection.get_frustum_corners(-near_bound, -far_bound)
    cascades.push(
      render3d_calculate_directional_cascade(
        camera.transform,
        pass_lighting.directional_transform,
        corners,
        far_bound,
        shadow_map_size,
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
fn render3d_directional_shadow_mesh_visible(
  cascade : Render3dDirectionalCascadePass,
  mesh : Mesh3dExtractedPayload,
) -> Bool {
  if mesh.has_no_frustum_culling {
    return true
  }
  let center = match mesh.aabb_center_world {
    Some(value) => value
    None => mesh.transform.translation
  }
  match cascade.clip_from_world.project_point3(center) {
    Some(ndc) =>
      ndc.x >= -1.05F &&
      ndc.x <= 1.05F &&
      ndc.y >= -1.05F &&
      ndc.y <= 1.05F &&
      ndc.z >= -0.05F &&
      ndc.z <= 1.05F
    None => false
  }
}

///|
fn render3d_execute_camera_directional_shadow_pass(
  world : @ecs.World,
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  pass_lighting : Render3dLightingState,
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  opaque_alpha_draw_item_indices : Array[Int],
  indexed_indirect_parameter_indices : Array[Int],
  non_indexed_indirect_parameter_indices : Array[Int],
  shadow_pass_kind : Int,
) -> Render3dDirectionalShadowBinding {
  if !pass_lighting.directional_shadow_maps_enabled ||
    pass_lighting.directional_entity is None {
    return render3d_directional_shadow_binding_none()
  }
  let shadow_map_size = match
    (try! world.get_resource(@light.ecs_key_directional_light_shadow_map)) {
    Some(v) => if v.size <= 0 { 1 } else { v.size }
    None => @light.DirectionalLightShadowMap::default().size
  }
  let cascades = render3d_directional_shadow_cascades(
    camera, pass_lighting, shadow_map_size,
  )
  if cascades.length() == 0 {
    return render3d_directional_shadow_binding_none()
  }
  guard pass_lighting.directional_entity is Some(light_entity) else {
    return render3d_directional_shadow_binding_none()
  }
  let target_id = render3d_directional_light_shadow_target_get_or_create(
    world,
    light_entity,
    camera_entity,
    shadow_map_size,
    cascades.length(),
  )
  let draw_items = draw_queue_entry.draw_items
  ignore(opaque_alpha_draw_item_indices)
  let shadow_phase_items = render3d_queue_shadow_phase_items(draw_items, meshes)
  ignore(indexed_indirect_parameter_indices)
  ignore(non_indexed_indirect_parameter_indices)
  for cascade_index in 0..<cascades.length() {
    let cascade = cascades[cascade_index]
    let cascade_phase_items : Array[ShadowPhaseItem3d] = []
    for shadow_phase_item in shadow_phase_items {
      let shadow_mesh = meshes[shadow_phase_item.extracted_index].payload
      if render3d_directional_shadow_mesh_visible(cascade, shadow_mesh) {
        cascade_phase_items.push(shadow_phase_item)
      }
    }
    let shadow_view = Render3dShadowView::{
      target_id,
      target_layer: cascade_index,
      width: shadow_map_size,
      height: shadow_map_size,
      transform: cascade.transform,
      projection: cascade.projection,
      clip_from_world: Some(cascade.clip_from_world),
      light_entity: Render3dLightEntity::Directional(
        light_entity~,
        cascade_index~,
      ),
      pass_name: "shadow_directional_light_cascade",
    }
    render3d_execute_shadow_phase_view(
      camera_entity,
      pass_lighting,
      shadow_pass_kind,
      0.1F,
      meshes,
      { shadow_view, items: cascade_phase_items },
    )
  }
  {
    texture_id: target_id,
    enabled: 1.0F,
    cascade_data: render3d_directional_shadow_cascade_data(cascades),
    cascade_count: cascades.length(),
  }
}

///|
priv struct DirectionalLightShadowTargetsEntry {
  light_entity : @core.Entity
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
impl @app.Resource for Render3dDirectionalLightShadowTargets with resource() {
  render3d_directional_light_shadow_targets_key
}

///|
fn render3d_directional_light_shadow_targets_ref_or_init(
  world : @ecs.World,
) -> Ref[Render3dDirectionalLightShadowTargets] {
  if (try! world.get_resource(Render3dDirectionalLightShadowTargets::resource()))
    is None {
    world.insert_resource(Render3dDirectionalLightShadowTargets::resource(), {
      entries: [],
    })
  }
  match
    (try! world.get_resource_mut(
      Render3dDirectionalLightShadowTargets::resource(),
    )) {
    Some(state) => Ref::new(state.peek())
    None => abort("Missing Render3dDirectionalLightShadowTargets resource")
  }
}

///|
fn render3d_directional_light_shadow_target_get_or_create(
  world : @ecs.World,
  light_entity : @core.Entity,
  camera_entity : @core.Entity,
  size : Int,
  layers : Int,
) -> Int {
  let shadow_targets_ref = render3d_directional_light_shadow_targets_ref_or_init(
    world,
  )
  let shadow_targets = shadow_targets_ref.val.entries
  let safe_size = if size <= 0 { 1 } else { size }
  let safe_layers = if layers <= 0 { 1 } else { layers }
  for item in shadow_targets {
    if item.light_entity.id == light_entity.id &&
      item.light_entity.generation == light_entity.generation &&
      item.camera_entity.id == camera_entity.id &&
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
    if item.light_entity.id == light_entity.id &&
      item.light_entity.generation == light_entity.generation &&
      item.camera_entity.id == camera_entity.id &&
      item.camera_entity.generation == camera_entity.generation {
      if !replaced {
        next.push({
          light_entity,
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
    next.push({
      light_entity,
      camera_entity,
      size: safe_size,
      layers: safe_layers,
      target_id,
    })
  }
  shadow_targets_ref.val.entries = next
  target_id
}
