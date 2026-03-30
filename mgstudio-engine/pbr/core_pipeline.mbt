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
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn DecalRenderMode3d::default() -> DecalRenderMode3d {
  DecalRenderMode3d::ForwardAndClustered
}

///|
pub struct CameraDecalConfig3d {
  mode : DecalRenderMode3d
  requires_depth_prepass : Bool
  clustered_requires_deferred_prepass : Bool
} derive(ToJson, FromJson)

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
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn CameraDeferredMode3d::default() -> CameraDeferredMode3d {
  CameraDeferredMode3d::Auto
}

///|
pub struct CameraDeferredConfig3d {
  mode : CameraDeferredMode3d
  requires_deferred_prepass : Bool
} derive(ToJson, FromJson)

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
  compensation_curve : @asset.Handle[AutoExposureCompensationCurve]?
  metering_mask : @asset.Handle[@asset.Image]?
} derive(ToJson, FromJson)

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
    compensation_curve: None,
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
pub fn AutoExposure::with_compensation_curve(
  self : AutoExposure,
  compensation_curve : @asset.Handle[AutoExposureCompensationCurve]?,
) -> AutoExposure {
  AutoExposure::{ ..self, compensation_curve, }
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
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn DepthOfFieldMode::default() -> DepthOfFieldMode {
  DepthOfFieldMode::Gaussian
}

///|
/// API-parity data model aligned with Bevy's `DepthOfField` camera component.
pub(all) struct DepthOfField {
  mut mode : DepthOfFieldMode
  mut focal_distance : Float
  mut sensor_height : Float
  mut aperture_f_stops : Float
  mut max_circle_of_confusion_diameter : Float
  mut max_depth : Float
} derive(ToJson, FromJson)

///|
pub fn DepthOfField::default() -> DepthOfField {
  DepthOfField::{
    mode: DepthOfFieldMode::default(),
    focal_distance: 10.0F,
    sensor_height: PhysicalCameraParameters::default().sensor_height,
    aperture_f_stops: 4.0F,
    max_circle_of_confusion_diameter: 64.0F,
    max_depth: @float.infinity,
  }
}

///|
pub fn DepthOfField::from_physical_camera(
  camera : PhysicalCameraParameters,
) -> DepthOfField {
  let depth_of_field = DepthOfField::default()
  depth_of_field.sensor_height = camera.sensor_height
  depth_of_field.aperture_f_stops = camera.aperture_f_stops
  depth_of_field
}

///|
/// Camera component aligned with Bevy's `Camera3d`.
///
/// This stores feature toggles and per-camera overrides that influence how the
/// current renderer approximates deferred/decal/volumetric/post-process APIs.
pub struct Camera3d {
  decal_config : CameraDecalConfig3d
  deferred_config : CameraDeferredConfig3d
  distance_fog : DistanceFog?
  volumetric_fog : VolumetricFog?
  atmosphere : Atmosphere?
  atmosphere_settings : AtmosphereSettings?
  auto_exposure : AutoExposure?
  depth_of_field : DepthOfField?
} derive(ToJson, FromJson)

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
pub(all) struct PerspectiveProjection3d {
  mut fov : Float
  mut near : Float
  mut far : Float
  mut aspect_ratio : Float
  mut near_clip_plane : @math.Vec4
} derive(ToJson, FromJson)

///|
pub fn PerspectiveProjection3d::default() -> PerspectiveProjection3d {
  PerspectiveProjection3d::{
    // Match Bevy's PerspectiveProjection::default() (PI / 4.0).
    fov: @math.pi_half() * 0.5F,
    near: 0.1F,
    far: 1000.0F,
    aspect_ratio: 1.0F,
    near_clip_plane: @math.Vec4::new(0.0F, 0.0F, -1.0F, -0.1F),
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
    near_clip_plane: self.near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::with_fov(
  self : PerspectiveProjection3d,
  fov : Float,
) -> PerspectiveProjection3d {
  let safe_fov = if fov <= 0.0F { @math.pi_half() * 0.5F } else { fov }
  PerspectiveProjection3d::{
    fov: safe_fov,
    near: self.near,
    far: self.far,
    aspect_ratio: self.aspect_ratio,
    near_clip_plane: self.near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::with_near(
  self : PerspectiveProjection3d,
  near : Float,
) -> PerspectiveProjection3d {
  let previous_default_near_clip_plane = @math.Vec4::new(
    0.0F,
    0.0F,
    -1.0F,
    -self.near,
  )
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  let safe_far = if self.far <= safe_near {
    safe_near + 0.0001F
  } else {
    self.far
  }
  let near_clip_plane = if self.near_clip_plane ==
    previous_default_near_clip_plane {
    @math.Vec4::new(0.0F, 0.0F, -1.0F, -safe_near)
  } else {
    self.near_clip_plane
  }
  PerspectiveProjection3d::{
    fov: self.fov,
    near: safe_near,
    far: safe_far,
    aspect_ratio: self.aspect_ratio,
    near_clip_plane,
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
    near_clip_plane: self.near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::with_near_clip_plane(
  self : PerspectiveProjection3d,
  near_clip_plane : @math.Vec4,
) -> PerspectiveProjection3d {
  PerspectiveProjection3d::{
    fov: self.fov,
    near: self.near,
    far: self.far,
    aspect_ratio: self.aspect_ratio,
    near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::fov(self : PerspectiveProjection3d) -> Float {
  self.fov
}

///|
pub fn PerspectiveProjection3d::near(self : PerspectiveProjection3d) -> Float {
  self.near
}

///|
pub fn PerspectiveProjection3d::far(self : PerspectiveProjection3d) -> Float {
  self.far
}

///|
pub fn PerspectiveProjection3d::aspect_ratio(
  self : PerspectiveProjection3d,
) -> Float {
  self.aspect_ratio
}

///|
pub fn PerspectiveProjection3d::near_clip_plane(
  self : PerspectiveProjection3d,
) -> @math.Vec4 {
  self.near_clip_plane
}

///|
pub(all) struct OrthographicProjection3d {
  mut near : Float
  mut far : Float
  mut viewport_origin : @math.Vec2
  mut scaling_mode : OrthographicScalingMode3d
  mut scale : Float
  mut area : @math.Rect
} derive(ToJson, FromJson)

///|
pub(all) enum OrthographicScalingMode3d {
  WindowSize
  Fixed(Float, Float)
  AutoMin(Float, Float)
  AutoMax(Float, Float)
  FixedVertical(Float)
  FixedHorizontal(Float)
} derive(Eq, Show, ToJson, FromJson)

///|
fn orthographic_scaling_mode_sanitize(
  mode : OrthographicScalingMode3d,
) -> OrthographicScalingMode3d {
  match mode {
    WindowSize => WindowSize
    Fixed(width, height) =>
      Fixed(
        if width <= 0.0F {
          1.0F
        } else {
          width
        },
        if height <= 0.0F {
          1.0F
        } else {
          height
        },
      )
    AutoMin(min_width, min_height) =>
      AutoMin(
        if min_width <= 0.0F {
          1.0F
        } else {
          min_width
        },
        if min_height <= 0.0F {
          1.0F
        } else {
          min_height
        },
      )
    AutoMax(max_width, max_height) =>
      AutoMax(
        if max_width <= 0.0F {
          1.0F
        } else {
          max_width
        },
        if max_height <= 0.0F {
          1.0F
        } else {
          max_height
        },
      )
    FixedVertical(viewport_height) =>
      FixedVertical(
        if viewport_height <= 0.0F {
          1.0F
        } else {
          viewport_height
        },
      )
    FixedHorizontal(viewport_width) =>
      FixedHorizontal(
        if viewport_width <= 0.0F {
          1.0F
        } else {
          viewport_width
        },
      )
  }
}

///|
pub fn OrthographicProjection3d::default_2d() -> OrthographicProjection3d {
  OrthographicProjection3d::{
    ..OrthographicProjection3d::default_3d(),
    near: -1000.0F,
  }
}

///|
pub fn OrthographicProjection3d::default_3d() -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: 0.0F,
    far: 1000.0F,
    viewport_origin: @math.Vec2::new(0.5F, 0.5F),
    scaling_mode: WindowSize,
    scale: 1.0F,
    area: @math.Rect::new(
      @math.Vec2::new(-1.0F, -1.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ),
  }
}

///|
pub fn OrthographicProjection3d::default() -> OrthographicProjection3d {
  OrthographicProjection3d::default_3d()
}

///|
pub fn OrthographicProjection3d::with_scale(
  self : OrthographicProjection3d,
  scale : Float,
) -> OrthographicProjection3d {
  let safe_scale = if scale <= 0.0F { 1.0F } else { scale }
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    scale: safe_scale,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_near(
  self : OrthographicProjection3d,
  near : Float,
) -> OrthographicProjection3d {
  let safe_far = if self.far <= near { near + 0.0001F } else { self.far }
  OrthographicProjection3d::{
    scale: self.scale,
    near,
    far: safe_far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_far(
  self : OrthographicProjection3d,
  far : Float,
) -> OrthographicProjection3d {
  let safe_far = if far <= self.near { self.near + 0.0001F } else { far }
  OrthographicProjection3d::{
    scale: self.scale,
    near: self.near,
    far: safe_far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_scaling_mode(
  self : OrthographicProjection3d,
  scaling_mode : OrthographicScalingMode3d,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin: self.viewport_origin,
    scaling_mode: orthographic_scaling_mode_sanitize(scaling_mode),
    scale: self.scale,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_viewport_origin(
  self : OrthographicProjection3d,
  viewport_origin : @math.Vec2,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin,
    scaling_mode: self.scaling_mode,
    scale: self.scale,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_area(
  self : OrthographicProjection3d,
  area : @math.Rect,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    scale: self.scale,
    area,
  }
}

///|
pub fn OrthographicProjection3d::scale(
  self : OrthographicProjection3d,
) -> Float {
  self.scale
}

///|
pub fn OrthographicProjection3d::near(self : OrthographicProjection3d) -> Float {
  self.near
}

///|
pub fn OrthographicProjection3d::far(self : OrthographicProjection3d) -> Float {
  self.far
}

///|
pub fn OrthographicProjection3d::scaling_mode(
  self : OrthographicProjection3d,
) -> OrthographicScalingMode3d {
  self.scaling_mode
}

///|
pub fn OrthographicProjection3d::viewport_origin(
  self : OrthographicProjection3d,
) -> @math.Vec2 {
  self.viewport_origin
}

///|
pub fn OrthographicProjection3d::area(
  self : OrthographicProjection3d,
) -> @math.Rect {
  self.area
}

///|
pub struct SubCameraView3d {
  full_size : @math.IVec2
  offset : @math.Vec2
  size : @math.IVec2
} derive(ToJson, FromJson)

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
pub(all) struct ProjectionMatrix3d {
  x_axis : @math.Vec4
  y_axis : @math.Vec4
  z_axis : @math.Vec4
  w_axis : @math.Vec4
}

///|
pub fn ProjectionMatrix3d::from_cols(
  x_axis : @math.Vec4,
  y_axis : @math.Vec4,
  z_axis : @math.Vec4,
  w_axis : @math.Vec4,
) -> ProjectionMatrix3d {
  ProjectionMatrix3d::{ x_axis, y_axis, z_axis, w_axis }
}

///|
pub fn ProjectionMatrix3d::mul_vec4(
  self : ProjectionMatrix3d,
  value : @math.Vec4,
) -> @math.Vec4 {
  @math.Vec4::new(
    self.x_axis.x * value.x +
    self.y_axis.x * value.y +
    self.z_axis.x * value.z +
    self.w_axis.x * value.w,
    self.x_axis.y * value.x +
    self.y_axis.y * value.y +
    self.z_axis.y * value.z +
    self.w_axis.y * value.w,
    self.x_axis.z * value.x +
    self.y_axis.z * value.y +
    self.z_axis.z * value.z +
    self.w_axis.z * value.w,
    self.x_axis.w * value.x +
    self.y_axis.w * value.y +
    self.z_axis.w * value.z +
    self.w_axis.w * value.w,
  )
}

///|
pub fn ProjectionMatrix3d::mul(
  self : ProjectionMatrix3d,
  other : ProjectionMatrix3d,
) -> ProjectionMatrix3d {
  ProjectionMatrix3d::from_cols(
    self.mul_vec4(other.x_axis),
    self.mul_vec4(other.y_axis),
    self.mul_vec4(other.z_axis),
    self.mul_vec4(other.w_axis),
  )
}

///|
pub fn ProjectionMatrix3d::project_point3(
  self : ProjectionMatrix3d,
  value : @math.Vec3,
) -> @math.Vec3? {
  let clip = self.mul_vec4(@math.Vec4::new(value.x, value.y, value.z, 1.0F))
  if clip.w == 0.0F {
    return None
  }
  Some(@math.Vec3::new(clip.x / clip.w, clip.y / clip.w, clip.z / clip.w))
}

///|
pub fn ProjectionMatrix3d::w_axis_w(self : ProjectionMatrix3d) -> Float {
  self.w_axis.w
}

///|
pub(open) trait CameraProjection3d {
  get_clip_from_view(self : Self) -> ProjectionMatrix3d
  get_clip_from_view_for_sub(self : Self, sub_view : SubCameraView3d) -> ProjectionMatrix3d
  update(self : Self, width : Float, height : Float) -> Self
  far(self : Self) -> Float
  compute_frustum(self : Self, camera_transform : @transform.Transform) -> Frustum
  get_frustum_corners(self : Self, z_near : Float, z_far : Float) -> Array[
    @math.Vec3,
  ]
}

///|
struct CustomProjection3d {
  type_name : String
  payload : @any.Any
  get_clip_from_view_fn : (@any.Any) -> ProjectionMatrix3d
  get_clip_from_view_for_sub_fn : (@any.Any, SubCameraView3d) -> ProjectionMatrix3d
  update_fn : (@any.Any, Float, Float) -> @any.Any
  far_fn : (@any.Any) -> Float
  get_frustum_corners_fn : (@any.Any, Float, Float) -> Array[@math.Vec3]
}

///|
pub fn[T : CameraProjection3d] CustomProjection3d::new(
  projection : T,
) -> CustomProjection3d {
  let payload = @any.of(projection)
  CustomProjection3d::{
    type_name: payload.type_name(),
    payload,
    get_clip_from_view_fn: fn(payload) {
      let projection : T = try! payload.to()
      projection.get_clip_from_view()
    },
    get_clip_from_view_for_sub_fn: fn(payload, sub_view) {
      let projection : T = try! payload.to()
      projection.get_clip_from_view_for_sub(sub_view)
    },
    update_fn: fn(payload, width, height) {
      let projection : T = try! payload.to()
      @any.of(projection.update(width, height))
    },
    far_fn: fn(payload) {
      let projection : T = try! payload.to()
      projection.far()
    },
    get_frustum_corners_fn: fn(payload, z_near, z_far) {
      let projection : T = try! payload.to()
      projection.get_frustum_corners(z_near, z_far)
    },
  }
}

///|
pub fn CustomProjection3d::default() -> CustomProjection3d {
  CustomProjection3d::new(PerspectiveProjection3d::default())
}

///|
pub fn[T] CustomProjection3d::get(self : CustomProjection3d) -> T? {
  self.payload.try_to()
}

///|
pub fn CustomProjection3d::type_name(self : CustomProjection3d) -> String {
  self.type_name
}

///|
pub fn CustomProjection3d::get_clip_from_view(
  self : CustomProjection3d,
) -> ProjectionMatrix3d {
  (self.get_clip_from_view_fn)(self.payload)
}

///|
pub fn CustomProjection3d::get_clip_from_view_for_sub(
  self : CustomProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  (self.get_clip_from_view_for_sub_fn)(self.payload, sub_view)
}

///|
pub fn CustomProjection3d::update(
  self : CustomProjection3d,
  width : Float,
  height : Float,
) -> CustomProjection3d {
  CustomProjection3d::{
    type_name: self.type_name,
    payload: (self.update_fn)(self.payload, width, height),
    get_clip_from_view_fn: self.get_clip_from_view_fn,
    get_clip_from_view_for_sub_fn: self.get_clip_from_view_for_sub_fn,
    update_fn: self.update_fn,
    far_fn: self.far_fn,
    get_frustum_corners_fn: self.get_frustum_corners_fn,
  }
}

///|
pub fn CustomProjection3d::far(self : CustomProjection3d) -> Float {
  (self.far_fn)(self.payload)
}

///|
pub fn CustomProjection3d::get_frustum_corners(
  self : CustomProjection3d,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  (self.get_frustum_corners_fn)(self.payload, z_near, z_far)
}

///|
pub(all) enum Projection {
  Perspective(PerspectiveProjection3d)
  Orthographic(OrthographicProjection3d)
  Custom(CustomProjection3d)
}

///|
pub fn Projection::default() -> Projection {
  Perspective(PerspectiveProjection3d::default())
}

///|
pub fn[T : CameraProjection3d] Projection::custom(projection : T) -> Projection {
  Custom(CustomProjection3d::new(projection))
}

///|
pub fn Projection::is_perspective(self : Projection) -> Bool {
  match self {
    Perspective(_) => true
    Orthographic(_) => false
    Custom(projection) => projection.get_clip_from_view().w_axis_w() == 0.0F
  }
}

///|
pub fn Projection::get_clip_from_view(self : Projection) -> ProjectionMatrix3d {
  match self {
    Perspective(projection) => projection.get_clip_from_view()
    Orthographic(projection) => projection.get_clip_from_view()
    Custom(projection) => projection.get_clip_from_view()
  }
}

///|
pub fn Projection::get_clip_from_view_for_sub(
  self : Projection,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  match self {
    Perspective(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Orthographic(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Custom(projection) => projection.get_clip_from_view_for_sub(sub_view)
  }
}

///|
pub fn Projection::update(
  self : Projection,
  width : Float,
  height : Float,
) -> Projection {
  match self {
    Perspective(projection) => Perspective(projection.update(width, height))
    Orthographic(projection) => Orthographic(projection.update(width, height))
    Custom(projection) => Custom(projection.update(width, height))
  }
}

///|
pub fn Projection::far(self : Projection) -> Float {
  match self {
    Perspective(projection) => projection.far()
    Orthographic(projection) => projection.far()
    Custom(projection) => projection.far()
  }
}

///|
pub fn Projection::get_frustum_corners(
  self : Projection,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  match self {
    Perspective(projection) => projection.get_frustum_corners(z_near, z_far)
    Orthographic(projection) => projection.get_frustum_corners(z_near, z_far)
    Custom(projection) => projection.get_frustum_corners(z_near, z_far)
  }
}

///|
pub impl CameraProjection3d for CustomProjection3d with get_clip_from_view(self) {
  (self.get_clip_from_view_fn)(self.payload)
}

///|
pub impl CameraProjection3d for CustomProjection3d with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  (self.get_clip_from_view_for_sub_fn)(self.payload, sub_view)
}

///|
pub impl CameraProjection3d for CustomProjection3d with update(
  self,
  width,
  height,
) {
  CustomProjection3d::{
    type_name: self.type_name,
    payload: (self.update_fn)(self.payload, width, height),
    get_clip_from_view_fn: self.get_clip_from_view_fn,
    get_clip_from_view_for_sub_fn: self.get_clip_from_view_for_sub_fn,
    update_fn: self.update_fn,
    far_fn: self.far_fn,
    get_frustum_corners_fn: self.get_frustum_corners_fn,
  }
}

///|
pub impl CameraProjection3d for CustomProjection3d with far(self) {
  (self.far_fn)(self.payload)
}

///|
pub impl CameraProjection3d for CustomProjection3d with compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for CustomProjection3d with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  (self.get_frustum_corners_fn)(self.payload, z_near, z_far)
}

///|
pub impl CameraProjection3d for Projection with get_clip_from_view(self) {
  match self {
    Perspective(projection) => projection.get_clip_from_view()
    Orthographic(projection) => projection.get_clip_from_view()
    Custom(projection) => projection.get_clip_from_view()
  }
}

///|
pub impl CameraProjection3d for Projection with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  match self {
    Perspective(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Orthographic(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Custom(projection) => projection.get_clip_from_view_for_sub(sub_view)
  }
}

///|
pub impl CameraProjection3d for Projection with update(self, width, height) {
  match self {
    Perspective(projection) => Perspective(projection.update(width, height))
    Orthographic(projection) => Orthographic(projection.update(width, height))
    Custom(projection) => Custom(projection.update(width, height))
  }
}

///|
pub impl CameraProjection3d for Projection with far(self) {
  match self {
    Perspective(projection) => projection.far()
    Orthographic(projection) => projection.far()
    Custom(projection) => projection.far()
  }
}

///|
pub impl CameraProjection3d for Projection with compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for Projection with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  match self {
    Perspective(projection) => projection.get_frustum_corners(z_near, z_far)
    Orthographic(projection) => projection.get_frustum_corners(z_near, z_far)
    Custom(projection) => projection.get_frustum_corners(z_near, z_far)
  }
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_clip_from_view(
  self,
) {
  render3d_perspective_projection_matrix(self)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  render3d_perspective_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with update(
  self,
  width,
  height,
) {
  self.aspect_ratio = render3d_projection_aspect_ratio(width, height)
  self
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with far(self) {
  self.far
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  render3d_perspective_frustum_corners(
    self.aspect_ratio,
    self.fov,
    z_near,
    z_far,
  )
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with get_clip_from_view(
  self,
) {
  render3d_orthographic_projection_matrix(
    self.area.min.x,
    self.area.max.x,
    self.area.min.y,
    self.area.max.y,
    self.far,
    self.near,
  )
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  render3d_orthographic_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with update(
  self,
  width,
  height,
) {
  self.area = render3d_orthographic_area(self, width, height)
  self
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with far(self) {
  self.far
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  [
    @math.Vec3::new(self.area.max.x, self.area.min.y, z_near),
    @math.Vec3::new(self.area.max.x, self.area.max.y, z_near),
    @math.Vec3::new(self.area.min.x, self.area.max.y, z_near),
    @math.Vec3::new(self.area.min.x, self.area.min.y, z_near),
    @math.Vec3::new(self.area.max.x, self.area.min.y, z_far),
    @math.Vec3::new(self.area.max.x, self.area.max.y, z_far),
    @math.Vec3::new(self.area.min.x, self.area.max.y, z_far),
    @math.Vec3::new(self.area.min.x, self.area.min.y, z_far),
  ]
}

///|
const FREE_CAMERA_RADIANS_PER_DOT : Float = 0.005555555555555556F

///|
/// A freecam-style controller configuration aligned with Bevy's `FreeCamera`.
pub(all) struct FreeCamera {
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
} derive(ToJson, FromJson)

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
pub(all) struct FreeCameraState {
  enabled : Bool
  initialized : Bool
  pitch : Float
  yaw : Float
  speed_multiplier : Float
  velocity : @math.Vec3
} derive(ToJson, FromJson)

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
pub type ChromaticAberration = @post_process.ChromaticAberration

///|
pub type Vignette = @post_process.Vignette

///|
pub type MotionBlur = @post_process.MotionBlur

///|
pub type Msaa = @core_pipeline.Msaa

///|
pub type FxaaSensitivity = @post_process.FxaaSensitivity

///|
pub type Fxaa = @post_process.Fxaa

///|
pub type CustomPostProcess3d = @post_process.CustomPostProcess3d

///|
pub type DepthPrepass = @core_pipeline.DepthPrepass

///|
pub type NormalPrepass = @core_pipeline.NormalPrepass

///|
pub type MotionVectorPrepass = @core_pipeline.MotionVectorPrepass

///|
pub type DeferredPrepass = @core_pipeline.DeferredPrepass

///|
/// Marker component aligned with Bevy's `OcclusionCulling`.
pub struct OcclusionCulling {} derive(ToJson, FromJson)

///|
pub fn OcclusionCulling::default() -> OcclusionCulling {
  OcclusionCulling::{  }
}

///|
/// Marker component aligned with Bevy's `NoIndirectDrawing`.
pub struct NoIndirectDrawing {} derive(ToJson, FromJson)

///|
pub fn NoIndirectDrawing::default() -> NoIndirectDrawing {
  NoIndirectDrawing::{  }
}

///|
/// Marker component aligned with Bevy's `NotShadowCaster`.
pub struct NotShadowCaster {} derive(ToJson, FromJson)

///|
pub fn NotShadowCaster::default() -> NotShadowCaster {
  NotShadowCaster::{  }
}

///|
/// Marker component aligned with Bevy's `NotShadowReceiver`.
pub struct NotShadowReceiver {} derive(ToJson, FromJson)

///|
pub fn NotShadowReceiver::default() -> NotShadowReceiver {
  NotShadowReceiver::{  }
}

///|
/// Marker component aligned with Bevy's `TransmittedShadowReceiver`.
pub struct TransmittedShadowReceiver {} derive(ToJson, FromJson)

///|
pub fn TransmittedShadowReceiver::default() -> TransmittedShadowReceiver {
  TransmittedShadowReceiver::{  }
}

///|
/// Camera transparency settings aligned with Bevy's
/// `OrderIndependentTransparencySettings`.
pub struct OrderIndependentTransparencySettings {
  sorted_fragment_max_count : Int
  fragments_per_pixel_average : Float
  alpha_threshold : Float
} derive(ToJson, FromJson)

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
/// Per-mesh lightmap settings aligned with Bevy's `Lightmap`.
pub struct Lightmap {
  image : @asset.Handle[@asset.Image]
  uv_rect : @math.Rect
  bicubic_sampling : Bool
} derive(ToJson, FromJson)

///|
pub fn Lightmap::default() -> Lightmap {
  Lightmap::{
    image: @asset.Handle::new(-1),
    uv_rect: @math.Rect::new(@math.Vec2::zero(), @math.Vec2::new(1.0F, 1.0F)),
    bicubic_sampling: false,
  }
}

///|
pub fn Lightmap::new(image : @asset.Handle[@asset.Image]) -> Lightmap {
  Lightmap::{ ..Lightmap::default(), image }
}

///|
pub fn Lightmap::with_uv_rect(
  self : Lightmap,
  uv_rect : @math.Rect,
) -> Lightmap {
  Lightmap::{ ..self, uv_rect, }
}

///|
pub fn Lightmap::with_bicubic_sampling(
  self : Lightmap,
  bicubic_sampling : Bool,
) -> Lightmap {
  Lightmap::{ ..self, bicubic_sampling, }
}

///|
pub type TemporalAntiAliasing = @post_process.TemporalAntiAliasing

///|
pub type TemporalJitter = @post_process.TemporalJitter

///|
pub type Hdr = @core_pipeline.Hdr

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
pub struct Exposure {
  ev100 : Float
} derive(ToJson, FromJson)

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
pub fn Exposure::from_physical_camera(
  physical_camera_parameters : PhysicalCameraParameters,
) -> Exposure {
  Exposure::{ ev100: physical_camera_parameters.ev100() }
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
fn render3d_log2(value : Float) -> Float {
  if value <= 0.0F {
    return @float.neg_infinity
  }
  let mut normalized = value
  let mut exponent = 0.0F
  while normalized < 1.0F {
    normalized = normalized * 2.0F
    exponent = exponent - 1.0F
  }
  while normalized >= 2.0F {
    normalized = normalized / 2.0F
    exponent = exponent + 1.0F
  }
  let mut fraction = 0.0F
  let mut factor = 0.5F
  let mut current = normalized
  for _ in 0..<16 {
    current = current * current
    if current >= 2.0F {
      current = current / 2.0F
      fraction = fraction + factor
    }
    factor = factor / 2.0F
  }
  exponent + fraction
}

///|
/// Physical camera parameters aligned with Bevy's `PhysicalCameraParameters`.
pub(all) struct PhysicalCameraParameters {
  mut aperture_f_stops : Float
  mut shutter_speed_s : Float
  mut sensitivity_iso : Float
  mut sensor_height : Float
} derive(ToJson, FromJson)

///|
pub fn PhysicalCameraParameters::default() -> PhysicalCameraParameters {
  PhysicalCameraParameters::{
    aperture_f_stops: 1.0F,
    shutter_speed_s: 1.0F / 125.0F,
    sensitivity_iso: 100.0F,
    sensor_height: 0.01866F,
  }
}

///|
pub fn PhysicalCameraParameters::ev100(
  self : PhysicalCameraParameters,
) -> Float {
  let numerator = self.aperture_f_stops * self.aperture_f_stops * 100.0F
  let denominator = self.shutter_speed_s * self.sensitivity_iso
  render3d_log2(numerator / denominator)
}

///|
pub type ColorGradingRange = @post_process.ColorGradingRange

///|
pub type ColorGradingGlobal = @post_process.ColorGradingGlobal

///|
pub type ColorGradingSection = @post_process.ColorGradingSection

///|
pub type ColorGrading = @post_process.ColorGrading

///|
pub type Tonemapping = @post_process.Tonemapping

///|
pub type DebandDither = @post_process.DebandDither

///|
pub type BloomPrefilter = @post_process.BloomPrefilter

///|
pub type BloomCompositeMode = @post_process.BloomCompositeMode

///|
pub type Bloom = @post_process.Bloom

///|
/// Camera skybox settings aligned with Bevy's `Skybox`.
pub struct Skybox {
  image : @asset.Handle[@asset.Image]?
  brightness : Float
  rotation : @math.Quat
} derive(ToJson, FromJson)

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
pub type ScreenSpaceAmbientOcclusionQualityLevel = @post_process.ScreenSpaceAmbientOcclusionQualityLevel

///|
pub type ScreenSpaceAmbientOcclusion = @post_process.ScreenSpaceAmbientOcclusion

///|
/// Camera contact shadow settings aligned with Bevy's `ContactShadows`.
pub struct ContactShadows {
  linear_steps : Int
  thickness : Float
  length : Float
} derive(ToJson, FromJson)

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
pub(all) enum ShadowFilteringMethod {
  Hardware2x2
  Gaussian
  Temporal
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn ShadowFilteringMethod::default() -> ShadowFilteringMethod {
  ShadowFilteringMethod::Gaussian
}

///|
/// Camera screen-space transmission quality aligned with Bevy's
/// `ScreenSpaceTransmissionQuality`.
pub type ScreenSpaceTransmissionQuality = @post_process.ScreenSpaceTransmissionQuality

///|
fn screen_space_transmission_blur_taps(
  quality : ScreenSpaceTransmissionQuality,
) -> Int {
  @post_process.screen_space_transmission_blur_taps(quality)
}

///|
pub type ScreenSpaceTransmission = @post_process.ScreenSpaceTransmission

///|
pub type ScreenSpaceReflections = @post_process.ScreenSpaceReflections
