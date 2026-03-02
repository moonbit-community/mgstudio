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
pub(all) enum DecalRenderMode3d {
  Disabled
  ForwardOnly
  ClusteredOnly
  ForwardAndClustered
} derive(Eq, Show)

///|
pub fn DecalRenderMode3d::default() -> DecalRenderMode3d {
  DecalRenderMode3d::ForwardAndClustered
}

///|
pub struct CameraDecalConfig3d {
  mode : DecalRenderMode3d
  requires_depth_prepass : Bool
  clustered_requires_deferred_prepass : Bool
}

///|
pub fn CameraDecalConfig3d::default() -> CameraDecalConfig3d {
  CameraDecalConfig3d::{
    mode: DecalRenderMode3d::ForwardAndClustered,
    requires_depth_prepass: true,
    clustered_requires_deferred_prepass: false,
  }
}

///|
pub fn CameraDecalConfig3d::with_mode(
  self : CameraDecalConfig3d,
  mode : DecalRenderMode3d,
) -> CameraDecalConfig3d {
  CameraDecalConfig3d::{ ..self, mode, }
}

///|
pub fn CameraDecalConfig3d::with_requires_depth_prepass(
  self : CameraDecalConfig3d,
  requires_depth_prepass : Bool,
) -> CameraDecalConfig3d {
  CameraDecalConfig3d::{ ..self, requires_depth_prepass, }
}

///|
pub fn CameraDecalConfig3d::with_clustered_requires_deferred_prepass(
  self : CameraDecalConfig3d,
  clustered_requires_deferred_prepass : Bool,
) -> CameraDecalConfig3d {
  CameraDecalConfig3d::{ ..self, clustered_requires_deferred_prepass, }
}

///|
pub(all) enum CameraDeferredMode3d {
  Auto
  Forward
  Deferred
} derive(Eq, Show)

///|
pub fn CameraDeferredMode3d::default() -> CameraDeferredMode3d {
  CameraDeferredMode3d::Auto
}

///|
pub struct CameraDeferredConfig3d {
  mode : CameraDeferredMode3d
  requires_deferred_prepass : Bool
}

///|
pub fn CameraDeferredConfig3d::default() -> CameraDeferredConfig3d {
  CameraDeferredConfig3d::{
    mode: CameraDeferredMode3d::Auto,
    requires_deferred_prepass: false,
  }
}

///|
pub fn CameraDeferredConfig3d::with_mode(
  self : CameraDeferredConfig3d,
  mode : CameraDeferredMode3d,
) -> CameraDeferredConfig3d {
  CameraDeferredConfig3d::{ ..self, mode, }
}

///|
pub fn CameraDeferredConfig3d::with_requires_deferred_prepass(
  self : CameraDeferredConfig3d,
  requires_deferred_prepass : Bool,
) -> CameraDeferredConfig3d {
  CameraDeferredConfig3d::{ ..self, requires_deferred_prepass, }
}

///|
/// API-parity data model aligned with Bevy's `AutoExposure` camera component.
pub struct AutoExposure {
  min_ev100 : Float
  max_ev100 : Float
  low_percent : Float
  high_percent : Float
  speed_brighten : Float
  speed_darken : Float
  exponential_transition_distance : Float
  compensation_ev : Float
  metering_mask : @asset.Handle[@asset.Image]?
}

///|
pub fn AutoExposure::default() -> AutoExposure {
  AutoExposure::{
    min_ev100: -8.0F,
    max_ev100: 8.0F,
    low_percent: 0.10F,
    high_percent: 0.90F,
    speed_brighten: 3.0F,
    speed_darken: 1.0F,
    exponential_transition_distance: 1.5F,
    compensation_ev: 0.0F,
    metering_mask: None,
  }
}

///|
pub fn AutoExposure::new(min_ev100 : Float, max_ev100 : Float) -> AutoExposure {
  AutoExposure::default().with_range(min_ev100, max_ev100)
}

///|
pub fn AutoExposure::with_range(
  self : AutoExposure,
  min_ev100 : Float,
  max_ev100 : Float,
) -> AutoExposure {
  let safe_min = if min_ev100 < max_ev100 { min_ev100 } else { max_ev100 }
  let safe_max = if max_ev100 > safe_min { max_ev100 } else { safe_min + 0.01F }
  AutoExposure::{ ..self, min_ev100: safe_min, max_ev100: safe_max }
}

///|
pub fn AutoExposure::with_filter(
  self : AutoExposure,
  low_percent : Float,
  high_percent : Float,
) -> AutoExposure {
  let safe_low = if low_percent < 0.0F {
    0.0F
  } else if low_percent > 1.0F {
    1.0F
  } else {
    low_percent
  }
  let mut safe_high = if high_percent < 0.0F {
    0.0F
  } else if high_percent > 1.0F {
    1.0F
  } else {
    high_percent
  }
  if safe_high < safe_low {
    safe_high = safe_low
  }
  AutoExposure::{ ..self, low_percent: safe_low, high_percent: safe_high }
}

///|
pub fn AutoExposure::with_speed_brighten(
  self : AutoExposure,
  speed_brighten : Float,
) -> AutoExposure {
  AutoExposure::{
    ..self,
    speed_brighten: if speed_brighten < 0.0F {
      0.0F
    } else {
      speed_brighten
    },
  }
}

///|
pub fn AutoExposure::with_speed_darken(
  self : AutoExposure,
  speed_darken : Float,
) -> AutoExposure {
  AutoExposure::{
    ..self,
    speed_darken: if speed_darken < 0.0F {
      0.0F
    } else {
      speed_darken
    },
  }
}

///|
pub fn AutoExposure::with_exponential_transition_distance(
  self : AutoExposure,
  exponential_transition_distance : Float,
) -> AutoExposure {
  AutoExposure::{
    ..self,
    exponential_transition_distance: if exponential_transition_distance <= 0.0F {
      0.0001F
    } else {
      exponential_transition_distance
    },
  }
}

///|
pub fn AutoExposure::with_compensation_ev(
  self : AutoExposure,
  compensation_ev : Float,
) -> AutoExposure {
  AutoExposure::{ ..self, compensation_ev, }
}

///|
pub fn AutoExposure::with_metering_mask(
  self : AutoExposure,
  metering_mask : @asset.Handle[@asset.Image]?,
) -> AutoExposure {
  AutoExposure::{ ..self, metering_mask, }
}

///|
pub(all) enum DepthOfFieldMode {
  Bokeh
  Gaussian
} derive(Eq, Show)

///|
pub fn DepthOfFieldMode::default() -> DepthOfFieldMode {
  DepthOfFieldMode::Gaussian
}

///|
/// API-parity data model aligned with Bevy's `DepthOfField` camera component.
pub struct DepthOfField {
  mode : DepthOfFieldMode
  focal_distance : Float
  sensor_height : Float
  aperture_f_stops : Float
  max_circle_of_confusion_diameter : Float
  max_depth : Float
}

///|
pub fn DepthOfField::default() -> DepthOfField {
  DepthOfField::{
    mode: DepthOfFieldMode::Gaussian,
    focal_distance: 10.0F,
    sensor_height: 0.01866F,
    aperture_f_stops: 4.0F,
    max_circle_of_confusion_diameter: 64.0F,
    max_depth: 1_000_000.0F,
  }
}

///|
pub fn DepthOfField::new(
  mode : DepthOfFieldMode,
  focal_distance : Float,
) -> DepthOfField {
  DepthOfField::default().with_mode(mode).with_focal_distance(focal_distance)
}

///|
pub fn DepthOfField::with_mode(
  self : DepthOfField,
  mode : DepthOfFieldMode,
) -> DepthOfField {
  DepthOfField::{ ..self, mode, }
}

///|
pub fn DepthOfField::with_focal_distance(
  self : DepthOfField,
  focal_distance : Float,
) -> DepthOfField {
  DepthOfField::{
    ..self,
    focal_distance: if focal_distance <= 0.0F {
      0.0001F
    } else {
      focal_distance
    },
  }
}

///|
pub fn DepthOfField::with_sensor_height(
  self : DepthOfField,
  sensor_height : Float,
) -> DepthOfField {
  DepthOfField::{
    ..self,
    sensor_height: if sensor_height <= 0.0F {
      0.0001F
    } else {
      sensor_height
    },
  }
}

///|
pub fn DepthOfField::with_aperture_f_stops(
  self : DepthOfField,
  aperture_f_stops : Float,
) -> DepthOfField {
  DepthOfField::{
    ..self,
    aperture_f_stops: if aperture_f_stops <= 0.0F {
      0.0001F
    } else {
      aperture_f_stops
    },
  }
}

///|
pub fn DepthOfField::with_max_circle_of_confusion_diameter(
  self : DepthOfField,
  max_circle_of_confusion_diameter : Float,
) -> DepthOfField {
  DepthOfField::{
    ..self,
    max_circle_of_confusion_diameter: if max_circle_of_confusion_diameter <=
      0.0F {
      1.0F
    } else {
      max_circle_of_confusion_diameter
    },
  }
}

///|
pub fn DepthOfField::with_max_depth(
  self : DepthOfField,
  max_depth : Float,
) -> DepthOfField {
  DepthOfField::{
    ..self,
    max_depth: if max_depth <= 0.0F {
      0.0001F
    } else {
      max_depth
    },
  }
}

///|
/// Camera component aligned with Bevy's `Camera3d`.
///
/// This stores feature toggles and per-camera overrides that influence how the
/// current renderer approximates deferred/decal/volumetric/post-process APIs.
#ecs.component
pub struct Camera3d {
  decal_config : CameraDecalConfig3d
  deferred_config : CameraDeferredConfig3d
  distance_fog : DistanceFog?
  volumetric_fog : VolumetricFog?
  atmosphere : Atmosphere?
  atmosphere_settings : AtmosphereSettings?
  auto_exposure : AutoExposure?
  depth_of_field : DepthOfField?
}

///|
pub fn Camera3d::default() -> Camera3d {
  Camera3d::{
    decal_config: CameraDecalConfig3d::default(),
    deferred_config: CameraDeferredConfig3d::default(),
    distance_fog: None,
    volumetric_fog: None,
    atmosphere: None,
    atmosphere_settings: None,
    auto_exposure: None,
    depth_of_field: None,
  }
}

///|
pub fn Camera3d::with_decal_config(
  self : Camera3d,
  decal_config : CameraDecalConfig3d,
) -> Camera3d {
  Camera3d::{ ..self, decal_config, }
}

///|
pub fn Camera3d::with_deferred_config(
  self : Camera3d,
  deferred_config : CameraDeferredConfig3d,
) -> Camera3d {
  Camera3d::{ ..self, deferred_config, }
}

///|
pub fn Camera3d::with_distance_fog(
  self : Camera3d,
  distance_fog : DistanceFog?,
) -> Camera3d {
  Camera3d::{ ..self, distance_fog, }
}

///|
pub fn Camera3d::with_volumetric_fog(
  self : Camera3d,
  volumetric_fog : VolumetricFog?,
) -> Camera3d {
  Camera3d::{ ..self, volumetric_fog, }
}

///|
pub fn Camera3d::with_atmosphere(
  self : Camera3d,
  atmosphere : Atmosphere?,
) -> Camera3d {
  Camera3d::{ ..self, atmosphere, }
}

///|
pub fn Camera3d::with_atmosphere_settings(
  self : Camera3d,
  atmosphere_settings : AtmosphereSettings?,
) -> Camera3d {
  Camera3d::{ ..self, atmosphere_settings, }
}

///|
pub fn Camera3d::with_auto_exposure(
  self : Camera3d,
  auto_exposure : AutoExposure?,
) -> Camera3d {
  Camera3d::{ ..self, auto_exposure, }
}

///|
pub fn Camera3d::with_depth_of_field(
  self : Camera3d,
  depth_of_field : DepthOfField?,
) -> Camera3d {
  Camera3d::{ ..self, depth_of_field, }
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
  scaling_mode : OrthographicScalingMode3d
}

///|
pub(all) enum OrthographicScalingMode3d {
  WindowSize
  // Legacy alias kept for backward compatibility with earlier mgstudio APIs.
  Scale
  FixedVertical(Float)
}

///|
fn orthographic_scaling_mode_sanitize(
  mode : OrthographicScalingMode3d,
) -> OrthographicScalingMode3d {
  match mode {
    WindowSize => WindowSize
    Scale => Scale
    FixedVertical(viewport_height) =>
      FixedVertical(
        if viewport_height <= 0.0F {
          1.0F
        } else {
          viewport_height
        },
      )
  }
}

///|
pub fn OrthographicProjection3d::default() -> OrthographicProjection3d {
  OrthographicProjection3d::{
    scale: 1.0F,
    near: -1000.0F,
    far: 1000.0F,
    scaling_mode: WindowSize,
  }
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
    scaling_mode: WindowSize,
  }
}

///|
pub fn OrthographicProjection3d::with_window_size_scaling(
  self : OrthographicProjection3d,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    scale: self.scale,
    near: self.near,
    far: self.far,
    scaling_mode: WindowSize,
  }
}

///|
pub fn OrthographicProjection3d::with_scaling_mode(
  self : OrthographicProjection3d,
  scaling_mode : OrthographicScalingMode3d,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    scale: self.scale,
    near: self.near,
    far: self.far,
    scaling_mode: orthographic_scaling_mode_sanitize(scaling_mode),
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
/// Runtime executes this in the shared full-screen post-process composite pass.
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
#ecs.component
pub struct MotionBlur {
  shutter_angle : Float
  samples : Int
}

///|
pub fn MotionBlur::default() -> MotionBlur {
  MotionBlur::{ shutter_angle: 0.5F, samples: 1 }
}

///|
pub fn MotionBlur::new(shutter_angle : Float, samples : Int) -> MotionBlur {
  let safe_shutter_angle = if shutter_angle < 0.0F {
    0.0F
  } else {
    shutter_angle
  }
  let safe_samples = if samples < 0 { 0 } else { samples }
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
pub fn Msaa::samples(self : Msaa) -> Int {
  match self {
    Off => 1
    Sample2 => 2
    Sample4 => 4
    Sample8 => 8
  }
}

///|
pub fn Msaa::from_samples(samples : Int) -> Msaa {
  if samples <= 1 {
    Msaa::Off
  } else if samples <= 2 {
    Msaa::Sample2
  } else if samples <= 4 {
    Msaa::Sample4
  } else {
    Msaa::Sample8
  }
}

///|
pub(all) enum FxaaSensitivity {
  Low
  Medium
  High
  Ultra
  Extreme
} derive(Eq, Show)

///|
pub fn FxaaSensitivity::default() -> FxaaSensitivity {
  FxaaSensitivity::High
}

///|
/// Camera post-process settings aligned with Bevy's `Fxaa`.
///
/// Current runtime note: this records camera intent as an ECS surface.
#ecs.component
pub struct Fxaa {
  enabled : Bool
  edge_threshold : FxaaSensitivity
  edge_threshold_min : FxaaSensitivity
}

///|
pub fn Fxaa::default() -> Fxaa {
  Fxaa::{
    enabled: true,
    edge_threshold: FxaaSensitivity::High,
    edge_threshold_min: FxaaSensitivity::High,
  }
}

///|
pub fn Fxaa::new(enabled : Bool) -> Fxaa {
  Fxaa::{ ..Fxaa::default(), enabled, }
}

///|
pub fn Fxaa::new_with_sensitivity(
  enabled : Bool,
  edge_threshold : FxaaSensitivity,
  edge_threshold_min : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ enabled, edge_threshold, edge_threshold_min }
}

///|
pub fn Fxaa::with_enabled(self : Fxaa, enabled : Bool) -> Fxaa {
  Fxaa::{ ..self, enabled, }
}

///|
pub fn Fxaa::with_edge_threshold(
  self : Fxaa,
  edge_threshold : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ ..self, edge_threshold, }
}

///|
pub fn Fxaa::with_edge_threshold_min(
  self : Fxaa,
  edge_threshold_min : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ ..self, edge_threshold_min, }
}

///|
pub fn Fxaa::with_sensitivity(
  self : Fxaa,
  sensitivity : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ ..self, edge_threshold: sensitivity, edge_threshold_min: sensitivity }
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
/// Marker component aligned with Bevy's `TransmittedShadowReceiver`.
///
/// Current runtime note: this backend records transmitted-shadow intent as ECS
/// API parity; transmitted shadowing itself remains backend-adapted.
#ecs.component
pub struct TransmittedShadowReceiver {}

///|
pub fn TransmittedShadowReceiver::default() -> TransmittedShadowReceiver {
  TransmittedShadowReceiver::{  }
}

///|
/// Camera transparency settings aligned with Bevy's
/// `OrderIndependentTransparencySettings`.
///
/// Current runtime note: this records camera intent as an ECS surface; the
/// renderer-side weighted OIT implementation is tracked separately.
#ecs.component
pub struct OrderIndependentTransparencySettings {
  sorted_fragment_max_count : Int
  fragments_per_pixel_average : Float
  alpha_threshold : Float
}

///|
fn oit_safe_sorted_fragment_max_count(value : Int) -> Int {
  if value < 1 {
    1
  } else {
    value
  }
}

///|
fn oit_safe_fragments_per_pixel_average(value : Float) -> Float {
  if value < 0.25F {
    0.25F
  } else {
    value
  }
}

///|
fn oit_safe_alpha_threshold(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
pub fn OrderIndependentTransparencySettings::default() -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    sorted_fragment_max_count: 8,
    fragments_per_pixel_average: 4.0F,
    alpha_threshold: 0.0F,
  }
}

///|
pub fn OrderIndependentTransparencySettings::new(
  sorted_fragment_max_count : Int,
  fragments_per_pixel_average : Float,
  alpha_threshold : Float,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    sorted_fragment_max_count: oit_safe_sorted_fragment_max_count(
      sorted_fragment_max_count,
    ),
    fragments_per_pixel_average: oit_safe_fragments_per_pixel_average(
      fragments_per_pixel_average,
    ),
    alpha_threshold: oit_safe_alpha_threshold(alpha_threshold),
  }
}

///|
pub fn OrderIndependentTransparencySettings::with_sorted_fragment_max_count(
  self : OrderIndependentTransparencySettings,
  sorted_fragment_max_count : Int,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    ..self,
    sorted_fragment_max_count: oit_safe_sorted_fragment_max_count(
      sorted_fragment_max_count,
    ),
  }
}

///|
pub fn OrderIndependentTransparencySettings::with_fragments_per_pixel_average(
  self : OrderIndependentTransparencySettings,
  fragments_per_pixel_average : Float,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    ..self,
    fragments_per_pixel_average: oit_safe_fragments_per_pixel_average(
      fragments_per_pixel_average,
    ),
  }
}

///|
pub fn OrderIndependentTransparencySettings::with_alpha_threshold(
  self : OrderIndependentTransparencySettings,
  alpha_threshold : Float,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    ..self,
    alpha_threshold: oit_safe_alpha_threshold(alpha_threshold),
  }
}

///|
/// Camera temporal AA settings aligned with Bevy's `TemporalAntiAliasing`.
#ecs.component
pub struct TemporalAntiAliasing {
  reset : Bool
}

///|
pub fn TemporalAntiAliasing::default() -> TemporalAntiAliasing {
  TemporalAntiAliasing::{ reset: true }
}

///|
pub fn TemporalAntiAliasing::new(reset : Bool) -> TemporalAntiAliasing {
  TemporalAntiAliasing::{ reset, }
}

///|
pub fn TemporalAntiAliasing::with_reset(
  self : TemporalAntiAliasing,
  reset : Bool,
) -> TemporalAntiAliasing {
  if self.reset == reset {
    self
  } else {
    TemporalAntiAliasing::{ reset, }
  }
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
const EXPOSURE_EV100_SUNLIGHT : Float = 15.0F

///|
const EXPOSURE_EV100_OVERCAST : Float = 12.0F

///|
const EXPOSURE_EV100_INDOOR : Float = 7.0F

///|
const EXPOSURE_EV100_BLENDER : Float = 9.7F

///|
/// Camera exposure settings aligned with Bevy's `Exposure`.
#ecs.component
pub struct Exposure {
  ev100 : Float
}

///|
pub fn Exposure::default() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_BLENDER }
}

///|
pub fn Exposure::new(ev100 : Float) -> Exposure {
  Exposure::{ ev100, }
}

///|
pub fn Exposure::sunlight() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_SUNLIGHT }
}

///|
pub fn Exposure::overcast() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_OVERCAST }
}

