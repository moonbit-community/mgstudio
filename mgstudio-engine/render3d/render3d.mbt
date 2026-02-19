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
/// Marker component aligned with Bevy's `Camera3d`.
#ecs.component
pub struct Camera3d {}

///|
pub fn Camera3d::default() -> Camera3d {
  Camera3d::{  }
}

///|
pub struct PerspectiveProjection3d {
  fov : Float
  near : Float
  far : Float
  aspect_ratio : Float
}

///|
pub fn PerspectiveProjection3d::default() -> PerspectiveProjection3d {
  PerspectiveProjection3d::{
    fov: @math.pi_half(),
    near: 0.1F,
    far: 1000.0F,
    aspect_ratio: 16.0F / 9.0F,
  }
}

///|
pub fn PerspectiveProjection3d::with_aspect_ratio(
  self : PerspectiveProjection3d,
  aspect_ratio : Float,
) -> PerspectiveProjection3d {
  let safe_aspect = if aspect_ratio <= 0.0F { 1.0F } else { aspect_ratio }
  PerspectiveProjection3d::{
    fov: self.fov,
    near: self.near,
    far: self.far,
    aspect_ratio: safe_aspect,
  }
}

///|
pub fn PerspectiveProjection3d::with_fov(
  self : PerspectiveProjection3d,
  fov : Float,
) -> PerspectiveProjection3d {
  let safe_fov = if fov <= 0.0F { @math.pi_half() } else { fov }
  PerspectiveProjection3d::{
    fov: safe_fov,
    near: self.near,
    far: self.far,
    aspect_ratio: self.aspect_ratio,
  }
}

///|
pub fn PerspectiveProjection3d::with_near(
  self : PerspectiveProjection3d,
  near : Float,
) -> PerspectiveProjection3d {
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  let safe_far = if self.far <= safe_near {
    safe_near + 0.0001F
  } else {
    self.far
  }
  PerspectiveProjection3d::{
    fov: self.fov,
    near: safe_near,
    far: safe_far,
    aspect_ratio: self.aspect_ratio,
  }
}

///|
pub fn PerspectiveProjection3d::with_far(
  self : PerspectiveProjection3d,
  far : Float,
) -> PerspectiveProjection3d {
  let safe_far = if far <= self.near { self.near + 0.0001F } else { far }
  PerspectiveProjection3d::{
    fov: self.fov,
    near: self.near,
    far: safe_far,
    aspect_ratio: self.aspect_ratio,
  }
}

///|
pub struct OrthographicProjection3d {
  scale : Float
  near : Float
  far : Float
}

///|
pub fn OrthographicProjection3d::default() -> OrthographicProjection3d {
  OrthographicProjection3d::{ scale: 1.0F, near: -1000.0F, far: 1000.0F }
}

///|
pub fn OrthographicProjection3d::with_scale(
  self : OrthographicProjection3d,
  scale : Float,
) -> OrthographicProjection3d {
  let safe_scale = if scale <= 0.0F { 1.0F } else { scale }
  OrthographicProjection3d::{
    scale: safe_scale,
    near: self.near,
    far: self.far,
  }
}

///|
pub(all) enum Projection3d {
  Perspective(PerspectiveProjection3d)
  Orthographic(OrthographicProjection3d)
}

///|
pub fn Projection3d::perspective_default() -> Projection3d {
  Perspective(PerspectiveProjection3d::default())
}

///|
pub fn Projection3d::orthographic_default() -> Projection3d {
  Orthographic(OrthographicProjection3d::default())
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct CameraProjection3d {
  projection : Projection3d
}

///|
pub fn CameraProjection3d::default() -> CameraProjection3d {
  CameraProjection3d::{ projection: Projection3d::perspective_default() }
}

///|
pub fn CameraProjection3d::new(projection : Projection3d) -> CameraProjection3d {
  CameraProjection3d::{ projection, }
}

///|
pub fn CameraProjection3d::with_projection(
  self : CameraProjection3d,
  projection : Projection3d,
) -> CameraProjection3d {
  self |> ignore
  CameraProjection3d::{ projection, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct SubCameraView3d {
  full_size : @math.IVec2
  offset : @math.Vec2
  size : @math.IVec2
}

///|
fn sub_camera_view3d_sanitize(
  full_size : @math.IVec2,
  offset : @math.Vec2,
  size : @math.IVec2,
) -> SubCameraView3d {
  let safe_full_width = if full_size.x <= 0 { 1 } else { full_size.x }
  let safe_full_height = if full_size.y <= 0 { 1 } else { full_size.y }
  let safe_size_width = if size.x <= 0 { 1 } else { size.x }
  let safe_size_height = if size.y <= 0 { 1 } else { size.y }
  SubCameraView3d::{
    full_size: @math.IVec2::new(safe_full_width, safe_full_height),
    offset,
    size: @math.IVec2::new(safe_size_width, safe_size_height),
  }
}

///|
pub fn SubCameraView3d::new(
  full_size : @math.IVec2,
  offset : @math.Vec2,
  size : @math.IVec2,
) -> SubCameraView3d {
  sub_camera_view3d_sanitize(full_size, offset, size)
}

///|
pub fn SubCameraView3d::with_offset(
  self : SubCameraView3d,
  offset : @math.Vec2,
) -> SubCameraView3d {
  sub_camera_view3d_sanitize(self.full_size, offset, self.size)
}

///|
const FREE_CAMERA_RADIANS_PER_DOT : Float = 0.005555555555555556F

///|
/// A freecam-style controller configuration aligned with Bevy's `FreeCamera`.
#ecs.component
pub struct FreeCamera {
  sensitivity : Float
  key_forward : @window.KeyCode
  key_back : @window.KeyCode
  key_left : @window.KeyCode
  key_right : @window.KeyCode
  key_up : @window.KeyCode
  key_down : @window.KeyCode
  key_run : @window.KeyCode
  mouse_key_cursor_grab : @window.MouseButton
  keyboard_key_toggle_cursor_grab : @window.KeyCode
  walk_speed : Float
  run_speed : Float
  scroll_factor : Float
  friction : Float
}

///|
pub fn FreeCamera::default() -> FreeCamera {
  FreeCamera::{
    sensitivity: 0.2F,
    key_forward: @window.KeyCode::KeyW,
    key_back: @window.KeyCode::KeyS,
    key_left: @window.KeyCode::KeyA,
    key_right: @window.KeyCode::KeyD,
    key_up: @window.KeyCode::KeyE,
    key_down: @window.KeyCode::KeyQ,
    key_run: @window.KeyCode::ShiftLeft,
    mouse_key_cursor_grab: @window.MouseButton::Left,
    keyboard_key_toggle_cursor_grab: @window.KeyCode::KeyM,
    walk_speed: 5.0F,
    run_speed: 15.0F,
    scroll_factor: 0.5F,
    friction: 40.0F,
  }
}

///|
/// Runtime state for `FreeCamera`.
#ecs.component
pub struct FreeCameraState {
  enabled : Bool
  initialized : Bool
  pitch : Float
  yaw : Float
  speed_multiplier : Float
  velocity : @math.Vec3
}

///|
pub fn FreeCameraState::default() -> FreeCameraState {
  FreeCameraState::{
    enabled: true,
    initialized: false,
    pitch: 0.0F,
    yaw: 0.0F,
    speed_multiplier: 1.0F,
    velocity: @math.Vec3::zero(),
  }
}

///|
priv struct FreeCameraSystemState {
  toggle_cursor_grab : Bool
  mouse_cursor_grab : Bool
  last_mouse_position : @math.Vec2?
}

///|
let free_camera_system_state : Ref[FreeCameraSystemState] = Ref::new(FreeCameraSystemState::{
  toggle_cursor_grab: false,
  mouse_cursor_grab: false,
  last_mouse_position: None,
})

///|
/// Camera post-process settings aligned with Bevy's `ChromaticAberration`.
///
/// This renderer currently applies a lightweight per-object approximation in
/// the draw phase instead of a full-screen post-process pass.
#ecs.component
pub struct ChromaticAberration {
  intensity : Float
  max_samples : Int
}

///|
pub fn ChromaticAberration::default() -> ChromaticAberration {
  ChromaticAberration::{ intensity: 0.02F, max_samples: 8 }
}

///|
pub fn ChromaticAberration::new(
  intensity : Float,
  max_samples : Int,
) -> ChromaticAberration {
  let safe_intensity = if intensity < 0.0F { 0.0F } else { intensity }
  let safe_max_samples = if max_samples <= 0 { 1 } else { max_samples }
  ChromaticAberration::{
    intensity: safe_intensity,
    max_samples: safe_max_samples,
  }
}

///|
pub fn ChromaticAberration::with_intensity(
  self : ChromaticAberration,
  intensity : Float,
) -> ChromaticAberration {
  ChromaticAberration::new(intensity, self.max_samples)
}

///|
pub fn ChromaticAberration::with_max_samples(
  self : ChromaticAberration,
  max_samples : Int,
) -> ChromaticAberration {
  ChromaticAberration::new(self.intensity, max_samples)
}

///|
/// Camera post-process settings aligned with Bevy's `Vignette`.
///
/// This renderer currently applies a lightweight per-object approximation in
/// the draw phase instead of a full-screen post-process pass.
#ecs.component
pub struct Vignette {
  intensity : Float
  radius : Float
  smoothness : Float
  roundness : Float
  center : @math.Vec2
  edge_compensation : Float
  color : @render2d.Color
}

///|
pub fn Vignette::default() -> Vignette {
  Vignette::{
    intensity: 1.0F,
    radius: 0.75F,
    smoothness: 5.0F,
    roundness: 1.0F,
    center: @math.Vec2::new(0.5F, 0.5F),
    edge_compensation: 1.0F,
    color: @render2d.Color::black(),
  }
}

///|
pub fn Vignette::new(
  intensity : Float,
  radius : Float,
  smoothness : Float,
  roundness : Float,
) -> Vignette {
  let safe_intensity = if intensity < 0.0F { 0.0F } else { intensity }
  let safe_radius = if radius < 0.0F { 0.0F } else { radius }
  let safe_smoothness = if smoothness <= 0.01F { 0.01F } else { smoothness }
  let safe_roundness = if roundness <= 0.01F { 0.01F } else { roundness }
  Vignette::{
    ..Vignette::default(),
    intensity: safe_intensity,
    radius: safe_radius,
    smoothness: safe_smoothness,
    roundness: safe_roundness,
  }
}

///|
pub fn Vignette::with_intensity(self : Vignette, intensity : Float) -> Vignette {
  Vignette::{
    ..self,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn Vignette::with_radius(self : Vignette, radius : Float) -> Vignette {
  Vignette::{ ..self, radius: if radius < 0.0F { 0.0F } else { radius } }
}

///|
pub fn Vignette::with_smoothness(
  self : Vignette,
  smoothness : Float,
) -> Vignette {
  Vignette::{
    ..self,
    smoothness: if smoothness <= 0.01F {
      0.01F
    } else {
      smoothness
    },
  }
}

///|
pub fn Vignette::with_roundness(self : Vignette, roundness : Float) -> Vignette {
  Vignette::{
    ..self,
    roundness: if roundness <= 0.01F {
      0.01F
    } else {
      roundness
    },
  }
}

///|
pub fn Vignette::with_center(self : Vignette, center : @math.Vec2) -> Vignette {
  Vignette::{ ..self, center, }
}

///|
pub fn Vignette::with_edge_compensation(
  self : Vignette,
  edge_compensation : Float,
) -> Vignette {
  let safe = if edge_compensation < 0.0F {
    0.0F
  } else if edge_compensation > 1.0F {
    1.0F
  } else {
    edge_compensation
  }
  Vignette::{ ..self, edge_compensation: safe }
}

///|
pub fn Vignette::with_color(
  self : Vignette,
  color : @render2d.Color,
) -> Vignette {
  Vignette::{ ..self, color, }
}

///|
/// Camera post-process settings aligned with Bevy's `MotionBlur`.
///
/// This renderer currently applies a lightweight per-object approximation in
/// the draw phase instead of Bevy's full-screen motion vector pipeline.
#ecs.component
pub struct MotionBlur {
  shutter_angle : Float
  samples : Int
}

///|
pub fn MotionBlur::default() -> MotionBlur {
  MotionBlur::{ shutter_angle: 1.0F, samples: 2 }
}

///|
pub fn MotionBlur::new(shutter_angle : Float, samples : Int) -> MotionBlur {
  let safe_shutter_angle = clamp01(shutter_angle)
  let safe_samples = if samples < 0 {
    0
  } else if samples > 64 {
    64
  } else {
    samples
  }
  MotionBlur::{ shutter_angle: safe_shutter_angle, samples: safe_samples }
}

///|
pub fn MotionBlur::with_shutter_angle(
  self : MotionBlur,
  shutter_angle : Float,
) -> MotionBlur {
  MotionBlur::new(shutter_angle, self.samples)
}

///|
pub fn MotionBlur::with_samples(self : MotionBlur, samples : Int) -> MotionBlur {
  MotionBlur::new(self.shutter_angle, samples)
}

///|
/// Camera MSAA mode aligned with Bevy's `Msaa`.
///
/// Current runtime note: this component is API-compatible but acts as a
/// render-path hint on top of the existing antialiasing pipeline.
#ecs.component
pub(all) enum Msaa {
  Off
  Sample2
  Sample4
  Sample8
} derive(Eq, Show)

///|
pub fn Msaa::default() -> Msaa {
  Msaa::Sample4
}

///|
/// Marker component aligned with Bevy's `Fxaa`.
///
/// Current runtime note: this records camera intent as an ECS surface.
#ecs.component
pub struct Fxaa {
  enabled : Bool
}

///|
pub fn Fxaa::default() -> Fxaa {
  Fxaa::{ enabled: true }
}

///|
pub fn Fxaa::new(enabled : Bool) -> Fxaa {
  Fxaa::{ enabled, }
}

///|
pub fn Fxaa::with_enabled(self : Fxaa, enabled : Bool) -> Fxaa {
  self |> ignore
  Fxaa::{ enabled, }
}

///|
/// Marker component aligned with Bevy's `DepthPrepass`.
#ecs.component
pub struct DepthPrepass {}

///|
pub fn DepthPrepass::default() -> DepthPrepass {
  DepthPrepass::{  }
}

///|
/// Marker component aligned with Bevy's `NormalPrepass`.
#ecs.component
pub struct NormalPrepass {}

///|
pub fn NormalPrepass::default() -> NormalPrepass {
  NormalPrepass::{  }
}

///|
/// Marker component aligned with Bevy's `MotionVectorPrepass`.
#ecs.component
pub struct MotionVectorPrepass {}

///|
pub fn MotionVectorPrepass::default() -> MotionVectorPrepass {
  MotionVectorPrepass::{  }
}

///|
/// Marker component aligned with Bevy's `DeferredPrepass`.
#ecs.component
pub struct DeferredPrepass {}

///|
pub fn DeferredPrepass::default() -> DeferredPrepass {
  DeferredPrepass::{  }
}

///|
/// Marker component aligned with Bevy's `OcclusionCulling`.
///
/// Current runtime note: this records per-camera occlusion-culling intent as an
/// ECS surface for parity and migration sequencing.
#ecs.component
pub struct OcclusionCulling {}

///|
pub fn OcclusionCulling::default() -> OcclusionCulling {
  OcclusionCulling::{  }
}

///|
/// Marker component aligned with Bevy's `NotShadowCaster`.
#ecs.component
pub struct NotShadowCaster {}

///|
pub fn NotShadowCaster::default() -> NotShadowCaster {
  NotShadowCaster::{  }
}

///|
/// Marker component aligned with Bevy's `NotShadowReceiver`.
#ecs.component
pub struct NotShadowReceiver {}

///|
pub fn NotShadowReceiver::default() -> NotShadowReceiver {
  NotShadowReceiver::{  }
}

///|
/// Marker component aligned with Bevy's
/// `OrderIndependentTransparencySettings`.
///
/// Current runtime note: this records camera intent as an ECS surface; the
/// renderer-side weighted OIT implementation is tracked separately.
#ecs.component
pub struct OrderIndependentTransparencySettings {}

///|
pub fn OrderIndependentTransparencySettings::default() -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{  }
}

///|
/// Marker component aligned with Bevy's `TemporalAntiAliasing`.
#ecs.component
pub struct TemporalAntiAliasing {}

///|
pub fn TemporalAntiAliasing::default() -> TemporalAntiAliasing {
  TemporalAntiAliasing::{  }
}

///|
/// Camera jitter settings aligned with Bevy's `TemporalJitter`.
#ecs.component
pub struct TemporalJitter {
  offset : @math.Vec2
}

///|
pub fn TemporalJitter::default() -> TemporalJitter {
  TemporalJitter::{ offset: @math.Vec2::new(0.0F, 0.0F) }
}

///|
pub fn TemporalJitter::new(offset : @math.Vec2) -> TemporalJitter {
  TemporalJitter::{ offset, }
}

///|
pub fn TemporalJitter::with_offset(
  self : TemporalJitter,
  offset : @math.Vec2,
) -> TemporalJitter {
  self |> ignore
  TemporalJitter::{ offset, }
}

///|
/// Marker component aligned with Bevy's `Hdr`.
#ecs.component
pub struct Hdr {}

///|
pub fn Hdr::default() -> Hdr {
  Hdr::{  }
}

///|
/// Camera tonemapping mode aligned with Bevy's `Tonemapping`.
#ecs.component
pub(all) enum Tonemapping {
  None
  Reinhard
  ReinhardLuminance
  AcesFitted
  AgX
  SomewhatBoringDisplayTransform
  TonyMcMapface
  BlenderFilmic
} derive(Eq, Show)

///|
pub fn Tonemapping::default() -> Tonemapping {
  Tonemapping::None
}

///|
/// Camera bloom settings aligned with Bevy's `Bloom`.
#ecs.component
pub struct Bloom {
  intensity : Float
}

///|
pub fn Bloom::default() -> Bloom {
  Bloom::{ intensity: 0.15F }
}

///|
pub fn Bloom::new(intensity : Float) -> Bloom {
  Bloom::{ intensity: if intensity < 0.0F { 0.0F } else { intensity } }
}

///|
pub fn Bloom::with_intensity(self : Bloom, intensity : Float) -> Bloom {
  self |> ignore
  Bloom::new(intensity)
}

///|
/// Camera skybox settings aligned with Bevy's `Skybox`.
#ecs.component
pub struct Skybox {
  image : @asset.Handle[@asset.Image]?
  brightness : Float
  rotation : @math.Quat
}

///|
pub fn Skybox::default() -> Skybox {
  Skybox::{ image: None, brightness: 1.0F, rotation: @math.Quat::identity() }
}

///|
pub fn Skybox::new(
  image : @asset.Handle[@asset.Image],
  brightness : Float,
) -> Skybox {
  Skybox::{
    ..Skybox::default(),
    image: Some(image),
    brightness: if brightness < 0.0F {
      0.0F
    } else {
      brightness
    },
  }
}

///|
pub fn Skybox::with_image(
  self : Skybox,
  image : @asset.Handle[@asset.Image]?,
) -> Skybox {
  Skybox::{ ..self, image, }
}

///|
pub fn Skybox::with_brightness(self : Skybox, brightness : Float) -> Skybox {
  Skybox::{
    ..self,
    brightness: if brightness < 0.0F {
      0.0F
    } else {
      brightness
    },
  }
}

///|
pub fn Skybox::with_rotation(self : Skybox, rotation : @math.Quat) -> Skybox {
  Skybox::{ ..self, rotation, }
}

///|
pub(all) enum ScreenSpaceAmbientOcclusionQualityLevel {
  Low
  Medium
  High
  Ultra
} derive(Eq, Show)

///|
pub fn ScreenSpaceAmbientOcclusionQualityLevel::default() -> ScreenSpaceAmbientOcclusionQualityLevel {
  ScreenSpaceAmbientOcclusionQualityLevel::High
}

///|
/// Camera ambient occlusion settings aligned with Bevy's
/// `ScreenSpaceAmbientOcclusion`.
#ecs.component
pub struct ScreenSpaceAmbientOcclusion {
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel
  constant_object_thickness : Float
}

///|
pub fn ScreenSpaceAmbientOcclusion::default() -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion::{
    quality_level: ScreenSpaceAmbientOcclusionQualityLevel::default(),
    constant_object_thickness: 0.25F,
  }
}

///|
pub fn ScreenSpaceAmbientOcclusion::with_quality_level(
  self : ScreenSpaceAmbientOcclusion,
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel,
) -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion::{ ..self, quality_level, }
}

///|
pub fn ScreenSpaceAmbientOcclusion::with_constant_object_thickness(
  self : ScreenSpaceAmbientOcclusion,
  constant_object_thickness : Float,
) -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion::{
    ..self,
    constant_object_thickness: if constant_object_thickness < 0.0F {
      0.0F
    } else {
      constant_object_thickness
    },
  }
}

///|
/// Camera contact shadow settings aligned with Bevy's `ContactShadows`.
#ecs.component
pub struct ContactShadows {
  linear_steps : Int
  thickness : Float
  length : Float
}

///|
pub fn ContactShadows::default() -> ContactShadows {
  ContactShadows::{ linear_steps: 16, thickness: 0.1F, length: 0.3F }
}

///|
pub fn ContactShadows::new(
  linear_steps : Int,
  thickness : Float,
  length : Float,
) -> ContactShadows {
  ContactShadows::{
    linear_steps: if linear_steps <= 0 {
      1
    } else {
      linear_steps
    },
    thickness: if thickness < 0.0F {
      0.0F
    } else {
      thickness
    },
    length: if length < 0.0F {
      0.0F
    } else {
      length
    },
  }
}

///|
pub fn ContactShadows::with_linear_steps(
  self : ContactShadows,
  linear_steps : Int,
) -> ContactShadows {
  ContactShadows::new(linear_steps, self.thickness, self.length)
}

///|
pub fn ContactShadows::with_thickness(
  self : ContactShadows,
  thickness : Float,
) -> ContactShadows {
  ContactShadows::new(self.linear_steps, thickness, self.length)
}

///|
pub fn ContactShadows::with_length(
  self : ContactShadows,
  length : Float,
) -> ContactShadows {
  ContactShadows::new(self.linear_steps, self.thickness, length)
}

///|
/// Camera shadow filtering mode aligned with Bevy's `ShadowFilteringMethod`.
#ecs.component
pub(all) enum ShadowFilteringMethod {
  Hardware2x2
  Gaussian
  Temporal
} derive(Eq, Show)

///|
pub fn ShadowFilteringMethod::default() -> ShadowFilteringMethod {
  ShadowFilteringMethod::Gaussian
}

///|
fn screen_space_reflections_safe_range(
  start : Float,
  end_ : Float,
) -> (Float, Float) {
  let safe_start = clamp01(start)
  let safe_end = clamp01(end_)
  (minf(safe_start, safe_end), maxf(safe_start, safe_end))
}

///|
fn screen_space_reflections_safe_thickness(thickness : Float) -> Float {
  if thickness < 0.0F {
    0.0F
  } else {
    thickness
  }
}

///|
fn screen_space_reflections_safe_linear_steps(linear_steps : Int) -> Int {
  if linear_steps <= 0 {
    1
  } else {
    linear_steps
  }
}

///|
fn screen_space_reflections_safe_linear_march_exponent(
  linear_march_exponent : Float,
) -> Float {
  if linear_march_exponent <= 0.0F {
    1.0F
  } else {
    linear_march_exponent
  }
}

///|
fn screen_space_reflections_safe_bisection_steps(bisection_steps : Int) -> Int {
  if bisection_steps < 0 {
    0
  } else {
    bisection_steps
  }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ScreenSpaceReflections {
  min_perceptual_roughness_start : Float
  min_perceptual_roughness_end : Float
  max_perceptual_roughness_start : Float
  max_perceptual_roughness_end : Float
  thickness : Float
  linear_steps : Int
  linear_march_exponent : Float
  edge_fadeout_start : Float
  edge_fadeout_end : Float
  bisection_steps : Int
  use_secant : Bool
}

///|
pub fn ScreenSpaceReflections::default() -> ScreenSpaceReflections {
  let (min_start, min_end) = screen_space_reflections_safe_range(0.08F, 0.12F)
  let (max_start, max_end) = screen_space_reflections_safe_range(0.55F, 0.6F)
  let (edge_start, edge_end) = screen_space_reflections_safe_range(0.0F, 0.0F)
  ScreenSpaceReflections::{
    min_perceptual_roughness_start: min_start,
    min_perceptual_roughness_end: min_end,
    max_perceptual_roughness_start: max_start,
    max_perceptual_roughness_end: max_end,
    thickness: screen_space_reflections_safe_thickness(0.25F),
    linear_steps: screen_space_reflections_safe_linear_steps(10),
    linear_march_exponent: screen_space_reflections_safe_linear_march_exponent(
      1.0F,
    ),
    edge_fadeout_start: edge_start,
    edge_fadeout_end: edge_end,
    bisection_steps: screen_space_reflections_safe_bisection_steps(5),
    use_secant: true,
  }
}

///|
pub fn ScreenSpaceReflections::with_min_perceptual_roughness(
  self : ScreenSpaceReflections,
  start : Float,
  end_ : Float,
) -> ScreenSpaceReflections {
  let (safe_start, safe_end) = screen_space_reflections_safe_range(start, end_)
  ScreenSpaceReflections::{
    ..self,
    min_perceptual_roughness_start: safe_start,
    min_perceptual_roughness_end: safe_end,
  }
}

///|
pub fn ScreenSpaceReflections::with_max_perceptual_roughness(
  self : ScreenSpaceReflections,
  start : Float,
  end_ : Float,
) -> ScreenSpaceReflections {
  let (safe_start, safe_end) = screen_space_reflections_safe_range(start, end_)
  ScreenSpaceReflections::{
    ..self,
    max_perceptual_roughness_start: safe_start,
    max_perceptual_roughness_end: safe_end,
  }
}

///|
pub fn ScreenSpaceReflections::with_edge_fadeout(
  self : ScreenSpaceReflections,
  start : Float,
  end_ : Float,
) -> ScreenSpaceReflections {
  let (safe_start, safe_end) = screen_space_reflections_safe_range(start, end_)
  ScreenSpaceReflections::{
    ..self,
    edge_fadeout_start: safe_start,
    edge_fadeout_end: safe_end,
  }
}

///|
pub fn ScreenSpaceReflections::with_thickness(
  self : ScreenSpaceReflections,
  thickness : Float,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    thickness: screen_space_reflections_safe_thickness(thickness),
  }
}

///|
pub fn ScreenSpaceReflections::with_linear_steps(
  self : ScreenSpaceReflections,
  linear_steps : Int,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    linear_steps: screen_space_reflections_safe_linear_steps(linear_steps),
  }
}

