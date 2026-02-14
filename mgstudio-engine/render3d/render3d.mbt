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
pub struct StandardMaterial {
  base_color : @render2d.Color
  base_color_texture : @asset.Handle[@asset.Image]?
  normal_map_texture : @asset.Handle[@asset.Image]?
  emissive : @render2d.Color
  emissive_texture : @asset.Handle[@asset.Image]?
  metallic : Float
  metallic_roughness_texture : @asset.Handle[@asset.Image]?
  perceptual_roughness : Float
  reflectance : Float
  occlusion_texture : @asset.Handle[@asset.Image]?
  alpha_mode : AlphaMode3d
  unlit : Bool
  cull_mode : Face3d?
}

///|
pub fn StandardMaterial::default() -> StandardMaterial {
  StandardMaterial::{
    base_color: @render2d.Color::white(),
    base_color_texture: None,
    normal_map_texture: None,
    emissive: @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    emissive_texture: None,
    metallic: 0.0F,
    metallic_roughness_texture: None,
    perceptual_roughness: 0.5F,
    reflectance: 0.5F,
    occlusion_texture: None,
    alpha_mode: AlphaMode3d::Opaque,
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
    normal_map_texture: default_value.normal_map_texture,
    emissive: default_value.emissive,
    emissive_texture: default_value.emissive_texture,
    metallic: default_value.metallic,
    metallic_roughness_texture: default_value.metallic_roughness_texture,
    perceptual_roughness: default_value.perceptual_roughness,
    reflectance: default_value.reflectance,
    occlusion_texture: default_value.occlusion_texture,
    alpha_mode,
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
pub fn StandardMaterial::with_base_color_texture(
  self : StandardMaterial,
  base_color_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, base_color_texture, }
}

///|
pub fn StandardMaterial::with_normal_map_texture(
  self : StandardMaterial,
  normal_map_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, normal_map_texture, }
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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct PointLight {
  color : @render2d.Color
  intensity : Float
  range : Float
  shadow_maps_enabled : Bool
}

///|
pub fn PointLight::default() -> PointLight {
  PointLight::{
    color: @render2d.Color::white(),
    intensity: 1_000_000.0F,
    range: 20.0F,
    shadow_maps_enabled: false,
  }
}

///|
pub fn PointLight::new(
  color : @render2d.Color,
  intensity : Float,
  range : Float,
  shadow_maps_enabled : Bool,
) -> PointLight {
  PointLight::{ color, intensity, range, shadow_maps_enabled }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct DirectionalLight {
  color : @render2d.Color
  illuminance : Float
  shadow_maps_enabled : Bool
}

///|
pub fn DirectionalLight::default() -> DirectionalLight {
  DirectionalLight::{
    color: @render2d.Color::white(),
    illuminance: 10000.0F,
    shadow_maps_enabled: false,
  }
}

///|
pub fn DirectionalLight::new(
  color : @render2d.Color,
  illuminance : Float,
  shadow_maps_enabled : Bool,
) -> DirectionalLight {
  DirectionalLight::{ color, illuminance, shadow_maps_enabled }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct SpotLight {
  color : @render2d.Color
  intensity : Float
  range : Float
  inner_angle : Float
  outer_angle : Float
  shadow_maps_enabled : Bool
}

///|
pub fn SpotLight::default() -> SpotLight {
  SpotLight::{
    color: @render2d.Color::white(),
    intensity: 1_000_000.0F,
    range: 20.0F,
    inner_angle: 0.6F,
    outer_angle: 0.8F,
    shadow_maps_enabled: false,
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
    inner_angle,
    outer_angle,
    shadow_maps_enabled,
  }
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
    camera3d: Camera3d::default(),
    transform,
    target: @render2d.RenderTarget::Screen,
    layers: @render2d.RenderLayers::default(),
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
pub(open) trait Camera3dBundleSpawnWorld: @core.SpawnWorld + @core.ChangeTickWorld + Has_Camera3d + Has_CameraProjection3d + @render2d.Has_Camera + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @math.Has_Transform {
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
  transform : @math.Transform
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
  layers : @render2d.RenderLayers
}

///|
priv struct Mesh3dInstance {
  entity : @core.Entity
  mesh_id : Int
  transform : @math.Transform
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
) -> (Float, Float, Float) {
  let safe_aspect = if aspect_ratio <= 0.0F { 1.0F } else { aspect_ratio }
  match projection.projection {
    Perspective(perspective) => {
      let p = perspective.with_aspect_ratio(safe_aspect)
      (p.fov, p.near, p.far)
    }
    Orthographic(orthographic) =>
      (@math.pi_half(), orthographic.near, orthographic.far)
  }
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
pub(open) trait Render3dExecuteWorld: HasRes_GlobalAmbientLight + Has_PointLight + Has_DirectionalLight + Has_SpotLight + Has_Camera3d + Has_CameraProjection3d + Has_Mesh3d + Has_MeshMaterial3d + @render2d.Has_Camera + @render2d.Has_RenderTarget + @render2d.Has_RenderLayers + @render2d.Has_GpuMesh2d + @math.Has_Transform + @visibility.Has_ViewVisibility + @core.ChangeTickWorld {
}

///|
pub fn[W : Render3dExecuteWorld] render3d_execute_system(world : W) -> Unit {
  let cameras : Array[Camera3dInstance] = []
  let meshes : Array[Mesh3dInstance] = []
  let camera3d_store = world.get_camera3d_store()
  let camera_store = world.get_camera_store()
  let projection_store = world.get_camera_projection3d_store()
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
          transform,
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
  mesh_store.for_each(fn(entity, _mesh3d) {
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
    meshes.push(Mesh3dInstance::{
      entity,
      mesh_id: gpu_mesh.mesh_id,
      transform,
      material,
      layers,
    })
  })
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
    let aspect_ratio = view_width_f / view_height_f
    let (camera_fov_y, camera_near, camera_far) = render3d_projection_params(
      camera.projection,
      aspect_ratio,
    )
    let clear_color = camera.camera.clear_color
    @window.host_gpu_begin_pass_3d(
      target_id=camera.target_id,
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
      ambient_r=lighting.ambient_color.r,
      ambient_g=lighting.ambient_color.g,
      ambient_b=lighting.ambient_color.b,
      ambient_brightness=lighting.ambient_brightness,
      directional_dir_x=lighting.directional_dir.x,
      directional_dir_y=lighting.directional_dir.y,
      directional_dir_z=lighting.directional_dir.z,
      directional_color_r=lighting.directional_color.r,
      directional_color_g=lighting.directional_color.g,
      directional_color_b=lighting.directional_color.b,
      directional_illuminance=lighting.directional_illuminance,
      point_pos_x=lighting.point_pos.x,
      point_pos_y=lighting.point_pos.y,
      point_pos_z=lighting.point_pos.z,
      point_color_r=lighting.point_color.r,
      point_color_g=lighting.point_color.g,
      point_color_b=lighting.point_color.b,
      point_intensity=lighting.point_intensity,
      point_range=lighting.point_range,
      spot_pos_x=lighting.spot_pos.x,
      spot_pos_y=lighting.spot_pos.y,
      spot_pos_z=lighting.spot_pos.z,
      spot_dir_x=lighting.spot_dir.x,
      spot_dir_y=lighting.spot_dir.y,
      spot_dir_z=lighting.spot_dir.z,
      spot_color_r=lighting.spot_color.r,
      spot_color_g=lighting.spot_color.g,
      spot_color_b=lighting.spot_color.b,
      spot_intensity=lighting.spot_intensity,
      spot_range=lighting.spot_range,
      spot_inner_angle=lighting.spot_inner_angle,
      spot_outer_angle=lighting.spot_outer_angle,
    )
    let draw_order = render3d_sorted_mesh_indices(
      meshes,
      camera.layers,
      camera.transform,
    )
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
      let normal_texture_id = match mesh.material.normal_map_texture {
        Some(texture) => texture.id()
        None => -1
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
      @window.host_gpu_draw_mesh3d(
        mesh_id=mesh.mesh_id,
        x=mesh.transform.translation.x,
        y=mesh.transform.translation.y,
        z=mesh.transform.translation.z,
        rotation_x=mesh.transform.rotation.x,
        rotation_y=mesh.transform.rotation.y,
        rotation_z=mesh.transform.rotation.z,
        rotation_w=mesh.transform.rotation.w,
        scale_x=mesh.transform.scale.x,
        scale_y=mesh.transform.scale.y,
        scale_z=mesh.transform.scale.z,
        color_r=mesh.material.base_color.r,
        color_g=mesh.material.base_color.g,
        color_b=mesh.material.base_color.b,
        color_a=draw_alpha,
        texture_id~,
        uv_offset_x=0.0F,
        uv_offset_y=0.0F,
        uv_scale_x=1.0F,
        uv_scale_y=1.0F,
        normal_texture_id~,
        emissive_texture_id~,
        metallic_roughness_texture_id~,
        occlusion_texture_id~,
        emissive_r=mesh.material.emissive.r,
        emissive_g=mesh.material.emissive.g,
        emissive_b=mesh.material.emissive.b,
        unlit=if mesh.material.unlit { 1.0F } else { 0.0F },
        metallic=mesh.material.metallic,
        roughness=mesh.material.perceptual_roughness,
        reflectance=mesh.material.reflectance,
      )
    }
    @window.host_gpu_end_pass()
  }
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