///|
pub fn Exposure::indoor() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_INDOOR }
}

///|
pub fn Exposure::blender() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_BLENDER }
}

///|
pub fn Exposure::with_ev100(self : Exposure, ev100 : Float) -> Exposure {
  self |> ignore
  Exposure::{ ev100, }
}

///|
pub fn Exposure::exposure(self : Exposure) -> Float {
  @math.pow(2.0F, -self.ev100) / 1.2F
}

///|
fn color_grading_midtones_range_sanitize(
  start : Float,
  end_ : Float,
) -> (Float, Float) {
  let safe_start = if start < 0.0F {
    0.0F
  } else if start > 1.0F {
    1.0F
  } else {
    start
  }
  let safe_end = if end_ < 0.0F {
    0.0F
  } else if end_ > 1.0F {
    1.0F
  } else {
    end_
  }
  if safe_start <= safe_end {
    (safe_start, safe_end)
  } else {
    (safe_end, safe_start)
  }
}

///|
/// Global color-grading controls aligned with Bevy's `ColorGradingGlobal`.
pub struct ColorGradingGlobal {
  exposure : Float
  temperature : Float
  tint : Float
  hue : Float
  post_saturation : Float
  midtones_start : Float
  midtones_end : Float
}

///|
pub fn ColorGradingGlobal::default() -> ColorGradingGlobal {
  ColorGradingGlobal::{
    exposure: 0.0F,
    temperature: 0.0F,
    tint: 0.0F,
    hue: 0.0F,
    post_saturation: 1.0F,
    midtones_start: 0.2F,
    midtones_end: 0.7F,
  }
}

///|
pub fn ColorGradingGlobal::new() -> ColorGradingGlobal {
  ColorGradingGlobal::default()
}

///|
pub fn ColorGradingGlobal::with_exposure(
  self : ColorGradingGlobal,
  exposure : Float,
) -> ColorGradingGlobal {
  ColorGradingGlobal::{ ..self, exposure, }
}

///|
pub fn ColorGradingGlobal::with_temperature(
  self : ColorGradingGlobal,
  temperature : Float,
) -> ColorGradingGlobal {
  ColorGradingGlobal::{ ..self, temperature, }
}

///|
pub fn ColorGradingGlobal::with_tint(
  self : ColorGradingGlobal,
  tint : Float,
) -> ColorGradingGlobal {
  ColorGradingGlobal::{ ..self, tint, }
}

///|
pub fn ColorGradingGlobal::with_hue(
  self : ColorGradingGlobal,
  hue : Float,
) -> ColorGradingGlobal {
  ColorGradingGlobal::{ ..self, hue, }
}

///|
pub fn ColorGradingGlobal::with_post_saturation(
  self : ColorGradingGlobal,
  post_saturation : Float,
) -> ColorGradingGlobal {
  ColorGradingGlobal::{
    ..self,
    post_saturation: if post_saturation < 0.0F {
      0.0F
    } else {
      post_saturation
    },
  }
}

///|
pub fn ColorGradingGlobal::with_midtones_range(
  self : ColorGradingGlobal,
  start : Float,
  end_ : Float,
) -> ColorGradingGlobal {
  let (safe_start, safe_end) = color_grading_midtones_range_sanitize(
    start, end_,
  )
  ColorGradingGlobal::{
    ..self,
    midtones_start: safe_start,
    midtones_end: safe_end,
  }
}

///|
pub fn ColorGradingGlobal::midtones_range(
  self : ColorGradingGlobal,
) -> (Float, Float) {
  (self.midtones_start, self.midtones_end)
}

///|
/// Sectional color-grading controls aligned with Bevy's `ColorGradingSection`.
pub struct ColorGradingSection {
  saturation : Float
  contrast : Float
  gamma : Float
  gain : Float
  lift : Float
}

///|
pub fn ColorGradingSection::default() -> ColorGradingSection {
  ColorGradingSection::{
    saturation: 1.0F,
    contrast: 1.0F,
    gamma: 1.0F,
    gain: 1.0F,
    lift: 0.0F,
  }
}

///|
pub fn ColorGradingSection::new() -> ColorGradingSection {
  ColorGradingSection::default()
}

///|
pub fn ColorGradingSection::with_saturation(
  self : ColorGradingSection,
  saturation : Float,
) -> ColorGradingSection {
  ColorGradingSection::{
    ..self,
    saturation: if saturation < 0.0F {
      0.0F
    } else {
      saturation
    },
  }
}

///|
pub fn ColorGradingSection::with_contrast(
  self : ColorGradingSection,
  contrast : Float,
) -> ColorGradingSection {
  ColorGradingSection::{
    ..self,
    contrast: if contrast < 0.0F {
      0.0F
    } else {
      contrast
    },
  }
}

///|
pub fn ColorGradingSection::with_gamma(
  self : ColorGradingSection,
  gamma : Float,
) -> ColorGradingSection {
  ColorGradingSection::{
    ..self,
    gamma: if gamma <= 0.0001F {
      0.0001F
    } else {
      gamma
    },
  }
}

///|
pub fn ColorGradingSection::with_gain(
  self : ColorGradingSection,
  gain : Float,
) -> ColorGradingSection {
  ColorGradingSection::{ ..self, gain: if gain < 0.0F { 0.0F } else { gain } }
}

///|
pub fn ColorGradingSection::with_lift(
  self : ColorGradingSection,
  lift : Float,
) -> ColorGradingSection {
  ColorGradingSection::{ ..self, lift, }
}

///|
/// Combined color-grading section settings for shadows / midtones / highlights.
pub struct ColorGradingSettings {
  shadows : ColorGradingSection
  midtones : ColorGradingSection
  highlights : ColorGradingSection
}

///|
pub fn ColorGradingSettings::default() -> ColorGradingSettings {
  ColorGradingSettings::{
    shadows: ColorGradingSection::default(),
    midtones: ColorGradingSection::default(),
    highlights: ColorGradingSection::default(),
  }
}

///|
pub fn ColorGradingSettings::with_identical_sections(
  section : ColorGradingSection,
) -> ColorGradingSettings {
  ColorGradingSettings::{
    shadows: section,
    midtones: section,
    highlights: section,
  }
}

///|
pub fn ColorGradingSettings::with_shadows(
  self : ColorGradingSettings,
  shadows : ColorGradingSection,
) -> ColorGradingSettings {
  ColorGradingSettings::{ ..self, shadows, }
}

///|
pub fn ColorGradingSettings::with_midtones(
  self : ColorGradingSettings,
  midtones : ColorGradingSection,
) -> ColorGradingSettings {
  ColorGradingSettings::{ ..self, midtones, }
}

///|
pub fn ColorGradingSettings::with_highlights(
  self : ColorGradingSettings,
  highlights : ColorGradingSection,
) -> ColorGradingSettings {
  ColorGradingSettings::{ ..self, highlights, }
}

///|
/// Camera color grading settings aligned with Bevy's `ColorGrading`.
#ecs.component
pub struct ColorGrading {
  global : ColorGradingGlobal
  shadows : ColorGradingSection
  midtones : ColorGradingSection
  highlights : ColorGradingSection
}

///|
pub fn ColorGrading::default() -> ColorGrading {
  ColorGrading::{
    global: ColorGradingGlobal::default(),
    shadows: ColorGradingSection::default(),
    midtones: ColorGradingSection::default(),
    highlights: ColorGradingSection::default(),
  }
}

///|
pub fn ColorGrading::new(
  global : ColorGradingGlobal,
  settings : ColorGradingSettings,
) -> ColorGrading {
  ColorGrading::{
    global,
    shadows: settings.shadows,
    midtones: settings.midtones,
    highlights: settings.highlights,
  }
}

///|
pub fn ColorGrading::with_identical_sections(
  global : ColorGradingGlobal,
  section : ColorGradingSection,
) -> ColorGrading {
  ColorGrading::new(
    global,
    ColorGradingSettings::with_identical_sections(section),
  )
}

///|
pub fn ColorGrading::with_global(
  self : ColorGrading,
  global : ColorGradingGlobal,
) -> ColorGrading {
  ColorGrading::{ ..self, global, }
}

///|
pub fn ColorGrading::with_settings(
  self : ColorGrading,
  settings : ColorGradingSettings,
) -> ColorGrading {
  ColorGrading::{
    ..self,
    shadows: settings.shadows,
    midtones: settings.midtones,
    highlights: settings.highlights,
  }
}

///|
pub fn ColorGrading::with_shadows(
  self : ColorGrading,
  shadows : ColorGradingSection,
) -> ColorGrading {
  ColorGrading::{ ..self, shadows, }
}

///|
pub fn ColorGrading::with_midtones(
  self : ColorGrading,
  midtones : ColorGradingSection,
) -> ColorGrading {
  ColorGrading::{ ..self, midtones, }
}

///|
pub fn ColorGrading::with_highlights(
  self : ColorGrading,
  highlights : ColorGradingSection,
) -> ColorGrading {
  ColorGrading::{ ..self, highlights, }
}

///|
pub fn ColorGrading::settings(self : ColorGrading) -> ColorGradingSettings {
  ColorGradingSettings::{
    shadows: self.shadows,
    midtones: self.midtones,
    highlights: self.highlights,
  }
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
/// Enables / disables screen-space deband dithering in the tonemapping pass.
#ecs.component
pub(all) enum DebandDither {
  Disabled
  Enabled
} derive(Eq, Show)

///|
pub fn DebandDither::default() -> DebandDither {
  DebandDither::Disabled
}

///|
pub struct BloomPrefilter {
  threshold : Float
  threshold_softness : Float
}

///|
pub fn BloomPrefilter::default() -> BloomPrefilter {
  BloomPrefilter::{ threshold: 0.0F, threshold_softness: 0.0F }
}

///|
pub fn BloomPrefilter::new(
  threshold : Float,
  threshold_softness : Float,
) -> BloomPrefilter {
  BloomPrefilter::{
    threshold: if threshold < 0.0F {
      0.0F
    } else {
      threshold
    },
    threshold_softness: if threshold_softness < 0.0F {
      0.0F
    } else if threshold_softness > 1.0F {
      1.0F
    } else {
      threshold_softness
    },
  }
}

///|
pub fn BloomPrefilter::with_threshold(
  self : BloomPrefilter,
  threshold : Float,
) -> BloomPrefilter {
  BloomPrefilter::new(threshold, self.threshold_softness)
}

///|
pub fn BloomPrefilter::with_threshold_softness(
  self : BloomPrefilter,
  threshold_softness : Float,
) -> BloomPrefilter {
  BloomPrefilter::new(self.threshold, threshold_softness)
}

///|
pub(all) enum BloomCompositeMode {
  EnergyConserving
  Additive
} derive(Eq, Show)

///|
pub fn BloomCompositeMode::default() -> BloomCompositeMode {
  BloomCompositeMode::EnergyConserving
}

///|
const BLOOM_DEFAULT_MAX_MIP_DIMENSION : Int = 512

///|
/// Camera bloom settings aligned with Bevy's `Bloom`.
#ecs.component
pub struct Bloom {
  intensity : Float
  low_frequency_boost : Float
  low_frequency_boost_curvature : Float
  high_pass_frequency : Float
  prefilter : BloomPrefilter
  composite_mode : BloomCompositeMode
  max_mip_dimension : Int
  scale : @math.Vec2
}

///|
pub fn Bloom::default() -> Bloom {
  Bloom::{
    intensity: 0.15F,
    low_frequency_boost: 0.7F,
    low_frequency_boost_curvature: 0.95F,
    high_pass_frequency: 1.0F,
    prefilter: BloomPrefilter::default(),
    composite_mode: BloomCompositeMode::EnergyConserving,
    max_mip_dimension: BLOOM_DEFAULT_MAX_MIP_DIMENSION,
    scale: @math.Vec2::new(1.0F, 1.0F),
  }
}

///|
pub fn Bloom::anamorphic() -> Bloom {
  Bloom::{
    ..Bloom::default(),
    max_mip_dimension: BLOOM_DEFAULT_MAX_MIP_DIMENSION * 2,
    scale: @math.Vec2::new(4.0F, 1.0F),
  }
}

///|
pub fn Bloom::old_school() -> Bloom {
  Bloom::{
    ..Bloom::default(),
    intensity: 0.05F,
    prefilter: BloomPrefilter::new(0.6F, 0.2F),
    composite_mode: BloomCompositeMode::Additive,
  }
}

///|
pub fn Bloom::screen_blur() -> Bloom {
  Bloom::{
    ..Bloom::default(),
    intensity: 1.0F,
    low_frequency_boost: 0.0F,
    low_frequency_boost_curvature: 0.0F,
    high_pass_frequency: 1.0F / 3.0F,
  }
}

///|
pub fn Bloom::new(intensity : Float) -> Bloom {
  Bloom::{
    ..Bloom::default(),
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn Bloom::with_intensity(self : Bloom, intensity : Float) -> Bloom {
  Bloom::{ ..self, intensity: if intensity < 0.0F { 0.0F } else { intensity } }
}

///|
pub fn Bloom::with_low_frequency_boost(
  self : Bloom,
  low_frequency_boost : Float,
) -> Bloom {
  Bloom::{
    ..self,
    low_frequency_boost: if low_frequency_boost < 0.0F {
      0.0F
    } else if low_frequency_boost > 1.0F {
      1.0F
    } else {
      low_frequency_boost
    },
  }
}

///|
pub fn Bloom::with_low_frequency_boost_curvature(
  self : Bloom,
  low_frequency_boost_curvature : Float,
) -> Bloom {
  Bloom::{
    ..self,
    low_frequency_boost_curvature: if low_frequency_boost_curvature < 0.0F {
      0.0F
    } else if low_frequency_boost_curvature > 1.0F {
      1.0F
    } else {
      low_frequency_boost_curvature
    },
  }
}

///|
pub fn Bloom::with_high_pass_frequency(
  self : Bloom,
  high_pass_frequency : Float,
) -> Bloom {
  Bloom::{
    ..self,
    high_pass_frequency: if high_pass_frequency < 0.0F {
      0.0F
    } else if high_pass_frequency > 1.0F {
      1.0F
    } else {
      high_pass_frequency
    },
  }
}

///|
pub fn Bloom::with_prefilter(
  self : Bloom,
  threshold : Float,
  threshold_softness : Float,
) -> Bloom {
  Bloom::{
    ..self,
    prefilter: BloomPrefilter::new(threshold, threshold_softness),
  }
}

///|
pub fn Bloom::with_prefilter_settings(
  self : Bloom,
  prefilter : BloomPrefilter,
) -> Bloom {
  Bloom::{
    ..self,
    prefilter: BloomPrefilter::new(
      prefilter.threshold,
      prefilter.threshold_softness,
    ),
  }
}

///|
pub fn Bloom::with_composite_mode(
  self : Bloom,
  composite_mode : BloomCompositeMode,
) -> Bloom {
  Bloom::{ ..self, composite_mode, }
}

///|
pub fn Bloom::with_max_mip_dimension(
  self : Bloom,
  max_mip_dimension : Int,
) -> Bloom {
  Bloom::{
    ..self,
    max_mip_dimension: if max_mip_dimension < 4 {
      4
    } else {
      max_mip_dimension
    },
  }
}

///|
pub fn Bloom::with_scale(self : Bloom, scale : @math.Vec2) -> Bloom {
  Bloom::{
    ..self,
    scale: @math.Vec2::new(
      if scale.x < 0.0F {
        0.0F
      } else {
        scale.x
      },
      if scale.y < 0.0F {
        0.0F
      } else {
        scale.y
      },
    ),
  }
}

///|
pub fn Bloom::with_scale_x(self : Bloom, scale_x : Float) -> Bloom {
  self.with_scale(@math.Vec2::new(scale_x, self.scale.y))
}

///|
pub fn Bloom::with_scale_y(self : Bloom, scale_y : Float) -> Bloom {
  self.with_scale(@math.Vec2::new(self.scale.x, scale_y))
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
  Skybox::{ image: None, brightness: 0.0F, rotation: @math.Quat::identity() }
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
/// Camera screen-space transmission quality aligned with Bevy's
/// `ScreenSpaceTransmissionQuality`.
pub(all) enum ScreenSpaceTransmissionQuality {
  Low
  Medium
  High
  Ultra
} derive(Eq, Show)

///|
pub fn ScreenSpaceTransmissionQuality::default() -> ScreenSpaceTransmissionQuality {
  ScreenSpaceTransmissionQuality::High
}

///|
/// Camera screen-space transmission settings aligned with Bevy's
/// `ScreenSpaceTransmission`.
#ecs.component
pub struct ScreenSpaceTransmission {
  quality : ScreenSpaceTransmissionQuality
  steps : Int
}

///|
pub fn ScreenSpaceTransmission::default() -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::{
    quality: ScreenSpaceTransmissionQuality::default(),
    steps: 2,
  }
}

///|
pub fn ScreenSpaceTransmission::new(
  quality : ScreenSpaceTransmissionQuality,
  steps : Int,
) -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::{
    quality,
    steps: if steps < 0 {
      0
    } else if steps > 4 {
      4
    } else {
      steps
    },
  }
}

///|
pub fn ScreenSpaceTransmission::with_quality(
  self : ScreenSpaceTransmission,
  quality : ScreenSpaceTransmissionQuality,
) -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::{ ..self, quality, }
}

///|
pub fn ScreenSpaceTransmission::with_steps(
  self : ScreenSpaceTransmission,
  steps : Int,
) -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::new(self.quality, steps)
}

///|
fn screen_space_transmission_blur_taps(
  quality : ScreenSpaceTransmissionQuality,
) -> Int {
  match quality {
    Low => 4
    Medium => 8
    High => 16
    Ultra => 32
  }
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
  Atmospheric(@math.Vec3, @math.Vec3)
}

///|
const FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD : Float = 0.05F

///|
const FOG_FALLOFF_E : Float = 2.718281828459045F

///|
const FOG_FALLOFF_LN2 : Float = 0.6931471805599453F

///|
const FOG_FALLOFF_MIN_VISIBILITY : Float = 0.0001F

///|
const FOG_FALLOFF_MIN_CONTRAST : Float = 0.000001F

///|
const FOG_FALLOFF_MAX_CONTRAST : Float = 0.999999F