///|
pub fn ScreenSpaceReflections::with_linear_march_exponent(
  self : ScreenSpaceReflections,
  linear_march_exponent : Float,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    linear_march_exponent: screen_space_reflections_safe_linear_march_exponent(
      linear_march_exponent,
    ),
  }
}

///|
pub fn ScreenSpaceReflections::with_bisection_steps(
  self : ScreenSpaceReflections,
  bisection_steps : Int,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    bisection_steps: screen_space_reflections_safe_bisection_steps(
      bisection_steps,
    ),
  }
}

///|
pub fn ScreenSpaceReflections::with_use_secant(
  self : ScreenSpaceReflections,
  use_secant : Bool,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{ ..self, use_secant, }
}

///|
pub(all) enum AlphaMode3d {
  Opaque
  Mask(Float)
  Blend
  Premultiplied
  Add
  Multiply
  AlphaToCoverage
}

///|
pub(all) enum Face3d {
  Front
  Back
}

///|
pub(all) enum FogFalloff3d {
  Linear(Float, Float)
  Exponential(Float)
  ExponentialSquared(Float)
}

///|
pub fn FogFalloff3d::linear(start : Float, end_ : Float) -> FogFalloff3d {
  let safe_start = if start < 0.0F { 0.0F } else { start }
  let safe_end = if end_ < safe_start { safe_start } else { end_ }
  FogFalloff3d::Linear(safe_start, safe_end)
}

///|
pub fn FogFalloff3d::exponential(density : Float) -> FogFalloff3d {
  let safe_density = if density < 0.0F { 0.0F } else { density }
  FogFalloff3d::Exponential(safe_density)
}

///|
pub fn FogFalloff3d::exponential_squared(density : Float) -> FogFalloff3d {
  let safe_density = if density < 0.0F { 0.0F } else { density }
  FogFalloff3d::ExponentialSquared(safe_density)
}

///|
// Global fog settings (currently global, not per-camera component).
pub struct DistanceFog {
  color : @render2d.Color
  falloff : FogFalloff3d
}

///|
pub fn DistanceFog::default() -> DistanceFog {
  DistanceFog::{
    color: @render2d.Color::new(0.25F, 0.25F, 0.25F, 0.0F),
    falloff: FogFalloff3d::linear(5.0F, 20.0F),
  }
}

///|
pub fn DistanceFog::new(
  color : @render2d.Color,
  falloff : FogFalloff3d,
) -> DistanceFog {
  DistanceFog::{ color, falloff }
}

///|
pub fn DistanceFog::with_color(
  self : DistanceFog,
  color : @render2d.Color,
) -> DistanceFog {
  DistanceFog::{ ..self, color, }
}

///|
pub fn DistanceFog::with_falloff(
  self : DistanceFog,
  falloff : FogFalloff3d,
) -> DistanceFog {
  DistanceFog::{ ..self, falloff, }
}

///|
let distance_fog_state : Ref[DistanceFog] = Ref::new(DistanceFog::default())

///|
pub fn render3d_set_distance_fog(fog : DistanceFog) -> Unit {
  distance_fog_state.val = fog
}

///|
pub fn render3d_distance_fog() -> DistanceFog {
  distance_fog_state.val
}

///|
pub(all) enum ParallaxMappingMethod {
  Occlusion
  Relief(Int)
} derive(Eq, Show)

///|
pub fn ParallaxMappingMethod::default() -> ParallaxMappingMethod {
  Occlusion
}

///|
pub fn ParallaxMappingMethod::relief_default() -> ParallaxMappingMethod {
  Relief(5)
}

///|
pub fn ParallaxMappingMethod::max_steps(self : ParallaxMappingMethod) -> Int {
  match self {
    Occlusion => 0
    Relief(max_steps) => if max_steps <= 0 { 1 } else { max_steps }
  }
}

///|
/// Opaque render path preference aligned with Bevy's `OpaqueRendererMethod`.
///
/// Current runtime note: only the forward backend is active; deferred options
/// are preserved as API surface for parity and migration sequencing.
pub(all) enum OpaqueRendererMethod {
  Auto
  Forward
  Deferred
} derive(Eq, Show)

///|
pub fn OpaqueRendererMethod::default() -> OpaqueRendererMethod {
  OpaqueRendererMethod::Auto
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct DefaultOpaqueRendererMethod {
  renderer_method : OpaqueRendererMethod
}

///|
pub fn DefaultOpaqueRendererMethod::default() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{ renderer_method: OpaqueRendererMethod::Auto }
}

///|
pub fn DefaultOpaqueRendererMethod::new(
  renderer_method : OpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{ renderer_method, }
}

///|
pub fn DefaultOpaqueRendererMethod::forward() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{
    renderer_method: OpaqueRendererMethod::Forward,
  }
}

///|
pub fn DefaultOpaqueRendererMethod::deferred() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{
    renderer_method: OpaqueRendererMethod::Deferred,
  }
}

///|
pub fn DefaultOpaqueRendererMethod::with_method(
  self : DefaultOpaqueRendererMethod,
  renderer_method : OpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  self |> ignore
  DefaultOpaqueRendererMethod::{ renderer_method, }
}

///|
pub fn DefaultOpaqueRendererMethod::set_to_forward(
  self : DefaultOpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  self.with_method(OpaqueRendererMethod::Forward)
}

///|
pub fn DefaultOpaqueRendererMethod::set_to_deferred(
  self : DefaultOpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  self.with_method(OpaqueRendererMethod::Deferred)
}

///|
pub fn DefaultOpaqueRendererMethod::renderer_method(
  self : DefaultOpaqueRendererMethod,
) -> OpaqueRendererMethod {
  self.renderer_method
}

///|
pub struct StandardMaterial {
  base_color : @render2d.Color
  base_color_texture : @asset.Handle[@asset.Image]?
  uv_offset : @math.Vec2
  uv_scale : @math.Vec2
  normal_map_texture : @asset.Handle[@asset.Image]?
  depth_map : @asset.Handle[@asset.Image]?
  parallax_depth_scale : Float
  max_parallax_layer_count : Float
  parallax_mapping_method : ParallaxMappingMethod
  clearcoat : Float
  clearcoat_perceptual_roughness : Float
  clearcoat_texture : @asset.Handle[@asset.Image]?
  clearcoat_roughness_texture : @asset.Handle[@asset.Image]?
  clearcoat_normal_texture : @asset.Handle[@asset.Image]?
  anisotropy_strength : Float
  anisotropy_rotation : Float
  anisotropy_texture : @asset.Handle[@asset.Image]?
  emissive : @render2d.Color
  emissive_texture : @asset.Handle[@asset.Image]?
  metallic : Float
  metallic_roughness_texture : @asset.Handle[@asset.Image]?
  perceptual_roughness : Float
  reflectance : Float
  occlusion_texture : @asset.Handle[@asset.Image]?
  alpha_mode : AlphaMode3d
  opaque_render_method : OpaqueRendererMethod
  unlit : Bool
  cull_mode : Face3d?
}

///|
pub fn StandardMaterial::default() -> StandardMaterial {
  StandardMaterial::{
    base_color: @render2d.Color::white(),
    base_color_texture: None,
    uv_offset: @math.Vec2::new(0.0F, 0.0F),
    uv_scale: @math.Vec2::new(1.0F, 1.0F),
    normal_map_texture: None,
    depth_map: None,
    parallax_depth_scale: 0.1F,
    max_parallax_layer_count: 16.0F,
    parallax_mapping_method: ParallaxMappingMethod::Occlusion,
    clearcoat: 0.0F,
    clearcoat_perceptual_roughness: 0.0F,
    clearcoat_texture: None,
    clearcoat_roughness_texture: None,
    clearcoat_normal_texture: None,
    anisotropy_strength: 0.0F,
    anisotropy_rotation: 0.0F,
    anisotropy_texture: None,
    emissive: @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    emissive_texture: None,
    metallic: 0.0F,
    metallic_roughness_texture: None,
    perceptual_roughness: 0.5F,
    reflectance: 0.5F,
    occlusion_texture: None,
    alpha_mode: AlphaMode3d::Opaque,
    opaque_render_method: OpaqueRendererMethod::Auto,
    unlit: false,
    cull_mode: Some(Face3d::Back),
  }
}

///|
pub fn StandardMaterial::from_color(
  color : @render2d.Color,
) -> StandardMaterial {
  let alpha_mode = if color.a < 0.999F {
    AlphaMode3d::Blend
  } else {
    AlphaMode3d::Opaque
  }
  let default_value = StandardMaterial::default()
  StandardMaterial::{
    base_color: color,
    base_color_texture: default_value.base_color_texture,
    uv_offset: default_value.uv_offset,
    uv_scale: default_value.uv_scale,
    normal_map_texture: default_value.normal_map_texture,
    depth_map: default_value.depth_map,
    parallax_depth_scale: default_value.parallax_depth_scale,
    max_parallax_layer_count: default_value.max_parallax_layer_count,
    parallax_mapping_method: default_value.parallax_mapping_method,
    clearcoat: default_value.clearcoat,
    clearcoat_perceptual_roughness: default_value.clearcoat_perceptual_roughness,
    clearcoat_texture: default_value.clearcoat_texture,
    clearcoat_roughness_texture: default_value.clearcoat_roughness_texture,
    clearcoat_normal_texture: default_value.clearcoat_normal_texture,
    anisotropy_strength: default_value.anisotropy_strength,
    anisotropy_rotation: default_value.anisotropy_rotation,
    anisotropy_texture: default_value.anisotropy_texture,
    emissive: default_value.emissive,
    emissive_texture: default_value.emissive_texture,
    metallic: default_value.metallic,
    metallic_roughness_texture: default_value.metallic_roughness_texture,
    perceptual_roughness: default_value.perceptual_roughness,
    reflectance: default_value.reflectance,
    occlusion_texture: default_value.occlusion_texture,
    alpha_mode,
    opaque_render_method: default_value.opaque_render_method,
    unlit: default_value.unlit,
    cull_mode: default_value.cull_mode,
  }
}

///|
pub fn StandardMaterial::with_base_color(
  self : StandardMaterial,
  color : @render2d.Color,
) -> StandardMaterial {
  StandardMaterial::{ ..self, base_color: color }
}

