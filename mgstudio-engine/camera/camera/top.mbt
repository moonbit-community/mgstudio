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
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::Camera`.

///|
pub type Viewport = @camera_viewport.Viewport

///|
pub type RenderTargetInfo = @camera_computed.RenderTargetInfo

///|
pub type ComputedCameraValues = @camera_computed.ComputedCameraValues

///|
pub type ClearColorConfig = @camera_clear_color.ClearColorConfig

///|
pub struct Camera {
  viewport : Viewport?
  order : Int
  is_active : Bool
  computed : ComputedCameraValues
  clear_color : ClearColorConfig
  invert_culling : Bool
}

///|
pub fn Camera::new(clear_color : @color.Color) -> Camera {
  Camera::{
    viewport: None,
    order: 0,
    is_active: true,
    computed: ComputedCameraValues::ComputedCameraValues(),
    clear_color: ClearColorConfig::Custom(clear_color),
    invert_culling: false,
  }
}

///|
pub fn Camera::Camera() -> Camera {
  Camera::{
    viewport: None,
    order: 0,
    is_active: true,
    computed: ComputedCameraValues::ComputedCameraValues(),
    clear_color: ClearColorConfig::default(),
    invert_culling: false,
  }
}

///|
pub fn Camera::with_order(self : Camera, order : Int) -> Camera {
  Camera::{ ..self, order, }
}

///|
pub fn Camera::with_viewport(self : Camera, viewport : Viewport) -> Camera {
  Camera::{ ..self, viewport: Some(viewport) }
}

///|
pub fn Camera::clear_viewport(self : Camera) -> Camera {
  Camera::{ ..self, viewport: None }
}

///|
pub fn Camera::with_clear_color(
  self : Camera,
  clear_color : @color.Color,
) -> Camera {
  Camera::{ ..self, clear_color: ClearColorConfig::Custom(clear_color) }
}

///|
pub fn Camera::with_clear_color_config(
  self : Camera,
  clear_color : ClearColorConfig,
) -> Camera {
  Camera::{ ..self, clear_color, }
}

///|
pub fn Camera::with_clear_color_none(self : Camera) -> Camera {
  Camera::{ ..self, clear_color: ClearColorConfig::None }
}

///|
pub fn Camera::with_is_active(self : Camera, is_active : Bool) -> Camera {
  Camera::{ ..self, is_active, }
}

///|
pub fn Camera::with_invert_culling(
  self : Camera,
  invert_culling : Bool,
) -> Camera {
  Camera::{ ..self, invert_culling, }
}

///|
pub fn Camera::with_computed(
  self : Camera,
  computed : ComputedCameraValues,
) -> Camera {
  Camera::{ ..self, computed, }
}

///|
pub fn Camera::to_logical(
  self : Camera,
  physical_size : @math.IVec2,
) -> @math.Vec2? {
  guard self.computed.target_info is Some(target_info) else { return None }
  let mut scale = target_info.scale_factor
  if scale <= 0.0F {
    scale = 1.0F
  }
  Some(
    @math.Vec2::new(
      Float::from_double(physical_size.x.to_double()) / scale,
      Float::from_double(physical_size.y.to_double()) / scale,
    ),
  )
}

///|
pub fn Camera::physical_target_size(self : Camera) -> @math.IVec2? {
  self.computed.target_info.map(fn(target_info) { target_info.physical_size })
}

///|
pub fn Camera::logical_target_size(self : Camera) -> @math.Vec2? {
  match self.physical_target_size() {
    Some(size) => self.to_logical(size)
    None => None
  }
}

///|
pub fn Camera::physical_viewport_size(self : Camera) -> @math.IVec2? {
  match self.viewport {
    Some(viewport) => Some(viewport.physical_size)
    None => self.physical_target_size()
  }
}

///|
pub fn Camera::logical_viewport_size(self : Camera) -> @math.Vec2? {
  match self.viewport {
    Some(viewport) => self.to_logical(viewport.physical_size)
    None => self.logical_target_size()
  }
}

///|
pub fn Camera::target_scaling_factor(self : Camera) -> Float? {
  self.computed.target_info.map(fn(target_info) { target_info.scale_factor })
}

///|
fn camera_transform_scale_axis(value : Float) -> Float {
  let safe = if value < 0.0F { -value } else { value }
  if safe == 0.0F {
    1.0F
  } else {
    safe
  }
}

///|
fn camera_uniform_scale(
  projection : @camera_projection2d.OrthographicProjection,
  camera_transform : @transform.Transform,
) -> Float {
  let projection_scale = if projection.scale == 0.0F {
    1.0F
  } else {
    projection.scale
  }
  projection_scale * camera_transform_scale_axis(camera_transform.scale.x)
}

///|
fn camera_viewport_rect_physical(
  target_width : Int,
  target_height : Int,
  viewport : Viewport?,
) -> (Int, Int, Int, Int)? {
  let width = target_width
  let height = target_height
  if width <= 0 || height <= 0 {
    return None
  }
  let mut rect_x = 0
  let mut rect_y = 0
  let mut rect_width = width
  let mut rect_height = height
  if viewport is Some(vp) {
    rect_x = if vp.physical_position.x < 0 { 0 } else { vp.physical_position.x }
    rect_y = if vp.physical_position.y < 0 { 0 } else { vp.physical_position.y }
    rect_width = if vp.physical_size.x < 0 { 0 } else { vp.physical_size.x }
    rect_height = if vp.physical_size.y < 0 { 0 } else { vp.physical_size.y }
    let max_width = if width - rect_x < 0 { 0 } else { width - rect_x }
    let max_height = if height - rect_y < 0 { 0 } else { height - rect_y }
    if rect_width > max_width {
      rect_width = max_width
    }
    if rect_height > max_height {
      rect_height = max_height
    }
    if rect_width <= 0 || rect_height <= 0 {
      return None
    }
  }
  Some((rect_x, rect_y, rect_width, rect_height))
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::Camera::viewport_to_world_2d`.
pub fn Camera::viewport_to_world_2d(
  self : Camera,
  camera_transform : @transform.Transform,
  viewport_position : @math.Vec2,
  projection : @camera_projection2d.OrthographicProjection,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  let width = target_size.x
  let height = target_size.y
  if width <= 0 || height <= 0 {
    return None
  }
  let mut safe_scale_factor = scale_factor
  if safe_scale_factor <= 0.0F {
    safe_scale_factor = 1.0F
  }
  guard camera_viewport_rect_physical(width, height, self.viewport)
    is Some((rect_x, rect_y, rect_width, rect_height)) else {
    return None
  }
  let rect_x_f = Float::from_double(rect_x.to_double()) / safe_scale_factor
  let rect_y_f = Float::from_double(rect_y.to_double()) / safe_scale_factor
  let rect_width_f = Float::from_double(rect_width.to_double()) /
    safe_scale_factor
  let rect_height_f = Float::from_double(rect_height.to_double()) /
    safe_scale_factor
  if rect_width_f <= 0.0F || rect_height_f <= 0.0F {
    return None
  }
  let half_width = rect_width_f / 2.0F
  let half_height = rect_height_f / 2.0F
  let scale = camera_uniform_scale(projection, camera_transform)
  let local_x = viewport_position.x - rect_x_f
  let local_y = viewport_position.y - rect_y_f
  let view_x = (local_x - half_width) * scale
  let view_y = (half_height - local_y) * scale
  let rot_z = camera_transform.rotation_z()
  let cosv = @math.cos(rot_z)
  let sinv = @math.sin(rot_z)
  let world_x = camera_transform.translation.x + view_x * cosv + view_y * sinv
  let world_y = camera_transform.translation.y - view_x * sinv + view_y * cosv
  Some(@math.Vec2::new(world_x, world_y))
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::Camera::world_to_viewport`.
pub fn Camera::world_to_viewport_2d(
  self : Camera,
  camera_transform : @transform.Transform,
  world_position : @math.Vec2,
  projection : @camera_projection2d.OrthographicProjection,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  let width = target_size.x
  let height = target_size.y
  if width <= 0 || height <= 0 {
    return None
  }
  let mut safe_scale_factor = scale_factor
  if safe_scale_factor <= 0.0F {
    safe_scale_factor = 1.0F
  }
  guard camera_viewport_rect_physical(width, height, self.viewport)
    is Some((rect_x, rect_y, rect_width, rect_height)) else {
    return None
  }
  let rect_x_f = Float::from_double(rect_x.to_double()) / safe_scale_factor
  let rect_y_f = Float::from_double(rect_y.to_double()) / safe_scale_factor
  let rect_width_f = Float::from_double(rect_width.to_double()) /
    safe_scale_factor
  let rect_height_f = Float::from_double(rect_height.to_double()) /
    safe_scale_factor
  if rect_width_f <= 0.0F || rect_height_f <= 0.0F {
    return None
  }
  let half_width = rect_width_f / 2.0F
  let half_height = rect_height_f / 2.0F
  let dx = world_position.x - camera_transform.translation.x
  let dy = world_position.y - camera_transform.translation.y
  let rot_z = camera_transform.rotation_z()
  let cosv = @math.cos(rot_z)
  let sinv = @math.sin(rot_z)
  let view_x = dx * cosv - dy * sinv
  let view_y = dx * sinv + dy * cosv
  let safe_scale = camera_uniform_scale(projection, camera_transform)
  let local_x = view_x / safe_scale + half_width
  let local_y = half_height - view_y / safe_scale
  if local_x < 0.0F ||
    local_y < 0.0F ||
    local_x > rect_width_f ||
    local_y > rect_height_f {
    return None
  }
  Some(@math.Vec2::new(local_x + rect_x_f, local_y + rect_y_f))
}

///|
pub struct CameraMainTextureUsages {
  bits : UInt64
}

///|
pub fn CameraMainTextureUsages::CameraMainTextureUsages() -> CameraMainTextureUsages {
  CameraMainTextureUsages::{
    bits: @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_TEXTURE_BINDING |
    @wgpu.TEXTURE_USAGE_COPY_SRC,
  }
}

///|
pub fn CameraMainTextureUsages::new(bits : UInt64) -> CameraMainTextureUsages {
  CameraMainTextureUsages::{ bits, }
}

///|
pub fn CameraMainTextureUsages::with_usage(
  self : CameraMainTextureUsages,
  usage : UInt64,
) -> CameraMainTextureUsages {
  CameraMainTextureUsages::{ bits: self.bits | usage }
}

///|
pub fn CameraMainTextureUsages::bits(self : CameraMainTextureUsages) -> UInt64 {
  self.bits
}

///|
pub struct VisibleEntities {
  entities : @hashmap.HashMap[Int, Array[@core.Entity]]
}

///|
pub fn VisibleEntities::VisibleEntities() -> VisibleEntities {
  let entities : @hashmap.HashMap[Int, Array[@core.Entity]] = @hashmap.HashMap([])
  entities.set(@mesh.ecs_key_mesh3d.id(), [])
  VisibleEntities::{ entities, }
}

///|
pub fn VisibleEntities::get(
  self : VisibleEntities,
  component_id : Int,
) -> Array[@core.Entity] {
  match self.entities.get(component_id) {
    Some(entities) => entities
    None => []
  }
}

///|
pub fn VisibleEntities::len(self : VisibleEntities, component_id : Int) -> Int {
  self.get(component_id).length()
}

///|
pub fn VisibleEntities::is_empty(
  self : VisibleEntities,
  component_id : Int,
) -> Bool {
  self.len(component_id) == 0
}

///|
pub fn VisibleEntities::clear(
  self : VisibleEntities,
  component_id : Int,
) -> Unit {
  self.entities.set(component_id, [])
}

///|
pub fn VisibleEntities::clear_all(self : VisibleEntities) -> Unit {
  self.entities.clear()
  self.entities.set(@mesh.ecs_key_mesh3d.id(), [])
}

///|
pub fn VisibleEntities::sort_all(self : VisibleEntities) -> Unit {
  for _, entities in self.entities {
    entities.sort_by(fn(left, right) { left.id.compare(right.id) })
  }
}

///|
pub fn VisibleEntities::push(
  self : VisibleEntities,
  entity : @core.Entity,
  component_id : Int,
) -> Unit {
  let entities = self.get(component_id)
  entities.push(entity)
  self.entities.set(component_id, entities)
}

///|
pub(all) enum RenderTarget {
  Screen
  Window(@window.WindowRef)
  Image(@asset.Handle[@asset.Image])
}

///|
pub let ecs_key_camera : @ecs.ComponentKey[Camera] = @ecs.register_component(
  debug_name="mgstudio.camera.Camera",
)

///|
pub let ecs_key_render_target : @ecs.ComponentKey[RenderTarget] = @ecs.register_component(
  debug_name="mgstudio.camera.RenderTarget",
)

///|
pub let ecs_key_camera_main_texture_usages : @ecs.ComponentKey[
  CameraMainTextureUsages,
] = @ecs.register_component(
  debug_name="mgstudio.camera.CameraMainTextureUsages",
)

///|
pub let ecs_key_visible_entities : @ecs.ComponentKey[VisibleEntities] = @ecs.register_component(
  debug_name="mgstudio.camera.VisibleEntities",
)

///|
pub impl @ecs.Component for Camera with fn component() {
  ecs_key_camera
}

///|
pub impl @ecs.Component for RenderTarget with fn component() {
  ecs_key_render_target
}

///|
pub impl @ecs.Component for CameraMainTextureUsages with fn component() {
  ecs_key_camera_main_texture_usages
}

///|
pub impl @ecs.Component for VisibleEntities with fn component() {
  ecs_key_visible_entities
}

///|
pub fn register_camera_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_camera,
    @camera_primitives.ecs_key_frustum,
    fn() { @camera_primitives.Frustum::Frustum() },
  )
  world.register_required_components_with(
    ecs_key_camera,
    ecs_key_camera_main_texture_usages,
    fn() { CameraMainTextureUsages::CameraMainTextureUsages() },
  )
  world.register_required_components_with(
    ecs_key_camera,
    ecs_key_visible_entities,
    fn() { VisibleEntities::VisibleEntities() },
  )
  world.register_required_components_with(
    ecs_key_camera,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_camera,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_camera,
    @render.ecs_key_sync_to_render_world,
    fn() { @render.SyncToRenderWorld::SyncToRenderWorld() },
  )
  world.register_required_components_with(
    ecs_key_camera,
    ecs_key_render_target,
    fn() { RenderTarget::Screen },
  )
}

///|
pub fn ensure_camera_required_components(world : @ecs.World) -> Unit {
  register_camera_required_components(world) catch {
    @ecs.RequiredComponentsError::DuplicateRegistration(_, _) => ()
    @ecs.RequiredComponentsError::ArchetypeExists(component_id) =>
      abort(
        "Camera required-component registration ran too late for component \{component_id}",
      )
    @ecs.RequiredComponentsError::CyclicRequirement(requiree, required) =>
      abort(
        "Camera required-component cycle detected: \{requiree} -> \{required}",
      )
  }
}

///|
fn encode_camera(camera : Camera) -> Json {
  (
    camera.viewport.map(fn(viewport) {
      @camera_viewport.encode_viewport(viewport)
    }),
    camera.order,
    camera.is_active,
    @camera_computed.encode_computed_camera_values(camera.computed),
    @camera_clear_color.encode_clear_color_config(camera.clear_color),
    camera.invert_culling,
  ).to_json()
}

///|
fn encode_image_handle(handle : @asset.Handle[@asset.Image]) -> Json {
  handle.id().to_json()
}

///|
fn encode_render_target(target : RenderTarget) -> Json {
  match target {
    Screen => (0, Json::null()).to_json()
    Image(image) => (1, encode_image_handle(image)).to_json()
    Window(window_ref) => (2, window_ref.to_json()).to_json()
  }
}

///|
fn decode_camera(json : Json) -> Camera {
  let (
    viewport_json,
    order,
    is_active,
    computed_json,
    clear_color_json,
    invert_culling,
  ) : (Json?, Int, Bool, Json, Json, Bool) = try! @json.from_json(json)
  Camera::{
    viewport: viewport_json.map(fn(value) {
      @camera_viewport.decode_viewport(value)
    }),
    order,
    is_active,
    computed: @camera_computed.decode_computed_camera_values(computed_json),
    clear_color: @camera_clear_color.decode_clear_color_config(clear_color_json),
    invert_culling,
  }
}

///|
fn decode_image_handle(json : Json) -> @asset.Handle[@asset.Image] {
  let id : Int = try! @json.from_json(json)
  @asset.Handle::new(id)
}

///|
fn decode_render_target(json : Json) -> RenderTarget {
  let (tag, payload) : (Int, Json) = try! @json.from_json(json)
  match tag {
    0 => Screen
    1 => Image(decode_image_handle(payload))
    2 => Window(try! @json.from_json(payload))
    _ => Screen
  }
}

///|
pub impl ToJson for Camera with fn to_json(self) {
  encode_camera(self)
}

///|
pub impl @json.FromJson for Camera with fn from_json(json, _path) {
  decode_camera(json)
}

///|
pub impl ToJson for RenderTarget with fn to_json(self) {
  encode_render_target(self)
}

///|
pub impl @json.FromJson for RenderTarget with fn from_json(json, _path) {
  decode_render_target(json)
}