///|
fn fog_falloff_clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn fog_falloff_sanitize_density(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn fog_falloff_sanitize_visibility(visibility : Float) -> Float {
  if visibility <= FOG_FALLOFF_MIN_VISIBILITY {
    FOG_FALLOFF_MIN_VISIBILITY
  } else {
    visibility
  }
}

///|
fn fog_falloff_sanitize_contrast(contrast_threshold : Float) -> Float {
  if contrast_threshold <= FOG_FALLOFF_MIN_CONTRAST {
    FOG_FALLOFF_MIN_CONTRAST
  } else if contrast_threshold >= FOG_FALLOFF_MAX_CONTRAST {
    FOG_FALLOFF_MAX_CONTRAST
  } else {
    contrast_threshold
  }
}

///|
fn fog_falloff_ln(value : Float) -> Float {
  if value <= 0.0F {
    return -87.3365447505531F
  }
  let mut x = value
  let mut exponent_shift = 0.0F
  while x > 2.0F {
    x = x * 0.5F
    exponent_shift = exponent_shift + FOG_FALLOFF_LN2
  }
  while x < 0.5F {
    x = x * 2.0F
    exponent_shift = exponent_shift - FOG_FALLOFF_LN2
  }
  let y = (x - 1.0F) / (x + 1.0F)
  let y_squared = y * y
  let mut series = 0.0F
  let mut numerator = y
  let mut denominator = 1.0F
  for _ in 0..<8 {
    series = series + numerator / denominator
    numerator = numerator * y_squared
    denominator = denominator + 2.0F
  }
  exponent_shift + 2.0F * series
}

///|
fn fog_falloff_pow_e(value : Float) -> Float {
  @math.pow(FOG_FALLOFF_E, value)
}

///|
fn fog_falloff_koschmieder(
  visibility : Float,
  contrast_threshold : Float,
) -> Float {
  let safe_visibility = fog_falloff_sanitize_visibility(visibility)
  let safe_contrast = fog_falloff_sanitize_contrast(contrast_threshold)
  -fog_falloff_ln(safe_contrast) / safe_visibility
}

///|
fn fog_falloff_atmospheric_from_colors(
  visibility : Float,
  contrast_threshold : Float,
  extinction_color : @render2d.Color,
  inscattering_color : @render2d.Color,
) -> FogFalloff3d {
  let beta = fog_falloff_koschmieder(visibility, contrast_threshold)

  let extinction_alpha = fog_falloff_pow_e(
    fog_falloff_clamp01(extinction_color.a),
  )
  let inscattering_alpha = fog_falloff_pow_e(
    fog_falloff_clamp01(inscattering_color.a),
  )

  let extinction = @math.Vec3::new(
    fog_falloff_pow_e(1.0F - fog_falloff_clamp01(extinction_color.r)) *
    beta *
    extinction_alpha,
    fog_falloff_pow_e(1.0F - fog_falloff_clamp01(extinction_color.g)) *
    beta *
    extinction_alpha,
    fog_falloff_pow_e(1.0F - fog_falloff_clamp01(extinction_color.b)) *
    beta *
    extinction_alpha,
  )

  let inscattering = @math.Vec3::new(
    fog_falloff_pow_e(fog_falloff_clamp01(inscattering_color.r)) *
    beta *
    inscattering_alpha,
    fog_falloff_pow_e(fog_falloff_clamp01(inscattering_color.g)) *
    beta *
    inscattering_alpha,
    fog_falloff_pow_e(fog_falloff_clamp01(inscattering_color.b)) *
    beta *
    inscattering_alpha,
  )

  FogFalloff3d::Atmospheric(extinction, inscattering)
}

///|
pub fn FogFalloff3d::revised_koschmieder_contrast_threshold() -> Float {
  FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD
}

///|
pub fn FogFalloff3d::linear(start : Float, end_ : Float) -> FogFalloff3d {
  let safe_start = if start < 0.0F { 0.0F } else { start }
  let safe_end = if end_ < safe_start { safe_start } else { end_ }
  FogFalloff3d::Linear(safe_start, safe_end)
}

///|
pub fn FogFalloff3d::exponential(density : Float) -> FogFalloff3d {
  let safe_density = fog_falloff_sanitize_density(density)
  FogFalloff3d::Exponential(safe_density)
}

///|
pub fn FogFalloff3d::exponential_squared(density : Float) -> FogFalloff3d {
  let safe_density = fog_falloff_sanitize_density(density)
  FogFalloff3d::ExponentialSquared(safe_density)
}

///|
pub fn FogFalloff3d::atmospheric(
  extinction : @math.Vec3,
  inscattering : @math.Vec3,
) -> FogFalloff3d {
  let safe_extinction = @math.Vec3::new(
    fog_falloff_sanitize_density(extinction.x),
    fog_falloff_sanitize_density(extinction.y),
    fog_falloff_sanitize_density(extinction.z),
  )
  let safe_inscattering = @math.Vec3::new(
    fog_falloff_sanitize_density(inscattering.x),
    fog_falloff_sanitize_density(inscattering.y),
    fog_falloff_sanitize_density(inscattering.z),
  )
  FogFalloff3d::Atmospheric(safe_extinction, safe_inscattering)
}

///|
pub fn FogFalloff3d::from_visibility(visibility : Float) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast(
  visibility : Float,
  contrast_threshold : Float,
) -> FogFalloff3d {
  FogFalloff3d::Exponential(
    fog_falloff_koschmieder(visibility, contrast_threshold),
  )
}

///|
pub fn FogFalloff3d::from_visibility_squared(
  visibility : Float,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_squared(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast_squared(
  visibility : Float,
  contrast_threshold : Float,
) -> FogFalloff3d {
  let safe_visibility = fog_falloff_sanitize_visibility(visibility)
  let density = @math.sqrt(
    fog_falloff_koschmieder(safe_visibility, contrast_threshold) /
    safe_visibility,
  )
  FogFalloff3d::ExponentialSquared(fog_falloff_sanitize_density(density))
}

///|
pub fn FogFalloff3d::from_visibility_color(
  visibility : Float,
  extinction_inscattering_color : @render2d.Color,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_colors(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
    extinction_inscattering_color,
    extinction_inscattering_color,
  )
}

///|
pub fn FogFalloff3d::from_visibility_colors(
  visibility : Float,
  extinction_color : @render2d.Color,
  inscattering_color : @render2d.Color,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_colors(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
    extinction_color,
    inscattering_color,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast_color(
  visibility : Float,
  contrast_threshold : Float,
  extinction_inscattering_color : @render2d.Color,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_colors(
    visibility, contrast_threshold, extinction_inscattering_color, extinction_inscattering_color,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast_colors(
  visibility : Float,
  contrast_threshold : Float,
  extinction_color : @render2d.Color,
  inscattering_color : @render2d.Color,
) -> FogFalloff3d {
  fog_falloff_atmospheric_from_colors(
    visibility, contrast_threshold, extinction_color, inscattering_color,
  )
}

///|
// Global fog defaults. Camera3d can apply per-camera volumetric/atmosphere
// overrides on top during render execution.
pub struct DistanceFog {
  color : @render2d.Color
  directional_light_color : @render2d.Color
  directional_light_exponent : Float
  falloff : FogFalloff3d
}

///|
pub fn DistanceFog::default() -> DistanceFog {
  DistanceFog::{
    color: @render2d.Color::white(),
    directional_light_color: @render2d.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    directional_light_exponent: 8.0F,
    falloff: FogFalloff3d::linear(0.0F, 100.0F),
  }
}

///|
pub fn DistanceFog::new(
  color : @render2d.Color,
  falloff : FogFalloff3d,
) -> DistanceFog {
  DistanceFog::{
    color,
    directional_light_color: @render2d.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    directional_light_exponent: 8.0F,
    falloff,
  }
}

///|
pub fn DistanceFog::with_color(
  self : DistanceFog,
  color : @render2d.Color,
) -> DistanceFog {
  DistanceFog::{ ..self, color, }
}

///|
pub fn DistanceFog::with_directional_light_color(
  self : DistanceFog,
  directional_light_color : @render2d.Color,
) -> DistanceFog {
  DistanceFog::{ ..self, directional_light_color, }
}

///|
pub fn DistanceFog::with_directional_light_exponent(
  self : DistanceFog,
  directional_light_exponent : Float,
) -> DistanceFog {
  DistanceFog::{
    ..self,
    directional_light_exponent: if directional_light_exponent < 0.0F {
      0.0F
    } else {
      directional_light_exponent
    },
  }
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
/// API-parity data model stub aligned with Bevy's `VolumetricLight`.
pub struct VolumetricLight {}

///|
pub fn VolumetricLight::default() -> VolumetricLight {
  VolumetricLight::{  }
}

///|
/// API-parity data model stub aligned with Bevy's `VolumetricFog`.
pub struct VolumetricFog {
  ambient_color : @render2d.Color
  ambient_intensity : Float
  jitter : Float
  step_count : Int
}

///|
pub fn VolumetricFog::default() -> VolumetricFog {
  VolumetricFog::{
    ambient_color: @render2d.Color::white(),
    ambient_intensity: 0.1F,
    jitter: 0.0F,
    step_count: 64,
  }
}

///|
pub fn VolumetricFog::with_ambient_color(
  self : VolumetricFog,
  ambient_color : @render2d.Color,
) -> VolumetricFog {
  VolumetricFog::{ ..self, ambient_color, }
}

///|
pub fn VolumetricFog::with_ambient_intensity(
  self : VolumetricFog,
  ambient_intensity : Float,
) -> VolumetricFog {
  VolumetricFog::{
    ..self,
    ambient_intensity: if ambient_intensity < 0.0F {
      0.0F
    } else {
      ambient_intensity
    },
  }
}

///|
pub fn VolumetricFog::with_jitter(
  self : VolumetricFog,
  jitter : Float,
) -> VolumetricFog {
  VolumetricFog::{ ..self, jitter: if jitter < 0.0F { 0.0F } else { jitter } }
}

///|
pub fn VolumetricFog::with_step_count(
  self : VolumetricFog,
  step_count : Int,
) -> VolumetricFog {
  VolumetricFog::{
    ..self,
    step_count: if step_count <= 0 {
      1
    } else {
      step_count
    },
  }
}

///|
/// API-parity data model stub aligned with Bevy's `FogVolume`.
pub struct FogVolume {
  fog_color : @render2d.Color
  density_factor : Float
  density_texture : @asset.Handle[@asset.Image]?
  density_texture_offset : @math.Vec3
  absorption : Float
  scattering : Float
  scattering_asymmetry : Float
  light_tint : @render2d.Color
  light_intensity : Float
}

///|
pub fn FogVolume::default() -> FogVolume {
  FogVolume::{
    fog_color: @render2d.Color::white(),
    density_factor: 0.1F,
    density_texture: None,
    density_texture_offset: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    absorption: 0.3F,
    scattering: 0.3F,
    scattering_asymmetry: 0.5F,
    light_tint: @render2d.Color::white(),
    light_intensity: 1.0F,
  }
}

///|
pub fn FogVolume::with_fog_color(
  self : FogVolume,
  fog_color : @render2d.Color,
) -> FogVolume {
  FogVolume::{ ..self, fog_color, }
}

///|
pub fn FogVolume::with_density_factor(
  self : FogVolume,
  density_factor : Float,
) -> FogVolume {
  FogVolume::{
    ..self,
    density_factor: fog_falloff_sanitize_density(density_factor),
  }
}

///|
pub fn FogVolume::with_density_texture(
  self : FogVolume,
  density_texture : @asset.Handle[@asset.Image]?,
) -> FogVolume {
  FogVolume::{ ..self, density_texture, }
}

///|
pub fn FogVolume::with_density_texture_offset(
  self : FogVolume,
  density_texture_offset : @math.Vec3,
) -> FogVolume {
  FogVolume::{ ..self, density_texture_offset, }
}

///|
pub fn FogVolume::with_absorption(
  self : FogVolume,
  absorption : Float,
) -> FogVolume {
  FogVolume::{ ..self, absorption: fog_falloff_sanitize_density(absorption) }
}

///|
pub fn FogVolume::with_scattering(
  self : FogVolume,
  scattering : Float,
) -> FogVolume {
  FogVolume::{ ..self, scattering: fog_falloff_sanitize_density(scattering) }
}

///|
pub fn FogVolume::with_scattering_asymmetry(
  self : FogVolume,
  scattering_asymmetry : Float,
) -> FogVolume {
  FogVolume::{
    ..self,
    scattering_asymmetry: fog_falloff_clamp01(
      (scattering_asymmetry + 1.0F) * 0.5F,
    ) *
    2.0F -
    1.0F,
  }
}

///|
pub fn FogVolume::with_light_tint(
  self : FogVolume,
  light_tint : @render2d.Color,
) -> FogVolume {
  FogVolume::{ ..self, light_tint, }
}

///|
pub fn FogVolume::with_light_intensity(
  self : FogVolume,
  light_intensity : Float,
) -> FogVolume {
  FogVolume::{
    ..self,
    light_intensity: if light_intensity < 0.0F {
      0.0F
    } else {
      light_intensity
    },
  }
}

///|
pub(all) enum AtmosphereMode {
  LookupTexture
  Raymarched
}

///|
pub fn AtmosphereMode::default() -> AtmosphereMode {
  AtmosphereMode::LookupTexture
}

///|
/// API-parity data model stub aligned with Bevy's `AtmosphereSettings`.
pub struct AtmosphereSettings {
  scene_units_to_m : Float
  sky_max_samples : Int
  rendering_method : AtmosphereMode
}

///|
pub fn AtmosphereSettings::default() -> AtmosphereSettings {
  AtmosphereSettings::{
    scene_units_to_m: 1.0F,
    sky_max_samples: 16,
    rendering_method: AtmosphereMode::LookupTexture,
  }
}

///|
pub fn AtmosphereSettings::with_scene_units_to_m(
  self : AtmosphereSettings,
  scene_units_to_m : Float,
) -> AtmosphereSettings {
  AtmosphereSettings::{
    ..self,
    scene_units_to_m: if scene_units_to_m <= 0.0F {
      0.0001F
    } else {
      scene_units_to_m
    },
  }
}

///|
pub fn AtmosphereSettings::with_sky_max_samples(
  self : AtmosphereSettings,
  sky_max_samples : Int,
) -> AtmosphereSettings {
  AtmosphereSettings::{
    ..self,
    sky_max_samples: if sky_max_samples <= 0 {
      1
    } else {
      sky_max_samples
    },
  }
}

///|
pub fn AtmosphereSettings::with_rendering_method(
  self : AtmosphereSettings,
  rendering_method : AtmosphereMode,
) -> AtmosphereSettings {
  AtmosphereSettings::{ ..self, rendering_method, }
}

///|
pub struct ScatteringMedium {
  density_multiplier : Float
}

///|
pub fn ScatteringMedium::default() -> ScatteringMedium {
  ScatteringMedium::{ density_multiplier: 1.0F }
}

///|
pub fn ScatteringMedium::earthlike() -> ScatteringMedium {
  ScatteringMedium::default()
}

///|
pub fn ScatteringMedium::with_density_multiplier(
  self : ScatteringMedium,
  density_multiplier : Float,
) -> ScatteringMedium {
  self |> ignore
  ScatteringMedium::{
    density_multiplier: if density_multiplier < 0.0F {
      0.0F
    } else {
      density_multiplier
    },
  }
}

///|
/// API-parity data model stub aligned with Bevy's `Atmosphere`.
pub struct Atmosphere {
  bottom_radius : Float
  top_radius : Float
  ground_albedo : @math.Vec3
  medium : ScatteringMedium
}

///|
pub fn Atmosphere::default() -> Atmosphere {
  Atmosphere::earthlike(ScatteringMedium::default())
}

///|
pub fn Atmosphere::earthlike(medium : ScatteringMedium) -> Atmosphere {
  Atmosphere::{
    bottom_radius: 6_360_000.0F,
    top_radius: 6_460_000.0F,
    ground_albedo: @math.Vec3::new(0.3F, 0.3F, 0.3F),
    medium,
  }
}

///|
pub fn Atmosphere::with_radii(
  self : Atmosphere,
  bottom_radius : Float,
  top_radius : Float,
) -> Atmosphere {
  let safe_bottom_radius = if bottom_radius <= 0.0F {
    0.0001F
  } else {
    bottom_radius
  }
  let safe_top_radius = if top_radius < safe_bottom_radius {
    safe_bottom_radius
  } else {
    top_radius
  }
  Atmosphere::{
    ..self,
    bottom_radius: safe_bottom_radius,
    top_radius: safe_top_radius,
  }
}

///|
pub fn Atmosphere::with_ground_albedo(
  self : Atmosphere,
  ground_albedo : @math.Vec3,
) -> Atmosphere {
  Atmosphere::{ ..self, ground_albedo, }
}

///|
pub fn Atmosphere::with_medium(
  self : Atmosphere,
  medium : ScatteringMedium,
) -> Atmosphere {
  Atmosphere::{ ..self, medium, }
}

///|
/// API-parity data model stub aligned with Bevy's `AtmosphereEnvironmentMapLight`.
pub struct AtmosphereEnvironmentMapLight {}

///|
pub fn AtmosphereEnvironmentMapLight::default() -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::{  }
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
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  specular_tint : @render2d.Color
  specular_tint_texture : @asset.Handle[@asset.Image]?
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
    diffuse_transmission: 0.0F,
    specular_transmission: 0.0F,
    thickness: 0.0F,
    ior: 1.5F,
    specular_tint: @render2d.Color::white(),
    specular_tint_texture: None,
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
    diffuse_transmission: default_value.diffuse_transmission,
    specular_transmission: default_value.specular_transmission,
    thickness: default_value.thickness,
    ior: default_value.ior,
    specular_tint: default_value.specular_tint,
    specular_tint_texture: default_value.specular_tint_texture,
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
  let safe_reflectance = if reflectance < 0.0F { 0.0F } else { reflectance }
  StandardMaterial::{ ..self, reflectance: safe_reflectance }
}

///|
pub fn StandardMaterial::with_diffuse_transmission(
  self : StandardMaterial,
  diffuse_transmission : Float,
) -> StandardMaterial {
  let safe_diffuse_transmission = if diffuse_transmission < 0.0F {
    0.0F
  } else if diffuse_transmission > 1.0F {
    1.0F
  } else {
    diffuse_transmission
  }
  StandardMaterial::{ ..self, diffuse_transmission: safe_diffuse_transmission }
}

///|
pub fn StandardMaterial::with_specular_transmission(
  self : StandardMaterial,
  specular_transmission : Float,
) -> StandardMaterial {
  let safe_specular_transmission = if specular_transmission < 0.0F {
    0.0F
  } else if specular_transmission > 1.0F {
    1.0F
  } else {
    specular_transmission
  }
  StandardMaterial::{
    ..self,
    specular_transmission: safe_specular_transmission,
  }
}

///|
pub fn StandardMaterial::with_thickness(
  self : StandardMaterial,
  thickness : Float,
) -> StandardMaterial {
  let safe_thickness = if thickness < 0.0F { 0.0F } else { thickness }
  StandardMaterial::{ ..self, thickness: safe_thickness }
}

///|
pub fn StandardMaterial::with_ior(
  self : StandardMaterial,
  ior : Float,
) -> StandardMaterial {
  let safe_ior = if ior < 1.0F { 1.0F } else { ior }
  StandardMaterial::{ ..self, ior: safe_ior }
}

///|
pub fn StandardMaterial::with_specular_tint(
  self : StandardMaterial,
  specular_tint : @render2d.Color,
) -> StandardMaterial {
  StandardMaterial::{ ..self, specular_tint, }
}

///|
pub fn StandardMaterial::with_specular_tint_texture(
  self : StandardMaterial,
  specular_tint_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, specular_tint_texture, }
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
pub fn StandardMaterial::with_cull_mode(
  self : StandardMaterial,
  cull_mode : Face3d?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, cull_mode, }
}

///|
pub fn StandardMaterial::with_double_sided(
  self : StandardMaterial,
  double_sided : Bool,
) -> StandardMaterial {
  let cull_mode : Face3d? = if double_sided { None } else { Some(Face3d::Back) }
  StandardMaterial::{ ..self, cull_mode, }
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
pub impl ToJson for Mesh3d with to_json(self) {
  self.mesh.id().to_json()
}

///|
pub impl @json.FromJson for Mesh3d with from_json(json, path) {
  let mesh_id : Int = @json.from_json(json, path~)
  Mesh3d::new(@asset.Handle::new(mesh_id))
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
/// Metadata-only hook aligned with Bevy's `ExtendedMaterial`.
///
/// This does not introduce a shader pipeline on its own; it stores extension
/// intent so examples and future backends can share a single API surface.
pub struct ExtendedMaterialMetadata3d {
  extension_tag : Int
  alpha_mode_override : AlphaMode3d?
  opaque_render_method_override : OpaqueRendererMethod?
  requires_depth_prepass : Bool
  requires_deferred_prepass : Bool
  disable_shadows : Bool
}

///|
pub fn ExtendedMaterialMetadata3d::default() -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    extension_tag: 0,
    alpha_mode_override: None,
    opaque_render_method_override: None,
    requires_depth_prepass: false,
    requires_deferred_prepass: false,
    disable_shadows: false,
  }
}

///|
pub fn ExtendedMaterialMetadata3d::new(
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::default().with_extension_tag(extension_tag)
}

///|
pub fn ExtendedMaterialMetadata3d::with_extension_tag(
  self : ExtendedMaterialMetadata3d,
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  let safe_tag = if extension_tag < 0 { 0 } else { extension_tag }
  ExtendedMaterialMetadata3d::{ ..self, extension_tag: safe_tag }
}

///|
pub fn ExtendedMaterialMetadata3d::with_alpha_mode_override(
  self : ExtendedMaterialMetadata3d,
  alpha_mode_override : AlphaMode3d?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, alpha_mode_override, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_opaque_render_method_override(
  self : ExtendedMaterialMetadata3d,
  opaque_render_method_override : OpaqueRendererMethod?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, opaque_render_method_override, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_requires_depth_prepass(
  self : ExtendedMaterialMetadata3d,
  requires_depth_prepass : Bool,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, requires_depth_prepass, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_requires_deferred_prepass(
  self : ExtendedMaterialMetadata3d,
  requires_deferred_prepass : Bool,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, requires_deferred_prepass, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_disable_shadows(
  self : ExtendedMaterialMetadata3d,
  disable_shadows : Bool,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, disable_shadows, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct MeshMaterial3d {
  material : @asset.Handle[StandardMaterial]
  extended_material : ExtendedMaterialMetadata3d?
}

///|
pub fn MeshMaterial3d::new(
  material : @asset.Handle[StandardMaterial],
) -> MeshMaterial3d {
  MeshMaterial3d::{ material, extended_material: None }
}

///|
pub impl ToJson for MeshMaterial3d with to_json(self) {
  self.material.id().to_json()
}

///|
pub impl @json.FromJson for MeshMaterial3d with from_json(json, path) {
  let material_id : Int = @json.from_json(json, path~)
  MeshMaterial3d::new(@asset.Handle::new(material_id))
}

///|
pub fn MeshMaterial3d::with_extended_material(
  self : MeshMaterial3d,
  extended_material : ExtendedMaterialMetadata3d?,
) -> MeshMaterial3d {
  MeshMaterial3d::{ ..self, extended_material, }
}

///|
pub fn MeshMaterial3d::with_extension_tag(
  self : MeshMaterial3d,
  extension_tag : Int,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(extension.with_extension_tag(extension_tag)),
  }
}

///|
pub fn MeshMaterial3d::with_extension_alpha_mode(
  self : MeshMaterial3d,
  alpha_mode_override : AlphaMode3d?,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_alpha_mode_override(alpha_mode_override),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_opaque_renderer_method(
  self : MeshMaterial3d,
  opaque_render_method_override : OpaqueRendererMethod?,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_opaque_render_method_override(
        opaque_render_method_override,
      ),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_requires_depth_prepass(
  self : MeshMaterial3d,
  requires_depth_prepass : Bool,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_requires_depth_prepass(requires_depth_prepass),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_requires_deferred_prepass(
  self : MeshMaterial3d,
  requires_deferred_prepass : Bool,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_requires_deferred_prepass(requires_deferred_prepass),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_disable_shadows(
  self : MeshMaterial3d,
  disable_shadows : Bool,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(extension.with_disable_shadows(disable_shadows)),
  }
}

///|
/// Marker component aligned with Bevy's `ForwardDecal`.
///
/// Current runtime note: projected forward-decal shading is not wired in this
/// backend yet. This component preserves scene/API parity for example
/// migration and future renderer integration.
#ecs.component
pub struct ForwardDecal {}

///|
pub fn ForwardDecal::default() -> ForwardDecal {
  ForwardDecal::{  }
}

///|
fn forward_decal_depth_fade_factor_safe(depth_fade_factor : Float) -> Float {
  if depth_fade_factor < 0.001F {
    0.001F
  } else {
    depth_fade_factor
  }
}

///|
/// Forward decal material-extension parameters aligned with Bevy's
/// `ForwardDecalMaterialExt`.
///
/// Current runtime note: values are stored for parity; extension shader
/// specialization is pending renderer support.
#ecs.component
pub struct ForwardDecalMaterialExt {
  depth_fade_factor : Float
}

///|
pub fn ForwardDecalMaterialExt::default() -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::{ depth_fade_factor: 8.0F }
}

///|
pub fn ForwardDecalMaterialExt::new(
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::{
    depth_fade_factor: forward_decal_depth_fade_factor_safe(depth_fade_factor),
  }
}

///|
pub fn ForwardDecalMaterialExt::with_depth_fade_factor(
  self : ForwardDecalMaterialExt,
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExt {
  self |> ignore
  ForwardDecalMaterialExt::{
    depth_fade_factor: forward_decal_depth_fade_factor_safe(depth_fade_factor),
  }
}

///|
fn clustered_decal_tag_safe(tag : Int) -> Int {
  if tag < 0 {
    0
  } else {
    tag
  }
}

///|
/// Clustered decal parameters aligned with Bevy's `ClusteredDecal`.
///
/// The decal volume follows Bevy semantics: a transformed unit cube that
/// projects textures along local `-Z`.
///
/// Current runtime note: clustered projection is not yet active in this
/// backend; this component currently carries scene intent metadata.
#ecs.component
pub struct ClusteredDecal {
  base_color_texture : @asset.Handle[@asset.Image]?
  normal_map_texture : @asset.Handle[@asset.Image]?
  metallic_roughness_texture : @asset.Handle[@asset.Image]?
  emissive_texture : @asset.Handle[@asset.Image]?
  tag : Int
}

///|
pub fn ClusteredDecal::default() -> ClusteredDecal {
  ClusteredDecal::{
    base_color_texture: None,
    normal_map_texture: None,
    metallic_roughness_texture: None,
    emissive_texture: None,
    tag: 0,
  }
}

///|
pub fn ClusteredDecal::new() -> ClusteredDecal {
  ClusteredDecal::default()
}

///|
pub fn ClusteredDecal::with_base_color_texture(
  self : ClusteredDecal,
  base_color_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, base_color_texture, }
}

///|
pub fn ClusteredDecal::with_normal_map_texture(
  self : ClusteredDecal,
  normal_map_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, normal_map_texture, }
}

///|
pub fn ClusteredDecal::with_metallic_roughness_texture(
  self : ClusteredDecal,
  metallic_roughness_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, metallic_roughness_texture, }
}

///|
pub fn ClusteredDecal::with_emissive_texture(
  self : ClusteredDecal,
  emissive_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, emissive_texture, }
}

///|
pub fn ClusteredDecal::with_tag(
  self : ClusteredDecal,
  tag : Int,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, tag: clustered_decal_tag_safe(tag) }
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
  affects_lightmapped_mesh_diffuse : Bool
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
    affects_lightmapped_mesh_diffuse: true,
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
    affects_lightmapped_mesh_diffuse: true,
    shadow_depth_bias: POINT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: POINT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn PointLight::with_color(
  self : PointLight,
  color : @render2d.Color,
) -> PointLight {
  PointLight::{ ..self, color, }
}

///|
pub fn PointLight::with_range(self : PointLight, range : Float) -> PointLight {
  PointLight::{ ..self, range: if range < 0.0F { 0.0F } else { range } }
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
pub fn PointLight::with_shadow_maps_enabled(
  self : PointLight,
  shadow_maps_enabled : Bool,
) -> PointLight {
  PointLight::{ ..self, shadow_maps_enabled, }
}

///|
pub fn PointLight::with_affects_lightmapped_mesh_diffuse(
  self : PointLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> PointLight {
  PointLight::{ ..self, affects_lightmapped_mesh_diffuse, }
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
/// Point-light shadow map resource aligned with Bevy's `PointLightShadowMap`.
#ecs.resource
pub struct PointLightShadowMap {
  size : Int
}

///|
pub fn PointLightShadowMap::default() -> PointLightShadowMap {
  PointLightShadowMap::{ size: 1024 }
}

///|
pub fn PointLightShadowMap::new(size : Int) -> PointLightShadowMap {
  PointLightShadowMap::{ size: if size <= 0 { 1 } else { size } }
}

///|
pub fn PointLightShadowMap::with_size(
  self : PointLightShadowMap,
  size : Int,
) -> PointLightShadowMap {
  self |> ignore
  PointLightShadowMap::new(size)
}

///|
fn directional_shadow_map_size_safe(size : Int) -> Int {
  let safe = if size <= 0 { 1 } else { size }
  let mut pow2 = 1
  while pow2 < safe {
    pow2 = pow2 * 2
  }
  pow2
}

///|
/// Directional/spot-light shadow map resource aligned with Bevy's
/// `DirectionalLightShadowMap`.
///
/// A single `size` value controls the width/height of each shadow map slice.
#ecs.resource
pub struct DirectionalLightShadowMap {
  size : Int
}

///|
pub fn DirectionalLightShadowMap::default() -> DirectionalLightShadowMap {
  DirectionalLightShadowMap::{ size: 2048 }
}

///|
pub fn DirectionalLightShadowMap::new(size : Int) -> DirectionalLightShadowMap {
  DirectionalLightShadowMap::{ size: directional_shadow_map_size_safe(size) }
}

///|
pub fn DirectionalLightShadowMap::with_size(
  self : DirectionalLightShadowMap,
  size : Int,
) -> DirectionalLightShadowMap {
  self |> ignore
  DirectionalLightShadowMap::new(size)
}

///|
pub struct CascadeShadowConfig {
  bounds : Array[Float]
  overlap_proportion : Float
  minimum_distance : Float
}

///|
pub struct CascadeShadowConfigBuilder {
  num_cascades : Int
  minimum_distance : Float
  maximum_distance : Float
  first_cascade_far_bound : Float
  overlap_proportion : Float
}

///|
fn cascade_shadow_config_safe_overlap(overlap : Float) -> Float {
  if overlap < 0.0F {
    0.0F
  } else if overlap >= 1.0F {
    0.9999F
  } else {
    overlap
  }
}

///|
fn cascade_shadow_config_calculate_bounds(
  num_cascades : Int,
  nearest_bound : Float,
  maximum_distance : Float,
) -> Array[Float] {
  if num_cascades <= 1 {
    return [maximum_distance]
  }
  let exponent = 1.0F / Float::from_double((num_cascades - 1).to_double())
  let base = @math.pow(maximum_distance / nearest_bound, exponent)
  let bounds : Array[Float] = []
  for i in 0..<num_cascades {
    bounds.push(
      nearest_bound * @math.pow(base, Float::from_double(i.to_double())),
    )
  }
  bounds
}

///|
pub fn CascadeShadowConfigBuilder::default() -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    num_cascades: 4,
    minimum_distance: 0.1F,
    maximum_distance: 150.0F,
    first_cascade_far_bound: 10.0F,
    overlap_proportion: 0.2F,
  }
}

///|
pub fn CascadeShadowConfigBuilder::new() -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::default()
}

///|
pub fn CascadeShadowConfigBuilder::with_num_cascades(
  self : CascadeShadowConfigBuilder,
  num_cascades : Int,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    num_cascades: if num_cascades <= 0 {
      1
    } else {
      num_cascades
    },
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_minimum_distance(
  self : CascadeShadowConfigBuilder,
  minimum_distance : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    minimum_distance: if minimum_distance < 0.0F {
      0.0F
    } else {
      minimum_distance
    },
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_maximum_distance(
  self : CascadeShadowConfigBuilder,
  maximum_distance : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    maximum_distance: if maximum_distance < 0.0F {
      0.0F
    } else {
      maximum_distance
    },
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_first_cascade_far_bound(
  self : CascadeShadowConfigBuilder,
  first_cascade_far_bound : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    first_cascade_far_bound: if first_cascade_far_bound < 0.0F {
      0.0F
    } else {
      first_cascade_far_bound
    },
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_overlap_proportion(
  self : CascadeShadowConfigBuilder,
  overlap_proportion : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    overlap_proportion: cascade_shadow_config_safe_overlap(overlap_proportion),
  }
}

///|
pub fn CascadeShadowConfigBuilder::build(
  self : CascadeShadowConfigBuilder,
) -> CascadeShadowConfig {
  let safe_num_cascades = if self.num_cascades <= 0 {
    1
  } else {
    self.num_cascades
  }
  let safe_minimum_distance = if self.minimum_distance < 0.0F {
    0.0F
  } else {
    self.minimum_distance
  }
  let mut safe_maximum_distance = if self.maximum_distance <=
    safe_minimum_distance {
    safe_minimum_distance + 0.1F
  } else {
    self.maximum_distance
  }
  if safe_maximum_distance <= 0.0F {
    safe_maximum_distance = 0.1F
  }
  let mut safe_first_cascade_far_bound = if self.first_cascade_far_bound <=
    safe_minimum_distance {
    safe_minimum_distance + 0.1F
  } else {
    self.first_cascade_far_bound
  }
  if safe_num_cascades == 1 {
    safe_first_cascade_far_bound = safe_maximum_distance
  } else if safe_first_cascade_far_bound > safe_maximum_distance {
    safe_first_cascade_far_bound = safe_maximum_distance
  }

  CascadeShadowConfig::{
    bounds: cascade_shadow_config_calculate_bounds(
      safe_num_cascades, safe_first_cascade_far_bound, safe_maximum_distance,
    ),
    overlap_proportion: cascade_shadow_config_safe_overlap(
      self.overlap_proportion,
    ),
    minimum_distance: safe_minimum_distance,
  }
}

///|
pub fn CascadeShadowConfig::default() -> CascadeShadowConfig {
  CascadeShadowConfigBuilder::default().build()
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
  cascade_shadow_config : CascadeShadowConfig?
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
    cascade_shadow_config: None,
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
    cascade_shadow_config: None,
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
pub fn DirectionalLight::with_cascade_shadow_config(
  self : DirectionalLight,
  cascade_shadow_config : CascadeShadowConfig?,
) -> DirectionalLight {
  DirectionalLight::{ ..self, cascade_shadow_config, }
}

///|
pub fn DirectionalLight::with_cascade_shadow_config_builder(
  self : DirectionalLight,
  cascade_shadow_config_builder : CascadeShadowConfigBuilder,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    cascade_shadow_config: Some(cascade_shadow_config_builder.build()),
  }
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
  screen_space_transmission : ScreenSpaceTransmission?
  screen_space_reflections : ScreenSpaceReflections?
  bloom : Bloom?
  tonemapping : Tonemapping?
  deband_dither : DebandDither?
  chromatic_aberration : ChromaticAberration?
  vignette : Vignette?
  motion_blur : MotionBlur?
  exposure : Exposure?
  color_grading : ColorGrading?
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
    screen_space_transmission: None,
    screen_space_reflections: None,
    bloom: None,
    tonemapping: None,
    deband_dither: None,
    chromatic_aberration: None,
    vignette: None,
    motion_blur: None,
    exposure: None,
    color_grading: None,
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
    screen_space_transmission: None,
    screen_space_reflections: None,
    bloom: None,
    tonemapping: None,
    deband_dither: None,
    chromatic_aberration: None,
    vignette: None,
    motion_blur: None,
    exposure: None,
    color_grading: None,
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
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_decal_config(decal_config),
  }
}

///|
pub fn Camera3dBundle::with_deferred_config(
  self : Camera3dBundle,
  deferred_config : CameraDeferredConfig3d,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_deferred_config(deferred_config),
  }
}

///|
pub fn Camera3dBundle::with_distance_fog(
  self : Camera3dBundle,
  distance_fog : DistanceFog?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_distance_fog(distance_fog),
  }
}

///|
pub fn Camera3dBundle::with_volumetric_fog(
  self : Camera3dBundle,
  volumetric_fog : VolumetricFog?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_volumetric_fog(volumetric_fog),
  }
}

///|
pub fn Camera3dBundle::with_atmosphere(
  self : Camera3dBundle,
  atmosphere : Atmosphere?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_atmosphere(atmosphere),
  }
}

///|
pub fn Camera3dBundle::with_atmosphere_settings(
  self : Camera3dBundle,
  atmosphere_settings : AtmosphereSettings?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_atmosphere_settings(atmosphere_settings),
  }
}

///|
pub fn Camera3dBundle::with_auto_exposure(
  self : Camera3dBundle,
  auto_exposure : AutoExposure?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_auto_exposure(auto_exposure),
  }
}

///|
pub fn Camera3dBundle::with_depth_of_field(
  self : Camera3dBundle,
  depth_of_field : DepthOfField?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_depth_of_field(depth_of_field),
  }
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
pub(open) trait Camera3dBundleSpawnWorld: @core.SpawnWorld + @core.ChangeTickWorld + Has_Camera3d + Has_CameraProjection3d + Has_SubCameraView3d + Has_ScreenSpaceTransmission + Has_ScreenSpaceReflections + Has_Bloom + Has_Tonemapping + Has_DebandDither + Has_ChromaticAberration + Has_Vignette + Has_MotionBlur + Has_Exposure + Has_ColorGrading + @render2d.Has_Camera + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @math.Has_Transform {
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
  if self.screen_space_transmission is Some(screen_space_transmission) {
    world
    .get_screen_space_transmission_store()
    .insert(entity, screen_space_transmission, tick)
  }
  if self.screen_space_reflections is Some(screen_space_reflections) {
    world
    .get_screen_space_reflections_store()
    .insert(entity, screen_space_reflections, tick)
  }
  if self.bloom is Some(bloom) {
    world.get_bloom_store().insert(entity, bloom, tick)
  }
  if self.tonemapping is Some(tonemapping) {
    world.get_tonemapping_store().insert(entity, tonemapping, tick)
  }
  if self.deband_dither is Some(deband_dither) {
    world.get_deband_dither_store().insert(entity, deband_dither, tick)
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
  if self.exposure is Some(exposure) {
    world.get_exposure_store().insert(entity, exposure, tick)
  }
  if self.color_grading is Some(color_grading) {
    world.get_color_grading_store().insert(entity, color_grading, tick)
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
  camera3d : Camera3d
  camera : @render2d.Camera
  projection : CameraProjection3d
  sub_camera_view : SubCameraView3d?
  screen_space_transmission : ScreenSpaceTransmission?
  screen_space_reflections : ScreenSpaceReflections?
  bloom : Bloom?
  tonemapping : Tonemapping?
  deband_dither : DebandDither?
  chromatic_aberration : ChromaticAberration?
  vignette : Vignette?
  motion_blur : MotionBlur?
  exposure : Exposure?
  color_grading : ColorGrading?
  skybox : Skybox?
  environment_map_light : EnvironmentMapLight?
  generated_environment_map_light : GeneratedEnvironmentMapLight?
  depth_prepass_enabled : Bool
  deferred_prepass_enabled : Bool
  hdr_enabled : Bool
  fxaa : Fxaa?
  temporal_jitter : TemporalJitter?
  temporal_anti_aliasing : TemporalAntiAliasing?
  motion_vector_prepass_enabled : Bool
  msaa : Msaa?
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
  mesh_handle : @asset.Handle[@mesh.Mesh]
  mesh_id : Int
  transform : @math.Transform
  previous_transform : @math.Transform
  visibility_range : @visibility.VisibilityRange?
  aabb_center_world : @math.Vec3?
  material : StandardMaterial
  material_extension : ExtendedMaterialMetadata3d?
  is_forward_decal : Bool
  forward_decal_material_ext : ForwardDecalMaterialExt?
  clustered_decal : ClusteredDecal?
  layers : @render2d.RenderLayers
  has_wireframe : Bool
  has_no_wireframe : Bool
  wireframe_color : WireframeColor?
}

///|
priv struct TransmissionMeshDraw {
  mesh : Mesh3dInstance
  draw_flags : Int
  draw_color_r : Float
  draw_color_g : Float
  draw_color_b : Float
  draw_alpha : Float
  texture_id : Int
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  anisotropy_texture_id : Int
  specular_tint_texture_id : Int
  draw_surface_roughness : Float
  draw_reflectance : Float
  draw_diffuse_transmission : Float
  draw_specular_transmission : Float
  draw_thickness : Float
  draw_ior : Float
  specular_tint : @render2d.Color
  anisotropy_strength : Float
  max_relief_mapping_search_steps : Float
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
priv struct TransmissionSourceTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  source_target_id : Int
}

///|
priv struct AutoExposureHistoryEntry {
  entity : @core.Entity
  ev100 : Float
}

///|
let motion_blur_history : Ref[Array[MotionBlurHistoryEntry]] = Ref::new([])

///|
let camera_motion_blur_history : Ref[Array[CameraMotionBlurHistoryEntry]] = Ref::new([],
)

///|
let motion_blur_targets : Ref[Array[MotionBlurTargetsEntry]] = Ref::new([])

///|
let transmission_source_targets : Ref[Array[TransmissionSourceTargetsEntry]] = Ref::new([],
)

///|
let auto_exposure_history : Ref[Array[AutoExposureHistoryEntry]] = Ref::new([])

///|
priv struct WireframeMeshCacheEntry {
  source_mesh_handle_id : Int
  wireframe_mesh_id : Int
}

///|
let wireframe_mesh_cache : Ref[Array[WireframeMeshCacheEntry]] = Ref::new([])

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
  ).with_depth(viewport.depth_min, viewport.depth_max)
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
fn render3d_float_clamp(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn render3d_fxaa_enabled(fxaa : Fxaa?) -> Bool {
  match fxaa {
    Some(value) => value.enabled
    None => false
  }
}

///|
fn render3d_tonemap_postprocess_enabled(
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  hdr_enabled : Bool,
  fxaa : Fxaa?,
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
) -> Bool {
  hdr_enabled ||
  tonemapping is Some(_) ||
  deband_dither is Some(Enabled) ||
  render3d_fxaa_enabled(fxaa) ||
  render3d_chromatic_aberration_enabled(chromatic_aberration) ||
  render3d_vignette_enabled(vignette)
}

///|
fn render3d_chromatic_aberration_enabled(
  chromatic_aberration : ChromaticAberration?,
) -> Bool {
  match chromatic_aberration {
    Some(value) => value.intensity > 0.0F && value.max_samples > 0
    None => false
  }
}

///|
fn render3d_vignette_enabled(vignette : Vignette?) -> Bool {
  match vignette {
    Some(value) => value.intensity > 0.0F
    None => false
  }
}

///|
const RENDER3D_PASS_KIND_BASE_SCENE : Int = 0

///|
const RENDER3D_PASS_KIND_BASE_MOTION_VECTOR : Int = 1

///|
const RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG : Int = 1 << 8

///|
const RENDER3D_PASS_KIND_DISABLE_FOG_FLAG : Int = 1 << 9

///|
const RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG : Int = 1 << 10

///|
const RENDER3D_MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
fn render3d_pass_kind_encode(
  base_kind : Int,
  postprocess_enabled : Bool,
  fog_enabled : Bool,
  decal_enabled : Bool,
) -> Int {
  let mut value = base_kind
  if !postprocess_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG
  }
  if !fog_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_FOG_FLAG
  }
  if !decal_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG
  }
  value
}

///|
fn render3d_mesh_draw_flags(mesh : Mesh3dInstance) -> Int {
  let mut flags = 0
  if mesh.is_forward_decal || mesh.clustered_decal is Some(_) {
    flags = flags | RENDER3D_MESH3D_DRAW_FLAG_DECAL
  }
  flags
}

///|
fn render3d_distance_fog_enabled(fog : DistanceFog) -> Bool {
  if fog.color.a <= 0.0F {
    return false
  }
  match fog.falloff {
    FogFalloff3d::Linear(start, end_) => end_ > start
    FogFalloff3d::Exponential(density) => density > 0.0F
    FogFalloff3d::ExponentialSquared(density) => density > 0.0F
    FogFalloff3d::Atmospheric(extinction, inscattering) =>
      extinction.x +
      extinction.y +
      extinction.z +
      inscattering.x +
      inscattering.y +
      inscattering.z >
      0.0001F
  }
}

///|
fn render3d_decal_mode_allows_forward(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => true
    ClusteredOnly => false
    ForwardAndClustered => true
  }
}

///|
fn render3d_decal_mode_allows_clustered(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => false
    ClusteredOnly => true
    ForwardAndClustered => true
  }
}

///|
fn render3d_camera_deferred_mode(
  config : CameraDeferredConfig3d,
  default_method : OpaqueRendererMethod,
) -> OpaqueRendererMethod {
  match config.mode {
    CameraDeferredMode3d::Forward => OpaqueRendererMethod::Forward
    CameraDeferredMode3d::Deferred => OpaqueRendererMethod::Deferred
    CameraDeferredMode3d::Auto =>
      match default_method {
        OpaqueRendererMethod::Forward => OpaqueRendererMethod::Forward
        OpaqueRendererMethod::Deferred => OpaqueRendererMethod::Deferred
        OpaqueRendererMethod::Auto => OpaqueRendererMethod::Forward
      }
  }
}

///|
fn render3d_apply_extended_material_metadata(
  material : StandardMaterial,
  extension : ExtendedMaterialMetadata3d?,
) -> StandardMaterial {
  guard extension is Some(extension_value) else { return material }
  let mut out = material
  if extension_value.alpha_mode_override is Some(alpha_mode_override) {
    out = StandardMaterial::{ ..out, alpha_mode: alpha_mode_override }
  }
  if extension_value.opaque_render_method_override
    is Some(opaque_render_method_override) {
    out = StandardMaterial::{
      ..out,
      opaque_render_method: opaque_render_method_override,
    }
  }
  out
}

///|
fn render3d_auto_exposure_history_get(entity : @core.Entity) -> Float? {
  for item in auto_exposure_history.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      return Some(item.ev100)
    }
  }
  None
}