///|
pub fn StandardMaterial::with_alpha_mode(
  self : StandardMaterial,
  alpha_mode : AlphaMode3d,
) -> StandardMaterial {
  StandardMaterial::{ ..self, alpha_mode, }
}

///|
pub fn StandardMaterial::with_opaque_render_method(
  self : StandardMaterial,
  opaque_render_method : OpaqueRendererMethod,
) -> StandardMaterial {
  StandardMaterial::{ ..self, opaque_render_method, }
}

///|
pub fn StandardMaterial::with_base_color_texture(
  self : StandardMaterial,
  base_color_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, base_color_texture, }
}

///|
pub fn StandardMaterial::with_uv_offset(
  self : StandardMaterial,
  uv_offset : @math.Vec2,
) -> StandardMaterial {
  StandardMaterial::{ ..self, uv_offset, }
}

///|
pub fn StandardMaterial::with_uv_scale(
  self : StandardMaterial,
  uv_scale : @math.Vec2,
) -> StandardMaterial {
  StandardMaterial::{ ..self, uv_scale, }
}

///|
pub fn StandardMaterial::with_normal_map_texture(
  self : StandardMaterial,
  normal_map_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, normal_map_texture, }
}

///|
pub fn StandardMaterial::with_depth_map(
  self : StandardMaterial,
  depth_map : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, depth_map, }
}

///|
pub fn StandardMaterial::with_parallax_depth_scale(
  self : StandardMaterial,
  parallax_depth_scale : Float,
) -> StandardMaterial {
  let safe_parallax_depth_scale = if parallax_depth_scale < 0.0F {
    0.0F
  } else {
    parallax_depth_scale
  }
  StandardMaterial::{ ..self, parallax_depth_scale: safe_parallax_depth_scale }
}

///|
pub fn StandardMaterial::with_max_parallax_layer_count(
  self : StandardMaterial,
  max_parallax_layer_count : Float,
) -> StandardMaterial {
  let safe_max_parallax_layer_count = if max_parallax_layer_count < 0.0F {
    0.0F
  } else {
    max_parallax_layer_count
  }
  StandardMaterial::{
    ..self,
    max_parallax_layer_count: safe_max_parallax_layer_count,
  }
}

///|
pub fn StandardMaterial::with_parallax_mapping_method(
  self : StandardMaterial,
  parallax_mapping_method : ParallaxMappingMethod,
) -> StandardMaterial {
  StandardMaterial::{ ..self, parallax_mapping_method, }
}

///|
pub fn StandardMaterial::with_clearcoat(
  self : StandardMaterial,
  clearcoat : Float,
) -> StandardMaterial {
  let safe_clearcoat = if clearcoat < 0.0F {
    0.0F
  } else if clearcoat > 1.0F {
    1.0F
  } else {
    clearcoat
  }
  StandardMaterial::{ ..self, clearcoat: safe_clearcoat }
}

///|
pub fn StandardMaterial::with_clearcoat_perceptual_roughness(
  self : StandardMaterial,
  clearcoat_perceptual_roughness : Float,
) -> StandardMaterial {
  let safe_clearcoat_perceptual_roughness = if clearcoat_perceptual_roughness <
    0.0F {
    0.0F
  } else if clearcoat_perceptual_roughness > 1.0F {
    1.0F
  } else {
    clearcoat_perceptual_roughness
  }
  StandardMaterial::{
    ..self,
    clearcoat_perceptual_roughness: safe_clearcoat_perceptual_roughness,
  }
}

///|
pub fn StandardMaterial::with_clearcoat_texture(
  self : StandardMaterial,
  clearcoat_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, clearcoat_texture, }
}

///|
pub fn StandardMaterial::with_clearcoat_roughness_texture(
  self : StandardMaterial,
  clearcoat_roughness_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, clearcoat_roughness_texture, }
}

///|
pub fn StandardMaterial::with_clearcoat_normal_texture(
  self : StandardMaterial,
  clearcoat_normal_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, clearcoat_normal_texture, }
}

///|
pub fn StandardMaterial::with_anisotropy_strength(
  self : StandardMaterial,
  anisotropy_strength : Float,
) -> StandardMaterial {
  let safe_anisotropy_strength = if anisotropy_strength < 0.0F {
    0.0F
  } else if anisotropy_strength > 1.0F {
    1.0F
  } else {
    anisotropy_strength
  }
  StandardMaterial::{ ..self, anisotropy_strength: safe_anisotropy_strength }
}

///|
pub fn StandardMaterial::with_anisotropy_rotation(
  self : StandardMaterial,
  anisotropy_rotation : Float,
) -> StandardMaterial {
  StandardMaterial::{ ..self, anisotropy_rotation, }
}

///|
pub fn StandardMaterial::with_anisotropy_texture(
  self : StandardMaterial,
  anisotropy_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, anisotropy_texture, }
}

///|
pub fn StandardMaterial::with_emissive(
  self : StandardMaterial,
  emissive : @render2d.Color,
) -> StandardMaterial {
  StandardMaterial::{ ..self, emissive, }
}

///|
pub fn StandardMaterial::with_emissive_texture(
  self : StandardMaterial,
  emissive_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, emissive_texture, }
}

///|
pub fn StandardMaterial::with_metallic(
  self : StandardMaterial,
  metallic : Float,
) -> StandardMaterial {
  let safe_metallic = if metallic < 0.0F {
    0.0F
  } else if metallic > 1.0F {
    1.0F
  } else {
    metallic
  }
  StandardMaterial::{ ..self, metallic: safe_metallic }
}

///|
pub fn StandardMaterial::with_perceptual_roughness(
  self : StandardMaterial,
  perceptual_roughness : Float,
) -> StandardMaterial {
  let safe_perceptual_roughness = if perceptual_roughness < 0.0F {
    0.0F
  } else if perceptual_roughness > 1.0F {
    1.0F
  } else {
    perceptual_roughness
  }
  StandardMaterial::{ ..self, perceptual_roughness: safe_perceptual_roughness }
}

///|
pub fn StandardMaterial::with_reflectance(
  self : StandardMaterial,
  reflectance : Float,
) -> StandardMaterial {
  let safe_reflectance = if reflectance < 0.0F {
    0.0F
  } else if reflectance > 1.0F {
    1.0F
  } else {
    reflectance
  }
  StandardMaterial::{ ..self, reflectance: safe_reflectance }
}

///|
pub fn StandardMaterial::with_metallic_roughness_texture(
  self : StandardMaterial,
  metallic_roughness_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, metallic_roughness_texture, }
}

///|
pub fn StandardMaterial::with_occlusion_texture(
  self : StandardMaterial,
  occlusion_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, occlusion_texture, }
}

///|
pub fn StandardMaterial::with_unlit(
  self : StandardMaterial,
  unlit : Bool,
) -> StandardMaterial {
  StandardMaterial::{ ..self, unlit, }
}

///|
let standard_material_assets : Ref[@asset.Assets[StandardMaterial]] = Ref::new(
  @asset.Assets::new(),
)

///|
pub fn standard_material_add(
  material : StandardMaterial,
) -> @asset.Handle[StandardMaterial] {
  standard_material_assets.val.add(material)
}

///|
pub fn standard_material_get(
  handle : @asset.Handle[StandardMaterial],
) -> StandardMaterial? {
  standard_material_assets.val.get(handle)
}

