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

// Bevy keeps extracted item identity, render phase ordering, and raw GPU draw
// payload in distinct layers. Keep the same split here instead of collapsing
// everything into ad-hoc `*Instance` records.

///|
priv struct PhaseEntityRef3d {
  render_entity : @core.Entity
  main_entity : @core.Entity
}

///|
fn phase_entity_ref3d_for_main(main_entity : @core.Entity) -> PhaseEntityRef3d {
  PhaseEntityRef3d::{ render_entity: main_entity, main_entity }
}

///|
fn phase_entity_ref3d_cmp(
  lhs : PhaseEntityRef3d,
  rhs : PhaseEntityRef3d,
) -> Int {
  let render_id = cmp_int(lhs.render_entity.id, rhs.render_entity.id)
  if render_id != 0 {
    return render_id
  }
  let render_generation = cmp_int(
    lhs.render_entity.generation,
    rhs.render_entity.generation,
  )
  if render_generation != 0 {
    return render_generation
  }
  let main_id = cmp_int(lhs.main_entity.id, rhs.main_entity.id)
  if main_id != 0 {
    return main_id
  }
  cmp_int(lhs.main_entity.generation, rhs.main_entity.generation)
}

///|
priv struct Camera3dViewPayload {
  camera3d : Camera3d
  camera : @sprite.Camera
  projection : Projection
  sub_camera_view : SubCameraView3d?
  oit_settings : OrderIndependentTransparencySettings?
  screen_space_transmission : ScreenSpaceTransmission?
  bloom : Bloom?
  tonemapping : Tonemapping?
  deband_dither : DebandDither?
  chromatic_aberration : ChromaticAberration?
  custom_post_process3d : CustomPostProcess3d?
  vignette : Vignette?
  motion_blur : MotionBlur?
  exposure : Exposure?
  color_grading : ColorGrading?
  skybox : Skybox?
  depth_prepass_enabled : Bool
  deferred_prepass_enabled : Bool
  no_indirect_drawing : Bool
  gpu_occlusion_culling_enabled : Bool
  hdr_enabled : Bool
  fxaa : Fxaa?
  temporal_jitter : TemporalJitter?
  temporal_anti_aliasing : TemporalAntiAliasing?
  motion_vector_prepass_enabled : Bool
  msaa : Msaa?
  transform : @transform.Transform
  previous_transform : @transform.Transform
  previous_clip_from_world : ProjectionMatrix3d?
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
  layers : @sprite.RenderLayers
}

///|
priv struct ExtractedCamera3d {
  entity : PhaseEntityRef3d
  payload : Camera3dViewPayload
}

///|
priv struct Mesh3dExtractedPayload {
  mesh_handle : @asset.Handle[@mesh.Mesh]
  mesh_id : Int
  transform : @transform.Transform
  previous_transform : @transform.Transform
  visibility_range : @visibility.VisibilityRange?
  aabb_center_world : @math.Vec3?
  material : StandardMaterial
  material_extension : ExtendedMaterialMetadata3d?
  lightmap : Lightmap?
  is_forward_decal : Bool
  forward_decal_material_ext : ForwardDecalMaterialExt?
  clustered_decal : ClusteredDecal?
  has_not_shadow_caster : Bool
  has_not_shadow_receiver : Bool
  has_transmitted_shadow_receiver : Bool
  layers : @sprite.RenderLayers
  has_wireframe : Bool
  has_no_wireframe : Bool
  wireframe_color : WireframeColor?
  skinning_matrices : Array[Float]?
}

///|
priv struct ExtractedMesh3d {
  entity : PhaseEntityRef3d
  payload : Mesh3dExtractedPayload
}

///|
const RENDER3D_PHASE_OPAQUE : Int = 0

///|
const RENDER3D_PHASE_ALPHA_MASK : Int = 1

///|
const RENDER3D_PHASE_TRANSPARENT : Int = 2

///|
priv struct CameraPhaseItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  order : Int
}

///|
priv struct MeshPhaseItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  phase : Int
  distance : Float
}

///|
const MESH3D_DRAW_INDIRECT_KIND_NONE : Int = 0

///|
const MESH3D_DRAW_INDIRECT_KIND_INDEXED : Int = 1

///|
const MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED : Int = 2

///|
priv struct MeshGpuDrawPayload3d {
  mesh_id : Int
  preprocess_camera_key_hi : Int
  preprocess_camera_key_lo : Int
  draw_storage_index : Int
  indirect_kind : Int
  indirect_parameters_index : Int
  transform : @transform.Transform
  previous_transform : @transform.Transform
  color_r : Float
  color_g : Float
  color_b : Float
  color_a : Float
  texture_id : Int
  uv_transform : @transform.Affine2
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  emissive : @sprite.Color
  metallic : Float
  anisotropy_texture_id : Int
  anisotropy_rotation : Float
  specular_tint_texture_id : Int
  parallax_depth_scale : Float
  max_parallax_layer_count : Float
  surface_roughness : Float
  reflectance : Float
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  alpha_cutoff : Float
  material_flags : UInt
  transmission_source_texture_id : Int
  transmission_blur_taps : Float
  transmission_steps : Float
  point_shadow_texture_id : Int
  point_shadow_enabled : Float
  point_shadow_depth_bias : Float
  specular_tint : @sprite.Color
  anisotropy_strength : Float
  max_relief_mapping_search_steps : Float
  cull_mode : Int
  shader_path : String?
  skinning_matrices : Array[Float]?
}

///|
priv struct TransmissivePhaseItem3d {
  entity : PhaseEntityRef3d
  distance : Float
  payload : MeshGpuDrawPayload3d
}

///|
fn render3d_sort_transmissive_phase_items(
  items : Array[TransmissivePhaseItem3d],
) -> Array[TransmissivePhaseItem3d] {
  items.sort_by(fn(a, b) {
    let distance_cmp = cmp_float(b.distance, a.distance)
    if distance_cmp != 0 {
      return distance_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}