///|
fn render3d_auto_exposure_history_set(
  entity : @core.Entity,
  ev100 : Float,
) -> Unit {
  let next : Array[AutoExposureHistoryEntry] = []
  let mut replaced = false
  for item in auto_exposure_history.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, ev100 })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, ev100 })
  }
  auto_exposure_history.val = next
}

///|
fn render3d_auto_exposure_history_sync(
  cameras : Array[Camera3dInstance],
) -> Unit {
  let next : Array[AutoExposureHistoryEntry] = []
  for camera in cameras {
    if render3d_auto_exposure_history_get(camera.entity) is Some(ev100) {
      next.push({ entity: camera.entity, ev100 })
    }
  }
  auto_exposure_history.val = next
}

///|
fn render3d_auto_exposure_target_ev100(
  auto_exposure : AutoExposure,
  lighting : Render3dLightingState,
) -> Float {
  // TODO(render3d-backend): replace this CPU approximation with histogram
  // metering + compensation-curve sampling when compute post-process exists.
  let ambient = if lighting.ambient_brightness < 0.0F {
    0.0F
  } else {
    lighting.ambient_brightness
  }
  let directional = if lighting.directional_illuminance < 0.0F {
    0.0F
  } else {
    lighting.directional_illuminance / 10_000.0F
  }
  let point = if lighting.point_intensity < 0.0F {
    0.0F
  } else {
    lighting.point_intensity / 100_000.0F
  }
  let spot = if lighting.spot_intensity < 0.0F {
    0.0F
  } else {
    lighting.spot_intensity / 100_000.0F
  }
  let metering_mask_weight = if auto_exposure.metering_mask is Some(_) {
    0.8F
  } else {
    1.0F
  }
  let filtered = ambient * (1.0F - auto_exposure.low_percent) +
    directional * auto_exposure.high_percent +
    (point + spot) * 0.5F
  let normalized_brightness = render3d_float_clamp(
    filtered * metering_mask_weight,
    0.0F,
    1.0F,
  )
  let span = auto_exposure.max_ev100 - auto_exposure.min_ev100
  let base_target = auto_exposure.max_ev100 - normalized_brightness * span
  render3d_float_clamp(
    base_target + auto_exposure.compensation_ev,
    auto_exposure.min_ev100,
    auto_exposure.max_ev100,
  )
}