///|
pub fn standard_material_set(
  handle : @asset.Handle[StandardMaterial],
  material : StandardMaterial,
) -> Bool {
  standard_material_assets.val.set(handle, material)
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Mesh3d {
  mesh : @asset.Handle[@mesh.Mesh]
}

///|
pub fn Mesh3d::new(mesh : @asset.Handle[@mesh.Mesh]) -> Mesh3d {
  Mesh3d::{ mesh, }
}

///|
fn mesh3d_append_quad(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
  d : @math.Vec3,
) -> Unit {
  positions.push(a)
  positions.push(b)
  positions.push(c)
  positions.push(a)
  positions.push(c)
  positions.push(d)
  uvs.push(@math.Vec2::new(0.0F, 0.0F))
  uvs.push(@math.Vec2::new(1.0F, 0.0F))
  uvs.push(@math.Vec2::new(1.0F, 1.0F))
  uvs.push(@math.Vec2::new(0.0F, 0.0F))
  uvs.push(@math.Vec2::new(1.0F, 1.0F))
  uvs.push(@math.Vec2::new(0.0F, 1.0F))
}

///|
fn mesh3d_append_triangle(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
) -> Unit {
  positions.push(a)
  positions.push(b)
  positions.push(c)
  uvs.push(@math.Vec2::new(0.5F, 0.0F))
  uvs.push(@math.Vec2::new(0.0F, 1.0F))
  uvs.push(@math.Vec2::new(1.0F, 1.0F))
}

///|
fn mesh3d_geometry_cuboid(
  width : Float,
  height : Float,
  depth : Float,
) -> @mesh.Mesh3dGeometry {
  let safe_width = if width <= 0.0F { 1.0F } else { width }
  let safe_height = if height <= 0.0F { 1.0F } else { height }
  let safe_depth = if depth <= 0.0F { 1.0F } else { depth }
  let hx = safe_width * 0.5F
  let hy = safe_height * 0.5F
  let hz = safe_depth * 0.5F
  let p000 = @math.Vec3::new(-hx, -hy, -hz)
  let p100 = @math.Vec3::new(hx, -hy, -hz)
  let p110 = @math.Vec3::new(hx, hy, -hz)
  let p010 = @math.Vec3::new(-hx, hy, -hz)
  let p001 = @math.Vec3::new(-hx, -hy, hz)
  let p101 = @math.Vec3::new(hx, -hy, hz)
  let p111 = @math.Vec3::new(hx, hy, hz)
  let p011 = @math.Vec3::new(-hx, hy, hz)
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  // +Z front
  mesh3d_append_quad(positions, uvs, p001, p101, p111, p011)
  // -Z back
  mesh3d_append_quad(positions, uvs, p100, p000, p010, p110)
  // +X right
  mesh3d_append_quad(positions, uvs, p101, p100, p110, p111)
  // -X left
  mesh3d_append_quad(positions, uvs, p000, p001, p011, p010)
  // +Y top
  mesh3d_append_quad(positions, uvs, p011, p111, p110, p010)
  // -Y bottom
  mesh3d_append_quad(positions, uvs, p000, p100, p101, p001)
  @mesh.Mesh3dGeometry::new(positions, uvs, None)
}

///|
fn mesh3d_geometry_plane(width : Float, depth : Float) -> @mesh.Mesh3dGeometry {
  let safe_width = if width <= 0.0F { 1.0F } else { width }
  let safe_depth = if depth <= 0.0F { 1.0F } else { depth }
  let hx = safe_width * 0.5F
  let hz = safe_depth * 0.5F
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  mesh3d_append_quad(
    positions,
    uvs,
    @math.Vec3::new(-hx, 0.0F, -hz),
    @math.Vec3::new(hx, 0.0F, -hz),
    @math.Vec3::new(hx, 0.0F, hz),
    @math.Vec3::new(-hx, 0.0F, hz),
  )
  @mesh.Mesh3dGeometry::new(positions, uvs, None)
}

///|
fn mesh3d_geometry_tetrahedron(edge : Float) -> @mesh.Mesh3dGeometry {
  let safe_edge = if edge <= 0.0F { 1.0F } else { edge }
  let h = safe_edge * 0.5F
  let v0 = @math.Vec3::new(0.0F, h, 0.0F)
  let v1 = @math.Vec3::new(-h, -h, h)
  let v2 = @math.Vec3::new(h, -h, h)
  let v3 = @math.Vec3::new(0.0F, -h, -h)
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  mesh3d_append_triangle(positions, uvs, v0, v1, v2)
  mesh3d_append_triangle(positions, uvs, v0, v2, v3)
  mesh3d_append_triangle(positions, uvs, v0, v3, v1)
  mesh3d_append_triangle(positions, uvs, v1, v3, v2)
  @mesh.Mesh3dGeometry::new(positions, uvs, None)
}

///|
pub fn Mesh3d::from_geometry(geometry : @mesh.Mesh3dGeometry) -> Mesh3d {
  Mesh3d::new(
    @render2d.render_mesh_asset_add(@mesh.Mesh::from_3d_geometry(geometry)),
  )
}

///|
pub fn Mesh3d::from_cuboid(
  width : Float,
  height : Float,
  depth : Float,
) -> Mesh3d {
  Mesh3d::from_geometry(mesh3d_geometry_cuboid(width, height, depth))
}

///|
pub fn Mesh3d::from_plane(width : Float, depth : Float) -> Mesh3d {
  Mesh3d::from_geometry(mesh3d_geometry_plane(width, depth))
}

///|
pub fn Mesh3d::from_tetrahedron(edge : Float) -> Mesh3d {
  Mesh3d::from_geometry(mesh3d_geometry_tetrahedron(edge))
}

///|
let skybox_proxy_mesh : Ref[@asset.Handle[@mesh.Mesh]?] = Ref::new(None)

///|
fn render3d_skybox_proxy_mesh_id() -> Int {
  let handle = match skybox_proxy_mesh.val {
    Some(handle) => handle
    None => {
      let mesh = Mesh3d::from_cuboid(2.0F, 2.0F, 2.0F)
      skybox_proxy_mesh.val = Some(mesh.mesh)
      mesh.mesh
    }
  }
  @render2d.render2d_upload_mesh_handle(handle)
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct MeshMaterial3d {
  material : @asset.Handle[StandardMaterial]
}

///|
pub fn MeshMaterial3d::new(
  material : @asset.Handle[StandardMaterial],
) -> MeshMaterial3d {
  MeshMaterial3d::{ material, }
}

///|
const POINT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS : Float = 0.08F

///|
const POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS : Float = 0.6F

///|
const POINT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z : Float = 0.1F

///|
const DIRECTIONAL_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS : Float = 0.02F

///|
const DIRECTIONAL_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS : Float = 1.8F

///|
const SPOT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS : Float = 0.02F

///|
const SPOT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS : Float = 1.8F

///|
const SPOT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z : Float = 0.1F

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct PointLight {
  color : @render2d.Color
  intensity : Float
  range : Float
  radius : Float
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  soft_shadows_enabled : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  shadow_map_near_z : Float
}

///|
pub fn PointLight::default() -> PointLight {
  PointLight::{
    color: @render2d.Color::white(),
    intensity: 1_000_000.0F,
    range: 20.0F,
    radius: 0.0F,
    shadow_maps_enabled: false,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    shadow_depth_bias: POINT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: POINT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn PointLight::new(
  color : @render2d.Color,
  intensity : Float,
  range : Float,
  shadow_maps_enabled : Bool,
) -> PointLight {
  PointLight::{
    color,
    intensity,
    range,
    radius: 0.0F,
    shadow_maps_enabled,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    shadow_depth_bias: POINT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: POINT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn PointLight::with_intensity(
  self : PointLight,
  intensity : Float,
) -> PointLight {
  PointLight::{
    ..self,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn PointLight::with_radius(self : PointLight, radius : Float) -> PointLight {
  PointLight::{ ..self, radius: if radius < 0.0F { 0.0F } else { radius } }
}

///|
pub fn PointLight::with_contact_shadows_enabled(
  self : PointLight,
  contact_shadows_enabled : Bool,
) -> PointLight {
  PointLight::{ ..self, contact_shadows_enabled, }
}

///|
pub fn PointLight::with_soft_shadows_enabled(
  self : PointLight,
  soft_shadows_enabled : Bool,
) -> PointLight {
  PointLight::{ ..self, soft_shadows_enabled, }
}

///|
pub fn PointLight::with_shadow_depth_bias(
  self : PointLight,
  shadow_depth_bias : Float,
) -> PointLight {
  PointLight::{
    ..self,
    shadow_depth_bias: if shadow_depth_bias < 0.0F {
      0.0F
    } else {
      shadow_depth_bias
    },
  }
}

///|
pub fn PointLight::with_shadow_normal_bias(
  self : PointLight,
  shadow_normal_bias : Float,
) -> PointLight {
  PointLight::{
    ..self,
    shadow_normal_bias: if shadow_normal_bias < 0.0F {
      0.0F
    } else {
      shadow_normal_bias
    },
  }
}

///|
pub fn PointLight::with_shadow_map_near_z(
  self : PointLight,
  shadow_map_near_z : Float,
) -> PointLight {
  PointLight::{
    ..self,
    shadow_map_near_z: if shadow_map_near_z <= 0.0001F {
      0.0001F
    } else {
      shadow_map_near_z
    },
  }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct DirectionalLight {
  color : @render2d.Color
  illuminance : Float
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  soft_shadow_size : Float?
  shadow_depth_bias : Float
  shadow_normal_bias : Float
}

///|
pub fn DirectionalLight::default() -> DirectionalLight {
  DirectionalLight::{
    color: @render2d.Color::white(),
    illuminance: 10000.0F,
    shadow_maps_enabled: false,
    contact_shadows_enabled: false,
    soft_shadow_size: None,
    shadow_depth_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
  }
}

///|
pub fn DirectionalLight::new(
  color : @render2d.Color,
  illuminance : Float,
  shadow_maps_enabled : Bool,
) -> DirectionalLight {
  DirectionalLight::{
    color,
    illuminance,
    shadow_maps_enabled,
    contact_shadows_enabled: false,
    soft_shadow_size: None,
    shadow_depth_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
  }
}

///|
pub fn DirectionalLight::with_illuminance(
  self : DirectionalLight,
  illuminance : Float,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    illuminance: if illuminance < 0.0F {
      0.0F
    } else {
      illuminance
    },
  }
}

///|
pub fn DirectionalLight::with_contact_shadows_enabled(
  self : DirectionalLight,
  contact_shadows_enabled : Bool,
) -> DirectionalLight {
  DirectionalLight::{ ..self, contact_shadows_enabled, }
}

///|
pub fn DirectionalLight::with_soft_shadow_size(
  self : DirectionalLight,
  soft_shadow_size : Float?,
) -> DirectionalLight {
  let safe_soft_shadow_size = match soft_shadow_size {
    Some(value) => Some(if value < 0.0F { 0.0F } else { value })
    None => None
  }
  DirectionalLight::{ ..self, soft_shadow_size: safe_soft_shadow_size }
}

///|
pub fn DirectionalLight::with_shadow_depth_bias(
  self : DirectionalLight,
  shadow_depth_bias : Float,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    shadow_depth_bias: if shadow_depth_bias < 0.0F {
      0.0F
    } else {
      shadow_depth_bias
    },
  }
}

///|
pub fn DirectionalLight::with_shadow_normal_bias(
  self : DirectionalLight,
  shadow_normal_bias : Float,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    shadow_normal_bias: if shadow_normal_bias < 0.0F {
      0.0F
    } else {
      shadow_normal_bias
    },
  }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct SpotLight {
  color : @render2d.Color
  intensity : Float
  range : Float
  radius : Float
  inner_angle : Float
  outer_angle : Float
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  soft_shadows_enabled : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  shadow_map_near_z : Float
}

///|
pub fn SpotLight::default() -> SpotLight {
  SpotLight::{
    color: @render2d.Color::white(),
    intensity: 1_000_000.0F,
    range: 20.0F,
    radius: 0.0F,
    inner_angle: 0.6F,
    outer_angle: 0.8F,
    shadow_maps_enabled: false,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    shadow_depth_bias: SPOT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: SPOT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: SPOT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn SpotLight::new(
  color : @render2d.Color,
  intensity : Float,
  range : Float,
  inner_angle : Float,
  outer_angle : Float,
  shadow_maps_enabled : Bool,
) -> SpotLight {
  SpotLight::{
    color,
    intensity,
    range,
    radius: 0.0F,
    inner_angle,
    outer_angle,
    shadow_maps_enabled,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    shadow_depth_bias: SPOT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: SPOT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: SPOT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn SpotLight::with_intensity(
  self : SpotLight,
  intensity : Float,
) -> SpotLight {
  SpotLight::{
    ..self,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn SpotLight::with_inner_angle(
  self : SpotLight,
  inner_angle : Float,
) -> SpotLight {
  let safe_inner_angle = if inner_angle < 0.0F {
    0.0F
  } else if inner_angle > self.outer_angle {
    self.outer_angle
  } else {
    inner_angle
  }
  SpotLight::{ ..self, inner_angle: safe_inner_angle }
}

///|
pub fn SpotLight::with_outer_angle(
  self : SpotLight,
  outer_angle : Float,
) -> SpotLight {
  let safe_outer_angle = if outer_angle <= 0.0001F {
    0.0001F
  } else {
    outer_angle
  }
  let safe_inner_angle = if self.inner_angle > safe_outer_angle {
    safe_outer_angle
  } else {
    self.inner_angle
  }
  SpotLight::{
    ..self,
    outer_angle: safe_outer_angle,
    inner_angle: safe_inner_angle,
  }
}

///|
pub fn SpotLight::with_radius(self : SpotLight, radius : Float) -> SpotLight {
  SpotLight::{ ..self, radius: if radius < 0.0F { 0.0F } else { radius } }
}

///|
pub fn SpotLight::with_contact_shadows_enabled(
  self : SpotLight,
  contact_shadows_enabled : Bool,
) -> SpotLight {
  SpotLight::{ ..self, contact_shadows_enabled, }
}

///|
pub fn SpotLight::with_soft_shadows_enabled(
  self : SpotLight,
  soft_shadows_enabled : Bool,
) -> SpotLight {
  SpotLight::{ ..self, soft_shadows_enabled, }
}

///|
pub fn SpotLight::with_shadow_depth_bias(
  self : SpotLight,
  shadow_depth_bias : Float,
) -> SpotLight {
  SpotLight::{
    ..self,
    shadow_depth_bias: if shadow_depth_bias < 0.0F {
      0.0F
    } else {
      shadow_depth_bias
    },
  }
}

///|
pub fn SpotLight::with_shadow_normal_bias(
  self : SpotLight,
  shadow_normal_bias : Float,
) -> SpotLight {
  SpotLight::{
    ..self,
    shadow_normal_bias: if shadow_normal_bias < 0.0F {
      0.0F
    } else {
      shadow_normal_bias
    },
  }
}

///|
pub fn SpotLight::with_shadow_map_near_z(
  self : SpotLight,
  shadow_map_near_z : Float,
) -> SpotLight {
  SpotLight::{
    ..self,
    shadow_map_near_z: if shadow_map_near_z <= 0.0001F {
      0.0001F
    } else {
      shadow_map_near_z
    },
  }
}

///|
/// Cubemap texture layout aligned with Bevy's `CubemapLayout`.
pub(all) enum CubemapLayout3d {
  CrossVertical
  CrossHorizontal
  LineVertical
  LineHorizontal
  Equirectangular
  Faces
} derive(Eq, Show)

///|
pub fn CubemapLayout3d::default() -> CubemapLayout3d {
  CubemapLayout3d::CrossVertical
}

///|
/// Directional light texture settings aligned with Bevy's
/// `DirectionalLightTexture`.
///
/// Current runtime note: texture projection is not yet applied in this backend;
/// this component preserves API parity for example migration.
#ecs.component
pub struct DirectionalLightTexture {
  image : @asset.Handle[@asset.Image]?
  tiled : Bool
}

///|
pub fn DirectionalLightTexture::default() -> DirectionalLightTexture {
  DirectionalLightTexture::{ image: None, tiled: false }
}

///|
pub fn DirectionalLightTexture::new(
  image : @asset.Handle[@asset.Image]?,
  tiled : Bool,
) -> DirectionalLightTexture {
  DirectionalLightTexture::{ image, tiled }
}

///|
pub fn DirectionalLightTexture::with_image(
  self : DirectionalLightTexture,
  image : @asset.Handle[@asset.Image]?,
) -> DirectionalLightTexture {
  DirectionalLightTexture::{ ..self, image, }
}

///|
pub fn DirectionalLightTexture::with_tiled(
  self : DirectionalLightTexture,
  tiled : Bool,
) -> DirectionalLightTexture {
  DirectionalLightTexture::{ ..self, tiled, }
}

///|
/// Spot light texture settings aligned with Bevy's `SpotLightTexture`.
///
/// Current runtime note: texture projection is not yet applied in this backend;
/// this component preserves API parity for example migration.
#ecs.component
pub struct SpotLightTexture {
  image : @asset.Handle[@asset.Image]?
}

///|
pub fn SpotLightTexture::default() -> SpotLightTexture {
  SpotLightTexture::{ image: None }
}

///|
pub fn SpotLightTexture::new(
  image : @asset.Handle[@asset.Image]?,
) -> SpotLightTexture {
  SpotLightTexture::{ image, }
}

///|
pub fn SpotLightTexture::with_image(
  self : SpotLightTexture,
  image : @asset.Handle[@asset.Image]?,
) -> SpotLightTexture {
  self |> ignore
  SpotLightTexture::{ image, }
}

///|
/// Point light texture settings aligned with Bevy's `PointLightTexture`.
///
/// Current runtime note: texture projection is not yet applied in this backend;
/// this component preserves API parity for example migration.
#ecs.component
pub struct PointLightTexture {
  image : @asset.Handle[@asset.Image]?
  cubemap_layout : CubemapLayout3d
}

///|
pub fn PointLightTexture::default() -> PointLightTexture {
  PointLightTexture::{
    image: None,
    cubemap_layout: CubemapLayout3d::CrossVertical,
  }
}

///|
pub fn PointLightTexture::new(
  image : @asset.Handle[@asset.Image]?,
  cubemap_layout : CubemapLayout3d,
) -> PointLightTexture {
  PointLightTexture::{ image, cubemap_layout }
}

///|
pub fn PointLightTexture::with_image(
  self : PointLightTexture,
  image : @asset.Handle[@asset.Image]?,
) -> PointLightTexture {
  PointLightTexture::{ ..self, image, }
}

///|
pub fn PointLightTexture::with_cubemap_layout(
  self : PointLightTexture,
  cubemap_layout : CubemapLayout3d,
) -> PointLightTexture {
  PointLightTexture::{ ..self, cubemap_layout, }
}

///|
/// Light probe component aligned with Bevy's `LightProbe`.
///
/// The probe influence volume is a unit cube transformed by the entity
/// transform. `falloff` controls the attenuation region inside this cube.
#ecs.component
pub struct LightProbe {
  falloff : @math.Vec3
}

///|
pub fn LightProbe::default() -> LightProbe {
  LightProbe::{ falloff: @math.Vec3::zero() }
}

///|
pub fn LightProbe::new() -> LightProbe {
  LightProbe::default()
}

///|
pub fn LightProbe::with_falloff(
  self : LightProbe,
  falloff : @math.Vec3,
) -> LightProbe {
  self |> ignore
  LightProbe::{ falloff, }
}

///|
/// Environment map lighting component aligned with Bevy's
/// `EnvironmentMapLight`.
///
/// Current runtime note: this backend stores and exposes the Bevy-aligned
/// component surface; reflection probe shading remains adapted.
#ecs.component
pub struct EnvironmentMapLight {
  diffuse_map : @asset.Handle[@asset.Image]?
  specular_map : @asset.Handle[@asset.Image]?
  intensity : Float
  rotation : @math.Quat
  affects_lightmapped_mesh_diffuse : Bool
}

///|
pub fn EnvironmentMapLight::default() -> EnvironmentMapLight {
  EnvironmentMapLight::{
    diffuse_map: None,
    specular_map: None,
    intensity: 0.0F,
    rotation: @math.Quat::identity(),
    affects_lightmapped_mesh_diffuse: true,
  }
}

///|
pub fn EnvironmentMapLight::new(
  diffuse_map : @asset.Handle[@asset.Image]?,
  specular_map : @asset.Handle[@asset.Image]?,
  intensity : Float,
) -> EnvironmentMapLight {
  EnvironmentMapLight::default()
  .with_diffuse_map(diffuse_map)
  .with_specular_map(specular_map)
  .with_intensity(intensity)
}

///|
pub fn EnvironmentMapLight::with_diffuse_map(
  self : EnvironmentMapLight,
  diffuse_map : @asset.Handle[@asset.Image]?,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, diffuse_map, }
}

///|
pub fn EnvironmentMapLight::with_specular_map(
  self : EnvironmentMapLight,
  specular_map : @asset.Handle[@asset.Image]?,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, specular_map, }
}

///|
pub fn EnvironmentMapLight::with_intensity(
  self : EnvironmentMapLight,
  intensity : Float,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{
    ..self,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn EnvironmentMapLight::with_rotation(
  self : EnvironmentMapLight,
  rotation : @math.Quat,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, rotation, }
}

///|
pub fn EnvironmentMapLight::with_affects_lightmapped_mesh_diffuse(
  self : EnvironmentMapLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
/// Runtime-generated environment map lighting aligned with Bevy's
/// `GeneratedEnvironmentMapLight`.
///
/// Current runtime note: this backend stores this component for API parity.
/// Runtime cubemap filtering remains adapted.
#ecs.component
pub struct GeneratedEnvironmentMapLight {
  environment_map : @asset.Handle[@asset.Image]?
  intensity : Float
  rotation : @math.Quat
  affects_lightmapped_mesh_diffuse : Bool
}

///|
pub fn GeneratedEnvironmentMapLight::default() -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{
    environment_map: None,
    intensity: 0.0F,
    rotation: @math.Quat::identity(),
    affects_lightmapped_mesh_diffuse: true,
  }
}

///|
pub fn GeneratedEnvironmentMapLight::new(
  environment_map : @asset.Handle[@asset.Image]?,
  intensity : Float,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::default()
  .with_environment_map(environment_map)
  .with_intensity(intensity)
}

///|
pub fn GeneratedEnvironmentMapLight::with_environment_map(
  self : GeneratedEnvironmentMapLight,
  environment_map : @asset.Handle[@asset.Image]?,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{ ..self, environment_map, }
}

///|
pub fn GeneratedEnvironmentMapLight::with_intensity(
  self : GeneratedEnvironmentMapLight,
  intensity : Float,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{
    ..self,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn GeneratedEnvironmentMapLight::with_rotation(
  self : GeneratedEnvironmentMapLight,
  rotation : @math.Quat,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{ ..self, rotation, }
}

///|
pub fn GeneratedEnvironmentMapLight::with_affects_lightmapped_mesh_diffuse(
  self : GeneratedEnvironmentMapLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
/// Parallax correction mode aligned with Bevy's `ParallaxCorrection`.
///
/// Current runtime note: this backend stores this component for parity and
/// example behavior; probe-space correction is currently adapted.
#ecs.component
pub(all) enum ParallaxCorrection {
  None
  Auto
  Custom(@math.Vec3)
}

///|
pub fn ParallaxCorrection::default() -> ParallaxCorrection {
  ParallaxCorrection::Auto
}

///|
/// Irradiance volume settings aligned with Bevy's `IrradianceVolume`.
///
/// Current runtime note: this backend uses this component as API surface and
/// scene intent metadata; voxel-light transfer remains adapted.
#ecs.component
pub struct IrradianceVolume {
  voxels : @asset.Handle[@asset.Image]?
  intensity : Float
}

///|
pub fn IrradianceVolume::default() -> IrradianceVolume {
  IrradianceVolume::{ voxels: None, intensity: 1.0F }
}

///|
pub fn IrradianceVolume::new(
  voxels : @asset.Handle[@asset.Image]?,
  intensity : Float,
) -> IrradianceVolume {
  IrradianceVolume::{
    voxels,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn IrradianceVolume::with_voxels(
  self : IrradianceVolume,
  voxels : @asset.Handle[@asset.Image]?,
) -> IrradianceVolume {
  IrradianceVolume::{ ..self, voxels, }
}

///|
pub fn IrradianceVolume::with_intensity(
  self : IrradianceVolume,
  intensity : Float,
) -> IrradianceVolume {
  IrradianceVolume::new(self.voxels, intensity)
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct GlobalAmbientLight {
  color : @render2d.Color
  brightness : Float
}

///|
pub fn GlobalAmbientLight::default() -> GlobalAmbientLight {
  GlobalAmbientLight::{ color: @render2d.Color::white(), brightness: 0.0F }
}

///|
pub fn GlobalAmbientLight::new(
  color : @render2d.Color,
  brightness : Float,
) -> GlobalAmbientLight {
  GlobalAmbientLight::{ color, brightness }
}

///|
pub struct Camera3dBundle {
  camera : @render2d.Camera
  projection : CameraProjection3d
  sub_camera_view : SubCameraView3d?
  screen_space_reflections : ScreenSpaceReflections?
  chromatic_aberration : ChromaticAberration?
  vignette : Vignette?
  motion_blur : MotionBlur?
  camera3d : Camera3d
  transform : @math.Transform
  target : @render2d.RenderTarget
  layers : @render2d.RenderLayers
}

///|
pub fn Camera3dBundle::new(
  camera : @render2d.Camera,
  transform : @math.Transform,
) -> Camera3dBundle {
  Camera3dBundle::{
    camera,
    projection: CameraProjection3d::default(),
    sub_camera_view: None,
    screen_space_reflections: None,
    chromatic_aberration: None,
    vignette: None,
    motion_blur: None,
    camera3d: Camera3d::default(),
    transform,
    target: @render2d.RenderTarget::Screen,
    layers: @render2d.RenderLayers::default(),
  }
}

///|
pub fn Camera3dBundle::new_with_projection(
  camera : @render2d.Camera,
  projection : Projection3d,
  transform : @math.Transform,
) -> Camera3dBundle {
  Camera3dBundle::{
    camera,
    projection: CameraProjection3d::{ projection, },
    sub_camera_view: None,
    screen_space_reflections: None,
    chromatic_aberration: None,
    vignette: None,
    motion_blur: None,
    camera3d: Camera3d::default(),
    transform,
    target: @render2d.RenderTarget::Screen,
    layers: @render2d.RenderLayers::default(),
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
pub fn Camera3dBundle::with_screen_space_reflections(
  self : Camera3dBundle,
  screen_space_reflections : ScreenSpaceReflections?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, screen_space_reflections, }
}

///|
pub fn Camera3dBundle::with_chromatic_aberration(
  self : Camera3dBundle,
  chromatic_aberration : ChromaticAberration?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, chromatic_aberration, }
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
pub struct MeshMaterial3dBundle {
  mesh : Mesh3d
  material : MeshMaterial3d
  transform : @math.Transform
  layers : @render2d.RenderLayers
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn MeshMaterial3dBundle::new(
  mesh : Mesh3d,
  material : MeshMaterial3d,
  transform : @math.Transform,
) -> MeshMaterial3dBundle {
  MeshMaterial3dBundle::{
    mesh,
    material,
    transform,
    layers: @render2d.RenderLayers::default(),
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
pub(open) trait Camera3dBundleSpawnWorld: @core.SpawnWorld + @core.ChangeTickWorld + Has_Camera3d + Has_CameraProjection3d + Has_SubCameraView3d + Has_ScreenSpaceReflections + Has_ChromaticAberration + Has_Vignette + Has_MotionBlur + @render2d.Has_Camera + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @math.Has_Transform {
}

///|
pub(open) trait MeshMaterial3dBundleSpawnWorld: @core.SpawnWorld + @core.ChangeTickWorld + Has_Mesh3d + Has_MeshMaterial3d + @render2d.Has_GpuMesh2d + @render2d.Has_RenderLayers + @math.Has_Transform + @visibility.Has_Visibility + @visibility.Has_InheritedVisibility + @visibility.Has_ViewVisibility {
}

///|
pub fn[W : Camera3dBundleSpawnWorld] Camera3dBundle::spawn(
  self : Camera3dBundle,
  world : W,
) -> @core.Entity {
  let tick = world.read_change_tick()
  let entity = world.spawn_empty()
  world.get_camera3d_store().insert(entity, self.camera3d, tick)
  world.get_camera_projection3d_store().insert(entity, self.projection, tick)
  if self.sub_camera_view is Some(sub_camera_view) {
    world.get_sub_camera_view3d_store().insert(entity, sub_camera_view, tick)
  }
  if self.screen_space_reflections is Some(screen_space_reflections) {
    world
    .get_screen_space_reflections_store()
    .insert(entity, screen_space_reflections, tick)
  }
  if self.chromatic_aberration is Some(chromatic_aberration) {
    world
    .get_chromatic_aberration_store()
    .insert(entity, chromatic_aberration, tick)
  }
  if self.vignette is Some(vignette) {
    world.get_vignette_store().insert(entity, vignette, tick)
  }
  if self.motion_blur is Some(motion_blur) {
    world.get_motion_blur_store().insert(entity, motion_blur, tick)
  }
  world.get_camera_store().insert(entity, self.camera, tick)
  world.get_render_target_store().insert(entity, self.target, tick)
  world.get_render_layers_store().insert(entity, self.layers, tick)
  world.get_transform_store().insert(entity, self.transform, tick)
  entity
}

///|
pub fn[W : MeshMaterial3dBundleSpawnWorld] MeshMaterial3dBundle::spawn(
  self : MeshMaterial3dBundle,
  world : W,
) -> @core.Entity {
  let tick = world.read_change_tick()
  let entity = world.spawn_empty()
  world.get_mesh3d_store().insert(entity, self.mesh, tick)
  world.get_mesh_material3d_store().insert(entity, self.material, tick)
  world.get_render_layers_store().insert(entity, self.layers, tick)
  world.get_visibility_store().insert(entity, self.visibility, tick)
  world
  .get_inherited_visibility_store()
  .insert(entity, self.inherited_visibility, tick)
  world.get_view_visibility_store().insert(entity, self.view_visibility, tick)
  world.get_transform_store().insert(entity, self.transform, tick)
  let mesh_id = @render2d.render2d_upload_mesh_handle(self.mesh.mesh)
  world
  .get_gpu_mesh2d_store()
  .insert(entity, @render2d.GpuMesh2d::new(mesh_id), tick)
  entity
}

///|
priv struct Camera3dInstance {
  entity : @core.Entity
  camera : @render2d.Camera
  projection : CameraProjection3d
  sub_camera_view : SubCameraView3d?
  screen_space_reflections : ScreenSpaceReflections?
  chromatic_aberration : ChromaticAberration?
  vignette : Vignette?
  motion_blur : MotionBlur?
  skybox : Skybox?
  environment_map_light : EnvironmentMapLight?
  generated_environment_map_light : GeneratedEnvironmentMapLight?
  transform : @math.Transform
  previous_transform : @math.Transform
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
  layers : @render2d.RenderLayers
}

///|
priv struct ReflectionProbeInstance {
  transform : @math.Transform
  light_probe : LightProbe
  environment_map_light : EnvironmentMapLight
}

///|
priv struct ResolvedEnvironmentLight {
  light : EnvironmentMapLight
  weight : Float
}

///|
priv struct Mesh3dInstance {
  entity : @core.Entity
  mesh_id : Int
  transform : @math.Transform
  previous_transform : @math.Transform
  visibility_range : @visibility.VisibilityRange?
  aabb_center_world : @math.Vec3?
  material : StandardMaterial
  layers : @render2d.RenderLayers
}

///|
priv struct RenderTargetComputed3d {
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
}

///|
priv struct Render3dLightingState {
  ambient_color : @render2d.Color
  ambient_brightness : Float
  directional_dir : @math.Vec3
  directional_color : @render2d.Color
  directional_illuminance : Float
  point_pos : @math.Vec3
  point_color : @render2d.Color
  point_intensity : Float
  point_range : Float
  spot_pos : @math.Vec3
  spot_dir : @math.Vec3
  spot_color : @render2d.Color
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
}

///|
priv struct MotionBlurHistoryEntry {
  entity : @core.Entity
  transform : @math.Transform
}

///|
priv struct CameraMotionBlurHistoryEntry {
  entity : @core.Entity
  transform : @math.Transform
}

///|
priv struct MotionBlurTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  scene_target_id : Int
  velocity_target_id : Int
}

///|
let motion_blur_history : Ref[Array[MotionBlurHistoryEntry]] = Ref::new([])

///|
let camera_motion_blur_history : Ref[Array[CameraMotionBlurHistoryEntry]] = Ref::new([],
)

///|
let motion_blur_targets : Ref[Array[MotionBlurTargetsEntry]] = Ref::new([])

///|
fn cmp_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn cmp_float(a : Float, b : Float) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn render3d_target_info(
  target : @render2d.RenderTarget,
) -> RenderTargetComputed3d? {
  match target {
    @render2d.RenderTarget::Screen => {
      let width = @window.window_width()
      let height = @window.window_height()
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor()
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some(RenderTargetComputed3d::{
        target_id: -1,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    @render2d.RenderTarget::Image(handle) => {
      let width = @asset.asset_texture_width(handle)
      let height = @asset.asset_texture_height(handle)
      if width <= 0 || height <= 0 {
        return None
      }
      Some(RenderTargetComputed3d::{
        target_id: handle.id(),
        target_size: @math.IVec2::new(width, height),
        scale_factor: 1.0F,
      })
    }
  }
}

///|
fn render3d_clamp_viewport(
  viewport : @render2d.Viewport,
  target_size : @math.IVec2,
) -> @render2d.Viewport {
  let mut position_x = viewport.physical_position.x
  let mut position_y = viewport.physical_position.y
  let mut size_x = viewport.physical_size.x
  let mut size_y = viewport.physical_size.y
  if position_x < 0 {
    position_x = 0
  }
  if position_y < 0 {
    position_y = 0
  }
  if size_x < 0 {
    size_x = 0
  }
  if size_y < 0 {
    size_y = 0
  }
  let max_width = if target_size.x - position_x < 0 {
    0
  } else {
    target_size.x - position_x
  }
  let max_height = if target_size.y - position_y < 0 {
    0
  } else {
    target_size.y - position_y
  }
  if size_x > max_width {
    size_x = max_width
  }
  if size_y > max_height {
    size_y = max_height
  }
  @render2d.Viewport::new(
    @math.IVec2::new(position_x, position_y),
    @math.IVec2::new(size_x, size_y),
  )
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn render3d_transform_forward(transform : @math.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
fn render3d_default_lighting_state() -> Render3dLightingState {
  Render3dLightingState::{
    ambient_color: @render2d.Color::white(),
    ambient_brightness: 0.0F,
    directional_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    directional_color: @render2d.Color::white(),
    directional_illuminance: 0.0F,
    point_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    point_color: @render2d.Color::white(),
    point_intensity: 0.0F,
    point_range: 1.0F,
    spot_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    spot_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    spot_color: @render2d.Color::white(),
    spot_intensity: 0.0F,
    spot_range: 1.0F,
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
  }
}

///|
fn motion_blur_history_get(entity : @core.Entity) -> @math.Transform? {
  for item in motion_blur_history.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      return Some(item.transform)
    }
  }
  None
}

///|
fn motion_blur_history_sync(meshes : Array[Mesh3dInstance]) -> Unit {
  let next : Array[MotionBlurHistoryEntry] = []
  for mesh in meshes {
    next.push({ entity: mesh.entity, transform: mesh.transform })
  }
  motion_blur_history.val = next
}

///|
fn camera_motion_blur_history_get(entity : @core.Entity) -> @math.Transform? {
  for item in camera_motion_blur_history.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      return Some(item.transform)
    }
  }
  None
}

///|
fn camera_motion_blur_history_sync(cameras : Array[Camera3dInstance]) -> Unit {
  let next : Array[CameraMotionBlurHistoryEntry] = []
  for camera in cameras {
    next.push({ entity: camera.entity, transform: camera.transform })
  }
  camera_motion_blur_history.val = next
}

///|
fn render3d_motion_blur_targets_get_or_create(
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> (Int, Int) {
  for item in motion_blur_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return (item.scene_target_id, item.velocity_target_id)
    }
  }
  let scene_target_id = @window.host_gpu_create_render_target(
    width~,
    height~,
    nearest=false,
  )
  let velocity_target_id = @window.host_gpu_create_render_target(
    width~,
    height~,
    nearest=false,
  )
  let next : Array[MotionBlurTargetsEntry] = []
  let mut replaced = false
  for item in motion_blur_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, width, height, scene_target_id, velocity_target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, width, height, scene_target_id, velocity_target_id })
  }
  motion_blur_targets.val = next
  (scene_target_id, velocity_target_id)
}

///|
fn[
  W : HasRes_GlobalAmbientLight + Has_PointLight + Has_DirectionalLight + Has_SpotLight + @math.Has_Transform,
] render3d_collect_lighting(
  world : W,
) -> Render3dLightingState {
  let mut lighting = render3d_default_lighting_state()
  if world.get_global_ambient_light_resource().get_ref() is Some(ambient) {
    lighting = Render3dLightingState::{
      ..lighting,
      ambient_color: ambient.val.color,
      ambient_brightness: ambient.val.brightness,
    }
  }
  let transform_store = world.get_transform_store()
  let mut directional_found = false
  world
  .get_directional_light_store()
  .for_each(fn(entity, light) {
    if directional_found {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @math.Transform::identity()
    }
    directional_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      directional_dir: render3d_transform_forward(transform),
      directional_color: light.color,
      directional_illuminance: light.illuminance,
    }
  })
  let mut point_found = false
  world
  .get_point_light_store()
  .for_each(fn(entity, light) {
    if point_found {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @math.Transform::identity()
    }
    point_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      point_pos: transform.translation,
      point_color: light.color,
      point_intensity: light.intensity,
      point_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
    }
  })
  let mut spot_found = false
  world
  .get_spot_light_store()
  .for_each(fn(entity, light) {
    if spot_found {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @math.Transform::identity()
    }
    let inner = light.inner_angle
    let mut outer = light.outer_angle
    if outer < inner {
      outer = inner
    }
    spot_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      spot_pos: transform.translation,
      spot_dir: render3d_transform_forward(transform),
      spot_color: light.color,
      spot_intensity: light.intensity,
      spot_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
      spot_inner_angle: inner,
      spot_outer_angle: outer,
    }
  })
  lighting
}

///|
fn render3d_generated_environment_map_to_light(
  generated : GeneratedEnvironmentMapLight,
) -> EnvironmentMapLight {
  EnvironmentMapLight::default()
  .with_diffuse_map(generated.environment_map)
  .with_specular_map(generated.environment_map)
  .with_intensity(generated.intensity)
  .with_rotation(generated.rotation)
  .with_affects_lightmapped_mesh_diffuse(
    generated.affects_lightmapped_mesh_diffuse,
  )
}

///|
fn render3d_camera_environment_map_light(
  camera : Camera3dInstance,
) -> EnvironmentMapLight? {
  if camera.generated_environment_map_light is Some(generated) {
    return Some(render3d_generated_environment_map_to_light(generated))
  }
  camera.environment_map_light
}

///|
fn render3d_draw_camera_skybox(
  camera : Camera3dInstance,
  camera_far : Float,
) -> Unit {
  guard camera.skybox is Some(skybox) else { return }
  guard skybox.image is Some(image) else { return }
  let mesh_id = render3d_skybox_proxy_mesh_id()
  if mesh_id <= 0 {
    return
  }
  let brightness = maxf(0.0F, skybox.brightness)
  let skybox_extent = maxf(5.0F, minf(camera_far * 0.45F, 20_000.0F))
  // Negative uv_scale_y marks stacked-vertical cubemap sampling in mesh3d.wgsl.
  @window.host_gpu_draw_mesh3d(
    mesh_id~,
    x=camera.transform.translation.x,
    y=camera.transform.translation.y,
    z=camera.transform.translation.z,
    rotation_x=skybox.rotation.x,
    rotation_y=skybox.rotation.y,
    rotation_z=skybox.rotation.z,
    rotation_w=skybox.rotation.w,
    scale_x=skybox_extent,
    scale_y=skybox_extent,
    scale_z=skybox_extent,
    previous_x=camera.previous_transform.translation.x,
    previous_y=camera.previous_transform.translation.y,
    previous_z=camera.previous_transform.translation.z,
    previous_rotation_x=camera.previous_transform.rotation.x,
    previous_rotation_y=camera.previous_transform.rotation.y,
    previous_rotation_z=camera.previous_transform.rotation.z,
    previous_rotation_w=camera.previous_transform.rotation.w,
    previous_scale_x=camera.previous_transform.scale.x,
    previous_scale_y=camera.previous_transform.scale.y,
    previous_scale_z=camera.previous_transform.scale.z,
    color_r=brightness,
    color_g=brightness,
    color_b=brightness,
    color_a=1.0F,
    texture_id=image.id(),
    uv_offset_x=0.0F,
    uv_offset_y=0.0F,
    uv_scale_x=1.0F,
    uv_scale_y=-1.0F,
    normal_texture_id=-1,
    emissive_texture_id=-1,
    metallic_roughness_texture_id=-1,
    occlusion_texture_id=-1,
    depth_texture_id=-1,
    emissive_r=0.0F,
    emissive_g=0.0F,
    emissive_b=0.0F,
    unlit=1.0F,
    metallic=0.0F,
    roughness=1.0F,
    reflectance=0.0F,
    parallax_depth_scale=0.0F,
    max_parallax_layer_count=0.0F,
    max_relief_mapping_search_steps=0.0F,
    anisotropy_texture_id=-1,
    anisotropy_strength=0.0F,
    anisotropy_rotation=0.0F,
  )
}

///|
fn render3d_probe_weight(
  probe : ReflectionProbeInstance,
  world_position : @math.Vec3,
) -> Float {
  let distance = world_position.sub(probe.transform.translation).length()
  let fx = absf(probe.light_probe.falloff.x)
  let fy = absf(probe.light_probe.falloff.y)
  let fz = absf(probe.light_probe.falloff.z)
  let radius = maxf(0.001F, maxf(fx, maxf(fy, fz)))
  clamp01(1.0F - distance / radius)
}

///|
fn render3d_probe_environment_map_light(
  probes : Array[ReflectionProbeInstance],
  world_position : @math.Vec3,
) -> ResolvedEnvironmentLight? {
  let mut best : ResolvedEnvironmentLight? = None
  for probe in probes {
    let weight = render3d_probe_weight(probe, world_position)
    if weight <= 0.0F {
      continue
    }
    let weighted_intensity = probe.environment_map_light.intensity * weight
    if weighted_intensity <= 0.0F {
      continue
    }
    if best is Some(current) && current.weight >= weight {
      continue
    }
    best = Some(ResolvedEnvironmentLight::{
      light: probe.environment_map_light,
      weight,
    })
  }
  best
}

///|
fn render3d_environment_strength(
  environment_map_light : EnvironmentMapLight?,
  probe_light : ResolvedEnvironmentLight?,
) -> (Float, Bool) {
  let mut total_intensity = 0.0F
  let mut affects_diffuse = false
  if environment_map_light is Some(light) {
    total_intensity = total_intensity + maxf(0.0F, light.intensity)
    affects_diffuse = affects_diffuse || light.affects_lightmapped_mesh_diffuse
  }
  if probe_light is Some(resolved) {
    total_intensity = total_intensity +
      maxf(0.0F, resolved.light.intensity) * resolved.weight
    affects_diffuse = affects_diffuse ||
      resolved.light.affects_lightmapped_mesh_diffuse
  }
  (clamp01(total_intensity / 5000.0F), affects_diffuse)
}

///|
fn render3d_sorted_camera_indices(
  cameras : Array[Camera3dInstance],
) -> Array[Int] {
  let order : Array[Int] = []
  for i in 0..<cameras.length() {
    order.push(i)
  }
  order.sort_by(fn(a, b) {
    let ca = cameras[a]
    let cb = cameras[b]
    let order_cmp = cmp_int(ca.camera.order, cb.camera.order)
    if order_cmp != 0 {
      return order_cmp
    }
    let id_cmp = cmp_int(ca.entity.id, cb.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(ca.entity.generation, cb.entity.generation)
  })
  order
}

///|
fn render3d_mesh_alpha_phase(alpha_mode : AlphaMode3d, alpha : Float) -> Int? {
  match alpha_mode {
    Opaque => Some(0)
    Blend => Some(if alpha >= 1.0F { 0 } else { 1 })
    Premultiplied => Some(if alpha >= 1.0F { 0 } else { 1 })
    Add => Some(1)
    Multiply => Some(if alpha >= 1.0F { 0 } else { 1 })
    AlphaToCoverage => Some(if alpha >= 1.0F { 0 } else { 1 })
    Mask(cutoff) => if alpha >= cutoff { Some(0) } else { None }
  }
}

///|
fn render3d_mesh_draw_alpha(alpha_mode : AlphaMode3d, alpha : Float) -> Float? {
  match alpha_mode {
    Opaque => Some(1.0F)
    Blend => Some(alpha)
    Premultiplied => Some(alpha)
    Add => Some(alpha)
    Multiply => Some(alpha)
    AlphaToCoverage => Some(alpha)
    Mask(cutoff) => if alpha >= cutoff { Some(1.0F) } else { None }
  }
}

///|
fn render3d_projection_params(
  projection : CameraProjection3d,
  aspect_ratio : Float,
  viewport_height_logical : Float,
) -> (Float, Float, Float) {
  let safe_aspect = if aspect_ratio <= 0.0F { 1.0F } else { aspect_ratio }
  let safe_view_height = if viewport_height_logical <= 0.0F {
    1.0F
  } else {
    viewport_height_logical
  }
  match projection.projection {
    Perspective(perspective) => {
      let p = perspective.with_aspect_ratio(safe_aspect)
      (p.fov, p.near, p.far)
    }
    Orthographic(orthographic) => {
      let safe_scale = if orthographic.scale <= 0.0F {
        1.0F
      } else {
        orthographic.scale
      }
      // Encode orthographic mode via negative `camera_fov_y` and pass world-space
      // half-height through its magnitude. Runtime shaders decode this sentinel.
      let half_height = 0.5F * safe_view_height * safe_scale
      let safe_half_height = if half_height <= 0.0F {
        0.5F
      } else {
        half_height
      }
      (-safe_half_height, orthographic.near, orthographic.far)
    }
  }
}

///|
fn render3d_sub_camera_projection_params(
  sub_camera_view : SubCameraView3d?,
  view_width : Int,
  view_height : Int,
) -> (Float, Float, Float, Float, Float) {
  let width_f = Float::from_double(view_width.to_double())
  let height_f = Float::from_double(view_height.to_double())
  let default_aspect = if width_f > 0.0F && height_f > 0.0F {
    width_f / height_f
  } else {
    1.0F
  }
  guard sub_camera_view is Some(sub_view) else {
    return (default_aspect, 1.0F, 1.0F, 0.0F, 0.0F)
  }
  let full_width = Float::from_double(sub_view.full_size.x.to_double())
  let full_height = Float::from_double(sub_view.full_size.y.to_double())
  let size_width = Float::from_double(sub_view.size.x.to_double())
  let size_height = Float::from_double(sub_view.size.y.to_double())
  if full_width <= 0.0F ||
    full_height <= 0.0F ||
    size_width <= 0.0F ||
    size_height <= 0.0F {
    return (default_aspect, 1.0F, 1.0F, 0.0F, 0.0F)
  }
  let scale_x = full_width / size_width
  let scale_y = full_height / size_height
  let bias_x = (full_width - 2.0F * sub_view.offset.x - size_width) / size_width
  let bias_y = (2.0F * sub_view.offset.y + size_height - full_height) /
    size_height
  let aspect_ratio = full_width / full_height
  (aspect_ratio, scale_x, scale_y, bias_x, bias_y)
}

///|
fn render3d_mesh_view_depth(
  mesh_transform : @math.Transform,
  camera_transform : @math.Transform,
) -> Float {
  let to_mesh = @math.Vec3::new(
    mesh_transform.translation.x - camera_transform.translation.x,
    mesh_transform.translation.y - camera_transform.translation.y,
    mesh_transform.translation.z - camera_transform.translation.z,
  )
  let camera_forward = render3d_transform_forward(camera_transform)
  to_mesh.x * camera_forward.x +
  to_mesh.y * camera_forward.y +
  to_mesh.z * camera_forward.z
}

///|
fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn render3d_rotate_by_quat(v : @math.Vec3, q : @math.Quat) -> @math.Vec3 {
  let q_vec = @math.Vec3::new(q.x, q.y, q.z)
  let t = q_vec.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(q_vec.cross(t))
}

///|
fn render3d_transform_point(
  transform : @math.Transform,
  local_point : @math.Vec3,
) -> @math.Vec3 {
  let scaled = local_point.mul(transform.scale)
  transform.translation.add(render3d_rotate_by_quat(scaled, transform.rotation))
}

///|
fn render3d_mesh_local_aabb_center(mesh3d : Mesh3d) -> @math.Vec3? {
  guard @render2d.render_mesh_asset_get(mesh3d.mesh) is Some(mesh_asset) else {
    return None
  }
  guard mesh_asset.geometry is @mesh.MeshGeometry::Geometry3d(geometry3d) else {
    return None
  }
  guard geometry3d.positions.length() > 0 else { return None }
  let mut min_x = geometry3d.positions[0].x
  let mut min_y = geometry3d.positions[0].y
  let mut min_z = geometry3d.positions[0].z
  let mut max_x = geometry3d.positions[0].x
  let mut max_y = geometry3d.positions[0].y
  let mut max_z = geometry3d.positions[0].z
  for i in 1..<geometry3d.positions.length() {
    let p = geometry3d.positions[i]
    min_x = minf(min_x, p.x)
    min_y = minf(min_y, p.y)
    min_z = minf(min_z, p.z)
    max_x = maxf(max_x, p.x)
    max_y = maxf(max_y, p.y)
    max_z = maxf(max_z, p.z)
  }
  Some(
    @math.Vec3::new(
      (min_x + max_x) * 0.5F,
      (min_y + max_y) * 0.5F,
      (min_z + max_z) * 0.5F,
    ),
  )
}

///|
fn render3d_world_position_uv(
  camera : Camera3dInstance,
  viewport_rect : (Float, Float, Float, Float)?,
  world_position : @math.Vec3,
) -> @math.Vec2? {
  guard viewport_rect
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  if viewport_width <= 0.0F || viewport_height <= 0.0F {
    return None
  }
  guard render3d_camera_world_to_viewport(
      world_position,
      camera.camera,
      camera.projection,
      camera.transform,
      camera.target_size,
      camera.scale_factor,
    )
    is Some(screen) else {
    return None
  }
  let uv_x = (screen.x - viewport_x) / viewport_width
  let uv_y = (screen.y - viewport_y) / viewport_height
  Some(@math.Vec2::new(clamp01(uv_x), clamp01(uv_y)))
}

///|
fn render3d_chromatic_aberration_amount(
  chromatic_aberration : ChromaticAberration,
  screen_uv : @math.Vec2,
) -> Float {
  let safe_intensity = if chromatic_aberration.intensity < 0.0F {
    0.0F
  } else {
    chromatic_aberration.intensity
  }
  if safe_intensity <= 0.0F {
    return 0.0F
  }
  let sample_factor = clamp01(
    Float::from_double(chromatic_aberration.max_samples.to_double()) / 64.0F,
  )
  let edge_x = absf(screen_uv.x - 0.5F) * 2.0F
  let edge_y = absf(screen_uv.y - 0.5F) * 2.0F
  let edge_factor = clamp01(maxf(edge_x, edge_y))
  let intensity_factor = clamp01(safe_intensity / 0.4F)
  clamp01(sample_factor * edge_factor * intensity_factor)
}

///|
fn render3d_vignette_mask(
  vignette : Vignette,
  screen_uv : @math.Vec2,
  aspect_ratio : Float,
) -> Float {
  let safe_intensity = if vignette.intensity < 0.0F {
    0.0F
  } else {
    vignette.intensity
  }
  if safe_intensity <= 0.0F {
    return 0.0F
  }
  let safe_radius = if vignette.radius < 0.0001F {
    0.0001F
  } else {
    vignette.radius
  }
  let safe_smoothness = if vignette.smoothness <= 0.01F {
    0.01F
  } else {
    vignette.smoothness
  }
  let safe_roundness = if vignette.roundness <= 0.01F {
    0.01F
  } else {
    vignette.roundness
  }
  let safe_aspect_ratio = if aspect_ratio <= 0.0001F {
    1.0F
  } else {
    aspect_ratio
  }
  let fit = if vignette.edge_compensation < 0.0F {
    0.0F
  } else if vignette.edge_compensation > 1.0F {
    1.0F
  } else {
    vignette.edge_compensation
  }
  let aspect_scale_x = 1.0F + (safe_aspect_ratio - 1.0F) * fit
  let dx = (screen_uv.x - vignette.center.x) * 2.0F * aspect_scale_x
  let dy = (screen_uv.y - vignette.center.y) * 2.0F
  let ellipse_distance = @math.sqrt(
    dx * dx + dy * dy * safe_roundness * safe_roundness,
  )
  let edge = clamp01((ellipse_distance - safe_radius) * safe_smoothness)
  clamp01(edge * safe_intensity)
}

///|

///|
fn render3d_ssr_ramp(value : Float, start : Float, end_ : Float) -> Float {
  let safe_start = minf(start, end_)
  let safe_end = maxf(start, end_)
  if safe_end <= safe_start + 0.000001F {
    if value >= safe_end {
      1.0F
    } else {
      0.0F
    }
  } else if value <= safe_start {
    0.0F
  } else if value >= safe_end {
    1.0F
  } else {
    (value - safe_start) / (safe_end - safe_start)
  }
}

///|
fn render3d_ssr_roughness_weight(
  ssr : ScreenSpaceReflections,
  roughness : Float,
) -> Float {
  let min_weight = render3d_ssr_ramp(
    roughness,
    ssr.min_perceptual_roughness_start,
    ssr.min_perceptual_roughness_end,
  )
  let max_fade = render3d_ssr_ramp(
    roughness,
    ssr.max_perceptual_roughness_start,
    ssr.max_perceptual_roughness_end,
  )
  clamp01(min_weight * (1.0F - max_fade))
}

///|
fn render3d_ssr_edge_weight(
  ssr : ScreenSpaceReflections,
  camera_transform : @math.Transform,
  camera_fov_y : Float,
  aspect_ratio : Float,
  mesh_translation : @math.Vec3,
) -> Float {
  let safe_fov_y = if camera_fov_y <= 0.0001F { 0.0001F } else { camera_fov_y }
  let safe_aspect_ratio = if aspect_ratio <= 0.0001F {
    1.0F
  } else {
    aspect_ratio
  }
  let half_fov = safe_fov_y * 0.5F
  let sin_half_fov = @math.sin(half_fov)
  let cos_half_fov = @math.cos(half_fov)
  if absf(cos_half_fov) <= 0.000001F {
    return 1.0F
  }
  let tan_half_fov = sin_half_fov / cos_half_fov
  if tan_half_fov <= 0.0001F {
    return 1.0F
  }

  let to_mesh = mesh_translation.sub(camera_transform.translation)
  let forward = render3d_transform_forward(camera_transform)
  let depth = to_mesh.dot(forward)
  if depth <= 0.0001F {
    return 0.0F
  }

  let right = quat_rotate_vec3(
    camera_transform.rotation,
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  ).normalize_or_zero()
  let up = quat_rotate_vec3(
    camera_transform.rotation,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  ).normalize_or_zero()

  let view_x = to_mesh.dot(right)
  let view_y = to_mesh.dot(up)
  let ndc_x = absf(view_x) / (depth * tan_half_fov * safe_aspect_ratio)
  let ndc_y = absf(view_y) / (depth * tan_half_fov)
  let ndc_max = maxf(ndc_x, ndc_y)
  let edge_distance = clamp01(1.0F - ndc_max)

  let edge_start = minf(ssr.edge_fadeout_start, ssr.edge_fadeout_end)
  let edge_end = maxf(ssr.edge_fadeout_start, ssr.edge_fadeout_end)
  if edge_end <= edge_start + 0.000001F {
    1.0F
  } else {
    render3d_ssr_ramp(edge_distance, edge_start, edge_end)
  }
}

///|
fn render3d_ssr_strength(
  ssr : ScreenSpaceReflections,
  roughness : Float,
  camera_transform : @math.Transform,
  camera_fov_y : Float,
  aspect_ratio : Float,
  mesh_translation : @math.Vec3,
) -> Float {
  let roughness_weight = render3d_ssr_roughness_weight(ssr, roughness)
  if roughness_weight <= 0.0F {
    return 0.0F
  }

  let edge_weight = render3d_ssr_edge_weight(
    ssr, camera_transform, camera_fov_y, aspect_ratio, mesh_translation,
  )
  if edge_weight <= 0.0F {
    return 0.0F
  }

  let steps = Float::from_double(
    (ssr.linear_steps + ssr.bisection_steps).to_double(),
  )
  let steps_factor = clamp01(steps / 20.0F)
  let thickness_factor = clamp01(ssr.thickness / 1.5F)
  let march_factor = clamp01(1.0F / ssr.linear_march_exponent)
  let secant_factor = if ssr.use_secant { 1.0F } else { 0.9F }
  clamp01(
    roughness_weight *
    edge_weight *
    clamp01(0.35F + steps_factor * 0.65F) *
    clamp01(0.4F + thickness_factor * 0.6F) *
    clamp01(0.75F + march_factor * 0.25F) *
    secant_factor,
  )
}

///|
fn render3d_pow_e(value : Float) -> Float {
  @math.pow(2.718281828459045F, value)
}

///|
fn render3d_fog_falloff_factor(
  falloff : FogFalloff3d,
  distance : Float,
) -> Float {
  let safe_distance = if distance < 0.0F { 0.0F } else { distance }
  match falloff {
    Linear(start, end_) => {
      let safe_start = if start < 0.0F { 0.0F } else { start }
      let safe_end = if end_ < safe_start { safe_start } else { end_ }
      if safe_end <= safe_start {
        if safe_distance >= safe_end {
          1.0F
        } else {
          0.0F
        }
      } else if safe_distance <= safe_start {
        0.0F
      } else if safe_distance >= safe_end {
        1.0F
      } else {
        (safe_distance - safe_start) / (safe_end - safe_start)
      }
    }
    Exponential(density) => {
      let safe_density = if density < 0.0F { 0.0F } else { density }
      1.0F - render3d_pow_e(-safe_density * safe_distance)
    }
    ExponentialSquared(density) => {
      let safe_density = if density < 0.0F { 0.0F } else { density }
      let d = safe_density * safe_distance
      1.0F - render3d_pow_e(-(d * d))
    }
  }
}

///|
fn render3d_distance_fog_mix_factor(
  fog : DistanceFog,
  distance : Float,
) -> Float {
  let falloff_factor = render3d_fog_falloff_factor(fog.falloff, distance)
  clamp01(falloff_factor * clamp01(fog.color.a))
}

///|
fn render3d_visibility_range_visible(
  visibility_range : @visibility.VisibilityRange,
  camera_transform : @math.Transform,
  mesh_transform : @math.Transform,
  mesh_aabb_center_world : @math.Vec3?,
) -> Bool {
  let mesh_position = if visibility_range.use_aabb {
    match mesh_aabb_center_world {
      Some(center) => center
      None => mesh_transform.translation
    }
  } else {
    mesh_transform.translation
  }
  let to_mesh = mesh_position.sub(camera_transform.translation)
  let distance = to_mesh.length()
  let near_bound = visibility_range.start_margin_min
  let far_bound = visibility_range.end_margin_max
  if far_bound < near_bound {
    return false
  }
  distance >= near_bound && distance < far_bound
}

///|
fn render3d_sorted_mesh_indices(
  meshes : Array[Mesh3dInstance],
  layers : @render2d.RenderLayers,
  camera_transform : @math.Transform,
) -> Array[Int] {
  let order : Array[Int] = []
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    if mesh.mesh_id <= 0 {
      continue
    }
    if !mesh.layers.matches(layers) {
      continue
    }
    if mesh.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        mesh.transform,
        mesh.aabb_center_world,
      ) {
      continue
    }
    if render3d_mesh_alpha_phase(
        mesh.material.alpha_mode,
        mesh.material.base_color.a,
      )
      is None {
      continue
    }
    order.push(i)
  }
  order.sort_by(fn(a, b) {
    let ma = meshes[a]
    let mb = meshes[b]
    let alpha_a = ma.material.base_color.a
    let alpha_b = mb.material.base_color.a
    let phase_a = render3d_mesh_alpha_phase(ma.material.alpha_mode, alpha_a).unwrap()
    let phase_b = render3d_mesh_alpha_phase(mb.material.alpha_mode, alpha_b).unwrap()
    let phase_cmp = cmp_int(phase_a, phase_b)
    if phase_cmp != 0 {
      return phase_cmp
    }
    let depth_a = render3d_mesh_view_depth(ma.transform, camera_transform)
    let depth_b = render3d_mesh_view_depth(mb.transform, camera_transform)
    if phase_a == 0 {
      let texture_a = match ma.material.base_color_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let texture_b = match mb.material.base_color_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let texture_cmp = cmp_int(texture_a, texture_b)
      if texture_cmp != 0 {
        return texture_cmp
      }
      let depth_cmp = cmp_float(depth_a, depth_b)
      if depth_cmp != 0 {
        return depth_cmp
      }
    } else {
      let depth_cmp = cmp_float(depth_b, depth_a)
      if depth_cmp != 0 {
        return depth_cmp
      }
    }
    let id_cmp = cmp_int(ma.entity.id, mb.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(ma.entity.generation, mb.entity.generation)
  })
  order
}

///|
fn free_camera_angles_from_transform(
  transform : @math.Transform,
) -> (Float, Float) {
  let forward = render3d_transform_forward(transform)
  let horizontal = @math.sqrt(forward.x * forward.x + forward.z * forward.z)
  let pitch = @math.atan2(forward.y, horizontal)
  let yaw = @math.atan2(-forward.x, -forward.z)
  (yaw, pitch)
}

///|
fn free_camera_clamp_pitch(pitch : Float) -> Float {
  let half_pi = @math.pi_half()
  if pitch < -half_pi {
    -half_pi
  } else if pitch > half_pi {
    half_pi
  } else {
    pitch
  }
}

///|
fn free_camera_exp_decay(rate : Float, delta_seconds : Float) -> Float {
  if rate <= 0.0F || delta_seconds <= 0.0F {
    return 1.0F
  }
  @math.pow(2.718281828459045F, -rate * delta_seconds)
}

///|
pub(open) trait FreeCameraControllerWorld: Has_FreeCamera + Has_FreeCameraState + @render2d.Has_Camera + @math.Has_Transform + @core.ChangeTickWorld {
}

///|
pub fn[W : FreeCameraControllerWorld] run_freecamera_controller(
  world : W,
) -> Unit {
  let delta_seconds = @time.time_delta_seconds()
  let tick = world.read_change_tick()
  let camera_store = world.get_camera_store()
  let transform_store = world.get_transform_store()
  let free_camera_store = world.get_free_camera_store()
  let free_camera_state_store = world.get_free_camera_state_store()
  let mut system_state = free_camera_system_state.val

  let controlled_entities : Array[@core.Entity] = []
  free_camera_store.for_each(fn(entity, _config) {
    if camera_store.get(entity) is None || transform_store.get(entity) is None {
      return
    }
    controlled_entities.push(entity)
  })
  if controlled_entities.length() != 1 {
    return
  }
  let controlled_entity = controlled_entities[0]

  guard free_camera_store.get(controlled_entity) is Some(config) else { return }
  guard transform_store.get(controlled_entity) is Some(initial_transform) else {
    return
  }
  let mut transform = initial_transform
  let mut state = match free_camera_state_store.get(controlled_entity) {
    Some(existing) => existing
    None => {
      let default_state = FreeCameraState::default()
      free_camera_state_store.insert(controlled_entity, default_state, tick)
      default_state
    }
  }

  if !state.initialized {
    let (yaw, pitch) = free_camera_angles_from_transform(transform)
    state = FreeCameraState::{ ..state, initialized: true, pitch, yaw }
  }

  if !state.enabled {
    if system_state.toggle_cursor_grab || system_state.mouse_cursor_grab {
      system_state = FreeCameraSystemState::{
        toggle_cursor_grab: false,
        mouse_cursor_grab: false,
        last_mouse_position: None,
      }
      @window.window_set_cursor_grab_mode(mode=@window.CursorGrabMode::GrabNone)
      @window.window_set_cursor_visible(visible=true)
    }
    free_camera_system_state.val = system_state
    free_camera_state_store.set(controlled_entity, state, tick) |> ignore
    return
  }

  let wheel = @input.mouse_wheel_delta()
  let mut speed_multiplier = state.speed_multiplier +
    wheel.y * config.scroll_factor
  if speed_multiplier < 0.0F {
    speed_multiplier = 0.0F
  }
  state = FreeCameraState::{ ..state, speed_multiplier, }

  let mut axis_input = @math.Vec3::zero()
  if @input.key_pressed(config.key_forward) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  }
  if @input.key_pressed(config.key_back) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 0.0F, -1.0F))
  }
  if @input.key_pressed(config.key_right) {
    axis_input = axis_input.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  }
  if @input.key_pressed(config.key_left) {
    axis_input = axis_input.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
  }
  if @input.key_pressed(config.key_up) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if @input.key_pressed(config.key_down) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  }

  let mut cursor_grab_change = false
  if @input.key_just_pressed(config.keyboard_key_toggle_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      toggle_cursor_grab: !system_state.toggle_cursor_grab,
    }
    cursor_grab_change = true
  }
  if @input.mouse_button_just_pressed(config.mouse_key_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      mouse_cursor_grab: true,
    }
    cursor_grab_change = true
  }
  if @input.mouse_button_just_released(config.mouse_key_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      mouse_cursor_grab: false,
    }
    cursor_grab_change = true
  }
  let cursor_grab = system_state.toggle_cursor_grab ||
    system_state.mouse_cursor_grab

  let mut velocity = state.velocity
  if axis_input.length_squared() > 0.0F {
    let base_speed = if @input.key_pressed(config.key_run) {
      config.run_speed
    } else {
      config.walk_speed
    }
    velocity = axis_input
      .normalize_or_zero()
      .mul_scalar(base_speed * state.speed_multiplier)
  } else {
    let friction = if config.friction < 0.0F { 0.0F } else { config.friction }
    let decay = free_camera_exp_decay(friction, delta_seconds)
    velocity = velocity.mul_scalar(decay)
    if velocity.length_squared() < 1.0e-6F {
      velocity = @math.Vec3::zero()
    }
  }
  state = FreeCameraState::{ ..state, velocity, }

  if velocity.length_squared() > 0.0F {
    let forward = render3d_transform_forward(transform)
    let right = quat_rotate_vec3(
      transform.rotation,
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
    ).normalize_or_zero()
    let movement = right
      .mul_scalar(velocity.x * delta_seconds)
      .add(
        @math.Vec3::new(0.0F, 1.0F, 0.0F).mul_scalar(velocity.y * delta_seconds),
      )
      .add(forward.mul_scalar(velocity.z * delta_seconds))
    transform = transform.with_translation(transform.translation.add(movement))
  }

  if cursor_grab_change {
    if cursor_grab {
      @window.window_set_cursor_grab_mode(
        mode=@window.CursorGrabMode::GrabLocked,
      )
      @window.window_set_cursor_visible(visible=false)
    } else {
      @window.window_set_cursor_grab_mode(mode=@window.CursorGrabMode::GrabNone)
      @window.window_set_cursor_visible(visible=true)
    }
  }

  if cursor_grab {
    match @input.mouse_position() {
      Some(mouse_position) => {
        let mouse_delta = match system_state.last_mouse_position {
          Some(last_position) => mouse_position.sub(last_position)
          None => @math.Vec2::new(0.0F, 0.0F)
        }
        system_state = FreeCameraSystemState::{
          ..system_state,
          last_mouse_position: Some(mouse_position),
        }
        if mouse_delta.x != 0.0F || mouse_delta.y != 0.0F {
          let pitch = free_camera_clamp_pitch(
            state.pitch -
            mouse_delta.y * FREE_CAMERA_RADIANS_PER_DOT * config.sensitivity,
          )
          let yaw = state.yaw -
            mouse_delta.x * FREE_CAMERA_RADIANS_PER_DOT * config.sensitivity
          let rotation = @math.Quat::from_rotation_y(yaw)
            .mul(@math.Quat::from_rotation_x(pitch))
            .normalize()
          transform = transform.with_rotation(rotation)
          state = FreeCameraState::{ ..state, pitch, yaw }
        }
      }
      None =>
        system_state = FreeCameraSystemState::{
          ..system_state,
          last_mouse_position: None,
        }
    }
  } else {
    system_state = FreeCameraSystemState::{
      ..system_state,
      last_mouse_position: None,
    }
  }

  free_camera_system_state.val = system_state
  transform_store.set(controlled_entity, transform, tick) |> ignore
  free_camera_state_store.set(controlled_entity, state, tick) |> ignore
}

///|
pub fn[W : FreeCameraControllerWorld] free_camera_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app.add_pre_update_system(run_freecamera_controller)
}

///|
pub(open) trait Render3dPrepareWorld: Has_Mesh3d + @render2d.Has_GpuMesh2d + @core.ChangeTickWorld {
}

///|
pub fn[W : Render3dPrepareWorld] render3d_prepare_system(world : W) -> Unit {
  let tick = world.read_change_tick()
  let mesh_store = world.get_mesh3d_store()
  let gpu_mesh_store = world.get_gpu_mesh2d_store()
  mesh_store.for_each(fn(entity, mesh) {
    if gpu_mesh_store.get(entity) is Some(_) {
      return
    }
    let mesh_id = @render2d.render2d_upload_mesh_handle(mesh.mesh)
    gpu_mesh_store.insert(entity, @render2d.GpuMesh2d::new(mesh_id), tick)
  })
}

///|
fn render3d_draw_mesh_instance(
  mesh : Mesh3dInstance,
  transform : @math.Transform,
  previous_transform : @math.Transform,
  draw_color_r : Float,
  draw_color_g : Float,
  draw_color_b : Float,
  draw_alpha : Float,
  texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  draw_surface_roughness : Float,
  draw_reflectance : Float,
  anisotropy_strength : Float,
  max_relief_mapping_search_steps : Float,
) -> Unit {
  @window.host_gpu_draw_mesh3d(
    mesh_id=mesh.mesh_id,
    x=transform.translation.x,
    y=transform.translation.y,
    z=transform.translation.z,
    rotation_x=transform.rotation.x,
    rotation_y=transform.rotation.y,
    rotation_z=transform.rotation.z,
    rotation_w=transform.rotation.w,
    scale_x=transform.scale.x,
    scale_y=transform.scale.y,
    scale_z=transform.scale.z,
    previous_x=previous_transform.translation.x,
    previous_y=previous_transform.translation.y,
    previous_z=previous_transform.translation.z,
    previous_rotation_x=previous_transform.rotation.x,
    previous_rotation_y=previous_transform.rotation.y,
    previous_rotation_z=previous_transform.rotation.z,
    previous_rotation_w=previous_transform.rotation.w,
    previous_scale_x=previous_transform.scale.x,
    previous_scale_y=previous_transform.scale.y,
    previous_scale_z=previous_transform.scale.z,
    color_r=draw_color_r,
    color_g=draw_color_g,
    color_b=draw_color_b,
    color_a=draw_alpha,
    texture_id~,
    uv_offset_x=mesh.material.uv_offset.x,
    uv_offset_y=mesh.material.uv_offset.y,
    uv_scale_x=mesh.material.uv_scale.x,
    uv_scale_y=mesh.material.uv_scale.y,
    normal_texture_id~,
    emissive_texture_id~,
    metallic_roughness_texture_id~,
    occlusion_texture_id~,
    depth_texture_id~,
    emissive_r=mesh.material.emissive.r,
    emissive_g=mesh.material.emissive.g,
    emissive_b=mesh.material.emissive.b,
    unlit=if mesh.material.unlit { 1.0F } else { 0.0F },
    metallic=mesh.material.metallic,
    roughness=draw_surface_roughness,
    reflectance=draw_reflectance,
    parallax_depth_scale=mesh.material.parallax_depth_scale,
    max_parallax_layer_count=mesh.material.max_parallax_layer_count,
    max_relief_mapping_search_steps~,
    anisotropy_texture_id~,
    anisotropy_strength~,
    anisotropy_rotation=mesh.material.anisotropy_rotation,
  )
}

///|
pub(open) trait Render3dExecuteWorld: HasRes_GlobalAmbientLight + Has_PointLight + Has_DirectionalLight + Has_SpotLight + Has_Camera3d + Has_CameraProjection3d + Has_SubCameraView3d + Has_ScreenSpaceReflections + Has_ChromaticAberration + Has_Vignette + Has_MotionBlur + Has_Skybox + Has_EnvironmentMapLight + Has_GeneratedEnvironmentMapLight + Has_LightProbe + Has_Mesh3d + Has_MeshMaterial3d + @render2d.Has_Camera + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @render2d.Has_GpuMesh2d + @math.Has_Transform + @visibility.Has_ViewVisibility + @visibility.Has_VisibilityRange + @core.ChangeTickWorld {
}

///|
pub fn[W : Render3dExecuteWorld] render3d_execute_system(world : W) -> Unit {
  let cameras : Array[Camera3dInstance] = []
  let meshes : Array[Mesh3dInstance] = []
  let reflection_probes : Array[ReflectionProbeInstance] = []
  let camera3d_store = world.get_camera3d_store()
  let camera_store = world.get_camera_store()
  let projection_store = world.get_camera_projection3d_store()
  let sub_camera_view_store = world.get_sub_camera_view3d_store()
  let screen_space_reflections_store = world.get_screen_space_reflections_store()
  let chromatic_aberration_store = world.get_chromatic_aberration_store()
  let vignette_store = world.get_vignette_store()
  let motion_blur_store = world.get_motion_blur_store()
  let skybox_store = world.get_skybox_store()
  let environment_map_light_store = world.get_environment_map_light_store()
  let generated_environment_map_light_store = world.get_generated_environment_map_light_store()
  let light_probe_store = world.get_light_probe_store()
  let target_store = world.get_render_target_store()
  let layers_store = world.get_render_layers_store()
  let transform_store = world.get_transform_store()
  let view_visibility_store = world.get_view_visibility_store()
  camera3d_store.for_each(fn(entity, _marker) {
    let camera = match camera_store.get(entity) {
      Some(v) => v
      None => @render2d.Camera::default()
    }
    let projection = match projection_store.get(entity) {
      Some(v) => v
      None => CameraProjection3d::default()
    }
    let sub_camera_view = sub_camera_view_store.get(entity)
    let screen_space_reflections = screen_space_reflections_store.get(entity)
    let chromatic_aberration = chromatic_aberration_store.get(entity)
    let vignette = vignette_store.get(entity)
    let motion_blur = motion_blur_store.get(entity)
    let skybox = skybox_store.get(entity)
    let environment_map_light = environment_map_light_store.get(entity)
    let generated_environment_map_light = generated_environment_map_light_store.get(
      entity,
    )
    let target = match target_store.get(entity) {
      Some(v) => v
      None => @render2d.RenderTarget::Screen
    }
    let layers = match layers_store.get(entity) {
      Some(v) => v
      None => @render2d.RenderLayers::default()
    }
    let transform = match transform_store.get(entity) {
      Some(v) => v
      None => @math.Transform::identity()
    }
    let previous_transform = match camera_motion_blur_history_get(entity) {
      Some(v) => v
      None => transform
    }
    match render3d_target_info(target) {
      Some(target_info) => {
        let mut camera_clamped = camera
        if camera.viewport is Some(viewport) {
          let clamped = render3d_clamp_viewport(
            viewport,
            target_info.target_size,
          )
          camera_clamped = camera.with_viewport(clamped)
        }
        cameras.push(Camera3dInstance::{
          entity,
          camera: camera_clamped,
          projection,
          sub_camera_view,
          screen_space_reflections,
          chromatic_aberration,
          vignette,
          motion_blur,
          skybox,
          environment_map_light,
          generated_environment_map_light,
          transform,
          previous_transform,
          target_id: target_info.target_id,
          target_size: target_info.target_size,
          scale_factor: target_info.scale_factor,
          layers,
        })
      }
      None => ()
    }
  })
  if cameras.length() == 0 {
    return
  }
  let mesh_store = world.get_mesh3d_store()
  let material_store = world.get_mesh_material3d_store()
  let gpu_mesh_store = world.get_gpu_mesh2d_store()
  let visibility_range_store = world.get_visibility_range_store()
  mesh_store.for_each(fn(entity, mesh3d) {
    if view_visibility_store.get(entity) is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard gpu_mesh_store.get(entity) is Some(gpu_mesh) else { return }
    guard material_store.get(entity) is Some(material_handle) else { return }
    guard standard_material_get(material_handle.material) is Some(material) else {
      return
    }
    let layers = match layers_store.get(entity) {
      Some(v) => v
      None => @render2d.RenderLayers::default()
    }
    let transform = match transform_store.get(entity) {
      Some(v) => v
      None => @math.Transform::identity()
    }
    let previous_transform = match motion_blur_history_get(entity) {
      Some(v) => v
      None => transform
    }
    let visibility_range = visibility_range_store.get(entity)
    let aabb_center_world = if visibility_range is Some(range) && range.use_aabb {
      match render3d_mesh_local_aabb_center(mesh3d) {
        Some(local_center) =>
          Some(render3d_transform_point(transform, local_center))
        None => None
      }
    } else {
      None
    }
    meshes.push(Mesh3dInstance::{
      entity,
      mesh_id: gpu_mesh.mesh_id,
      transform,
      previous_transform,
      visibility_range,
      aabb_center_world,
      material,
      layers,
    })
  })
  light_probe_store.for_each(fn(entity, light_probe) {
    guard environment_map_light_store.get(entity) is Some(environment_map_light) else {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @math.Transform::identity()
    }
    reflection_probes.push(ReflectionProbeInstance::{
      transform,
      light_probe,
      environment_map_light,
    })
  })
  motion_blur_history_sync(meshes)
  camera_motion_blur_history_sync(cameras)
  let lighting = render3d_collect_lighting(world)
  for camera_index in render3d_sorted_camera_indices(cameras) {
    let camera = cameras[camera_index]
    let target_width = camera.target_size.x
    let target_height = camera.target_size.y
    if target_width <= 0 || target_height <= 0 {
      continue
    }
    let mut viewport_x = 0
    let mut viewport_y = 0
    let mut viewport_width = target_width
    let mut viewport_height = target_height
    let mut view_width = target_width
    let mut view_height = target_height
    if camera.camera.viewport is Some(viewport) {
      viewport_x = viewport.physical_position.x
      viewport_y = viewport.physical_position.y
      viewport_width = viewport.physical_size.x
      viewport_height = viewport.physical_size.y
      if viewport_width <= 0 || viewport_height <= 0 {
        continue
      }
      view_width = viewport_width
      view_height = viewport_height
    }
    let mut scale_factor = camera.scale_factor
    if scale_factor <= 0.0F {
      scale_factor = 1.0F
    }
    let view_width_f = Float::from_double(view_width.to_double()) / scale_factor
    let view_height_f = Float::from_double(view_height.to_double()) /
      scale_factor
    let view_width_logical = view_width_f.to_int()
    let view_height_logical = view_height_f.to_int()
    if view_width_logical <= 0 || view_height_logical <= 0 {
      continue
    }
    let (
      aspect_ratio,
      sub_camera_view_scale_x,
      sub_camera_view_scale_y,
      sub_camera_view_bias_x,
      sub_camera_view_bias_y,
    ) = render3d_sub_camera_projection_params(
      camera.sub_camera_view,
      view_width,
      view_height,
    )
    let (camera_fov_y, camera_near, camera_far) = render3d_projection_params(
      camera.projection,
      aspect_ratio,
      Float::from_double(view_height_logical.to_double()),
    )
    let viewport_rect = render3d_camera_viewport_rect_logical(
      camera.camera,
      camera.target_size,
      camera.scale_factor,
    )
    let camera_environment_map_light = render3d_camera_environment_map_light(
      camera,
    )
    let mut pass_lighting = lighting
    if camera_environment_map_light is Some(environment_map_light) &&
      environment_map_light.affects_lightmapped_mesh_diffuse {
      pass_lighting = Render3dLightingState::{
        ..pass_lighting,
        ambient_brightness: pass_lighting.ambient_brightness +
        maxf(0.0F, environment_map_light.intensity) / 10_000.0F,
      }
    }
    let (clear_enabled, clear_color) = camera.camera.clear_color.resolve()
    let motion_blur_active = if camera.motion_blur is Some(motion_blur) {
      motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F
    } else {
      false
    }
    let mut scene_target_id = camera.target_id
    let mut velocity_target_id = -1
    if motion_blur_active {
      let (scene_id, velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera.entity,
        view_width,
        view_height,
      )
      scene_target_id = scene_id
      velocity_target_id = velocity_id
      @window.host_gpu_begin_pass_3d(
        target_id=velocity_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=0.5F,
        clear_g=0.5F,
        clear_b=0.0F,
        clear_a=1.0F,
        camera_x=camera.transform.translation.x,
        camera_y=camera.transform.translation.y,
        camera_z=camera.transform.translation.z,
        camera_rot_x=camera.transform.rotation.x,
        camera_rot_y=camera.transform.rotation.y,
        camera_rot_z=camera.transform.rotation.z,
        camera_rot_w=camera.transform.rotation.w,
        camera_fov_y~,
        camera_near~,
        camera_far~,
        viewport_x~,
        viewport_y~,
        viewport_width~,
        viewport_height~,
        ambient_r=pass_lighting.ambient_color.r,
        ambient_g=pass_lighting.ambient_color.g,
        ambient_b=pass_lighting.ambient_color.b,
        ambient_brightness=pass_lighting.ambient_brightness,
        directional_dir_x=pass_lighting.directional_dir.x,
        directional_dir_y=pass_lighting.directional_dir.y,
        directional_dir_z=pass_lighting.directional_dir.z,
        directional_color_r=pass_lighting.directional_color.r,
        directional_color_g=pass_lighting.directional_color.g,
        directional_color_b=pass_lighting.directional_color.b,
        directional_illuminance=pass_lighting.directional_illuminance,
        point_pos_x=pass_lighting.point_pos.x,
        point_pos_y=pass_lighting.point_pos.y,
        point_pos_z=pass_lighting.point_pos.z,
        point_color_r=pass_lighting.point_color.r,
        point_color_g=pass_lighting.point_color.g,
        point_color_b=pass_lighting.point_color.b,
        point_intensity=pass_lighting.point_intensity,
        point_range=pass_lighting.point_range,
        spot_pos_x=pass_lighting.spot_pos.x,
        spot_pos_y=pass_lighting.spot_pos.y,
        spot_pos_z=pass_lighting.spot_pos.z,
        spot_dir_x=pass_lighting.spot_dir.x,
        spot_dir_y=pass_lighting.spot_dir.y,
        spot_dir_z=pass_lighting.spot_dir.z,
        spot_color_r=pass_lighting.spot_color.r,
        spot_color_g=pass_lighting.spot_color.g,
        spot_color_b=pass_lighting.spot_color.b,
        spot_intensity=pass_lighting.spot_intensity,
        spot_range=pass_lighting.spot_range,
        spot_inner_angle=pass_lighting.spot_inner_angle,
        spot_outer_angle=pass_lighting.spot_outer_angle,
        sub_camera_view_scale_x~,
        sub_camera_view_scale_y~,
        sub_camera_view_bias_x~,
        sub_camera_view_bias_y~,
        previous_camera_x=camera.previous_transform.translation.x,
        previous_camera_y=camera.previous_transform.translation.y,
        previous_camera_z=camera.previous_transform.translation.z,
        previous_camera_rot_x=camera.previous_transform.rotation.x,
        previous_camera_rot_y=camera.previous_transform.rotation.y,
        previous_camera_rot_z=camera.previous_transform.rotation.z,
        previous_camera_rot_w=camera.previous_transform.rotation.w,
        pass_kind=1,
        clear_enabled=1,
      )
      let velocity_draw_order = render3d_sorted_mesh_indices(
        meshes,
        camera.layers,
        camera.transform,
      )
      for draw_index in velocity_draw_order {
        let mesh = meshes[draw_index]
        guard render3d_mesh_draw_alpha(
            mesh.material.alpha_mode,
            mesh.material.base_color.a,
          )
          is Some(draw_alpha) else {
          continue
        }
        if draw_alpha < 0.999F {
          continue
        }
        render3d_draw_mesh_instance(
          mesh,
          mesh.transform,
          mesh.previous_transform,
          1.0F,
          1.0F,
          1.0F,
          1.0F,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          0.5F,
          0.5F,
          0.0F,
          0.0F,
        )
      }
      @window.host_gpu_end_pass()
    }
    @window.host_gpu_begin_pass_3d(
      target_id=scene_target_id,
      width=view_width_logical,
      height=view_height_logical,
      clear_r=clear_color.r,
      clear_g=clear_color.g,
      clear_b=clear_color.b,
      clear_a=clear_color.a,
      camera_x=camera.transform.translation.x,
      camera_y=camera.transform.translation.y,
      camera_z=camera.transform.translation.z,
      camera_rot_x=camera.transform.rotation.x,
      camera_rot_y=camera.transform.rotation.y,
      camera_rot_z=camera.transform.rotation.z,
      camera_rot_w=camera.transform.rotation.w,
      camera_fov_y~,
      camera_near~,
      camera_far~,
      viewport_x~,
      viewport_y~,
      viewport_width~,
      viewport_height~,
      ambient_r=pass_lighting.ambient_color.r,
      ambient_g=pass_lighting.ambient_color.g,
      ambient_b=pass_lighting.ambient_color.b,
      ambient_brightness=pass_lighting.ambient_brightness,
      directional_dir_x=pass_lighting.directional_dir.x,
      directional_dir_y=pass_lighting.directional_dir.y,
      directional_dir_z=pass_lighting.directional_dir.z,
      directional_color_r=pass_lighting.directional_color.r,
      directional_color_g=pass_lighting.directional_color.g,
      directional_color_b=pass_lighting.directional_color.b,
      directional_illuminance=pass_lighting.directional_illuminance,
      point_pos_x=pass_lighting.point_pos.x,
      point_pos_y=pass_lighting.point_pos.y,
      point_pos_z=pass_lighting.point_pos.z,
      point_color_r=pass_lighting.point_color.r,
      point_color_g=pass_lighting.point_color.g,
      point_color_b=pass_lighting.point_color.b,
      point_intensity=pass_lighting.point_intensity,
      point_range=pass_lighting.point_range,
      spot_pos_x=pass_lighting.spot_pos.x,
      spot_pos_y=pass_lighting.spot_pos.y,
      spot_pos_z=pass_lighting.spot_pos.z,
      spot_dir_x=pass_lighting.spot_dir.x,
      spot_dir_y=pass_lighting.spot_dir.y,
      spot_dir_z=pass_lighting.spot_dir.z,
      spot_color_r=pass_lighting.spot_color.r,
      spot_color_g=pass_lighting.spot_color.g,
      spot_color_b=pass_lighting.spot_color.b,
      spot_intensity=pass_lighting.spot_intensity,
      spot_range=pass_lighting.spot_range,
      spot_inner_angle=pass_lighting.spot_inner_angle,
      spot_outer_angle=pass_lighting.spot_outer_angle,
      sub_camera_view_scale_x~,
      sub_camera_view_scale_y~,
      sub_camera_view_bias_x~,
      sub_camera_view_bias_y~,
      previous_camera_x=camera.previous_transform.translation.x,
      previous_camera_y=camera.previous_transform.translation.y,
      previous_camera_z=camera.previous_transform.translation.z,
      previous_camera_rot_x=camera.previous_transform.rotation.x,
      previous_camera_rot_y=camera.previous_transform.rotation.y,
      previous_camera_rot_z=camera.previous_transform.rotation.z,
      previous_camera_rot_w=camera.previous_transform.rotation.w,
      pass_kind=0,
      clear_enabled=if clear_enabled { 1 } else { 0 },
    )
    render3d_draw_camera_skybox(camera, camera_far)
    let draw_order = render3d_sorted_mesh_indices(
      meshes,
      camera.layers,
      camera.transform,
    )
    let distance_fog = render3d_distance_fog()
    for draw_index in draw_order {
      let mesh = meshes[draw_index]
      guard render3d_mesh_draw_alpha(
          mesh.material.alpha_mode,
          mesh.material.base_color.a,
        )
        is Some(draw_alpha) else {
        continue
      }
      let texture_id = match mesh.material.base_color_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let normal_texture_id = match
        (
          mesh.material.normal_map_texture,
          mesh.material.clearcoat_normal_texture,
        ) {
        (Some(texture), _) => texture.id()
        (None, Some(texture)) => texture.id()
        (None, None) => -1
      }
      let emissive_texture_id = match mesh.material.emissive_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let metallic_roughness_texture_id = match
        mesh.material.metallic_roughness_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let occlusion_texture_id = match mesh.material.occlusion_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let depth_texture_id = match mesh.material.depth_map {
        Some(texture) => texture.id()
        None => -1
      }
      let anisotropy_texture_id = match mesh.material.anisotropy_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let anisotropy_strength = maxf(
        0.0F,
        minf(1.0F, mesh.material.anisotropy_strength),
      )
      let max_relief_mapping_search_steps = Float::from_double(
        mesh.material.parallax_mapping_method.max_steps().to_double(),
      )
      let clearcoat_reflectance = minf(
        1.0F,
        maxf(0.0F, mesh.material.reflectance + mesh.material.clearcoat * 0.5F),
      )
      let clearcoat_roughness = minf(
        mesh.material.perceptual_roughness,
        mesh.material.clearcoat_perceptual_roughness,
      )
      let draw_roughness = if mesh.material.clearcoat > 0.0F {
        clearcoat_roughness
      } else {
        mesh.material.perceptual_roughness
      }
      let mesh_distance = mesh.transform.translation
        .sub(camera.transform.translation)
        .length()
      let fog_mix = render3d_distance_fog_mix_factor(
        distance_fog, mesh_distance,
      )
      let fog_color = distance_fog.color
      let mut draw_color_r = mesh.material.base_color.r * (1.0F - fog_mix) +
        fog_color.r * fog_mix
      let mut draw_color_g = mesh.material.base_color.g * (1.0F - fog_mix) +
        fog_color.g * fog_mix
      let mut draw_color_b = mesh.material.base_color.b * (1.0F - fog_mix) +
        fog_color.b * fog_mix
      if render3d_world_position_uv(
          camera,
          viewport_rect,
          mesh.transform.translation,
        )
        is Some(screen_uv) {
        if camera.chromatic_aberration is Some(chromatic_aberration) {
          let aberration = render3d_chromatic_aberration_amount(
            chromatic_aberration, screen_uv,
          )
          if aberration > 0.0F {
            draw_color_r = clamp01(draw_color_r + aberration * 0.12F)
            draw_color_g = clamp01(draw_color_g + aberration * 0.02F)
            draw_color_b = clamp01(draw_color_b - aberration * 0.12F)
          }
        }
        if camera.vignette is Some(vignette) {
          let vignette_mask = render3d_vignette_mask(
            vignette, screen_uv, aspect_ratio,
          )
          if vignette_mask > 0.0F {
            let keep = 1.0F - vignette_mask
            draw_color_r = clamp01(
              draw_color_r * keep + vignette.color.r * vignette_mask,
            )
            draw_color_g = clamp01(
              draw_color_g * keep + vignette.color.g * vignette_mask,
            )
            draw_color_b = clamp01(
              draw_color_b * keep + vignette.color.b * vignette_mask,
            )
          }
        }
      }
      let mut draw_surface_roughness = draw_roughness
      let probe_environment_light = render3d_probe_environment_map_light(
        reflection_probes,
        mesh.transform.translation,
      )
      let (environment_strength, environment_affects_diffuse) = render3d_environment_strength(
        camera_environment_map_light, probe_environment_light,
      )
      if environment_affects_diffuse && environment_strength > 0.0F {
        let diffuse_boost = environment_strength *
          (0.18F + (1.0F - draw_surface_roughness) * 0.12F)
        draw_color_r = clamp01(draw_color_r + diffuse_boost)
        draw_color_g = clamp01(draw_color_g + diffuse_boost)
        draw_color_b = clamp01(draw_color_b + diffuse_boost)
      }
      let mut draw_reflectance = clearcoat_reflectance
      if environment_strength > 0.0F {
        draw_reflectance = clamp01(
          draw_reflectance +
          (1.0F - draw_surface_roughness) * environment_strength * 0.6F,
        )
      }
      if camera.screen_space_reflections is Some(ssr) {
        let ssr_strength = render3d_ssr_strength(
          ssr,
          draw_surface_roughness,
          camera.transform,
          camera_fov_y,
          aspect_ratio,
          mesh.transform.translation,
        )
        if ssr_strength > 0.0F {
          draw_reflectance = clamp01(
            draw_reflectance +
            (1.0F - draw_surface_roughness) * ssr_strength * 0.45F,
          )
          draw_surface_roughness = maxf(
            0.02F,
            draw_surface_roughness * (1.0F - ssr_strength * 0.35F),
          )
        }
      }
      render3d_draw_mesh_instance(
        mesh,
        mesh.transform,
        mesh.previous_transform,
        draw_color_r,
        draw_color_g,
        draw_color_b,
        draw_alpha,
        texture_id,
        normal_texture_id,
        emissive_texture_id,
        metallic_roughness_texture_id,
        occlusion_texture_id,
        depth_texture_id,
        anisotropy_texture_id,
        draw_surface_roughness,
        draw_reflectance,
        anisotropy_strength,
        max_relief_mapping_search_steps,
      )
    }
    @window.host_gpu_end_pass()
    if motion_blur_active &&
      camera.motion_blur is Some(motion_blur) &&
      velocity_target_id >= 0 {
      @window.host_gpu_begin_pass(
        target_id=camera.target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera_x=0.0F,
        camera_y=0.0F,
        camera_rotation=0.0F,
        camera_scale=1.0F,
        viewport_x~,
        viewport_y~,
        viewport_width~,
        viewport_height~,
        clear_enabled=if clear_enabled { 1 } else { 0 },
      )
      @window.host_gpu_draw_motion_blur(
        scene_texture_id=scene_target_id,
        velocity_texture_id=velocity_target_id,
        shutter_angle=motion_blur.shutter_angle,
        samples=motion_blur.samples,
      )
      @window.host_gpu_end_pass()
    }
  }
}

///|
fn render3d_camera_viewport_rect_logical(
  camera : @render2d.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Float, Float, Float, Float)? {
  let target_width = target_size.x
  let target_height = target_size.y
  if target_width <= 0 || target_height <= 0 {
    return None
  }
  let mut viewport_x = 0
  let mut viewport_y = 0
  let mut viewport_width = target_width
  let mut viewport_height = target_height
  if camera.viewport is Some(viewport) {
    viewport_x = if viewport.physical_position.x < 0 {
      0
    } else {
      viewport.physical_position.x
    }
    viewport_y = if viewport.physical_position.y < 0 {
      0
    } else {
      viewport.physical_position.y
    }
    viewport_width = if viewport.physical_size.x < 0 {
      0
    } else {
      viewport.physical_size.x
    }
    viewport_height = if viewport.physical_size.y < 0 {
      0
    } else {
      viewport.physical_size.y
    }
    let max_width = if target_width - viewport_x < 0 {
      0
    } else {
      target_width - viewport_x
    }
    let max_height = if target_height - viewport_y < 0 {
      0
    } else {
      target_height - viewport_y
    }
    if viewport_width > max_width {
      viewport_width = max_width
    }
    if viewport_height > max_height {
      viewport_height = max_height
    }
  }
  if viewport_width <= 0 || viewport_height <= 0 {
    return None
  }
  let sf = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let logical_x = Float::from_double(viewport_x.to_double()) / sf
  let logical_y = Float::from_double(viewport_y.to_double()) / sf
  let logical_width = Float::from_double(viewport_width.to_double()) / sf
  let logical_height = Float::from_double(viewport_height.to_double()) / sf
  if logical_width <= 0.0F || logical_height <= 0.0F {
    return None
  }
  Some((logical_x, logical_y, logical_width, logical_height))
}

///|
fn render3d_orthographic_half_height(
  orthographic : OrthographicProjection3d,
  viewport_height : Float,
) -> Float {
  let safe_scale = if orthographic.scale <= 0.0F {
    1.0F
  } else {
    orthographic.scale
  }
  let safe_viewport_height = if viewport_height <= 0.0F {
    1.0F
  } else {
    viewport_height
  }
  let half_height = 0.5F * safe_viewport_height * safe_scale
  if half_height <= 0.0F {
    0.5F
  } else {
    half_height
  }
}

///|
fn render3d_quat_conjugate(value : @math.Quat) -> @math.Quat {
  @math.Quat::new(-value.x, -value.y, -value.z, value.w)
}

///|
pub fn render3d_camera_viewport_to_world_ray(
  screen : @math.Vec2,
  camera : @render2d.Camera,
  projection : CameraProjection3d,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (@math.Vec3, @math.Vec3)? {
  guard render3d_camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  if screen.x < viewport_x ||
    screen.y < viewport_y ||
    screen.x > viewport_x + viewport_width ||
    screen.y > viewport_y + viewport_height {
    return None
  }
  let viewport_local_x = (screen.x - viewport_x) / viewport_width
  let viewport_local_y = (screen.y - viewport_y) / viewport_height
  let ndc_x = viewport_local_x * 2.0F - 1.0F
  let ndc_y = 1.0F - viewport_local_y * 2.0F
  let aspect_ratio = viewport_width / viewport_height
  match projection.projection {
    Perspective(perspective) => {
      let fov = perspective.with_aspect_ratio(aspect_ratio).fov
      let half_fov = fov * 0.5F
      let cos_half_fov = @math.cos(half_fov)
      if cos_half_fov == 0.0F {
        return None
      }
      let tan_half_fov = @math.sin(half_fov) / cos_half_fov
      let ray_camera = @math.Vec3::new(
        ndc_x * tan_half_fov * aspect_ratio,
        ndc_y * tan_half_fov,
        -1.0F,
      ).normalize_or_zero()
      if ray_camera.length_squared() <= 1.0e-12F {
        return None
      }
      let ray_world = quat_rotate_vec3(camera_transform.rotation, ray_camera).normalize_or_zero()
      if ray_world.length_squared() <= 1.0e-12F {
        return None
      }
      Some((camera_transform.translation, ray_world))
    }
    Orthographic(orthographic) => {
      let half_height = render3d_orthographic_half_height(
        orthographic, viewport_height,
      )
      let half_width = half_height * aspect_ratio
      if half_width == 0.0F {
        return None
      }
      let ray_origin_camera = @math.Vec3::new(
        ndc_x * half_width,
        ndc_y * half_height,
        0.0F,
      )
      let ray_origin_world = camera_transform.translation.add(
        quat_rotate_vec3(camera_transform.rotation, ray_origin_camera),
      )
      let ray_world = quat_rotate_vec3(
        camera_transform.rotation,
        @math.Vec3::new(0.0F, 0.0F, -1.0F),
      ).normalize_or_zero()
      if ray_world.length_squared() <= 1.0e-12F {
        return None
      }
      Some((ray_origin_world, ray_world))
    }
  }
}

///|
pub fn render3d_camera_world_to_viewport(
  world : @math.Vec3,
  camera : @render2d.Camera,
  projection : CameraProjection3d,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  guard render3d_camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  let to_world = world.sub(camera_transform.translation)
  let inv_rotation = render3d_quat_conjugate(camera_transform.rotation).normalize()
  let view_pos = quat_rotate_vec3(inv_rotation, to_world)
  let aspect_ratio = viewport_width / viewport_height
  let (ndc_x, ndc_y) = match projection.projection {
    Perspective(perspective) => {
      let view_depth = -view_pos.z
      if view_depth <= 0.0F {
        return None
      }
      let (_, near, far) = render3d_projection_params(
        projection, aspect_ratio, viewport_height,
      )
      if view_depth < near || view_depth > far {
        return None
      }
      let fov = perspective.with_aspect_ratio(aspect_ratio).fov
      let half_fov = fov * 0.5F
      let cos_half_fov = @math.cos(half_fov)
      if cos_half_fov == 0.0F {
        return None
      }
      let tan_half_fov = @math.sin(half_fov) / cos_half_fov
      let denom_x = view_depth * tan_half_fov * aspect_ratio
      let denom_y = view_depth * tan_half_fov
      if denom_x == 0.0F || denom_y == 0.0F {
        return None
      }
      (view_pos.x / denom_x, view_pos.y / denom_y)
    }
    Orthographic(orthographic) => {
      let z_min = if orthographic.near < orthographic.far {
        orthographic.near
      } else {
        orthographic.far
      }
      let z_max = if orthographic.near > orthographic.far {
        orthographic.near
      } else {
        orthographic.far
      }
      if view_pos.z < z_min || view_pos.z > z_max {
        return None
      }
      let half_height = render3d_orthographic_half_height(
        orthographic, viewport_height,
      )
      let half_width = half_height * aspect_ratio
      if half_width == 0.0F || half_height == 0.0F {
        return None
      }
      (view_pos.x / half_width, view_pos.y / half_height)
    }
  }
  let local_x = (ndc_x + 1.0F) * 0.5F * viewport_width
  let local_y = (1.0F - ndc_y) * 0.5F * viewport_height
  if local_x < 0.0F ||
    local_y < 0.0F ||
    local_x > viewport_width ||
    local_y > viewport_height {
    return None
  }
  Some(@math.Vec2::new(local_x + viewport_x, local_y + viewport_y))
}

///|
fn[W : HasRes_GlobalAmbientLight + @core.ChangeTickWorld] init_render3d_resources(
  world : W,
) -> Unit {
  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if !ambient.is_present() {
    ambient.insert(GlobalAmbientLight::default(), tick)
  }
}

///|
pub(open) trait Render3dPluginWorld: HasRes_GlobalAmbientLight + Render3dPrepareWorld + Render3dExecuteWorld {
}

///|
pub fn[W : Render3dPluginWorld] render3d_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_startup_system(init_render3d_resources)
  .add_system(render3d_prepare_system)
  .add_system(render3d_execute_system)
}
