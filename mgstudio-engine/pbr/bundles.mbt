// Copyright 2025 International Digital Economy Academy
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
pub struct Camera3dBundle {
  camera : @sprite.Camera
  projection : Projection
  sub_camera_view : SubCameraView3d?
  screen_space_transmission : ScreenSpaceTransmission?
  screen_space_reflections : ScreenSpaceReflections?
  bloom : Bloom?
  tonemapping : Tonemapping?
  deband_dither : DebandDither?
  chromatic_aberration : ChromaticAberration?
  custom_post_process3d : CustomPostProcess3d?
  vignette : Vignette?
  motion_blur : MotionBlur?
  exposure : Exposure?
  color_grading : ColorGrading?
  camera3d : Camera3d
  decal_config : CameraDecalConfig3d?
  deferred_config : CameraDeferredConfig3d?
  distance_fog : DistanceFog?
  auto_exposure : AutoExposure?
  depth_of_field : DepthOfField?
  volumetric_fog : VolumetricFog?
  atmosphere : Atmosphere?
  atmosphere_settings : AtmosphereSettings?
  transform : @transform.Transform
  target : @sprite.RenderTarget
  layers : @sprite.RenderLayers
}

///|
pub fn Camera3dBundle::new(
  camera : @sprite.Camera,
  transform : @transform.Transform,
) -> Camera3dBundle {
  Camera3dBundle::{
    camera,
    projection: Projection::default(),
    sub_camera_view: None,
    screen_space_transmission: None,
    screen_space_reflections: None,
    bloom: None,
    tonemapping: Some(Tonemapping::default()),
    deband_dither: Some(Enabled),
    chromatic_aberration: None,
    custom_post_process3d: None,
    vignette: None,
    motion_blur: None,
    exposure: Some(Exposure::default()),
    color_grading: None,
    camera3d: Camera3d::default(),
    decal_config: None,
    deferred_config: None,
    distance_fog: None,
    auto_exposure: None,
    depth_of_field: None,
    volumetric_fog: None,
    atmosphere: None,
    atmosphere_settings: None,
    transform,
    target: @sprite.RenderTarget::Screen,
    layers: @sprite.RenderLayers::default(),
  }
}

///|
pub fn Camera3dBundle::new_with_projection(
  camera : @sprite.Camera,
  projection : Projection,
  transform : @transform.Transform,
) -> Camera3dBundle {
  Camera3dBundle::{
    camera,
    projection,
    sub_camera_view: None,
    screen_space_transmission: None,
    screen_space_reflections: None,
    bloom: None,
    tonemapping: Some(Tonemapping::default()),
    deband_dither: Some(Enabled),
    chromatic_aberration: None,
    custom_post_process3d: None,
    vignette: None,
    motion_blur: None,
    exposure: Some(Exposure::default()),
    color_grading: None,
    camera3d: Camera3d::default(),
    decal_config: None,
    deferred_config: None,
    distance_fog: None,
    auto_exposure: None,
    depth_of_field: None,
    volumetric_fog: None,
    atmosphere: None,
    atmosphere_settings: None,
    transform,
    target: @sprite.RenderTarget::Screen,
    layers: @sprite.RenderLayers::default(),
  }
}

///|
pub fn Camera3dBundle::with_sub_camera_view(
  self : Camera3dBundle,
  sub_camera_view : SubCameraView3d?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, sub_camera_view, }
}

///|
pub fn Camera3dBundle::with_target(
  self : Camera3dBundle,
  target : @sprite.RenderTarget,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, target, }
}

///|
pub fn Camera3dBundle::with_screen_space_transmission(
  self : Camera3dBundle,
  screen_space_transmission : ScreenSpaceTransmission?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, screen_space_transmission, }
}

///|
pub fn Camera3dBundle::with_screen_space_reflections(
  self : Camera3dBundle,
  screen_space_reflections : ScreenSpaceReflections?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, screen_space_reflections, }
}

///|
pub fn Camera3dBundle::with_bloom(
  self : Camera3dBundle,
  bloom : Bloom?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, bloom, }
}

///|
pub fn Camera3dBundle::with_tonemapping(
  self : Camera3dBundle,
  tonemapping : Tonemapping?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, tonemapping, }
}

///|
pub fn Camera3dBundle::with_deband_dither(
  self : Camera3dBundle,
  deband_dither : DebandDither?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, deband_dither, }
}

///|
pub fn Camera3dBundle::with_chromatic_aberration(
  self : Camera3dBundle,
  chromatic_aberration : ChromaticAberration?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, chromatic_aberration, }
}

///|
pub fn Camera3dBundle::with_custom_post_process3d(
  self : Camera3dBundle,
  custom_post_process3d : CustomPostProcess3d?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, custom_post_process3d, }
}

///|
pub fn Camera3dBundle::with_vignette(
  self : Camera3dBundle,
  vignette : Vignette?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, vignette, }
}

///|
pub fn Camera3dBundle::with_motion_blur(
  self : Camera3dBundle,
  motion_blur : MotionBlur?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, motion_blur, }
}

