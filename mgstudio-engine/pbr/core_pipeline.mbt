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
  compensation_ev : Float
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
  compute_frustum(self : Self, camera_transform : @math.Transform) -> Frustum
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
pub fn[T] CustomProjection3d::get_mut(self : CustomProjection3d) -> T? {
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
/// Camera post-process settings aligned with Bevy's `ChromaticAberration`.
///
/// This renderer currently applies a lightweight per-object approximation in
/// the draw phase instead of a full-screen post-process pass.
pub struct ChromaticAberration {
  intensity : Float
  max_samples : Int
} derive(ToJson, FromJson)

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
pub struct Vignette {
  intensity : Float
  radius : Float
  smoothness : Float
  roundness : Float
  center : @math.Vec2
  edge_compensation : Float
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn Vignette::default() -> Vignette {
  Vignette::{
    intensity: 1.0F,
    radius: 0.75F,
    smoothness: 5.0F,
    roundness: 1.0F,
    center: @math.Vec2::new(0.5F, 0.5F),
    edge_compensation: 1.0F,
    color: @sprite.Color::black(),
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
pub fn Vignette::with_color(self : Vignette, color : @sprite.Color) -> Vignette {
  Vignette::{ ..self, color, }
}

///|
/// Camera post-process settings aligned with Bevy's `MotionBlur`.
pub struct MotionBlur {
  shutter_angle : Float
  samples : Int
} derive(ToJson, FromJson)

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
pub type Msaa = @core_pipeline.Msaa

///|
pub(all) enum FxaaSensitivity {
  Low
  Medium
  High
  Ultra
  Extreme
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn FxaaSensitivity::default() -> FxaaSensitivity {
  FxaaSensitivity::High
}

///|
/// Camera post-process settings aligned with Bevy's `Fxaa`.
///
/// Current runtime note: this records camera intent as an ECS surface.
pub struct Fxaa {
  enabled : Bool
  edge_threshold : FxaaSensitivity
  edge_threshold_min : FxaaSensitivity
} derive(ToJson, FromJson)

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
pub type DepthPrepass = @core_pipeline.DepthPrepass

///|
pub type NormalPrepass = @core_pipeline.NormalPrepass

///|
pub type MotionVectorPrepass = @core_pipeline.MotionVectorPrepass

///|
pub type DeferredPrepass = @core_pipeline.DeferredPrepass

///|
/// Marker component aligned with Bevy's `OcclusionCulling`.
///
/// Current runtime note: this records per-camera occlusion-culling intent as an
/// ECS surface for parity and migration sequencing.
pub struct OcclusionCulling {} derive(ToJson, FromJson)

///|
pub fn OcclusionCulling::default() -> OcclusionCulling {
  OcclusionCulling::{  }
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
///
/// Current runtime note: this backend records transmitted-shadow intent as ECS
/// API parity; transmitted shadowing itself remains backend-adapted.
pub struct TransmittedShadowReceiver {} derive(ToJson, FromJson)

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
/// Camera temporal AA settings aligned with Bevy's `TemporalAntiAliasing`.
pub struct TemporalAntiAliasing {
  reset : Bool
} derive(ToJson, FromJson)

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
pub struct TemporalJitter {
  offset : @math.Vec2
} derive(ToJson, FromJson)

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
/// Midtone range controls aligned with Bevy's `Range<f32>`-based surface.
pub(all) struct ColorGradingRange {
  mut start : Float
  mut end_ : Float
} derive(ToJson, FromJson)

///|
pub fn ColorGradingRange::default() -> ColorGradingRange {
  ColorGradingRange::{ start: 0.2F, end_: 0.7F }
}

///|
fn render3d_color_grading_range_copy(
  value : ColorGradingRange,
) -> ColorGradingRange {
  let out = ColorGradingRange::default()
  out.start = value.start
  out.end_ = value.end_
  out
}

///|
/// Global color-grading controls aligned with Bevy's `ColorGradingGlobal`.
pub(all) struct ColorGradingGlobal {
  mut exposure : Float
  mut temperature : Float
  mut tint : Float
  mut hue : Float
  mut post_saturation : Float
  mut midtones_range : ColorGradingRange
} derive(ToJson, FromJson)

///|
pub fn ColorGradingGlobal::default() -> ColorGradingGlobal {
  ColorGradingGlobal::{
    exposure: 0.0F,
    temperature: 0.0F,
    tint: 0.0F,
    hue: 0.0F,
    post_saturation: 1.0F,
    midtones_range: ColorGradingRange::default(),
  }
}

///|
fn render3d_color_grading_global_copy(
  value : ColorGradingGlobal,
) -> ColorGradingGlobal {
  let out = ColorGradingGlobal::default()
  out.exposure = value.exposure
  out.temperature = value.temperature
  out.tint = value.tint
  out.hue = value.hue
  out.post_saturation = value.post_saturation
  out.midtones_range = render3d_color_grading_range_copy(value.midtones_range)
  out
}

///|
/// Sectional color-grading controls aligned with Bevy's `ColorGradingSection`.
pub(all) struct ColorGradingSection {
  mut saturation : Float
  mut contrast : Float
  mut gamma : Float
  mut gain : Float
  mut lift : Float
} derive(ToJson, FromJson)

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
fn render3d_color_grading_section_copy(
  value : ColorGradingSection,
) -> ColorGradingSection {
  let out = ColorGradingSection::default()
  out.saturation = value.saturation
  out.contrast = value.contrast
  out.gamma = value.gamma
  out.gain = value.gain
  out.lift = value.lift
  out
}

///|
/// Camera color grading settings aligned with Bevy's `ColorGrading`.
pub(all) struct ColorGrading {
  mut global : ColorGradingGlobal
  mut shadows : ColorGradingSection
  mut midtones : ColorGradingSection
  mut highlights : ColorGradingSection
} derive(ToJson, FromJson)

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
pub fn ColorGrading::with_identical_sections(
  global : ColorGradingGlobal,
  section : ColorGradingSection,
) -> ColorGrading {
  let color_grading = ColorGrading::default()
  color_grading.global = render3d_color_grading_global_copy(global)
  color_grading.shadows = render3d_color_grading_section_copy(section)
  color_grading.midtones = render3d_color_grading_section_copy(section)
  color_grading.highlights = render3d_color_grading_section_copy(section)
  color_grading
}

///|
pub fn ColorGrading::all_sections(
  self : ColorGrading,
) -> Iter[ColorGradingSection] {
  [self.shadows, self.midtones, self.highlights].iter()
}

///|
pub fn ColorGrading::all_sections_mut(
  self : ColorGrading,
) -> Iter[ColorGradingSection] {
  [self.shadows, self.midtones, self.highlights].iter()
}

///|
/// Camera tonemapping mode aligned with Bevy's `Tonemapping`.
pub(all) enum Tonemapping {
  None
  Reinhard
  ReinhardLuminance
  AcesFitted
  AgX
  SomewhatBoringDisplayTransform
  TonyMcMapface
  BlenderFilmic
} derive(Eq, Hash, Show, ToJson, FromJson)

///|
pub fn Tonemapping::default() -> Tonemapping {
  Tonemapping::TonyMcMapface
}

///|
/// Enables / disables screen-space deband dithering in the tonemapping pass.
pub(all) enum DebandDither {
  Disabled
  Enabled
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn DebandDither::default() -> DebandDither {
  DebandDither::Enabled
}

///|
pub struct BloomPrefilter {
  threshold : Float
  threshold_softness : Float
} derive(ToJson, FromJson)

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
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn BloomCompositeMode::default() -> BloomCompositeMode {
  BloomCompositeMode::EnergyConserving
}

///|
const BLOOM_DEFAULT_MAX_MIP_DIMENSION : Int = 512

///|
/// Camera bloom settings aligned with Bevy's `Bloom`.
pub struct Bloom {
  intensity : Float
  low_frequency_boost : Float
  low_frequency_boost_curvature : Float
  high_pass_frequency : Float
  prefilter : BloomPrefilter
  composite_mode : BloomCompositeMode
  max_mip_dimension : Int
  scale : @math.Vec2
} derive(ToJson, FromJson)

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
pub(all) enum ScreenSpaceAmbientOcclusionQualityLevel {
  Low
  Medium
  High
  Ultra
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn ScreenSpaceAmbientOcclusionQualityLevel::default() -> ScreenSpaceAmbientOcclusionQualityLevel {
  ScreenSpaceAmbientOcclusionQualityLevel::High
}

///|
/// Camera ambient occlusion settings aligned with Bevy's
/// `ScreenSpaceAmbientOcclusion`.
pub struct ScreenSpaceAmbientOcclusion {
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel
  constant_object_thickness : Float
} derive(ToJson, FromJson)

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
pub(all) enum ScreenSpaceTransmissionQuality {
  Low
  Medium
  High
  Ultra
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn ScreenSpaceTransmissionQuality::default() -> ScreenSpaceTransmissionQuality {
  ScreenSpaceTransmissionQuality::High
}

///|
/// Camera screen-space transmission settings aligned with Bevy's
/// `ScreenSpaceTransmission`.
pub struct ScreenSpaceTransmission {
  quality : ScreenSpaceTransmissionQuality
  steps : Int
} derive(ToJson, FromJson)

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
} derive(ToJson, FromJson)

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