///|
fn render3d_camera_effective_exposure(
  camera_entity : @core.Entity,
  exposure : Exposure?,
  auto_exposure : AutoExposure?,
  lighting : Render3dLightingState,
) -> Exposure? {
  guard auto_exposure is Some(auto_exposure_value) else { return exposure }
  let target_ev100 = render3d_auto_exposure_target_ev100(
    auto_exposure_value, lighting,
  )
  let default_ev100 = match exposure {
    Some(value) => value.ev100
    None => Exposure::default().ev100
  }
  let current_ev100 = match render3d_auto_exposure_history_get(camera_entity) {
    Some(value) => value
    None => default_ev100
  }
  let delta = @time.time_delta_seconds()
  let safe_delta = if delta <= 0.0F { 0.0F } else { delta }
  let diff = target_ev100 - current_ev100
  let abs_diff = if diff < 0.0F { -diff } else { diff }
  let transition = if auto_exposure_value.exponential_transition_distance <=
    0.0F {
    0.0001F
  } else {
    auto_exposure_value.exponential_transition_distance
  }
  let speed = if diff < 0.0F {
    auto_exposure_value.speed_brighten
  } else {
    auto_exposure_value.speed_darken
  }
  let mut step = speed * safe_delta
  if abs_diff < transition {
    step = step * abs_diff / transition
  }
  let next_ev100 = if diff > 0.0F {
    if current_ev100 + step > target_ev100 {
      target_ev100
    } else {
      current_ev100 + step
    }
  } else if current_ev100 - step < target_ev100 {
    target_ev100
  } else {
    current_ev100 - step
  }
  render3d_auto_exposure_history_set(camera_entity, next_ev100)
  Some(Exposure::new(next_ev100))
}

///|
fn render3d_depth_of_field_weight(
  depth_of_field : DepthOfField?,
  mesh_distance : Float,
) -> Float {
  guard depth_of_field is Some(depth_of_field_value) else { return 0.0F }
  let distance = if mesh_distance < 0.0F {
    0.0F
  } else if mesh_distance > depth_of_field_value.max_depth {
    depth_of_field_value.max_depth
  } else {
    mesh_distance
  }
  let focus_delta = if distance > depth_of_field_value.focal_distance {
    distance - depth_of_field_value.focal_distance
  } else {
    depth_of_field_value.focal_distance - distance
  }
  let focus_norm = focus_delta / depth_of_field_value.focal_distance
  let aperture_term = 1.0F / depth_of_field_value.aperture_f_stops
  let coc_term = depth_of_field_value.max_circle_of_confusion_diameter / 64.0F
  let mode_term = if depth_of_field_value.mode is DepthOfFieldMode::Bokeh {
    1.0F
  } else {
    0.7F
  }
  render3d_float_clamp(
    focus_norm * aperture_term * coc_term * mode_term,
    0.0F,
    1.0F,
  )
}

///|
fn render3d_color_lerp(
  from_ : @render2d.Color,
  to_ : @render2d.Color,
  t : Float,
) -> @render2d.Color {
  @render2d.Color::new(
    from_.r + (to_.r - from_.r) * t,
    from_.g + (to_.g - from_.g) * t,
    from_.b + (to_.b - from_.b) * t,
    from_.a + (to_.a - from_.a) * t,
  )
}

///|
fn render3d_camera_distance_fog(
  base_fog : DistanceFog,
  volumetric_fog : VolumetricFog?,
  atmosphere : Atmosphere?,
  atmosphere_settings : AtmosphereSettings?,
) -> DistanceFog {
  let mut fog = base_fog
  if volumetric_fog is Some(volumetric_fog_value) {
    let ambient_mix = render3d_float_clamp(
      volumetric_fog_value.ambient_intensity,
      0.0F,
      1.0F,
    )
    fog = DistanceFog::{
      ..fog,
      color: render3d_color_lerp(
        fog.color,
        volumetric_fog_value.ambient_color,
        ambient_mix,
      ),
      directional_light_color: render3d_color_lerp(
        fog.directional_light_color,
        volumetric_fog_value.ambient_color,
        ambient_mix * 0.6F,
      ),
      directional_light_exponent: fog.directional_light_exponent +
      Float::from_double(volumetric_fog_value.step_count.to_double()) /
      64.0F *
      0.5F,
    }
  }
  if atmosphere is Some(atmosphere_value) {
    let albedo_color = @render2d.Color::new(
      render3d_float_clamp(atmosphere_value.ground_albedo.x, 0.0F, 1.0F),
      render3d_float_clamp(atmosphere_value.ground_albedo.y, 0.0F, 1.0F),
      render3d_float_clamp(atmosphere_value.ground_albedo.z, 0.0F, 1.0F),
      1.0F,
    )
    fog = DistanceFog::{
      ..fog,
      color: render3d_color_lerp(fog.color, albedo_color, 0.15F),
    }
  }
  if atmosphere_settings is Some(atmosphere_settings_value) {
    let unit_scale = if atmosphere_settings_value.scene_units_to_m <= 0.0F {
      0.0001F
    } else {
      atmosphere_settings_value.scene_units_to_m
    }
    let falloff = match fog.falloff {
      FogFalloff3d::Linear(start, end_) =>
        FogFalloff3d::linear(start * unit_scale, end_ * unit_scale)
      FogFalloff3d::Exponential(density) =>
        FogFalloff3d::exponential(density / unit_scale)
      FogFalloff3d::ExponentialSquared(density) =>
        FogFalloff3d::exponential_squared(density / @math.sqrt(unit_scale))
      FogFalloff3d::Atmospheric(extinction, inscattering) =>
        FogFalloff3d::atmospheric(
          extinction.mul_scalar(1.0F / unit_scale),
          inscattering.mul_scalar(1.0F / unit_scale),
        )
    }
    fog = DistanceFog::{ ..fog, falloff, }
    if atmosphere_settings_value.rendering_method is AtmosphereMode::Raymarched {
      fog = DistanceFog::{
        ..fog,
        directional_light_exponent: fog.directional_light_exponent + 1.0F,
      }
    }
  }
  fog
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
  let velocity_target_id = @window.host_gpu_create_render_target_rgba16f(
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
fn render3d_transmission_source_target_get_or_create(
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> Int {
  for item in transmission_source_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return item.source_target_id
    }
  }
  let source_target_id = @window.host_gpu_create_render_target(
    width~,
    height~,
    nearest=false,
  )
  let next : Array[TransmissionSourceTargetsEntry] = []
  let mut replaced = false
  for item in transmission_source_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, width, height, source_target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, width, height, source_target_id })
  }
  transmission_source_targets.val = next
  source_target_id
}

///|
fn render3d_blit_texture_to_target(
  source_texture_id : Int,
  target_id : Int,
  width_logical : Int,
  height_logical : Int,
) -> Unit {
  if source_texture_id < 0 ||
    target_id < 0 ||
    width_logical <= 0 ||
    height_logical <= 0 {
    return
  }
  let sx = Float::from_double(width_logical.to_double()) / 128.0F
  let sy = Float::from_double(height_logical.to_double()) / 128.0F
  @window.host_gpu_begin_pass(
    target_id~,
    width=width_logical,
    height=height_logical,
    clear_r=0.0F,
    clear_g=0.0F,
    clear_b=0.0F,
    clear_a=0.0F,
    camera_x=0.0F,
    camera_y=0.0F,
    camera_rotation=0.0F,
    camera_scale=1.0F,
    viewport_x=0,
    viewport_y=0,
    viewport_width=width_logical,
    viewport_height=height_logical,
    viewport_depth_min=0.0F,
    viewport_depth_max=1.0F,
    clear_enabled=1,
  )
  @window.host_gpu_draw_sprite_uv(
    texture_id=source_texture_id,
    x=0.0F,
    y=0.0F,
    rotation=0.0F,
    scale_x=sx,
    scale_y=sy,
    color_r=1.0F,
    color_g=1.0F,
    color_b=1.0F,
    color_a=1.0F,
    uv_min_x=0.0F,
    uv_min_y=0.0F,
    uv_max_x=1.0F,
    uv_max_y=1.0F,
  )
  @window.host_gpu_end_pass()
}

///|
fn render3d_wireframe_mesh_cache_get(source_mesh_handle_id : Int) -> Int? {
  for item in wireframe_mesh_cache.val {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      return Some(item.wireframe_mesh_id)
    }
  }
  None
}

///|
fn render3d_wireframe_mesh_cache_set(
  source_mesh_handle_id : Int,
  wireframe_mesh_id : Int,
) -> Unit {
  let next : Array[WireframeMeshCacheEntry] = []
  let mut replaced = false
  for item in wireframe_mesh_cache.val {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      if !replaced {
        next.push({ source_mesh_handle_id, wireframe_mesh_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ source_mesh_handle_id, wireframe_mesh_id })
  }
  wireframe_mesh_cache.val = next
}

///|
fn render3d_wireframe_mesh_id(mesh_handle : @asset.Handle[@mesh.Mesh]) -> Int? {
  let source_mesh_handle_id = mesh_handle.id()
  if render3d_wireframe_mesh_cache_get(source_mesh_handle_id) is Some(mesh_id) {
    return Some(mesh_id)
  }
  let source_mesh = match @render2d.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) => mesh_asset
    None => return None
  }
  match source_mesh.geometry {
    @mesh.MeshGeometry::Geometry3d(geometry3d) =>
      match geometry3d.primitive_topology() {
        @mesh.Mesh3dPrimitiveTopology::TriangleList =>
          match geometry3d.to_wireframe_line_list() {
            Some(wireframe_geometry) => {
              let wireframe_handle = @render2d.render_mesh_asset_add(
                @mesh.Mesh::from_3d_geometry(wireframe_geometry),
              )
              let wireframe_mesh_id = @render2d.render2d_upload_mesh_handle(
                wireframe_handle,
              )
              render3d_wireframe_mesh_cache_set(
                source_mesh_handle_id, wireframe_mesh_id,
              )
              Some(wireframe_mesh_id)
            }
            None => return None
          }
        @mesh.Mesh3dPrimitiveTopology::LineList => {
          let mesh_id = @render2d.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(source_mesh_handle_id, mesh_id)
          Some(mesh_id)
        }
        @mesh.Mesh3dPrimitiveTopology::LineStrip => {
          let mesh_id = @render2d.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(source_mesh_handle_id, mesh_id)
          Some(mesh_id)
        }
      }
    _ => return None
  }
}

///|
fn render3d_mesh_should_draw_wireframe(
  mesh : Mesh3dInstance,
  wireframe_config : WireframeConfig?,
) -> Bool {
  guard wireframe_config is Some(config) else { return false }
  if mesh.has_no_wireframe {
    false
  } else if mesh.has_wireframe {
    true
  } else {
    config.global
  }
}