///|
pub fn Camera3dBundle::with_exposure(
  self : Camera3dBundle,
  exposure : Exposure?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, exposure, }
}

///|
pub fn Camera3dBundle::with_color_grading(
  self : Camera3dBundle,
  color_grading : ColorGrading?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, color_grading, }
}

///|
pub fn Camera3dBundle::with_camera3d(
  self : Camera3dBundle,
  camera3d : Camera3d,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, camera3d, }
}

///|
pub fn Camera3dBundle::with_decal_config(
  self : Camera3dBundle,
  decal_config : CameraDecalConfig3d,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, decal_config: Some(decal_config) }
}

///|
pub fn Camera3dBundle::with_deferred_config(
  self : Camera3dBundle,
  deferred_config : CameraDeferredConfig3d,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, deferred_config: Some(deferred_config) }
}

///|
pub fn Camera3dBundle::with_distance_fog(
  self : Camera3dBundle,
  distance_fog : DistanceFog?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, distance_fog, }
}

///|
pub fn Camera3dBundle::with_volumetric_fog(
  self : Camera3dBundle,
  volumetric_fog : VolumetricFog?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, volumetric_fog, }
}

///|
pub fn Camera3dBundle::with_atmosphere(
  self : Camera3dBundle,
  atmosphere : Atmosphere?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, atmosphere, }
}

///|
pub fn Camera3dBundle::with_atmosphere_settings(
  self : Camera3dBundle,
  atmosphere_settings : AtmosphereSettings?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, atmosphere_settings, }
}

///|
pub fn Camera3dBundle::with_auto_exposure(
  self : Camera3dBundle,
  auto_exposure : AutoExposure?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, auto_exposure, }
}

///|
pub fn Camera3dBundle::with_depth_of_field(
  self : Camera3dBundle,
  depth_of_field : DepthOfField?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, depth_of_field, }
}

///|
pub struct MeshMaterial3dBundle {
  mesh : Mesh3d
  material : MeshMaterial3d
  transform : @transform.Transform
  layers : @sprite.RenderLayers
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn MeshMaterial3dBundle::new(
  mesh : Mesh3d,
  material : MeshMaterial3d,
  transform : @transform.Transform,
) -> MeshMaterial3dBundle {
  MeshMaterial3dBundle::{
    mesh,
    material,
    transform,
    layers: @sprite.RenderLayers::default(),
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
fn camera3d_bundle_insert(
  bundle : Camera3dBundle,
  world : @ecs.World,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit raise @ecs.EcsError {
  world.set_by_key(entity, ecs_key_camera3d, bundle.camera3d, loc~)
  if bundle.decal_config is Some(decal_config) {
    world.set_by_key(entity, ecs_key_camera_decal_config3d, decal_config, loc~)
  }
  if bundle.deferred_config is Some(deferred_config) {
    world.set_by_key(
      entity,
      ecs_key_camera_deferred_config3d,
      deferred_config,
      loc~,
    )
  }
  if bundle.distance_fog is Some(distance_fog) {
    world.set_by_key(entity, ecs_key_distance_fog, distance_fog, loc~)
  }
  if bundle.auto_exposure is Some(auto_exposure) {
    world.set_by_key(entity, ecs_key_auto_exposure, auto_exposure, loc~)
  }
  if bundle.depth_of_field is Some(depth_of_field) {
    world.set_by_key(entity, ecs_key_depth_of_field, depth_of_field, loc~)
  }
  if bundle.volumetric_fog is Some(volumetric_fog) {
    world.set_by_key(entity, ecs_key_volumetric_fog, volumetric_fog, loc~)
  }
  if bundle.atmosphere is Some(atmosphere) {
    world.set_by_key(entity, ecs_key_atmosphere, atmosphere, loc~)
  }
  if bundle.atmosphere_settings is Some(atmosphere_settings) {
    world.set_by_key(
      entity,
      ecs_key_atmosphere_settings,
      atmosphere_settings,
      loc~,
    )
  }
  world.set_by_key(entity, ecs_key_projection, bundle.projection, loc~)
  if bundle.sub_camera_view is Some(sub_camera_view) {
    world.set_by_key(entity, ecs_key_sub_camera_view3d, sub_camera_view, loc~)
  }
  if bundle.screen_space_transmission is Some(screen_space_transmission) {
    world.set_by_key(
      entity,
      ecs_key_screen_space_transmission,
      screen_space_transmission,
      loc~,
    )
  }
  if bundle.screen_space_reflections is Some(screen_space_reflections) {
    world.set_by_key(
      entity,
      ecs_key_screen_space_reflections,
      screen_space_reflections,
      loc~,
    )
  }
  if bundle.bloom is Some(bloom) {
    world.set_by_key(entity, ecs_key_bloom, bloom, loc~)
  }
  if bundle.tonemapping is Some(tonemapping) {
    world.set_by_key(entity, ecs_key_tonemapping, tonemapping, loc~)
  }
  if bundle.deband_dither is Some(deband_dither) {
    world.set_by_key(entity, ecs_key_deband_dither, deband_dither, loc~)
  }
  if bundle.chromatic_aberration is Some(chromatic_aberration) {
    world.set_by_key(
      entity,
      ecs_key_chromatic_aberration,
      chromatic_aberration,
      loc~,
    )
  }
  if bundle.custom_post_process3d is Some(custom_post_process3d) {
    world.set_by_key(
      entity,
      ecs_key_custom_post_process3d,
      custom_post_process3d,
      loc~,
    )
  }
  if bundle.vignette is Some(vignette) {
    world.set_by_key(entity, ecs_key_vignette, vignette, loc~)
  }
  if bundle.motion_blur is Some(motion_blur) {
    world.set_by_key(entity, ecs_key_motion_blur, motion_blur, loc~)
  }
  if bundle.exposure is Some(exposure) {
    world.set_by_key(entity, ecs_key_exposure, exposure, loc~)
  }
  if bundle.color_grading is Some(color_grading) {
    world.set_by_key(entity, ecs_key_color_grading, color_grading, loc~)
  }
  world.set_by_key(entity, @sprite.ecs_key_camera, bundle.camera, loc~)
  world.set_by_key(entity, @sprite.ecs_key_render_target, bundle.target, loc~)
  world.set_by_key(entity, @sprite.ecs_key_render_layers, bundle.layers, loc~)
  world.set_by_key(
    entity,
    ecs_key_frustum,
    bundle.projection.compute_frustum(bundle.transform),
    loc~,
  )
  world.set_by_key(entity, @transform.ecs_key_transform, bundle.transform, loc~)
}

///|
pub impl @app.CommandSpawnComponents for Camera3dBundle with spawn_components(
  self,
  world,
  entity,
  sequence,
  loc~,
) {
  ignore(sequence)
  camera3d_bundle_insert(self, world, entity, loc~)
}

///|
pub impl @ecs.Bundle for Camera3dBundle with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  camera3d_bundle_insert(self, world, entity, loc~)
}

///|
#callsite(autofill(loc))
pub fn Camera3dBundle::spawn(
  self : Camera3dBundle,
  world : @ecs.World,
  loc~ : SourceLoc,
) -> @core.Entity {
  try! world.spawn_bundle(self, loc~)
}

///|
pub fn register_render3d_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_mesh3d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_mesh3d,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_camera3d,
    @sprite.ecs_key_camera,
    fn() { @sprite.Camera::default() },
  )
  world.register_required_components_with(
    ecs_key_camera3d,
    ecs_key_projection,
    fn() { Projection::default() },
  )
  world.register_required_components_with(
    ecs_key_camera3d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_camera3d,
    @sprite.ecs_key_render_target,
    fn() { @sprite.RenderTarget::Screen },
  )
  world.register_required_components_with(
    ecs_key_camera3d,
    @sprite.ecs_key_render_layers,
    fn() { @sprite.RenderLayers::default() },
  )
  world.register_required_components_with(
    ecs_key_camera3d,
    ecs_key_tonemapping,
    fn() { Tonemapping::default() },
  )
  world.register_required_components_with(ecs_key_camera3d, ecs_key_hdr, fn() {
    Hdr::default()
  })
  world.register_required_components_with(
    ecs_key_camera3d,
    ecs_key_deband_dither,
    fn() { DebandDither::Enabled },
  )
  world.register_required_components_with(ecs_key_camera3d, ecs_key_exposure, fn() {
    Exposure::default()
  })
  world.register_required_components_with(ecs_key_camera3d, ecs_key_frustum, fn() {
    Projection::default().compute_frustum(@transform.Transform::identity())
  })
}

///|
fn mesh_material3d_bundle_insert(
  bundle : MeshMaterial3dBundle,
  world : @ecs.World,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit raise @ecs.EcsError {
  world.set_by_key(entity, ecs_key_mesh3d, bundle.mesh, loc~)
  world.set_by_key(entity, ecs_key_mesh_material3d, bundle.material, loc~)
  world.set_by_key(entity, @sprite.ecs_key_render_layers, bundle.layers, loc~)
  world.set_by_key(
    entity,
    @visibility.ecs_key_visibility,
    bundle.visibility,
    loc~,
  )
  world.set_by_key(
    entity,
    @visibility.ecs_key_inherited_visibility,
    bundle.inherited_visibility,
    loc~,
  )
  world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    bundle.view_visibility,
    loc~,
  )
  world.set_by_key(entity, @transform.ecs_key_transform, bundle.transform, loc~)
}

///|
pub impl @app.CommandSpawnComponents for MeshMaterial3dBundle with spawn_components(
  self,
  world,
  entity,
  sequence,
  loc~,
) {
  ignore(sequence)
  mesh_material3d_bundle_insert(self, world, entity, loc~)
}

///|
pub impl @ecs.Bundle for MeshMaterial3dBundle with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  mesh_material3d_bundle_insert(self, world, entity, loc~)
}

///|
#callsite(autofill(loc))
pub fn MeshMaterial3dBundle::spawn(
  self : MeshMaterial3dBundle,
  world : @ecs.World,
  loc~ : SourceLoc,
) -> @core.Entity {
  try! world.spawn_bundle(self, loc~)
}