///|
fn render3d_mesh_wireframe_color(
  mesh : Mesh3dInstance,
  wireframe_config : WireframeConfig?,
) -> @render2d.Color {
  if mesh.wireframe_color is Some(color_component) {
    color_component.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    @render2d.Color::white()
  }
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
    specular_tint_texture_id=-1,
    specular_tint_r=1.0F,
    specular_tint_g=1.0F,
    specular_tint_b=1.0F,
    diffuse_transmission=0.0F,
    specular_transmission=0.0F,
    thickness=0.0F,
    ior=1.5F,
    transmission_source_texture_id=-1,
    transmission_blur_taps=0.0F,
    transmission_steps=0.0F,
    cull_mode=1,
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
      // Encode orthographic mode via negative `camera_fov_y` and pass world-space
      // half-height through its magnitude. Runtime shaders decode this sentinel.
      let safe_half_height = render3d_orthographic_half_height(
        orthographic, safe_view_height,
      )
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
const RENDER3D_TONEMAPPING_LUT_AGX_PATH : String = "textures/tonemapping/AgX-default_contrast.ktx2"

///|
const RENDER3D_TONEMAPPING_LUT_TONY_PATH : String = "textures/tonemapping/tony_mc_mapface.ktx2"

///|
const RENDER3D_TONEMAPPING_LUT_BLENDER_PATH : String = "textures/tonemapping/Blender_-11_12.ktx2"

///|
priv struct Render3dTonemappingLutHandles {
  agx : @asset.Handle[@asset.Image]
  tony : @asset.Handle[@asset.Image]
  blender : @asset.Handle[@asset.Image]
}

///|
let render3d_tonemapping_lut_handles_ref : Ref[Render3dTonemappingLutHandles?] = Ref::new(
  None,
)

///|
fn render3d_tonemapping_lut_handles() -> Render3dTonemappingLutHandles {
  if render3d_tonemapping_lut_handles_ref.val is Some(handles) {
    return handles
  }
  let asset_server = @asset.AssetServer::new()
  let handles = Render3dTonemappingLutHandles::{
    agx: asset_server.load(RENDER3D_TONEMAPPING_LUT_AGX_PATH),
    tony: asset_server.load(RENDER3D_TONEMAPPING_LUT_TONY_PATH),
    blender: asset_server.load(RENDER3D_TONEMAPPING_LUT_BLENDER_PATH),
  }
  render3d_tonemapping_lut_handles_ref.val = Some(handles)
  handles
}

///|
fn render3d_bloom_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_max_mip_dimension(value : Int) -> Int {
  if value < 4 {
    4
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_scale_axis(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_sanitize(bloom : Bloom) -> Bloom {
  Bloom::{
    intensity: render3d_bloom_clamp_non_negative(bloom.intensity),
    low_frequency_boost: render3d_bloom_clamp_unit(bloom.low_frequency_boost),
    low_frequency_boost_curvature: render3d_bloom_clamp_unit(
      bloom.low_frequency_boost_curvature,
    ),
    high_pass_frequency: render3d_bloom_clamp_unit(bloom.high_pass_frequency),
    prefilter: BloomPrefilter::{
      threshold: render3d_bloom_clamp_non_negative(bloom.prefilter.threshold),
      threshold_softness: render3d_bloom_clamp_unit(
        bloom.prefilter.threshold_softness,
      ),
    },
    composite_mode: bloom.composite_mode,
    max_mip_dimension: render3d_bloom_safe_max_mip_dimension(
      bloom.max_mip_dimension,
    ),
    scale: @math.Vec2::new(
      render3d_bloom_safe_scale_axis(bloom.scale.x),
      render3d_bloom_safe_scale_axis(bloom.scale.y),
    ),
  }
}

///|
fn render3d_tonemapping_mode_to_int(mode : Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
  }
}

///|
fn render3d_fxaa_sensitivity_edge_threshold(
  sensitivity : FxaaSensitivity,
) -> Float {
  match sensitivity {
    Low => 0.250F
    Medium => 0.166F
    High => 0.125F
    Ultra => 0.063F
    Extreme => 0.031F
  }
}

///|
fn render3d_fxaa_sensitivity_edge_threshold_min(
  sensitivity : FxaaSensitivity,
) -> Float {
  match sensitivity {
    Low => 0.0833F
    Medium => 0.0625F
    High => 0.0312F
    Ultra => 0.0156F
    Extreme => 0.0078F
  }
}

///|
fn render3d_fxaa_postprocess_values(fxaa : Fxaa?) -> (Int, Float, Float) {
  match fxaa {
    Some(value) =>
      (
        if value.enabled {
          1
        } else {
          0
        },
        render3d_fxaa_sensitivity_edge_threshold(value.edge_threshold),
        render3d_fxaa_sensitivity_edge_threshold_min(value.edge_threshold_min),
      )
    None =>
      (
        0,
        render3d_fxaa_sensitivity_edge_threshold(FxaaSensitivity::default()),
        render3d_fxaa_sensitivity_edge_threshold_min(FxaaSensitivity::default()),
      )
  }
}

///|
fn render3d_chromatic_aberration_postprocess_values(
  chromatic_aberration : ChromaticAberration?,
) -> (Float, Int) {
  match chromatic_aberration {
    Some(value) =>
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.max_samples <= 0 {
          1
        } else {
          value.max_samples
        },
      )
    None => {
      let defaults = ChromaticAberration::default()
      (0.0F, defaults.max_samples)
    }
  }
}

///|
fn render3d_vignette_postprocess_values(
  vignette : Vignette?,
) -> (
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
) {
  match vignette {
    Some(value) => {
      let safe_edge_compensation = if value.edge_compensation < 0.0F {
        0.0F
      } else if value.edge_compensation > 1.0F {
        1.0F
      } else {
        value.edge_compensation
      }
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.radius < 0.0F {
          0.0F
        } else {
          value.radius
        },
        if value.smoothness <= 0.01F {
          0.01F
        } else {
          value.smoothness
        },
        if value.roundness <= 0.01F {
          0.01F
        } else {
          value.roundness
        },
        value.center.x,
        value.center.y,
        safe_edge_compensation,
        value.color.r,
        value.color.g,
        value.color.b,
        value.color.a,
      )
    }
    None => {
      let defaults = Vignette::default()
      (
        0.0F,
        defaults.radius,
        defaults.smoothness,
        defaults.roundness,
        defaults.center.x,
        defaults.center.y,
        defaults.edge_compensation,
        defaults.color.r,
        defaults.color.g,
        defaults.color.b,
        defaults.color.a,
      )
    }
  }
}

///|
fn render3d_draw_camera_bloom(
  scene_texture_id : Int,
  bloom : Bloom,
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  fxaa : Fxaa?,
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let luts = render3d_tonemapping_lut_handles()
  let settings = render3d_bloom_sanitize(bloom)
  let (fxaa_enabled, fxaa_edge_threshold, fxaa_edge_threshold_min) = render3d_fxaa_postprocess_values(
    fxaa,
  )
  let (chromatic_aberration_intensity, chromatic_aberration_max_samples) = render3d_chromatic_aberration_postprocess_values(
    chromatic_aberration,
  )
  let (
    vignette_intensity,
    vignette_radius,
    vignette_smoothness,
    vignette_roundness,
    vignette_center_x,
    vignette_center_y,
    vignette_edge_compensation,
    vignette_color_r,
    vignette_color_g,
    vignette_color_b,
    vignette_color_a,
  ) = render3d_vignette_postprocess_values(vignette)
  @window.host_gpu_draw_bloom2d(
    scene_texture_id~,
    enabled=1,
    intensity=settings.intensity,
    low_frequency_boost=settings.low_frequency_boost,
    low_frequency_boost_curvature=settings.low_frequency_boost_curvature,
    high_pass_frequency=settings.high_pass_frequency,
    threshold=settings.prefilter.threshold,
    threshold_softness=settings.prefilter.threshold_softness,
    composite_mode=match settings.composite_mode {
      EnergyConserving => 0
      Additive => 1
    },
    max_mip_dimension=settings.max_mip_dimension,
    scale_x=settings.scale.x,
    scale_y=settings.scale.y,
    tonemapping_mode=match tonemapping {
      Some(mode) => render3d_tonemapping_mode_to_int(mode)
      None => 0
    },
    deband_dither_enabled=match deband_dither {
      Some(Enabled) => 1
      _ => 0
    },
    fxaa_enabled~,
    fxaa_edge_threshold~,
    fxaa_edge_threshold_min~,
    chromatic_aberration_intensity~,
    chromatic_aberration_max_samples~,
    vignette_intensity~,
    vignette_radius~,
    vignette_smoothness~,
    vignette_roundness~,
    vignette_center_x~,
    vignette_center_y~,
    vignette_edge_compensation~,
    vignette_color_r~,
    vignette_color_g~,
    vignette_color_b~,
    vignette_color_a~,
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony.id(),
    blender_lut_texture_id=luts.blender.id(),
  )
}

///|
fn render3d_draw_camera_tonemap_only(
  scene_texture_id : Int,
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  fxaa : Fxaa?,
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let luts = render3d_tonemapping_lut_handles()
  let bloom_defaults = render3d_bloom_sanitize(Bloom::default())
  let (fxaa_enabled, fxaa_edge_threshold, fxaa_edge_threshold_min) = render3d_fxaa_postprocess_values(
    fxaa,
  )
  let (chromatic_aberration_intensity, chromatic_aberration_max_samples) = render3d_chromatic_aberration_postprocess_values(
    chromatic_aberration,
  )
  let (
    vignette_intensity,
    vignette_radius,
    vignette_smoothness,
    vignette_roundness,
    vignette_center_x,
    vignette_center_y,
    vignette_edge_compensation,
    vignette_color_r,
    vignette_color_g,
    vignette_color_b,
    vignette_color_a,
  ) = render3d_vignette_postprocess_values(vignette)
  @window.host_gpu_draw_bloom2d(
    scene_texture_id~,
    enabled=0,
    intensity=0.0F,
    low_frequency_boost=bloom_defaults.low_frequency_boost,
    low_frequency_boost_curvature=bloom_defaults.low_frequency_boost_curvature,
    high_pass_frequency=bloom_defaults.high_pass_frequency,
    threshold=bloom_defaults.prefilter.threshold,
    threshold_softness=bloom_defaults.prefilter.threshold_softness,
    composite_mode=match bloom_defaults.composite_mode {
      EnergyConserving => 0
      Additive => 1
    },
    max_mip_dimension=bloom_defaults.max_mip_dimension,
    scale_x=bloom_defaults.scale.x,
    scale_y=bloom_defaults.scale.y,
    tonemapping_mode=match tonemapping {
      Some(mode) => render3d_tonemapping_mode_to_int(mode)
      None => 0
    },
    deband_dither_enabled=match deband_dither {
      Some(Enabled) => 1
      _ => 0
    },
    fxaa_enabled~,
    fxaa_edge_threshold~,
    fxaa_edge_threshold_min~,
    chromatic_aberration_intensity~,
    chromatic_aberration_max_samples~,
    vignette_intensity~,
    vignette_radius~,
    vignette_smoothness~,
    vignette_roundness~,
    vignette_center_x~,
    vignette_center_y~,
    vignette_edge_compensation~,
    vignette_color_r~,
    vignette_color_g~,
    vignette_color_b~,
    vignette_color_a~,
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony.id(),
    blender_lut_texture_id=luts.blender.id(),
  )
}

///|
const COLOR_GRADING_TWO_PI : Float = 6.283185307179586F

///|
const COLOR_GRADING_HUE_SEXTANT : Float = 1.0471975511965976F

///|
fn render3d_wrap_angle(angle : Float) -> Float {
  let mut wrapped = angle
  while wrapped < 0.0F {
    wrapped = wrapped + COLOR_GRADING_TWO_PI
  }
  while wrapped >= COLOR_GRADING_TWO_PI {
    wrapped = wrapped - COLOR_GRADING_TWO_PI
  }
  wrapped
}

///|
fn render3d_rgb_to_hsv(
  r : Float,
  g : Float,
  b : Float,
) -> (Float, Float, Float) {
  let max_component = maxf(r, maxf(g, b))
  let min_component = minf(r, minf(g, b))
  let delta = max_component - min_component
  let mut hue = 0.0F
  if delta > 0.000001F {
    if max_component >= g && max_component >= b {
      hue = (g - b) / delta
      if hue < 0.0F {
        hue = hue + 6.0F
      }
    } else if max_component >= b {
      hue = (b - r) / delta + 2.0F
    } else {
      hue = (r - g) / delta + 4.0F
    }
    hue = hue * COLOR_GRADING_HUE_SEXTANT
  }
  let saturation = if max_component <= 0.000001F {
    0.0F
  } else {
    delta / max_component
  }
  (render3d_wrap_angle(hue), saturation, max_component)
}

///|
fn render3d_hsv_to_rgb(
  h : Float,
  s : Float,
  v : Float,
) -> (Float, Float, Float) {
  let hue = render3d_wrap_angle(h)
  let safe_saturation = clamp01(s)
  let c = v * safe_saturation
  let h_prime = hue / COLOR_GRADING_HUE_SEXTANT
  let mut h_mod = h_prime
  while h_mod >= 2.0F {
    h_mod = h_mod - 2.0F
  }
  while h_mod < 0.0F {
    h_mod = h_mod + 2.0F
  }
  let x = c * (1.0F - absf(h_mod - 1.0F))
  let (r1, g1, b1) = if h_prime < 1.0F {
    (c, x, 0.0F)
  } else if h_prime < 2.0F {
    (x, c, 0.0F)
  } else if h_prime < 3.0F {
    (0.0F, c, x)
  } else if h_prime < 4.0F {
    (0.0F, x, c)
  } else if h_prime < 5.0F {
    (x, 0.0F, c)
  } else {
    (c, 0.0F, x)
  }
  let m = v - c
  (r1 + m, g1 + m, b1 + m)
}

///|
fn render3d_apply_white_balance(
  r : Float,
  g : Float,
  b : Float,
  temperature : Float,
  tint : Float,
) -> (Float, Float, Float) {
  if absf(temperature) < 0.000001F && absf(tint) < 0.000001F {
    return (r, g, b)
  }
  let white_point_x = 0.31272F - temperature
  let white_point_y_unclamped = 0.32903F + tint
  let white_point_y = if white_point_y_unclamped < 0.0001F {
    0.0001F
  } else {
    white_point_y_unclamped
  }
  let white_point_lms_x = 0.701634F +
    (-0.051461F + 0.452749F * white_point_x) / white_point_y
  let white_point_lms_y = 1.15856F +
    (0.045854F - 0.296122F * white_point_x) / white_point_y
  let white_point_lms_z = -0.904175F +
    (0.953127F - 0.955206F * white_point_x) / white_point_y
  let adjust_l = 0.975538F / white_point_lms_x
  let adjust_m = 1.01648F / white_point_lms_y
  let adjust_s = 1.08475F / white_point_lms_z

  let l = (0.311692F * r + 0.652085F * g + 0.0362225F * b) * adjust_l
  let m = (0.0905138F * r + 0.901341F * g + 0.00814478F * b) * adjust_m
  let s = (0.00764433F * r + 0.0486554F * g + 0.943700F * b) * adjust_s

  let balanced_r = 4.06305F * l + -2.93241F * m + -0.130646F * s
  let balanced_g = -0.40791F * l + 1.40437F * m + 0.00353630F * s
  let balanced_b = -0.0118812F * l + -0.0486532F * m + 1.0605344F * s
  (maxf(0.0F, balanced_r), maxf(0.0F, balanced_g), maxf(0.0F, balanced_b))
}

///|
fn render3d_color_luminance(r : Float, g : Float, b : Float) -> Float {
  clamp01(r * 0.2126F + g * 0.7152F + b * 0.0722F)
}

///|
fn render3d_color_apply_saturation(
  r : Float,
  g : Float,
  b : Float,
  saturation : Float,
) -> (Float, Float, Float) {
  let safe_saturation = if saturation < 0.0F { 0.0F } else { saturation }
  let luminance = render3d_color_luminance(r, g, b)
  let nr = luminance + (r - luminance) * safe_saturation
  let ng = luminance + (g - luminance) * safe_saturation
  let nb = luminance + (b - luminance) * safe_saturation
  (nr, ng, nb)
}

///|
fn render3d_apply_color_grading_section(
  r : Float,
  g : Float,
  b : Float,
  section : ColorGradingSection,
) -> (Float, Float, Float) {
  let mut cr = r
  let mut cg = g
  let mut cb = b
  let (sr, sg, sb) = render3d_color_apply_saturation(
    cr,
    cg,
    cb,
    section.saturation,
  )
  cr = sr
  cg = sg
  cb = sb
  let safe_contrast = if section.contrast < 0.0F {
    0.0F
  } else {
    section.contrast
  }
  cr = (cr - 0.5F) * safe_contrast + 0.5F
  cg = (cg - 0.5F) * safe_contrast + 0.5F
  cb = (cb - 0.5F) * safe_contrast + 0.5F
  let safe_gain = if section.gain < 0.0F { 0.0F } else { section.gain }
  cr = cr * safe_gain + section.lift
  cg = cg * safe_gain + section.lift
  cb = cb * safe_gain + section.lift
  let safe_gamma = if section.gamma <= 0.0001F {
    0.0001F
  } else {
    section.gamma
  }
  cr = @math.pow(maxf(0.0F, cr), 1.0F / safe_gamma)
  cg = @math.pow(maxf(0.0F, cg), 1.0F / safe_gamma)
  cb = @math.pow(maxf(0.0F, cb), 1.0F / safe_gamma)
  (cr, cg, cb)
}

///|
fn render3d_apply_camera_color_controls(
  r : Float,
  g : Float,
  b : Float,
  exposure : Exposure?,
  color_grading : ColorGrading?,
) -> (Float, Float, Float) {
  let default_exposure = Exposure::default()
  let ev100 = match exposure {
    Some(value) => value.ev100
    None => default_exposure.ev100
  }
  let grading = match color_grading {
    Some(value) => value
    None => ColorGrading::default()
  }
  let exposure_scale = @math.pow(2.0F, default_exposure.ev100 - ev100) *
    @math.pow(2.0F, grading.global.exposure)
  let mut cr = maxf(0.0F, r)
  let mut cg = maxf(0.0F, g)
  let mut cb = maxf(0.0F, b)

  if absf(grading.global.hue) > 0.000001F {
    let (h, s, v) = render3d_rgb_to_hsv(cr, cg, cb)
    let (rotated_r, rotated_g, rotated_b) = render3d_hsv_to_rgb(
      h + grading.global.hue,
      s,
      v,
    )
    cr = rotated_r
    cg = rotated_g
    cb = rotated_b
  }

  let (balanced_r, balanced_g, balanced_b) = render3d_apply_white_balance(
    cr,
    cg,
    cb,
    grading.global.temperature,
    grading.global.tint,
  )
  cr = balanced_r
  cg = balanced_g
  cb = balanced_b

  let luminance = render3d_color_luminance(cr, cg, cb)
  let section = if luminance < grading.global.midtones_start {
    grading.shadows
  } else if luminance > grading.global.midtones_end {
    grading.highlights
  } else {
    grading.midtones
  }
  let (section_r, section_g, section_b) = render3d_apply_color_grading_section(
    cr, cg, cb, section,
  )
  cr = section_r
  cg = section_g
  cb = section_b
  cr = maxf(0.0F, cr * exposure_scale)
  cg = maxf(0.0F, cg * exposure_scale)
  cb = maxf(0.0F, cb * exposure_scale)
  let (post_r, post_g, post_b) = render3d_color_apply_saturation(
    cr,
    cg,
    cb,
    grading.global.post_saturation,
  )
  (clamp01(post_r), clamp01(post_g), clamp01(post_b))
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
fn render3d_inverse_transform_point(
  transform : @math.Transform,
  world_point : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let translated = world_point.sub(transform.translation)
  let rotated = render3d_rotate_by_quat(
    translated,
    render3d_quat_conjugate(transform.rotation),
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
fn render3d_inverse_transform_direction(
  transform : @math.Transform,
  world_direction : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let rotated = render3d_rotate_by_quat(
    world_direction,
    render3d_quat_conjugate(transform.rotation),
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
fn render3d_transform_local_normal(
  transform : @math.Transform,
  local_normal : @math.Vec3,
) -> @math.Vec3 {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return render3d_rotate_by_quat(local_normal, transform.rotation).normalize_or_zero()
  }
  let scaled = @math.Vec3::new(
    local_normal.x / transform.scale.x,
    local_normal.y / transform.scale.y,
    local_normal.z / transform.scale.z,
  )
  render3d_rotate_by_quat(scaled, transform.rotation).normalize_or_zero()
}

///|
fn render3d_ray_local_aabb_hit(
  origin : @math.Vec3,
  direction : @math.Vec3,
  min_corner : @math.Vec3,
  max_corner : @math.Vec3,
  ray_epsilon : Float,
  max_distance : Float,
) -> (Float, @math.Vec3)? {
  let mut t_min = -max_distance
  let mut t_max = max_distance
  let mut enter_normal = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let mut exit_normal = @math.Vec3::new(-1.0F, 0.0F, 0.0F)

  let axes : Array[(@math.Vec3, Float, Float, Float, Float)] = [
    (
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      origin.x,
      direction.x,
      min_corner.x,
      max_corner.x,
    ),
    (
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      origin.y,
      direction.y,
      min_corner.y,
      max_corner.y,
    ),
    (
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
      origin.z,
      direction.z,
      min_corner.z,
      max_corner.z,
    ),
  ]

  for axis_data in axes {
    let axis = axis_data.0
    let o = axis_data.1
    let d = axis_data.2
    let slab_min = axis_data.3
    let slab_max = axis_data.4
    if absf(d) <= 1.0e-9F {
      if o < slab_min || o > slab_max {
        return None
      }
      continue
    }

    let inv_d = 1.0F / d
    let mut t1 = (slab_min - o) * inv_d
    let mut t2 = (slab_max - o) * inv_d
    let mut near_normal = axis.neg()
    let mut far_normal = axis
    if t1 > t2 {
      let t_swap = t1
      t1 = t2
      t2 = t_swap
      let normal_swap = near_normal
      near_normal = far_normal
      far_normal = normal_swap
    }
    if t1 > t_min {
      t_min = t1
      enter_normal = near_normal
    }
    if t2 < t_max {
      t_max = t2
      exit_normal = far_normal
    }
    if t_min > t_max {
      return None
    }
  }

  if t_max < ray_epsilon {
    return None
  }
  let (distance, normal) = if t_min >= ray_epsilon {
    (t_min, enter_normal)
  } else {
    (t_max, exit_normal)
  }
  if distance < ray_epsilon || distance > max_distance {
    return None
  }
  Some((distance, normal))
}

///|
fn render3d_mesh_local_aabb(mesh3d : Mesh3d) -> (@math.Vec3, @math.Vec3)? {
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
    (@math.Vec3::new(min_x, min_y, min_z), @math.Vec3::new(max_x, max_y, max_z)),
  )
}

///|
fn render3d_mesh_local_aabb_center(mesh3d : Mesh3d) -> @math.Vec3? {
  if render3d_mesh_local_aabb(mesh3d) is Some((min_corner, max_corner)) {
    Some(
      @math.Vec3::new(
        (min_corner.x + max_corner.x) * 0.5F,
        (min_corner.y + max_corner.y) * 0.5F,
        (min_corner.z + max_corner.z) * 0.5F,
      ),
    )
  } else {
    None
  }
}

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
  @math.pow(FOG_FALLOFF_E, value)
}

///|
fn render3d_fog_channel_factor(density : Float, distance : Float) -> Float {
  let safe_density = if density < 0.0F { 0.0F } else { density }
  1.0F - render3d_pow_e(-(safe_density * distance))
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
    Atmospheric(extinction, inscattering) => {
      let extinction_max = maxf(maxf(extinction.x, extinction.y), extinction.z)
      let inscattering_max = maxf(
        maxf(inscattering.x, inscattering.y),
        inscattering.z,
      )
      let extinction_factor = render3d_fog_channel_factor(
        extinction_max, safe_distance,
      )
      let inscattering_factor = render3d_fog_channel_factor(
        inscattering_max, safe_distance,
      )
      clamp01((extinction_factor + inscattering_factor) * 0.5F)
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
fn render3d_distance_fog_directional_mix(
  fog : DistanceFog,
  fog_presence : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
  lighting : Render3dLightingState,
) -> Float {
  let directional_alpha = clamp01(fog.directional_light_color.a)
  if directional_alpha <= 0.0F {
    return 0.0F
  }
  if fog.directional_light_exponent <= 0.0F {
    return 0.0F
  }
  if lighting.directional_illuminance <= 0.0F {
    return 0.0F
  }
  let view_direction = mesh_position.sub(camera_position).normalize_or_zero()
  let light_direction = lighting.directional_dir.neg().normalize_or_zero()
  let alignment = clamp01(light_direction.dot(view_direction) * 0.5F + 0.5F)
  let phase = @math.pow(alignment, fog.directional_light_exponent)
  let illuminance_mix = clamp01(lighting.directional_illuminance / 50_000.0F)
  clamp01(phase * directional_alpha * illuminance_mix * fog_presence)
}

///|
fn render3d_apply_distance_fog(
  fog : DistanceFog,
  distance : Float,
  base_r : Float,
  base_g : Float,
  base_b : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
  lighting : Render3dLightingState,
) -> (Float, Float, Float) {
  let fog_alpha = clamp01(fog.color.a)
  let mut fogged_r = base_r
  let mut fogged_g = base_g
  let mut fogged_b = base_b
  let mut fog_presence = 0.0F

  match fog.falloff {
    Atmospheric(extinction, inscattering) => {
      let extinction_r = clamp01(
        render3d_fog_channel_factor(extinction.x, distance) * fog_alpha,
      )
      let extinction_g = clamp01(
        render3d_fog_channel_factor(extinction.y, distance) * fog_alpha,
      )
      let extinction_b = clamp01(
        render3d_fog_channel_factor(extinction.z, distance) * fog_alpha,
      )
      let inscattering_r = clamp01(
        render3d_fog_channel_factor(inscattering.x, distance) * fog_alpha,
      )
      let inscattering_g = clamp01(
        render3d_fog_channel_factor(inscattering.y, distance) * fog_alpha,
      )
      let inscattering_b = clamp01(
        render3d_fog_channel_factor(inscattering.z, distance) * fog_alpha,
      )

      fogged_r = base_r * (1.0F - extinction_r) + fog.color.r * inscattering_r
      fogged_g = base_g * (1.0F - extinction_g) + fog.color.g * inscattering_g
      fogged_b = base_b * (1.0F - extinction_b) + fog.color.b * inscattering_b

      let extinction_peak = maxf(maxf(extinction_r, extinction_g), extinction_b)
      let inscattering_peak = maxf(
        maxf(inscattering_r, inscattering_g),
        inscattering_b,
      )
      fog_presence = clamp01((extinction_peak + inscattering_peak) * 0.5F)
    }
    _ => {
      let fog_mix = render3d_distance_fog_mix_factor(fog, distance)
      fogged_r = base_r * (1.0F - fog_mix) + fog.color.r * fog_mix
      fogged_g = base_g * (1.0F - fog_mix) + fog.color.g * fog_mix
      fogged_b = base_b * (1.0F - fog_mix) + fog.color.b * fog_mix
      fog_presence = fog_mix
    }
  }

  let directional_mix = render3d_distance_fog_directional_mix(
    fog, fog_presence, camera_position, mesh_position, lighting,
  )
  if directional_mix > 0.0F {
    let directional_tint_r = clamp01(
      fog.directional_light_color.r * lighting.directional_color.r,
    )
    let directional_tint_g = clamp01(
      fog.directional_light_color.g * lighting.directional_color.g,
    )
    let directional_tint_b = clamp01(
      fog.directional_light_color.b * lighting.directional_color.b,
    )
    fogged_r = fogged_r * (1.0F - directional_mix) +
      directional_tint_r * directional_mix
    fogged_g = fogged_g * (1.0F - directional_mix) +
      directional_tint_g * directional_mix
    fogged_b = fogged_b * (1.0F - directional_mix) +
      directional_tint_b * directional_mix
  }

  (clamp01(fogged_r), clamp01(fogged_g), clamp01(fogged_b))
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
  specular_tint_texture_id : Int,
  draw_surface_roughness : Float,
  draw_reflectance : Float,
  draw_diffuse_transmission : Float,
  draw_specular_transmission : Float,
  draw_thickness : Float,
  draw_ior : Float,
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  specular_tint : @render2d.Color,
  anisotropy_strength : Float,
  max_relief_mapping_search_steps : Float,
  draw_flags : Int,
) -> Unit {
  let draw_cull_mode_base = match mesh.material.cull_mode {
    None => 0
    Some(face) =>
      match face {
        Face3d::Front => 1
        Face3d::Back => 2
      }
  }
  let draw_cull_mode = draw_cull_mode_base | draw_flags
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
    specular_tint_texture_id~,
    specular_tint_r=specular_tint.r,
    specular_tint_g=specular_tint.g,
    specular_tint_b=specular_tint.b,
    diffuse_transmission=draw_diffuse_transmission,
    specular_transmission=draw_specular_transmission,
    thickness=draw_thickness,
    ior=draw_ior,
    transmission_source_texture_id~,
    transmission_blur_taps~,
    transmission_steps~,
    cull_mode=draw_cull_mode,
  )
}

///|
pub(open) trait Render3dExecuteWorld: HasRes_GlobalAmbientLight + HasRes_WireframeConfig + HasRes_DefaultOpaqueRendererMethod + Has_PointLight + Has_DirectionalLight + Has_SpotLight + Has_Camera3d + Has_CameraProjection3d + Has_SubCameraView3d + Has_ScreenSpaceTransmission + Has_ScreenSpaceReflections + Has_Bloom + Has_Tonemapping + Has_DebandDither + Has_ChromaticAberration + Has_Vignette + Has_MotionBlur + Has_Exposure + Has_ColorGrading + Has_Skybox + Has_EnvironmentMapLight + Has_GeneratedEnvironmentMapLight + Has_LightProbe + Has_Hdr + Has_Fxaa + Has_TemporalJitter + Has_MotionVectorPrepass + Has_TemporalAntiAliasing + Has_Mesh3d + Has_MeshMaterial3d + Has_Wireframe + Has_NoWireframe + Has_WireframeColor + Has_DepthPrepass + Has_DeferredPrepass + Has_Msaa + Has_ForwardDecal + Has_ForwardDecalMaterialExt + Has_ClusteredDecal + @render2d.Has_Camera + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @render2d.Has_GpuMesh2d + @math.Has_Transform + @visibility.Has_ViewVisibility + @visibility.Has_VisibilityRange + @core.ChangeTickWorld {
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
  let screen_space_transmission_store = world.get_screen_space_transmission_store()
  let screen_space_reflections_store = world.get_screen_space_reflections_store()
  let bloom_store = world.get_bloom_store()
  let tonemapping_store = world.get_tonemapping_store()
  let deband_dither_store = world.get_deband_dither_store()
  let chromatic_aberration_store = world.get_chromatic_aberration_store()
  let vignette_store = world.get_vignette_store()
  let motion_blur_store = world.get_motion_blur_store()
  let exposure_store = world.get_exposure_store()
  let color_grading_store = world.get_color_grading_store()
  let skybox_store = world.get_skybox_store()
  let environment_map_light_store = world.get_environment_map_light_store()
  let generated_environment_map_light_store = world.get_generated_environment_map_light_store()
  let light_probe_store = world.get_light_probe_store()
  let hdr_store = world.get_hdr_store()
  let fxaa_store = world.get_fxaa_store()
  let temporal_jitter_store = world.get_temporal_jitter_store()
  let motion_vector_prepass_store = world.get_motion_vector_prepass_store()
  let temporal_anti_aliasing_store = world.get_temporal_anti_aliasing_store()
  let target_store = world.get_render_target_store()
  let layers_store = world.get_render_layers_store()
  let depth_prepass_store = world.get_depth_prepass_store()
  let deferred_prepass_store = world.get_deferred_prepass_store()
  let msaa_store = world.get_msaa_store()
  let transform_store = world.get_transform_store()
  let view_visibility_store = world.get_view_visibility_store()
  let default_opaque_renderer_method = if world
    .get_default_opaque_renderer_method_resource()
    .get_ref()
    is Some(default_method) {
    default_method.val.renderer_method()
  } else {
    OpaqueRendererMethod::Forward
  }
  camera3d_store.for_each(fn(entity, camera3d) {
    let camera = match camera_store.get(entity) {
      Some(v) => v
      None => @render2d.Camera::default()
    }
    let projection = match projection_store.get(entity) {
      Some(v) => v
      None => CameraProjection3d::default()
    }
    let sub_camera_view = sub_camera_view_store.get(entity)
    let screen_space_transmission = screen_space_transmission_store.get(entity)
    let screen_space_reflections = screen_space_reflections_store.get(entity)
    let bloom = bloom_store.get(entity)
    let tonemapping = tonemapping_store.get(entity)
    let deband_dither = deband_dither_store.get(entity)
    let chromatic_aberration = chromatic_aberration_store.get(entity)
    let vignette = vignette_store.get(entity)
    let motion_blur = motion_blur_store.get(entity)
    let exposure = exposure_store.get(entity)
    let color_grading = color_grading_store.get(entity)
    let skybox = skybox_store.get(entity)
    let environment_map_light = environment_map_light_store.get(entity)
    let generated_environment_map_light = generated_environment_map_light_store.get(
      entity,
    )
    let hdr_enabled = hdr_store.get(entity) is Some(_)
    let fxaa = fxaa_store.get(entity)
    let temporal_jitter = temporal_jitter_store.get(entity)
    let motion_vector_prepass_enabled = motion_vector_prepass_store.get(entity)
      is Some(_)
    let temporal_anti_aliasing = temporal_anti_aliasing_store.get(entity)
    let depth_prepass_enabled = depth_prepass_store.get(entity) is Some(_)
    let deferred_prepass_enabled = deferred_prepass_store.get(entity) is Some(_)
    let msaa = msaa_store.get(entity)
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
          camera3d,
          camera: camera_clamped,
          projection,
          sub_camera_view,
          screen_space_transmission,
          screen_space_reflections,
          bloom,
          tonemapping,
          deband_dither,
          chromatic_aberration,
          vignette,
          motion_blur,
          exposure,
          color_grading,
          skybox,
          environment_map_light,
          generated_environment_map_light,
          depth_prepass_enabled,
          deferred_prepass_enabled,
          hdr_enabled,
          fxaa,
          temporal_jitter,
          temporal_anti_aliasing,
          motion_vector_prepass_enabled,
          msaa,
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
  let wireframe_store = world.get_wireframe_store()
  let no_wireframe_store = world.get_no_wireframe_store()
  let wireframe_color_store = world.get_wireframe_color_store()
  let forward_decal_store = world.get_forward_decal_store()
  let forward_decal_material_ext_store = world.get_forward_decal_material_ext_store()
  let clustered_decal_store = world.get_clustered_decal_store()
  let wireframe_config = if world.get_wireframe_config_resource().get_ref()
    is Some(config) {
    Some(config.val)
  } else {
    None
  }
  mesh_store.for_each(fn(entity, mesh3d) {
    if view_visibility_store.get(entity) is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard gpu_mesh_store.get(entity) is Some(gpu_mesh) else { return }
    guard material_store.get(entity) is Some(material_handle) else { return }
    guard standard_material_get(material_handle.material) is Some(base_material) else {
      return
    }
    let material = render3d_apply_extended_material_metadata(
      base_material,
      material_handle.extended_material,
    )
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
      mesh_handle: mesh3d.mesh,
      mesh_id: gpu_mesh.mesh_id,
      transform,
      previous_transform,
      visibility_range,
      aabb_center_world,
      material,
      material_extension: material_handle.extended_material,
      is_forward_decal: forward_decal_store.get(entity) is Some(_),
      forward_decal_material_ext: forward_decal_material_ext_store.get(entity),
      clustered_decal: clustered_decal_store.get(entity),
      layers,
      has_wireframe: wireframe_store.get(entity) is Some(_),
      has_no_wireframe: no_wireframe_store.get(entity) is Some(_),
      wireframe_color: wireframe_color_store.get(entity),
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
  render3d_auto_exposure_history_sync(cameras)
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
    let mut viewport_depth_min = 0.0F
    let mut viewport_depth_max = 1.0F
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
      viewport_depth_min = viewport.depth_min
      viewport_depth_max = viewport.depth_max
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
    let temporal_aa_enabled = camera.temporal_anti_aliasing is Some(_)
    let (sub_camera_view_bias_with_jitter_x, sub_camera_view_bias_with_jitter_y) = if temporal_aa_enabled &&
      camera.temporal_jitter is Some(temporal_jitter) {
      (
        sub_camera_view_bias_x +
        temporal_jitter.offset.x / Float::from_double(view_width.to_double()),
        sub_camera_view_bias_y +
        temporal_jitter.offset.y / Float::from_double(view_height.to_double()),
      )
    } else {
      (sub_camera_view_bias_x, sub_camera_view_bias_y)
    }
    let (camera_fov_y, camera_near, camera_far) = render3d_projection_params(
      camera.projection,
      aspect_ratio,
      Float::from_double(view_height_logical.to_double()),
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
    let camera_deferred_mode = render3d_camera_deferred_mode(
      camera.camera3d.deferred_config,
      default_opaque_renderer_method,
    )
    let camera_deferred_enabled = camera.deferred_prepass_enabled ||
      camera.camera3d.deferred_config.requires_deferred_prepass ||
      camera_deferred_mode is OpaqueRendererMethod::Deferred
    let camera_msaa_allows_forward_decals = match camera.msaa {
      Some(msaa) => msaa is Msaa::Off
      None => true
    }
    let camera_forward_decal_enabled = render3d_decal_mode_allows_forward(
        camera.camera3d.decal_config.mode,
      ) &&
      camera_msaa_allows_forward_decals &&
      (
        !camera.camera3d.decal_config.requires_depth_prepass ||
        camera.depth_prepass_enabled
      )
    let camera_clustered_decal_enabled = render3d_decal_mode_allows_clustered(
        camera.camera3d.decal_config.mode,
      ) &&
      (
        !camera.camera3d.decal_config.clustered_requires_deferred_prepass ||
        camera_deferred_enabled
      )
    let effective_exposure = render3d_camera_effective_exposure(
      camera.entity,
      camera.exposure,
      camera.camera3d.auto_exposure,
      pass_lighting,
    )
    let camera_base_fog = match camera.camera3d.distance_fog {
      Some(value) => value
      None => render3d_distance_fog()
    }
    let distance_fog = render3d_camera_distance_fog(
      camera_base_fog,
      camera.camera3d.volumetric_fog,
      camera.camera3d.atmosphere,
      camera.camera3d.atmosphere_settings,
    )
    let (clear_enabled, clear_color) = camera.camera.clear_color.resolve()
    let motion_blur_active = if camera.motion_blur is Some(motion_blur) {
      motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F
    } else {
      false
    }
    let transmission_blur_taps = if camera.screen_space_transmission
      is Some(transmission) &&
      transmission.steps > 0 {
      screen_space_transmission_blur_taps(transmission.quality)
    } else {
      0
    }
    let transmission_steps = if camera.screen_space_transmission
      is Some(transmission) {
      transmission.steps
    } else {
      0
    }
    let transmission_enabled = transmission_blur_taps > 0
    let bloom_enabled = camera.bloom is Some(_)
    let tonemap_postprocess_enabled = render3d_tonemap_postprocess_enabled(
      camera.tonemapping,
      camera.deband_dither,
      camera.hdr_enabled,
      camera.fxaa,
      camera.chromatic_aberration,
      camera.vignette,
    )
    let motion_vector_prepass_enabled = motion_blur_active ||
      camera.motion_vector_prepass_enabled ||
      temporal_aa_enabled
    let fog_enabled = render3d_distance_fog_enabled(distance_fog)
    let decal_enabled = camera_forward_decal_enabled ||
      camera_clustered_decal_enabled
    let postprocess_enabled = motion_blur_active ||
      bloom_enabled ||
      tonemap_postprocess_enabled
    let scene_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_SCENE,
      postprocess_enabled,
      fog_enabled,
      decal_enabled,
    )
    let motion_vector_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_MOTION_VECTOR,
      false,
      false,
      false,
    )
    let mut scene_target_id = camera.target_id
    let mut velocity_target_id = -1
    if motion_vector_prepass_enabled {
      let (shared_scene_id, shared_velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera.entity,
        view_width,
        view_height,
      )
      if motion_blur_active {
        scene_target_id = shared_scene_id
      }
      velocity_target_id = shared_velocity_id
      @window.host_gpu_begin_pass_3d(
        target_id=velocity_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=0.0F,
        clear_g=0.0F,
        clear_b=0.0F,
        clear_a=0.0F,
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
        sub_camera_view_bias_x=sub_camera_view_bias_with_jitter_x,
        sub_camera_view_bias_y=sub_camera_view_bias_with_jitter_y,
        previous_camera_x=camera.previous_transform.translation.x,
        previous_camera_y=camera.previous_transform.translation.y,
        previous_camera_z=camera.previous_transform.translation.z,
        previous_camera_rot_x=camera.previous_transform.rotation.x,
        previous_camera_rot_y=camera.previous_transform.rotation.y,
        previous_camera_rot_z=camera.previous_transform.rotation.z,
        previous_camera_rot_w=camera.previous_transform.rotation.w,
        pass_kind=motion_vector_pass_kind,
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
          -1,
          0.5F,
          0.5F,
          0.0F,
          0.0F,
          0.0F,
          1.5F,
          -1,
          0.0F,
          0.0F,
          @render2d.Color::white(),
          0.0F,
          0.0F,
          render3d_mesh_draw_flags(mesh),
        )
      }
      @window.host_gpu_end_pass()
    }
    if !motion_blur_active &&
      (transmission_enabled || bloom_enabled || tonemap_postprocess_enabled) &&
      (camera.target_id < 0 || bloom_enabled || tonemap_postprocess_enabled) {
      let (scene_id, _velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera.entity,
        view_width,
        view_height,
      )
      scene_target_id = scene_id
    }
    let mut transmission_source_target_id = -1
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
      sub_camera_view_bias_x=sub_camera_view_bias_with_jitter_x,
      sub_camera_view_bias_y=sub_camera_view_bias_with_jitter_y,
      previous_camera_x=camera.previous_transform.translation.x,
      previous_camera_y=camera.previous_transform.translation.y,
      previous_camera_z=camera.previous_transform.translation.z,
      previous_camera_rot_x=camera.previous_transform.rotation.x,
      previous_camera_rot_y=camera.previous_transform.rotation.y,
      previous_camera_rot_z=camera.previous_transform.rotation.z,
      previous_camera_rot_w=camera.previous_transform.rotation.w,
      pass_kind=scene_pass_kind,
      clear_enabled=if clear_enabled { 1 } else { 0 },
    )
    render3d_draw_camera_skybox(camera, camera_far)
    let draw_order = render3d_sorted_mesh_indices(
      meshes,
      camera.layers,
      camera.transform,
    )
    let transmissive_draws : Array[TransmissionMeshDraw] = []
    for draw_index in draw_order {
      let mesh = meshes[draw_index]
      if mesh.is_forward_decal && !camera_forward_decal_enabled {
        continue
      }
      if mesh.clustered_decal is Some(_) && !camera_clustered_decal_enabled {
        continue
      }
      if mesh.material_extension is Some(extension) {
        if extension.requires_depth_prepass && !camera.depth_prepass_enabled {
          continue
        }
        if extension.requires_deferred_prepass && !camera_deferred_enabled {
          continue
        }
      }
      let mesh_opaque_mode = if mesh.material.opaque_render_method
        is OpaqueRendererMethod::Auto {
        camera_deferred_mode
      } else {
        mesh.material.opaque_render_method
      }
      if mesh_opaque_mode is OpaqueRendererMethod::Deferred &&
        !camera_deferred_enabled {
        continue
      }
      guard render3d_mesh_draw_alpha(
          mesh.material.alpha_mode,
          mesh.material.base_color.a,
        )
        is Some(base_draw_alpha) else {
        continue
      }
      let mut draw_alpha = base_draw_alpha
      let mut texture_id = match mesh.material.base_color_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let mut normal_texture_id = match
        (
          mesh.material.normal_map_texture,
          mesh.material.clearcoat_normal_texture,
        ) {
        (Some(texture), _) => texture.id()
        (None, Some(texture)) => texture.id()
        (None, None) => -1
      }
      let mut emissive_texture_id = match mesh.material.emissive_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let mut metallic_roughness_texture_id = match
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
      let specular_tint_texture_id = match mesh.material.specular_tint_texture {
        Some(texture) => texture.id()
        None => -1
      }
      if mesh.clustered_decal is Some(clustered_decal) {
        if clustered_decal.base_color_texture is Some(texture) {
          texture_id = texture.id()
        }
        if clustered_decal.normal_map_texture is Some(texture) {
          normal_texture_id = texture.id()
        }
        if clustered_decal.metallic_roughness_texture is Some(texture) {
          metallic_roughness_texture_id = texture.id()
        }
        if clustered_decal.emissive_texture is Some(texture) {
          emissive_texture_id = texture.id()
        }
      }
      let anisotropy_strength = maxf(
        0.0F,
        minf(1.0F, mesh.material.anisotropy_strength),
      )
      let max_relief_mapping_search_steps = Float::from_double(
        mesh.material.parallax_mapping_method.max_steps().to_double(),
      )
      let mut clearcoat_reflectance = maxf(
        0.0F,
        mesh.material.reflectance + mesh.material.clearcoat * 0.5F,
      )
      let clearcoat_roughness = minf(
        mesh.material.perceptual_roughness,
        mesh.material.clearcoat_perceptual_roughness,
      )
      let mut draw_roughness = if mesh.material.clearcoat > 0.0F {
        clearcoat_roughness
      } else {
        mesh.material.perceptual_roughness
      }
      let mesh_distance = mesh.transform.translation
        .sub(camera.transform.translation)
        .length()
      if mesh.is_forward_decal {
        let depth_fade_factor = if mesh.forward_decal_material_ext
          is Some(extension) {
          extension.depth_fade_factor
        } else {
          8.0F
        }
        let safe_depth_fade_factor = if depth_fade_factor < 0.001F {
          0.001F
        } else {
          depth_fade_factor
        }
        let decal_alpha = safe_depth_fade_factor /
          (safe_depth_fade_factor + maxf(0.0F, mesh_distance - camera_near))
        draw_alpha = draw_alpha * render3d_float_clamp(decal_alpha, 0.0F, 1.0F)
        clearcoat_reflectance = 0.0F
        draw_roughness = maxf(draw_roughness, 0.85F)
      }
      let (fogged_r, fogged_g, fogged_b) = render3d_apply_distance_fog(
        distance_fog,
        mesh_distance,
        mesh.material.base_color.r,
        mesh.material.base_color.g,
        mesh.material.base_color.b,
        camera.transform.translation,
        mesh.transform.translation,
        pass_lighting,
      )
      let mut draw_color_r = fogged_r
      let mut draw_color_g = fogged_g
      let mut draw_color_b = fogged_b
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
        draw_reflectance = maxf(
          0.0F,
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
          draw_reflectance = maxf(
            0.0F,
            draw_reflectance +
            (1.0F - draw_surface_roughness) * ssr_strength * 0.45F,
          )
          draw_surface_roughness = maxf(
            0.02F,
            draw_surface_roughness * (1.0F - ssr_strength * 0.35F),
          )
        }
      }
      let (graded_color_r, graded_color_g, graded_color_b) = render3d_apply_camera_color_controls(
        draw_color_r,
        draw_color_g,
        draw_color_b,
        effective_exposure,
        camera.color_grading,
      )
      draw_color_r = graded_color_r
      draw_color_g = graded_color_g
      draw_color_b = graded_color_b
      let depth_of_field_weight = render3d_depth_of_field_weight(
        camera.camera3d.depth_of_field,
        mesh_distance,
      )
      if depth_of_field_weight > 0.0F {
        let luminance = render3d_color_luminance(
          draw_color_r, draw_color_g, draw_color_b,
        )
        draw_color_r = clamp01(
          draw_color_r * (1.0F - depth_of_field_weight) +
          luminance * depth_of_field_weight,
        )
        draw_color_g = clamp01(
          draw_color_g * (1.0F - depth_of_field_weight) +
          luminance * depth_of_field_weight,
        )
        draw_color_b = clamp01(
          draw_color_b * (1.0F - depth_of_field_weight) +
          luminance * depth_of_field_weight,
        )
        draw_surface_roughness = maxf(
          draw_surface_roughness,
          depth_of_field_weight * 0.9F,
        )
      }
      let draw_diffuse_transmission = clamp01(
        mesh.material.diffuse_transmission,
      )
      let draw_specular_transmission = clamp01(
        mesh.material.specular_transmission,
      )
      let draw_thickness = maxf(0.0F, mesh.material.thickness)
      let draw_ior = maxf(1.0F, mesh.material.ior)
      let draw_flags = render3d_mesh_draw_flags(mesh)
      if transmission_enabled && draw_specular_transmission > 0.0F {
        transmissive_draws.push(TransmissionMeshDraw::{
          mesh,
          draw_flags,
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
          specular_tint_texture_id,
          draw_surface_roughness,
          draw_reflectance,
          draw_diffuse_transmission,
          draw_specular_transmission,
          draw_thickness,
          draw_ior,
          specular_tint: mesh.material.specular_tint,
          anisotropy_strength,
          max_relief_mapping_search_steps,
        })
        continue
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
        specular_tint_texture_id,
        draw_surface_roughness,
        draw_reflectance,
        draw_diffuse_transmission,
        draw_specular_transmission,
        draw_thickness,
        draw_ior,
        -1,
        0.0F,
        0.0F,
        mesh.material.specular_tint,
        anisotropy_strength,
        max_relief_mapping_search_steps,
        draw_flags,
      )
    }
    if transmissive_draws.length() > 0 {
      @window.host_gpu_end_pass()
      transmission_source_target_id = render3d_transmission_source_target_get_or_create(
        camera.entity,
        view_width,
        view_height,
      )
      render3d_blit_texture_to_target(
        scene_target_id, transmission_source_target_id, view_width_logical, view_height_logical,
      )
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
        sub_camera_view_bias_x=sub_camera_view_bias_with_jitter_x,
        sub_camera_view_bias_y=sub_camera_view_bias_with_jitter_y,
        previous_camera_x=camera.previous_transform.translation.x,
        previous_camera_y=camera.previous_transform.translation.y,
        previous_camera_z=camera.previous_transform.translation.z,
        previous_camera_rot_x=camera.previous_transform.rotation.x,
        previous_camera_rot_y=camera.previous_transform.rotation.y,
        previous_camera_rot_z=camera.previous_transform.rotation.z,
        previous_camera_rot_w=camera.previous_transform.rotation.w,
        pass_kind=scene_pass_kind,
        clear_enabled=0,
      )
      for transmissive_draw in transmissive_draws {
        render3d_draw_mesh_instance(
          transmissive_draw.mesh,
          transmissive_draw.mesh.transform,
          transmissive_draw.mesh.previous_transform,
          transmissive_draw.draw_color_r,
          transmissive_draw.draw_color_g,
          transmissive_draw.draw_color_b,
          transmissive_draw.draw_alpha,
          transmissive_draw.texture_id,
          transmissive_draw.normal_texture_id,
          transmissive_draw.emissive_texture_id,
          transmissive_draw.metallic_roughness_texture_id,
          transmissive_draw.occlusion_texture_id,
          transmissive_draw.depth_texture_id,
          transmissive_draw.anisotropy_texture_id,
          transmissive_draw.specular_tint_texture_id,
          transmissive_draw.draw_surface_roughness,
          transmissive_draw.draw_reflectance,
          transmissive_draw.draw_diffuse_transmission,
          transmissive_draw.draw_specular_transmission,
          transmissive_draw.draw_thickness,
          transmissive_draw.draw_ior,
          transmission_source_target_id,
          Float::from_double(transmission_blur_taps.to_double()),
          Float::from_double(transmission_steps.to_double()),
          transmissive_draw.specular_tint,
          transmissive_draw.anisotropy_strength,
          transmissive_draw.max_relief_mapping_search_steps,
          transmissive_draw.draw_flags,
        )
      }
    }
    for draw_index in draw_order {
      let mesh = meshes[draw_index]
      if !render3d_mesh_should_draw_wireframe(mesh, wireframe_config) {
        continue
      }
      guard render3d_wireframe_mesh_id(mesh.mesh_handle)
        is Some(wireframe_mesh_id) else {
        continue
      }
      let wireframe_color = render3d_mesh_wireframe_color(
        mesh, wireframe_config,
      )
      let wireframe_material = StandardMaterial::{
        ..StandardMaterial::from_color(wireframe_color).with_unlit(true),
        cull_mode: mesh.material.cull_mode,
      }
      guard render3d_mesh_draw_alpha(
          wireframe_material.alpha_mode,
          wireframe_material.base_color.a,
        )
        is Some(wireframe_draw_alpha) else {
        continue
      }
      render3d_draw_mesh_instance(
        Mesh3dInstance::{
          ..mesh,
          mesh_id: wireframe_mesh_id,
          material: wireframe_material,
        },
        mesh.transform,
        mesh.previous_transform,
        wireframe_material.base_color.r,
        wireframe_material.base_color.g,
        wireframe_material.base_color.b,
        wireframe_draw_alpha,
        -1,
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
        0.0F,
        1.5F,
        -1,
        0.0F,
        0.0F,
        @render2d.Color::white(),
        0.0F,
        0.0F,
        render3d_mesh_draw_flags(mesh),
      )
    }
    @window.host_gpu_end_pass()
    let mut final_source_texture_id = -1
    if motion_blur_active &&
      camera.motion_blur is Some(motion_blur) &&
      velocity_target_id >= 0 {
      if bloom_enabled || tonemap_postprocess_enabled {
        let post_motion_blur_target_id = render3d_transmission_source_target_get_or_create(
          camera.entity,
          view_width,
          view_height,
        )
        @window.host_gpu_begin_pass(
          target_id=post_motion_blur_target_id,
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
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        @window.host_gpu_draw_motion_blur(
          scene_texture_id=scene_target_id,
          velocity_texture_id=velocity_target_id,
          shutter_angle=motion_blur.shutter_angle,
          samples=motion_blur.samples,
        )
        @window.host_gpu_end_pass()
        final_source_texture_id = post_motion_blur_target_id
      } else {
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
          viewport_depth_min~,
          viewport_depth_max~,
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
    } else if scene_target_id != camera.target_id {
      final_source_texture_id = scene_target_id
    }
    if bloom_enabled && camera.bloom is Some(bloom) {
      let bloom_source_texture_id = if final_source_texture_id >= 0 {
        final_source_texture_id
      } else {
        scene_target_id
      }
      if bloom_source_texture_id >= 0 {
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
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        render3d_draw_camera_bloom(
          bloom_source_texture_id,
          bloom,
          camera.tonemapping,
          camera.deband_dither,
          camera.fxaa,
          camera.chromatic_aberration,
          camera.vignette,
          view_width_logical,
          view_height_logical,
        )
        @window.host_gpu_end_pass()
      }
    } else if tonemap_postprocess_enabled {
      let tonemap_source_texture_id = if final_source_texture_id >= 0 {
        final_source_texture_id
      } else {
        scene_target_id
      }
      if tonemap_source_texture_id >= 0 {
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
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        render3d_draw_camera_tonemap_only(
          tonemap_source_texture_id,
          camera.tonemapping,
          camera.deband_dither,
          camera.fxaa,
          camera.chromatic_aberration,
          camera.vignette,
          view_width_logical,
          view_height_logical,
        )
        @window.host_gpu_end_pass()
      }
    } else if final_source_texture_id >= 0 {
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
        viewport_depth_min~,
        viewport_depth_max~,
        clear_enabled=if clear_enabled { 1 } else { 0 },
      )
      @window.host_gpu_draw_sprite_uv(
        texture_id=final_source_texture_id,
        x=0.0F,
        y=0.0F,
        rotation=0.0F,
        scale_x=Float::from_double(view_width_logical.to_double()) / 128.0F,
        scale_y=Float::from_double(view_height_logical.to_double()) / 128.0F,
        color_r=1.0F,
        color_g=1.0F,
        color_b=1.0F,
        color_a=1.0F,
        uv_min_x=0.0F,
        uv_min_y=0.0F,
        uv_max_x=1.0F,
        uv_max_y=1.0F,
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
  let half_height = match orthographic.scaling_mode {
    WindowSize => {
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
      0.5F * safe_viewport_height * safe_scale
    }
    Scale => {
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
      0.5F * safe_viewport_height * safe_scale
    }
    FixedVertical(viewport_height_world) => {
      let safe_viewport_height_world = if viewport_height_world <= 0.0F {
        1.0F
      } else {
        viewport_height_world
      }
      0.5F * safe_viewport_height_world
    }
  }
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
const MESH_RAY_CAST_DEFAULT_MAX_DISTANCE : Float = 1_000_000.0F

///|
const MESH_RAY_CAST_DEFAULT_RAY_EPSILON : Float = 0.000001F

///|
const MESH_RAY_CAST_DEFAULT_MAX_HITS : Int = 64

///|
pub struct MeshRayCastSettings {
  max_distance : Float
  ray_epsilon : Float
  max_hits : Int
  include_invisible : Bool
  only_entities : Array[@core.Entity]?
}

///|
pub fn MeshRayCastSettings::default() -> MeshRayCastSettings {
  {
    max_distance: MESH_RAY_CAST_DEFAULT_MAX_DISTANCE,
    ray_epsilon: MESH_RAY_CAST_DEFAULT_RAY_EPSILON,
    max_hits: MESH_RAY_CAST_DEFAULT_MAX_HITS,
    include_invisible: false,
    only_entities: None,
  }
}

///|
pub fn MeshRayCastSettings::with_max_distance(
  self : MeshRayCastSettings,
  max_distance : Float,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, max_distance, }
}

///|
pub fn MeshRayCastSettings::with_ray_epsilon(
  self : MeshRayCastSettings,
  ray_epsilon : Float,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, ray_epsilon, }
}

///|
pub fn MeshRayCastSettings::with_max_hits(
  self : MeshRayCastSettings,
  max_hits : Int,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, max_hits, }
}

///|
pub fn MeshRayCastSettings::with_include_invisible(
  self : MeshRayCastSettings,
  include_invisible : Bool,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, include_invisible, }
}

///|
pub fn MeshRayCastSettings::with_only_entities(
  self : MeshRayCastSettings,
  only_entities : Array[@core.Entity]?,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, only_entities, }
}

///|
pub struct MeshRayCastHit {
  point : @math.Vec3
  normal : @math.Vec3
  distance : Float
}

///|
pub(open) trait MeshRayCastWorld: Has_Mesh3d + @math.Has_Transform + @visibility.Has_ViewVisibility {
}

///|
fn render3d_entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn render3d_entity_in_list(
  entity : @core.Entity,
  entities : Array[@core.Entity],
) -> Bool {
  for candidate in entities {
    if render3d_entity_eq(entity, candidate) {
      return true
    }
  }
  false
}

///|
pub fn[W : MeshRayCastWorld] mesh_ray_cast(
  world : W,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  let ray_direction = direction.normalize_or_zero()
  if ray_direction.length_squared() <= 1.0e-12F {
    return []
  }
  let max_distance = if settings.max_distance <= 0.0F {
    MESH_RAY_CAST_DEFAULT_MAX_DISTANCE
  } else {
    settings.max_distance
  }
  let ray_epsilon = if settings.ray_epsilon <= 0.0F {
    MESH_RAY_CAST_DEFAULT_RAY_EPSILON
  } else {
    settings.ray_epsilon
  }
  let max_hits = if settings.max_hits <= 0 { 1 } else { settings.max_hits }
  let hits : Array[(@core.Entity, MeshRayCastHit)] = []
  let mesh_store = world.get_mesh3d_store()
  let transform_store = world.get_transform_store()
  let view_visibility_store = world.get_view_visibility_store()

  mesh_store.for_each(fn(entity, mesh3d) {
    if settings.only_entities is Some(only_entities) &&
      !render3d_entity_in_list(entity, only_entities) {
      return
    }
    if !settings.include_invisible &&
      view_visibility_store.get(entity) is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard render3d_mesh_local_aabb(mesh3d) is Some((min_corner, max_corner)) else {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @math.Transform::identity()
    }
    guard render3d_inverse_transform_point(transform, origin)
      is Some(local_origin) else {
      return
    }
    guard render3d_inverse_transform_direction(transform, ray_direction)
      is Some(local_direction) else {
      return
    }
    guard render3d_ray_local_aabb_hit(
        local_origin, local_direction, min_corner, max_corner, ray_epsilon, max_distance,
      )
      is Some((distance, local_normal)) else {
      return
    }
    let normal = render3d_transform_local_normal(transform, local_normal)
    if normal.length_squared() <= 1.0e-12F {
      return
    }
    hits.push(
      (
        entity,
        {
          point: origin.add(ray_direction.mul_scalar(distance)),
          normal,
          distance,
        },
      ),
    )
  })

  hits.sort_by(fn(a, b) {
    let distance_cmp = cmp_float(a.1.distance, b.1.distance)
    if distance_cmp != 0 {
      return distance_cmp
    }
    let id_cmp = cmp_int(a.0.id, b.0.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(a.0.generation, b.0.generation)
  })

  let capped_hits : Array[(@core.Entity, MeshRayCastHit)] = []
  for i in 0..<hits.length() {
    if i >= max_hits {
      break
    }
    capped_hits.push(hits[i])
  }
  capped_hits
}

///|
pub fn[W : MeshRayCastWorld] mesh_ray_cast_first(
  world : W,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  let hits = mesh_ray_cast(world, origin, direction, settings.with_max_hits(1))
  if hits.length() > 0 {
    Some(hits[0])
  } else {
    None
  }
}

///|
pub fn[W : MeshRayCastWorld] mesh_ray_cast_from_camera(
  world : W,
  screen : @math.Vec2,
  camera : @render2d.Camera,
  projection : CameraProjection3d,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  if render3d_camera_viewport_to_world_ray(
      screen, camera, projection, camera_transform, target_size, scale_factor,
    )
    is Some((origin, direction)) {
    mesh_ray_cast(world, origin, direction, settings)
  } else {
    []
  }
}

///|
pub fn[W : MeshRayCastWorld] mesh_ray_cast_from_camera_first(
  world : W,
  screen : @math.Vec2,
  camera : @render2d.Camera,
  projection : CameraProjection3d,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  let hits = mesh_ray_cast_from_camera(
    world,
    screen,
    camera,
    projection,
    camera_transform,
    target_size,
    scale_factor,
    settings.with_max_hits(1),
  )
  if hits.length() > 0 {
    Some(hits[0])
  } else {
    None
  }
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
fn[
  W : HasRes_GlobalAmbientLight + HasRes_PointLightShadowMap + HasRes_DefaultOpaqueRendererMethod + @core.ChangeTickWorld,
] init_render3d_resources(
  world : W,
) -> Unit {
  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if !ambient.is_present() {
    ambient.insert(GlobalAmbientLight::default(), tick)
  }
  let point_light_shadow_map = world.get_point_light_shadow_map_resource()
  if !point_light_shadow_map.is_present() {
    point_light_shadow_map.insert(PointLightShadowMap::default(), tick)
  }
  let default_opaque_renderer_method = world.get_default_opaque_renderer_method_resource()
  if !default_opaque_renderer_method.is_present() {
    default_opaque_renderer_method.insert(
      DefaultOpaqueRendererMethod::forward(),
      tick,
    )
  }
}

///|
fn[W : HasRes_WireframeConfig + @core.ChangeTickWorld] init_wireframe_resources(
  world : W,
) -> Unit {
  let tick = world.read_change_tick()
  let wireframe_config = world.get_wireframe_config_resource()
  if !wireframe_config.is_present() {
    wireframe_config.insert(WireframeConfig::default(), tick)
  }
}

///|
pub(open) trait WireframePluginWorld: HasRes_WireframeConfig + @core.ChangeTickWorld {
}

///|
pub fn[W : WireframePluginWorld] wireframe_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app.add_startup_system(init_wireframe_resources)
}

///|
pub(open) trait Render3dPluginWorld: HasRes_GlobalAmbientLight + HasRes_PointLightShadowMap + HasRes_DefaultOpaqueRendererMethod + Render3dPrepareWorld + Render3dExecuteWorld {
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
