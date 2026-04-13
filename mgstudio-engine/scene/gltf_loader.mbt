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
priv struct PendingGltfSceneRequest {
  scene_handle : @asset.Handle[Scene]
  gltf_path : String
  scene_index : Int
  gltf_blob : @asset.Handle[@asset.Blob]
  mut doc : ParsedGltfDocument?
  buffer_blobs : Array[@asset.Handle[@asset.Blob]?]
  mut buffer_bytes : Array[Bytes?]
}

///|
let pending_gltf_scene_requests : Ref[Array[PendingGltfSceneRequest]] = Ref::new([],
)

///|
priv struct PendingGltfAnimationRequest {
  clip_handle : @asset.Handle[@animation.AnimationClip]
  gltf_path : String
  animation_index : Int
  gltf_blob : @asset.Handle[@asset.Blob]
  mut doc : ParsedGltfDocument?
  buffer_blobs : Array[@asset.Handle[@asset.Blob]?]
  mut buffer_bytes : Array[Bytes?]
}

///|
let pending_gltf_animation_requests : Ref[Array[PendingGltfAnimationRequest]] = Ref::new([],
)

///|
priv struct PendingGltfMeshRequest {
  mesh_handle : @asset.Handle[@mesh.Mesh]
  gltf_path : String
  mesh_index : Int
  primitive_index : Int
  gltf_blob : @asset.Handle[@asset.Blob]
  mut doc : ParsedGltfDocument?
  buffer_blobs : Array[@asset.Handle[@asset.Blob]?]
  mut buffer_bytes : Array[Bytes?]
}

///|
let pending_gltf_mesh_requests : Ref[Array[PendingGltfMeshRequest]] = Ref::new([])

///|
priv struct GltfBufferDef {
  uri : String?
  byte_length : Int
}

///|
priv struct GltfBufferViewDef {
  buffer : Int
  byte_offset : Int
  byte_length : Int
  byte_stride : Int?
}

///|
priv struct GltfAccessorDef {
  buffer_view : Int?
  byte_offset : Int
  component_type : Int
  count : Int
  accessor_type : String
}

///|
priv struct GltfPrimitiveDef {
  primitive_index : Int
  position : Int?
  uv0 : Int?
  joint_indices : Int?
  joint_weights : Int?
  custom_attributes : Array[(String, Int)]
  morph_targets : Array[Int?]
  indices : Int?
  material : Int?
  extras : String?
}

///|
priv struct GltfMeshDef {
  name : String
  extras : String?
  weights : Array[Float]
  morph_target_names : Array[String]
  primitives : Array[GltfPrimitiveDef]
}

///|
priv struct GltfNodeDef {
  name : String
  mesh : Int?
  skin : Int?
  children : Array[Int]
  lod_nodes : Array[Int]
  transform : @transform.Transform
}

///|
priv struct GltfSkinDef {
  inverse_bind_matrices : Int?
  joints : Array[Int]
}

///|
priv struct GltfSceneDef {
  nodes : Array[Int]
  extras : String?
}

///|
priv struct GltfMaterialDef {
  name : String
  extras : String?
  base_color : @color.Color
  base_color_texture : Int?
  base_color_uv_offset : @math.Vec2
  base_color_uv_scale : @math.Vec2
  clearcoat : Float
  clearcoat_roughness : Float
  clearcoat_texture : Int?
  clearcoat_roughness_texture : Int?
  clearcoat_normal_texture : Int?
  anisotropy_strength : Float
  anisotropy_rotation : Float
  anisotropy_texture : Int?
  normal_texture : Int?
  emissive_texture : Int?
  metallic_roughness_texture : Int?
  occlusion_texture : Int?
  metallic : Float
  roughness : Float
  emissive : @color.Color
  alpha_mode : @pbr.AlphaMode3d
  unlit : Bool
}

///|
priv struct GltfSamplerDef {
  nearest : Bool
  repeat : Bool
}

///|
priv struct GltfTextureDef {
  source : Int?
  sampler : Int?
}

///|
priv struct GltfImageDef {
  uri : String?
  mime_type : String?
  buffer_view : Int?
}

///|
priv struct GltfAnimationSamplerDef {
  input : Int?
  output : Int?
  interpolation : @animation.GltfInterpolation
}

///|
priv struct GltfAnimationChannelDef {
  sampler : Int?
  target_node : Int?
  target_path : String
}

///|
priv struct GltfAnimationDef {
  name : String
  samplers : Array[GltfAnimationSamplerDef]
  channels : Array[GltfAnimationChannelDef]
}

///|
priv struct ParsedGltfDocument {
  default_scene : Int
  buffers : Array[GltfBufferDef]
  buffer_views : Array[GltfBufferViewDef]
  accessors : Array[GltfAccessorDef]
  meshes : Array[GltfMeshDef]
  nodes : Array[GltfNodeDef]
  skins : Array[GltfSkinDef]
  scenes : Array[GltfSceneDef]
  materials : Array[GltfMaterialDef]
  samplers : Array[GltfSamplerDef]
  textures : Array[GltfTextureDef]
  images : Array[GltfImageDef]
  animations : Array[GltfAnimationDef]
}

///|
priv enum GltfResolveBuffersState {
  Pending
  Fatal
  Ready(Array[Bytes])
}

///|
priv enum GltfAssetLabel {
  Scene(Int)
  Node(Int)
  Mesh(Int)
  Primitive(Int, Int)
  MorphTarget(Int, Int)
  Texture(Int)
  Material(Int, Bool)
  DefaultMaterial
  Animation(Int)
  Skin(Int)
  InverseBindMatrices(Int)
}

///|
const SCENE_GLTF_ASSET_LABEL_MESH_PREFIX : String = "Mesh"

///|
const SCENE_GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT : String = "/Primitive"

///|
const SCENE_GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX : String = "/MorphTargets"

///|
const SCENE_GLTF_ASSET_LABEL_MATERIAL_PREFIX : String = "Material"

///|
const SCENE_GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX : String = " (inverted)"

///|
const SCENE_GLTF_ASSET_LABEL_SKIN_PREFIX : String = "Skin"

///|
const SCENE_GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX : String = "/InverseBindMatrices"

///|
fn scene_gltf_parse_non_negative_int(payload : String) -> Int? {
  let parsed = @string.parse_int(payload[:], base=10) catch { _ => -1 }
  if parsed < 0 {
    None
  } else {
    Some(parsed)
  }
}

///|
fn scene_gltf_parse_prefixed_index(label : String, prefix : String) -> Int? {
  if !label.has_prefix(prefix) {
    return None
  }
  let suffix = label[prefix.length():label.length()].to_string()
  if suffix.length() == 0 {
    None
  } else {
    scene_gltf_parse_non_negative_int(suffix)
  }
}

///|
fn scene_gltf_parse_mesh_primitive_label(label : String) -> (Int, Int)? {
  if !label.has_prefix(SCENE_GLTF_ASSET_LABEL_MESH_PREFIX) {
    return None
  }
  guard label.find(SCENE_GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT)
    is Some(split_index) else {
    return None
  }
  let mesh_start = SCENE_GLTF_ASSET_LABEL_MESH_PREFIX.length()
  let primitive_start = split_index +
    SCENE_GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT.length()
  let mesh_text = label[mesh_start:split_index].to_string()
  let primitive_text = label[primitive_start:label.length()].to_string()
  if mesh_text.length() == 0 || primitive_text.length() == 0 {
    return None
  }
  guard scene_gltf_parse_non_negative_int(mesh_text) is Some(mesh_index) else {
    return None
  }
  guard scene_gltf_parse_non_negative_int(primitive_text)
    is Some(primitive_index) else {
    return None
  }
  Some((mesh_index, primitive_index))
}

///|
fn scene_gltf_parse_material_label(label : String) -> (Int, Bool)? {
  if !label.has_prefix(SCENE_GLTF_ASSET_LABEL_MATERIAL_PREFIX) {
    return None
  }
  let payload = label[SCENE_GLTF_ASSET_LABEL_MATERIAL_PREFIX.length():label.length()].to_string()
  if payload.length() == 0 {
    return None
  }
  let mut is_scale_inverted = false
  let mut index_payload = payload
  if payload.has_suffix(SCENE_GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX) {
    let end = payload.length() -
      SCENE_GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX.length()
    if end <= 0 {
      return None
    }
    index_payload = payload[0:end].to_string()
    is_scale_inverted = true
  }
  guard scene_gltf_parse_non_negative_int(index_payload) is Some(index) else {
    return None
  }
  Some((index, is_scale_inverted))
}

///|
fn scene_parse_gltf_asset_label(label : String) -> GltfAssetLabel? {
  if label == "DefaultMaterial" {
    return Some(GltfAssetLabel::DefaultMaterial)
  }
  if label.has_suffix(SCENE_GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX) {
    let end = label.length() -
      SCENE_GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX.length()
    if end <= 0 {
      return None
    }
    let primitive_label = label[0:end].to_string()
    if scene_gltf_parse_mesh_primitive_label(primitive_label)
      is Some((mesh, primitive)) {
      return Some(GltfAssetLabel::MorphTarget(mesh, primitive))
    }
    return None
  }
  if scene_gltf_parse_mesh_primitive_label(label) is Some((mesh, primitive)) {
    return Some(GltfAssetLabel::Primitive(mesh, primitive))
  }
  if label.has_suffix(SCENE_GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX) &&
    label.has_prefix(SCENE_GLTF_ASSET_LABEL_SKIN_PREFIX) {
    let end = label.length() -
      SCENE_GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX.length()
    if end <= SCENE_GLTF_ASSET_LABEL_SKIN_PREFIX.length() {
      return None
    }
    let index_payload = label[SCENE_GLTF_ASSET_LABEL_SKIN_PREFIX.length():end].to_string()
    if scene_gltf_parse_non_negative_int(index_payload) is Some(index) {
      return Some(GltfAssetLabel::InverseBindMatrices(index))
    }
    return None
  }
  if scene_gltf_parse_material_label(label) is Some((index, is_scale_inverted)) {
    return Some(GltfAssetLabel::Material(index, is_scale_inverted))
  }
  if scene_gltf_parse_prefixed_index(label, "Scene") is Some(index) {
    return Some(GltfAssetLabel::Scene(index))
  }
  if scene_gltf_parse_prefixed_index(label, "Node") is Some(index) {
    return Some(GltfAssetLabel::Node(index))
  }
  if scene_gltf_parse_prefixed_index(label, "Mesh") is Some(index) {
    return Some(GltfAssetLabel::Mesh(index))
  }
  if scene_gltf_parse_prefixed_index(label, "Texture") is Some(index) {
    return Some(GltfAssetLabel::Texture(index))
  }
  if scene_gltf_parse_prefixed_index(label, "Animation") is Some(index) {
    return Some(GltfAssetLabel::Animation(index))
  }
  if scene_gltf_parse_prefixed_index(label, "Skin") is Some(index) {
    return Some(GltfAssetLabel::Skin(index))
  }
  None
}

///|
fn scene_touch_gltf_asset_label(label : GltfAssetLabel?) -> Unit {
  match label {
    Some(GltfAssetLabel::Scene(index)) => ignore(index)
    Some(GltfAssetLabel::Node(index)) => ignore(index)
    Some(GltfAssetLabel::Mesh(index)) => ignore(index)
    Some(GltfAssetLabel::Primitive(mesh, primitive)) => {
      ignore(mesh)
      ignore(primitive)
    }
    Some(GltfAssetLabel::MorphTarget(mesh, primitive)) => {
      ignore(mesh)
      ignore(primitive)
    }
    Some(GltfAssetLabel::Texture(index)) => ignore(index)
    Some(GltfAssetLabel::Material(index, is_scale_inverted)) => {
      ignore(index)
      ignore(is_scale_inverted)
    }
    Some(GltfAssetLabel::DefaultMaterial) => ()
    Some(GltfAssetLabel::Animation(index)) => ignore(index)
    Some(GltfAssetLabel::Skin(index)) => ignore(index)
    Some(GltfAssetLabel::InverseBindMatrices(index)) => ignore(index)
    None => ()
  }
}

///|
fn scene_split_gltf_asset_path(
  asset_path : String,
) -> (String, GltfAssetLabel?) {
  if asset_path.rev_find("#") is Some(index) {
    let base_path = asset_path[0:index].to_string()
    let label_start = index + 1
    if label_start >= asset_path.length() {
      return (base_path, None)
    }
    let label = asset_path[label_start:asset_path.length()].to_string()
    let parsed_label = scene_parse_gltf_asset_label(label)
    scene_touch_gltf_asset_label(parsed_label)
    (base_path, parsed_label)
  } else {
    (asset_path, None)
  }
}

///|
fn scene_pending_remove_scene_handle(handle : @asset.Handle[Scene]) -> Unit {
  let filtered : Array[PendingGltfSceneRequest] = []
  for req in pending_gltf_scene_requests.val {
    if req.scene_handle.id() != handle.id() {
      filtered.push(req)
    }
  }
  pending_gltf_scene_requests.val = filtered
}

///|
fn scene_pending_remove_animation_handle(
  handle : @asset.Handle[@animation.AnimationClip],
) -> Unit {
  let filtered : Array[PendingGltfAnimationRequest] = []
  for req in pending_gltf_animation_requests.val {
    if req.clip_handle.id() != handle.id() {
      filtered.push(req)
    }
  }
  pending_gltf_animation_requests.val = filtered
}

///|
fn scene_pending_remove_mesh_handle(handle : @asset.Handle[@mesh.Mesh]) -> Unit {
  let filtered : Array[PendingGltfMeshRequest] = []
  for req in pending_gltf_mesh_requests.val {
    if req.mesh_handle.id() != handle.id() {
      filtered.push(req)
    }
  }
  pending_gltf_mesh_requests.val = filtered
}

///|
fn scene_queue_gltf_request(
  asset_server : @asset.AssetServer,
  scene_handle : @asset.Handle[Scene],
  scene_asset_path : String,
) -> Unit {
  scene_pending_remove_scene_handle(scene_handle)
  let (gltf_path, label) = scene_split_gltf_asset_path(scene_asset_path)
  let scene_index = match label {
    Some(GltfAssetLabel::Scene(index)) => index
    _ => 0
  }
  pending_gltf_scene_requests.val.push({
    scene_handle,
    gltf_path,
    scene_index,
    gltf_blob: asset_server.load_bytes(gltf_path),
    doc: None,
    buffer_blobs: [],
    buffer_bytes: [],
  })
}

///|
fn scene_queue_gltf_animation_request(
  asset_server : @asset.AssetServer,
  clip_handle : @asset.Handle[@animation.AnimationClip],
  animation_asset_path : String,
) -> Unit {
  scene_pending_remove_animation_handle(clip_handle)
  let (gltf_path, label) = scene_split_gltf_asset_path(animation_asset_path)
  let animation_index = match label {
    Some(GltfAssetLabel::Animation(index)) => index
    _ => 0
  }
  pending_gltf_animation_requests.val.push({
    clip_handle,
    gltf_path,
    animation_index,
    gltf_blob: asset_server.load_bytes(gltf_path),
    doc: None,
    buffer_blobs: [],
    buffer_bytes: [],
  })
}

///|
fn scene_queue_gltf_mesh_request(
  asset_server : @asset.AssetServer,
  mesh_handle : @asset.Handle[@mesh.Mesh],
  mesh_asset_path : String,
) -> Unit {
  scene_pending_remove_mesh_handle(mesh_handle)
  let (gltf_path, label) = scene_split_gltf_asset_path(mesh_asset_path)
  let (mesh_index, primitive_index) = match label {
    Some(GltfAssetLabel::Primitive(mesh, primitive)) => (mesh, primitive)
    _ =>
      abort(
        "Mesh asset loading requires a glTF primitive label such as Mesh0/Primitive0",
      )
  }
  pending_gltf_mesh_requests.val.push({
    mesh_handle,
    gltf_path,
    mesh_index,
    primitive_index,
    gltf_blob: asset_server.load_bytes(gltf_path),
    doc: None,
    buffer_blobs: [],
    buffer_bytes: [],
  })
}

///|
fn json_number(value : Json) -> Double? {
  if value is Number(number, ..) {
    Some(number)
  } else {
    None
  }
}

///|
fn json_string(value : Json) -> String? {
  if value is String(s) {
    Some(s)
  } else {
    None
  }
}

///|
fn json_object(value : Json) -> Map[String, Json]? {
  if value is Object(obj) {
    Some(obj)
  } else {
    None
  }
}

///|
fn json_array(value : Json) -> Array[Json]? {
  if value is Array(arr) {
    Some(arr)
  } else {
    None
  }
}

///|
fn json_get_int(obj : Map[String, Json], key : String) -> Int? {
  guard obj.get(key) is Some(value) else { return None }
  guard json_number(value) is Some(number) else { return None }
  Some(number.to_int())
}

///|
fn json_get_float(obj : Map[String, Json], key : String) -> Float? {
  guard obj.get(key) is Some(value) else { return None }
  guard json_number(value) is Some(number) else { return None }
  Some(Float::from_double(number))
}

///|
fn json_get_string(obj : Map[String, Json], key : String) -> String? {
  guard obj.get(key) is Some(value) else { return None }
  json_string(value)
}

///|
fn json_get_object(obj : Map[String, Json], key : String) -> Map[String, Json]? {
  guard obj.get(key) is Some(value) else { return None }
  json_object(value)
}

///|
fn json_get_array(obj : Map[String, Json], key : String) -> Array[Json]? {
  guard obj.get(key) is Some(value) else { return None }
  json_array(value)
}

///|
fn json_array_float(values : Array[Json], index : Int) -> Float? {
  guard values.get(index) is Some(value) else { return None }
  guard json_number(value) is Some(number) else { return None }
  Some(Float::from_double(number))
}

///|
fn gltf_parse_vec3(value : Json, default_value : @math.Vec3) -> @math.Vec3 {
  guard json_array(value) is Some(values) else { return default_value }
  guard json_array_float(values, 0) is Some(x) else { return default_value }
  guard json_array_float(values, 1) is Some(y) else { return default_value }
  guard json_array_float(values, 2) is Some(z) else { return default_value }
  @math.Vec3::new(x, y, z)
}

///|
fn gltf_parse_vec2(value : Json, default_value : @math.Vec2) -> @math.Vec2 {
  guard json_array(value) is Some(items) else { return default_value }
  guard items.length() >= 2 else { return default_value }
  guard json_array_float(items, 0) is Some(x) else { return default_value }
  guard json_array_float(items, 1) is Some(y) else { return default_value }
  @math.Vec2::new(x, y)
}

///|
fn gltf_parse_quat(value : Json, default_value : @math.Quat) -> @math.Quat {
  guard json_array(value) is Some(values) else { return default_value }
  guard json_array_float(values, 0) is Some(x) else { return default_value }
  guard json_array_float(values, 1) is Some(y) else { return default_value }
  guard json_array_float(values, 2) is Some(z) else { return default_value }
  guard json_array_float(values, 3) is Some(w) else { return default_value }
  @math.Quat::new(x, y, z, w).normalize()
}

///|
fn gltf_parse_color(value : Json, default_value : @color.Color) -> @color.Color {
  guard json_array(value) is Some(values) else { return default_value }
  guard json_array_float(values, 0) is Some(r) else { return default_value }
  guard json_array_float(values, 1) is Some(g) else { return default_value }
  guard json_array_float(values, 2) is Some(b) else { return default_value }
  let a = match json_array_float(values, 3) {
    Some(alpha) => alpha
    None => default_value.a
  }
  @color.Color::new(r, g, b, a)
}

///|
fn gltf_parse_emissive(
  value : Json,
  default_value : @color.Color,
) -> @color.Color {
  guard json_array(value) is Some(values) else { return default_value }
  guard json_array_float(values, 0) is Some(r) else { return default_value }
  guard json_array_float(values, 1) is Some(g) else { return default_value }
  guard json_array_float(values, 2) is Some(b) else { return default_value }
  @color.Color::new(r, g, b, 1.0F)
}

///|
fn quat_from_basis(
  x_axis : @math.Vec3,
  y_axis : @math.Vec3,
  z_axis : @math.Vec3,
) -> @math.Quat {
  let m00 = x_axis.x
  let m01 = y_axis.x
  let m02 = z_axis.x
  let m10 = x_axis.y
  let m11 = y_axis.y
  let m12 = z_axis.y
  let m20 = x_axis.z
  let m21 = y_axis.z
  let m22 = z_axis.z
  let trace = m00 + m11 + m22
  if trace > 0.0F {
    let s = @math.sqrt(trace + 1.0F) * 2.0F
    return @math.Quat::new(
      (m21 - m12) / s,
      (m02 - m20) / s,
      (m10 - m01) / s,
      0.25F * s,
    ).normalize()
  }
  if m00 > m11 && m00 > m22 {
    let s = @math.sqrt(1.0F + m00 - m11 - m22) * 2.0F
    return @math.Quat::new(
      0.25F * s,
      (m01 + m10) / s,
      (m02 + m20) / s,
      (m21 - m12) / s,
    ).normalize()
  }
  if m11 > m22 {
    let s = @math.sqrt(1.0F + m11 - m00 - m22) * 2.0F
    return @math.Quat::new(
      (m01 + m10) / s,
      0.25F * s,
      (m12 + m21) / s,
      (m02 - m20) / s,
    ).normalize()
  }
  let s = @math.sqrt(1.0F + m22 - m00 - m11) * 2.0F
  @math.Quat::new((m02 + m20) / s, (m12 + m21) / s, 0.25F * s, (m10 - m01) / s).normalize()
}

///|
fn gltf_parse_transform_from_matrix(
  values : Array[Json],
) -> @transform.Transform? {
  if values.length() != 16 {
    return None
  }
  let numbers : Array[Float] = []
  for i in 0..<16 {
    guard json_array_float(values, i) is Some(value) else { return None }
    numbers.push(value)
  }

  let x_axis = @math.Vec3::new(numbers[0], numbers[1], numbers[2])
  let y_axis = @math.Vec3::new(numbers[4], numbers[5], numbers[6])
  let z_axis = @math.Vec3::new(numbers[8], numbers[9], numbers[10])
  let translation = @math.Vec3::new(numbers[12], numbers[13], numbers[14])

  let sx = x_axis.length()
  let sy = y_axis.length()
  let sz = z_axis.length()
  let safe_x = if sx <= 1.0e-6F {
    @math.Vec3::new(1.0F, 0.0F, 0.0F)
  } else {
    x_axis.mul_scalar(1.0F / sx)
  }
  let safe_y = if sy <= 1.0e-6F {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    y_axis.mul_scalar(1.0F / sy)
  }
  let safe_z = if sz <= 1.0e-6F {
    @math.Vec3::new(0.0F, 0.0F, 1.0F)
  } else {
    z_axis.mul_scalar(1.0F / sz)
  }

  Some(
    @transform.Transform::new(
      translation,
      quat_from_basis(safe_x, safe_y, safe_z),
      @math.Vec3::new(sx, sy, sz),
    ),
  )
}

///|
fn gltf_parse_node_transform(obj : Map[String, Json]) -> @transform.Transform {
  if json_get_array(obj, "matrix") is Some(values) {
    if gltf_parse_transform_from_matrix(values) is Some(transform) {
      return transform
    }
  }

  let translation = if obj.get("translation") is Some(value) {
    gltf_parse_vec3(value, @math.Vec3::zero())
  } else {
    @math.Vec3::zero()
  }
  let rotation = if obj.get("rotation") is Some(value) {
    gltf_parse_quat(value, @math.Quat::identity())
  } else {
    @math.Quat::identity()
  }
  let scale = if obj.get("scale") is Some(value) {
    gltf_parse_vec3(value, @math.Vec3::splat(1.0F))
  } else {
    @math.Vec3::splat(1.0F)
  }
  @transform.Transform::new(translation, rotation, scale)
}

///|
fn gltf_parse_node_lod_ids(obj : Map[String, Json]) -> Array[Int] {
  let lod_node_ids : Array[Int] = []
  guard json_get_object(obj, "extensions") is Some(extensions) else {
    return lod_node_ids
  }
  guard json_get_object(extensions, "MSFT_lod") is Some(msft_lod) else {
    return lod_node_ids
  }
  guard json_get_array(msft_lod, "ids") is Some(ids) else {
    return lod_node_ids
  }
  for id_value in ids {
    if json_number(id_value) is Some(number) {
      let node_index = number.to_int()
      if node_index >= 0 {
        lod_node_ids.push(node_index)
      }
    }
  }
  lod_node_ids
}

///|
fn gltf_parse_extras(obj : Map[String, Json]) -> String? {
  match obj.get("extras") {
    Some(extras) => Some(extras.stringify())
    None => None
  }
}

///|
fn gltf_primitive_display_name(
  mesh : GltfMeshDef,
  material_name : String?,
) -> @ecs.Name? {
  let mesh_name = if mesh.name == "" { "Mesh" } else { mesh.name }
  match material_name {
    Some(name) => Some(@ecs.Name::new("\{mesh_name}.\{name}"))
    None => Some(@ecs.Name::new(mesh_name))
  }
}

///|
fn gltf_parse_texture_index(obj : Map[String, Json], key : String) -> Int? {
  guard json_get_object(obj, key) is Some(texture_info) else { return None }
  json_get_int(texture_info, "index")
}

///|
fn gltf_parse_texture_transform(
  texture_info : Map[String, Json],
) -> (@math.Vec2, @math.Vec2) {
  let mut uv_offset = @math.Vec2::new(0.0F, 0.0F)
  let mut uv_scale = @math.Vec2::new(1.0F, 1.0F)
  guard json_get_object(texture_info, "extensions") is Some(extensions) else {
    return (uv_offset, uv_scale)
  }
  guard json_get_object(extensions, "KHR_texture_transform") is Some(transform) else {
    return (uv_offset, uv_scale)
  }
  if transform.get("offset") is Some(value) {
    uv_offset = gltf_parse_vec2(value, uv_offset)
  }
  if transform.get("scale") is Some(value) {
    uv_scale = gltf_parse_vec2(value, uv_scale)
  }
  (uv_offset, uv_scale)
}

///|
fn gltf_parse_material_alpha_mode(obj : Map[String, Json]) -> @pbr.AlphaMode3d {
  guard json_get_string(obj, "alphaMode") is Some(alpha_mode) else {
    return @pbr.AlphaMode3d::Opaque
  }
  match alpha_mode {
    "BLEND" => @pbr.AlphaMode3d::Blend
    "MASK" => {
      let cutoff = match json_get_float(obj, "alphaCutoff") {
        Some(value) => value
        None => 0.5F
      }
      @pbr.AlphaMode3d::Mask(cutoff)
    }
    _ => @pbr.AlphaMode3d::Opaque
  }
}

///|
fn gltf_parse_material_unlit(obj : Map[String, Json]) -> Bool {
  guard json_get_object(obj, "extensions") is Some(extensions) else {
    return false
  }
  extensions.get("KHR_materials_unlit") is Some(_)
}

///|
fn gltf_parse_material_clearcoat(
  obj : Map[String, Json],
) -> (Float, Float, Int?, Int?, Int?) {
  guard json_get_object(obj, "extensions") is Some(extensions) else {
    return (0.0F, 0.0F, None, None, None)
  }
  guard json_get_object(extensions, "KHR_materials_clearcoat")
    is Some(clearcoat_ext) else {
    return (0.0F, 0.0F, None, None, None)
  }
  let clearcoat_factor = match
    json_get_float(clearcoat_ext, "clearcoatFactor") {
    Some(v) => if v < 0.0F { 0.0F } else if v > 1.0F { 1.0F } else { v }
    None => 0.0F
  }
  let clearcoat_roughness_factor = match
    json_get_float(clearcoat_ext, "clearcoatRoughnessFactor") {
    Some(v) => if v < 0.0F { 0.0F } else if v > 1.0F { 1.0F } else { v }
    None => 0.0F
  }
  (
    clearcoat_factor,
    clearcoat_roughness_factor,
    gltf_parse_texture_index(clearcoat_ext, "clearcoatTexture"),
    gltf_parse_texture_index(clearcoat_ext, "clearcoatRoughnessTexture"),
    gltf_parse_texture_index(clearcoat_ext, "clearcoatNormalTexture"),
  )
}

///|
fn gltf_parse_material_anisotropy(
  obj : Map[String, Json],
) -> (Float, Float, Int?) {
  guard json_get_object(obj, "extensions") is Some(extensions) else {
    return (0.0F, 0.0F, None)
  }
  guard json_get_object(extensions, "KHR_materials_anisotropy")
    is Some(anisotropy_ext) else {
    return (0.0F, 0.0F, None)
  }
  let anisotropy_strength = match
    json_get_float(anisotropy_ext, "anisotropyStrength") {
    Some(v) => if v < 0.0F { 0.0F } else if v > 1.0F { 1.0F } else { v }
    None => 0.0F
  }
  let anisotropy_rotation = match
    json_get_float(anisotropy_ext, "anisotropyRotation") {
    Some(v) => v
    None => 0.0F
  }
  (
    anisotropy_strength,
    anisotropy_rotation,
    gltf_parse_texture_index(anisotropy_ext, "anisotropyTexture"),
  )
}

///|
fn gltf_sampler_filter_is_nearest(filter : Int) -> Bool {
  filter == 9728 || filter == 9984 || filter == 9986
}

///|
fn gltf_sampler_wrap_is_repeat(wrap_mode : Int) -> Bool {
  wrap_mode == 10497 || wrap_mode == 33648
}

///|
fn gltf_parse_animation_interpolation(
  obj : Map[String, Json],
) -> @animation.GltfInterpolation {
  @animation.gltf_interpolation_from_name(json_get_string(obj, "interpolation"))
}

///|
fn gltf_parse_document(source : String) -> ParsedGltfDocument? {
  let root_json = @json.parse(source) catch { _ => return None }
  guard json_object(root_json) is Some(root) else { return None }

  let default_scene = match json_get_int(root, "scene") {
    Some(index) => if index < 0 { 0 } else { index }
    None => 0
  }

  let buffers : Array[GltfBufferDef] = []
  if json_get_array(root, "buffers") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        buffers.push({
          uri: json_get_string(obj, "uri"),
          byte_length: match json_get_int(obj, "byteLength") {
            Some(v) => v
            None => 0
          },
        })
      } else {
        buffers.push({ uri: None, byte_length: 0 })
      }
    }
  }

  let buffer_views : Array[GltfBufferViewDef] = []
  if json_get_array(root, "bufferViews") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        buffer_views.push({
          buffer: match json_get_int(obj, "buffer") {
            Some(index) => index
            None => -1
          },
          byte_offset: match json_get_int(obj, "byteOffset") {
            Some(offset) => offset
            None => 0
          },
          byte_length: match json_get_int(obj, "byteLength") {
            Some(length) => length
            None => 0
          },
          byte_stride: json_get_int(obj, "byteStride"),
        })
      } else {
        buffer_views.push({
          buffer: -1,
          byte_offset: 0,
          byte_length: 0,
          byte_stride: None,
        })
      }
    }
  }

  let accessors : Array[GltfAccessorDef] = []
  if json_get_array(root, "accessors") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        accessors.push({
          buffer_view: json_get_int(obj, "bufferView"),
          byte_offset: match json_get_int(obj, "byteOffset") {
            Some(offset) => offset
            None => 0
          },
          component_type: match json_get_int(obj, "componentType") {
            Some(component) => component
            None => 0
          },
          count: match json_get_int(obj, "count") {
            Some(count) => count
            None => 0
          },
          accessor_type: match json_get_string(obj, "type") {
            Some(value) => value
            None => ""
          },
        })
      } else {
        accessors.push({
          buffer_view: None,
          byte_offset: 0,
          component_type: 0,
          count: 0,
          accessor_type: "",
        })
      }
    }
  }

  let meshes : Array[GltfMeshDef] = []
  if json_get_array(root, "meshes") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let primitives : Array[GltfPrimitiveDef] = []
        let weights : Array[Float] = []
        let morph_target_names : Array[String] = []
        if json_get_array(obj, "weights") is Some(weight_entries) {
          for weight_entry in weight_entries {
            if json_number(weight_entry) is Some(number) {
              weights.push(Float::from_double(number))
            }
          }
        }
        if json_get_object(obj, "extras") is Some(extras_obj) &&
          json_get_array(extras_obj, "targetNames") is Some(target_name_entries) {
          for target_name_entry in target_name_entries {
            if json_string(target_name_entry) is Some(target_name) {
              morph_target_names.push(target_name)
            }
          }
        }
        if json_get_array(obj, "primitives") is Some(primitive_entries) {
          for primitive_index, primitive_entry in primitive_entries {
            if json_object(primitive_entry) is Some(primitive_obj) {
              let attributes = json_get_object(primitive_obj, "attributes")
              let position = match attributes {
                Some(attr_obj) => json_get_int(attr_obj, "POSITION")
                None => None
              }
              let uv0 = match attributes {
                Some(attr_obj) => json_get_int(attr_obj, "TEXCOORD_0")
                None => None
              }
              let joint_indices = match attributes {
                Some(attr_obj) => json_get_int(attr_obj, "JOINTS_0")
                None => None
              }
              let joint_weights = match attributes {
                Some(attr_obj) => json_get_int(attr_obj, "WEIGHTS_0")
                None => None
              }
              let custom_attributes : Array[(String, Int)] = []
              if attributes is Some(attr_obj) {
                for entry in attr_obj.iter() {
                  let (key, value) = entry
                  if key != "POSITION" &&
                    key != "NORMAL" &&
                    key != "TEXCOORD_0" &&
                    key != "TEXCOORD_1" &&
                    key != "COLOR_0" &&
                    key != "JOINTS_0" &&
                    key != "WEIGHTS_0" &&
                    key.has_prefix("_") &&
                    json_number(value) is Some(number) {
                    custom_attributes.push((key, number.to_int()))
                  }
                }
              }
              let morph_targets : Array[Int?] = []
              if json_get_array(primitive_obj, "targets")
                is Some(target_entries) {
                for target_entry in target_entries {
                  if json_object(target_entry) is Some(target_obj) {
                    morph_targets.push(json_get_int(target_obj, "POSITION"))
                  } else {
                    morph_targets.push(None)
                  }
                }
              }
              primitives.push({
                primitive_index,
                position,
                uv0,
                joint_indices,
                joint_weights,
                custom_attributes,
                morph_targets,
                indices: json_get_int(primitive_obj, "indices"),
                material: json_get_int(primitive_obj, "material"),
                extras: gltf_parse_extras(primitive_obj),
              })
            } else {
              primitives.push({
                primitive_index,
                position: None,
                uv0: None,
                joint_indices: None,
                joint_weights: None,
                custom_attributes: [],
                morph_targets: [],
                indices: None,
                material: None,
                extras: None,
              })
            }
          }
        }
        meshes.push({
          name: json_get_string(obj, "name").unwrap_or(""),
          extras: gltf_parse_extras(obj),
          weights,
          morph_target_names,
          primitives,
        })
      } else {
        meshes.push({
          name: "",
          extras: None,
          weights: [],
          morph_target_names: [],
          primitives: [],
        })
      }
    }
  }

  let nodes : Array[GltfNodeDef] = []
  if json_get_array(root, "nodes") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let children : Array[Int] = []
        if json_get_array(obj, "children") is Some(child_entries) {
          for child_entry in child_entries {
            if json_number(child_entry) is Some(number) {
              children.push(number.to_int())
            }
          }
        }
        nodes.push({
          name: match json_get_string(obj, "name") {
            Some(value) => value
            None => ""
          },
          mesh: json_get_int(obj, "mesh"),
          skin: json_get_int(obj, "skin"),
          children,
          lod_nodes: gltf_parse_node_lod_ids(obj),
          transform: gltf_parse_node_transform(obj),
        })
      } else {
        nodes.push({
          name: "",
          mesh: None,
          skin: None,
          children: [],
          lod_nodes: [],
          transform: @transform.Transform::identity(),
        })
      }
    }
  }

  let skins : Array[GltfSkinDef] = []
  if json_get_array(root, "skins") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let joints : Array[Int] = []
        if json_get_array(obj, "joints") is Some(joint_entries) {
          for joint_entry in joint_entries {
            if json_number(joint_entry) is Some(number) {
              joints.push(number.to_int())
            }
          }
        }
        skins.push({
          inverse_bind_matrices: json_get_int(obj, "inverseBindMatrices"),
          joints,
        })
      } else {
        skins.push({ inverse_bind_matrices: None, joints: [] })
      }
    }
  }

  let scenes : Array[GltfSceneDef] = []
  if json_get_array(root, "scenes") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let node_indices : Array[Int] = []
        if json_get_array(obj, "nodes") is Some(node_entries) {
          for node_entry in node_entries {
            if json_number(node_entry) is Some(number) {
              node_indices.push(number.to_int())
            }
          }
        }
        scenes.push({ nodes: node_indices, extras: gltf_parse_extras(obj) })
      } else {
        scenes.push({ nodes: [], extras: None })
      }
    }
  }

  let materials : Array[GltfMaterialDef] = []
  if json_get_array(root, "materials") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let mut base_color = @color.Color::white()
        let mut metallic = 1.0F
        let mut roughness = 1.0F
        let mut clearcoat = 0.0F
        let mut clearcoat_roughness = 0.0F
        let mut clearcoat_texture : Int? = None
        let mut clearcoat_roughness_texture : Int? = None
        let mut clearcoat_normal_texture : Int? = None
        let mut anisotropy_strength = 0.0F
        let mut anisotropy_rotation = 0.0F
        let mut anisotropy_texture : Int? = None
        let mut base_color_texture : Int? = None
        let mut base_color_uv_offset = @math.Vec2::new(0.0F, 0.0F)
        let mut base_color_uv_scale = @math.Vec2::new(1.0F, 1.0F)
        let mut metallic_roughness_texture : Int? = None

        if json_get_object(obj, "pbrMetallicRoughness") is Some(pbr) {
          if pbr.get("baseColorFactor") is Some(value) {
            base_color = gltf_parse_color(value, base_color)
          }
          if json_get_float(pbr, "metallicFactor") is Some(value) {
            metallic = value
          }
          if json_get_float(pbr, "roughnessFactor") is Some(value) {
            roughness = value
          }
          if json_get_object(pbr, "baseColorTexture") is Some(base_color_tex) {
            base_color_texture = json_get_int(base_color_tex, "index")
            let (uv_offset, uv_scale) = gltf_parse_texture_transform(
              base_color_tex,
            )
            base_color_uv_offset = uv_offset
            base_color_uv_scale = uv_scale
          }
          metallic_roughness_texture = gltf_parse_texture_index(
            pbr, "metallicRoughnessTexture",
          )
        }
        let (
          parsed_clearcoat,
          parsed_clearcoat_roughness,
          parsed_clearcoat_texture,
          parsed_clearcoat_roughness_texture,
          parsed_clearcoat_normal_texture,
        ) = gltf_parse_material_clearcoat(obj)
        clearcoat = parsed_clearcoat
        clearcoat_roughness = parsed_clearcoat_roughness
        clearcoat_texture = parsed_clearcoat_texture
        clearcoat_roughness_texture = parsed_clearcoat_roughness_texture
        clearcoat_normal_texture = parsed_clearcoat_normal_texture
        let (
          parsed_anisotropy_strength,
          parsed_anisotropy_rotation,
          parsed_anisotropy_texture,
        ) = gltf_parse_material_anisotropy(obj)
        anisotropy_strength = parsed_anisotropy_strength
        anisotropy_rotation = parsed_anisotropy_rotation
        anisotropy_texture = parsed_anisotropy_texture

        let emissive = if obj.get("emissiveFactor") is Some(value) {
          gltf_parse_emissive(value, @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F))
        } else {
          @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F)
        }

        materials.push({
          name: json_get_string(obj, "name").unwrap_or(""),
          extras: gltf_parse_extras(obj),
          base_color,
          base_color_texture,
          base_color_uv_offset,
          base_color_uv_scale,
          clearcoat,
          clearcoat_roughness,
          clearcoat_texture,
          clearcoat_roughness_texture,
          clearcoat_normal_texture,
          anisotropy_strength,
          anisotropy_rotation,
          anisotropy_texture,
          normal_texture: gltf_parse_texture_index(obj, "normalTexture"),
          emissive_texture: gltf_parse_texture_index(obj, "emissiveTexture"),
          metallic_roughness_texture,
          occlusion_texture: gltf_parse_texture_index(obj, "occlusionTexture"),
          metallic,
          roughness,
          emissive,
          alpha_mode: gltf_parse_material_alpha_mode(obj),
          unlit: gltf_parse_material_unlit(obj),
        })
      } else {
        materials.push({
          name: "",
          extras: None,
          base_color: @color.Color::white(),
          base_color_texture: None,
          base_color_uv_offset: @math.Vec2::new(0.0F, 0.0F),
          base_color_uv_scale: @math.Vec2::new(1.0F, 1.0F),
          clearcoat: 0.0F,
          clearcoat_roughness: 0.0F,
          clearcoat_texture: None,
          clearcoat_roughness_texture: None,
          clearcoat_normal_texture: None,
          anisotropy_strength: 0.0F,
          anisotropy_rotation: 0.0F,
          anisotropy_texture: None,
          normal_texture: None,
          emissive_texture: None,
          metallic_roughness_texture: None,
          occlusion_texture: None,
          metallic: 1.0F,
          roughness: 1.0F,
          emissive: @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
          alpha_mode: @pbr.AlphaMode3d::Opaque,
          unlit: false,
        })
      }
    }
  }

  let samplers : Array[GltfSamplerDef] = []
  if json_get_array(root, "samplers") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let nearest = match json_get_int(obj, "magFilter") {
          Some(mag_filter) => gltf_sampler_filter_is_nearest(mag_filter)
          None =>
            match json_get_int(obj, "minFilter") {
              Some(min_filter) => gltf_sampler_filter_is_nearest(min_filter)
              None => false
            }
        }
        let repeat = match
          (json_get_int(obj, "wrapS"), json_get_int(obj, "wrapT")) {
          (Some(wrap_s), Some(wrap_t)) =>
            gltf_sampler_wrap_is_repeat(wrap_s) &&
            gltf_sampler_wrap_is_repeat(wrap_t)
          (Some(wrap_s), None) => gltf_sampler_wrap_is_repeat(wrap_s)
          (None, Some(wrap_t)) => gltf_sampler_wrap_is_repeat(wrap_t)
          (None, None) => true
        }
        samplers.push({ nearest, repeat })
      } else {
        samplers.push({ nearest: false, repeat: true })
      }
    }
  }

  let textures : Array[GltfTextureDef] = []
  if json_get_array(root, "textures") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        textures.push({
          source: json_get_int(obj, "source"),
          sampler: json_get_int(obj, "sampler"),
        })
      } else {
        textures.push({ source: None, sampler: None })
      }
    }
  }

  let images : Array[GltfImageDef] = []
  if json_get_array(root, "images") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        images.push({
          uri: json_get_string(obj, "uri"),
          mime_type: json_get_string(obj, "mimeType"),
          buffer_view: json_get_int(obj, "bufferView"),
        })
      } else {
        images.push({ uri: None, mime_type: None, buffer_view: None })
      }
    }
  }

  let animations : Array[GltfAnimationDef] = []
  if json_get_array(root, "animations") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let animation_samplers : Array[GltfAnimationSamplerDef] = []
        if json_get_array(obj, "samplers") is Some(sampler_entries) {
          for sampler_entry in sampler_entries {
            if json_object(sampler_entry) is Some(sampler_obj) {
              animation_samplers.push({
                input: json_get_int(sampler_obj, "input"),
                output: json_get_int(sampler_obj, "output"),
                interpolation: gltf_parse_animation_interpolation(sampler_obj),
              })
            } else {
              animation_samplers.push({
                input: None,
                output: None,
                interpolation: @animation.gltf_interpolation_from_name(None),
              })
            }
          }
        }

        let channels : Array[GltfAnimationChannelDef] = []
        if json_get_array(obj, "channels") is Some(channel_entries) {
          for channel_entry in channel_entries {
            if json_object(channel_entry) is Some(channel_obj) {
              let target = json_get_object(channel_obj, "target")
              channels.push({
                sampler: json_get_int(channel_obj, "sampler"),
                target_node: match target {
                  Some(target_obj) => json_get_int(target_obj, "node")
                  None => None
                },
                target_path: match target {
                  Some(target_obj) =>
                    match json_get_string(target_obj, "path") {
                      Some(path) => path
                      None => ""
                    }
                  None => ""
                },
              })
            } else {
              channels.push({
                sampler: None,
                target_node: None,
                target_path: "",
              })
            }
          }
        }
        animations.push({
          name: json_get_string(obj, "name").unwrap_or(""),
          samplers: animation_samplers,
          channels,
        })
      } else {
        animations.push({ name: "", samplers: [], channels: [] })
      }
    }
  }

  Some({
    default_scene,
    buffers,
    buffer_views,
    accessors,
    meshes,
    nodes,
    skins,
    scenes,
    materials,
    samplers,
    textures,
    images,
    animations,
  })
}

///|
fn hex_nibble(code : Int) -> Int? {
  if code >= 48 && code <= 57 {
    return Some(code - 48)
  }
  if code >= 65 && code <= 70 {
    return Some(code - 55)
  }
  if code >= 97 && code <= 102 {
    return Some(code - 87)
  }
  None
}

///|
fn uri_percent_decode_bytes(payload : String) -> Bytes? {
  let out : Array[Byte] = []
  let mut i = 0
  let len = payload.length()
  while i < len {
    let code = payload.code_unit_at(i).to_int() & 0xFFFF
    if code == 37 && i + 2 < len {
      let c1 = payload.code_unit_at(i + 1).to_int() & 0xFFFF
      let c2 = payload.code_unit_at(i + 2).to_int() & 0xFFFF
      guard hex_nibble(c1) is Some(h1) else { return None }
      guard hex_nibble(c2) is Some(h2) else { return None }
      out.push((h1 * 16 + h2).to_byte())
      i = i + 3
      continue
    }
    guard code <= 255 else { return None }
    out.push(code.to_byte())
    i = i + 1
  }
  Some(Bytes::from_array(out))
}

///|
fn data_uri_decode_bytes(uri : String) -> Bytes? {
  guard uri.has_prefix("data:") else { return None }
  guard uri.find(",") is Some(split) else { return None }
  let head = uri[0:split].to_string()
  let payload = uri[split + 1:uri.length()].to_string()
  if head.contains(";base64") {
    let decoded = @base64.decode(payload[:], ignore_whitespace=true) catch {
      _ => @base64.decode_lossy(payload[:], ignore_whitespace=true)
    }
    return Some(decoded)
  }
  uri_percent_decode_bytes(payload)
}

///|
fn bytes_slice(bytes : Bytes, start : Int, end_ : Int) -> Bytes? {
  guard start >= 0 && end_ >= start && end_ <= bytes.length() else {
    return None
  }
  let out : Array[Byte] = []
  for i in start..<end_ {
    out.push(bytes[i])
  }
  Some(Bytes::from_array(out))
}

///|
fn bytes_text(bytes : Bytes) -> String {
  let chars : Array[Char] = []
  for byte in bytes {
    let code = byte.to_int() & 0xFF
    if code.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  String::from_array(chars)
}

///|
fn gltf_parse_glb(blob_bytes : Bytes) -> (String, Bytes?)? {
  guard bytes_read_u32_le(blob_bytes, 0) is Some(magic) else { return None }
  guard magic == 0x46546C67U else { return None } // 'glTF'
  guard bytes_read_u32_le(blob_bytes, 4) is Some(version) else { return None }
  guard version == 2U else { return None }
  guard bytes_read_u32_le(blob_bytes, 8) is Some(total_u) else { return None }
  guard total_u <= 2_147_483_647U else { return None }
  let total = total_u.reinterpret_as_int()
  guard total >= 12 && total <= blob_bytes.length() else { return None }

  let mut offset = 12
  let mut json_chunk : String? = None
  let mut bin_chunk : Bytes? = None
  while offset + 8 <= total {
    guard bytes_read_u32_le(blob_bytes, offset) is Some(chunk_len_u) else {
      return None
    }
    guard bytes_read_u32_le(blob_bytes, offset + 4) is Some(chunk_type) else {
      return None
    }
    guard chunk_len_u <= 2_147_483_647U else { return None }
    let chunk_len = chunk_len_u.reinterpret_as_int()
    let start = offset + 8
    let end_ = start + chunk_len
    guard chunk_len >= 0 && end_ <= total else { return None }
    guard bytes_slice(blob_bytes, start, end_) is Some(chunk_data) else {
      return None
    }

    if chunk_type == 0x4E4F534AU && json_chunk is None { // JSON
      json_chunk = Some(bytes_text(chunk_data))
    } else if chunk_type == 0x004E4942U && bin_chunk is None { // BIN
      bin_chunk = Some(chunk_data)
    }
    offset = end_
  }
  guard offset == total else { return None }
  guard json_chunk is Some(json_text) else { return None }
  Some((json_text, bin_chunk))
}

///|
fn gltf_parse_source(
  gltf_path : String,
  blob_bytes : Bytes,
) -> (ParsedGltfDocument, Array[Bytes?])? {
  let mut source_json : String? = None
  let mut embedded_bin : Bytes? = None

  if gltf_path.has_suffix(".glb") {
    if gltf_parse_glb(blob_bytes) is Some(parsed_glb) {
      source_json = Some(parsed_glb.0)
      embedded_bin = parsed_glb.1
    } else {
      return None
    }
  } else if bytes_read_u32_le(blob_bytes, 0) is Some(magic) &&
    magic == 0x46546C67U {
    if gltf_parse_glb(blob_bytes) is Some(parsed_glb) {
      source_json = Some(parsed_glb.0)
      embedded_bin = parsed_glb.1
    } else {
      return None
    }
  } else {
    source_json = Some(bytes_text(blob_bytes))
  }

  guard source_json is Some(json_text) else { return None }
  guard gltf_parse_document(json_text) is Some(doc) else { return None }

  let initial_buffer_bytes : Array[Bytes?] = []
  for _ in doc.buffers {
    initial_buffer_bytes.push(None)
  }
  if embedded_bin is Some(bin) {
    let mut assigned = false
    for i in 0..<doc.buffers.length() {
      if doc.buffers[i].uri is None && !assigned {
        initial_buffer_bytes[i] = Some(bin)
        assigned = true
      }
    }
  }

  Some((doc, initial_buffer_bytes))
}

///|
fn gltf_component_count(accessor_type : String) -> Int? {
  match accessor_type {
    "SCALAR" => Some(1)
    "VEC2" => Some(2)
    "VEC3" => Some(3)
    "VEC4" => Some(4)
    "MAT4" => Some(16)
    _ => None
  }
}

///|
fn gltf_component_size(component_type : Int) -> Int? {
  match component_type {
    5121 => Some(1)
    5123 => Some(2)
    5125 => Some(4)
    5126 => Some(4)
    _ => None
  }
}

///|
fn gltf_accessor_layout(
  doc : ParsedGltfDocument,
  accessor_index : Int,
) -> (Int, Int, Int, Int, Int, Int)? {
  guard accessor_index >= 0 && accessor_index < doc.accessors.length() else {
    return None
  }
  let accessor = doc.accessors[accessor_index]
  guard accessor.buffer_view is Some(buffer_view_index) else { return None }
  guard buffer_view_index >= 0 && buffer_view_index < doc.buffer_views.length() else {
    return None
  }
  let view = doc.buffer_views[buffer_view_index]
  let buffer_index = view.buffer
  guard buffer_index >= 0 else { return None }
  guard gltf_component_size(accessor.component_type) is Some(component_size) else {
    return None
  }
  guard gltf_component_count(accessor.accessor_type) is Some(component_count) else {
    return None
  }
  let stride = match view.byte_stride {
    Some(s) => if s <= 0 { component_size * component_count } else { s }
    None => component_size * component_count
  }
  let base_offset = view.byte_offset + accessor.byte_offset
  let required_span = if accessor.count <= 0 {
    0
  } else {
    stride * (accessor.count - 1) + component_size * component_count
  }
  guard base_offset >= 0 &&
    view.byte_length >= required_span &&
    base_offset + required_span <= view.byte_offset + view.byte_length else {
    return None
  }
  Some(
    (
      buffer_index,
      base_offset,
      stride,
      accessor.count,
      accessor.component_type,
      component_count,
    ),
  )
}

///|
fn bytes_read_u8(bytes : Bytes, offset : Int) -> Int? {
  guard offset >= 0 && offset < bytes.length() else { return None }
  Some(bytes[offset].to_int() & 0xFF)
}

///|
fn bytes_read_u16_le(bytes : Bytes, offset : Int) -> Int? {
  guard bytes_read_u8(bytes, offset) is Some(b0) else { return None }
  guard bytes_read_u8(bytes, offset + 1) is Some(b1) else { return None }
  Some(b0 | (b1 << 8))
}

///|
fn bytes_read_u32_le(bytes : Bytes, offset : Int) -> UInt? {
  guard bytes_read_u8(bytes, offset) is Some(b0) else { return None }
  guard bytes_read_u8(bytes, offset + 1) is Some(b1) else { return None }
  guard bytes_read_u8(bytes, offset + 2) is Some(b2) else { return None }
  guard bytes_read_u8(bytes, offset + 3) is Some(b3) else { return None }
  Some(
    b0.reinterpret_as_uint() |
    (b1.reinterpret_as_uint() << 8) |
    (b2.reinterpret_as_uint() << 16) |
    (b3.reinterpret_as_uint() << 24),
  )
}

///|
fn bytes_read_f32_le(bytes : Bytes, offset : Int) -> Float? {
  guard bytes_read_u32_le(bytes, offset) is Some(bits) else { return None }
  Some(Float::reinterpret_from_uint(bits))
}

///|
fn gltf_read_accessor_vec3(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> Array[@math.Vec3]? {
  guard gltf_accessor_layout(doc, accessor_index) is Some(layout) else {
    return None
  }
  let buffer_index = layout.0
  let base_offset = layout.1
  let stride = layout.2
  let count = layout.3
  let component_type = layout.4
  let component_count = layout.5
  guard buffer_index < buffer_bytes.length() else { return None }
  let bytes = buffer_bytes[buffer_index]
  guard component_type == 5126 && component_count == 3 else { return None }
  let out : Array[@math.Vec3] = []
  for i in 0..<count {
    let offset = base_offset + i * stride
    guard bytes_read_f32_le(bytes, offset) is Some(x) else { return None }
    guard bytes_read_f32_le(bytes, offset + 4) is Some(y) else { return None }
    guard bytes_read_f32_le(bytes, offset + 8) is Some(z) else { return None }
    out.push(@math.Vec3::new(x, y, z))
  }
  Some(out)
}

///|
fn gltf_read_accessor_vec2(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> Array[@math.Vec2]? {
  guard gltf_accessor_layout(doc, accessor_index) is Some(layout) else {
    return None
  }
  let buffer_index = layout.0
  let base_offset = layout.1
  let stride = layout.2
  let count = layout.3
  let component_type = layout.4
  let component_count = layout.5
  guard buffer_index < buffer_bytes.length() else { return None }
  let bytes = buffer_bytes[buffer_index]
  guard component_type == 5126 && component_count == 2 else { return None }
  let out : Array[@math.Vec2] = []
  for i in 0..<count {
    let offset = base_offset + i * stride
    guard bytes_read_f32_le(bytes, offset) is Some(x) else { return None }
    guard bytes_read_f32_le(bytes, offset + 4) is Some(y) else { return None }
    out.push(@math.Vec2::new(x, y))
  }
  Some(out)
}

///|
fn gltf_read_accessor_joint_indices(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> Array[@mesh.MeshJointIndices]? {
  guard gltf_accessor_layout(doc, accessor_index) is Some(layout) else {
    return None
  }
  let buffer_index = layout.0
  let base_offset = layout.1
  let stride = layout.2
  let count = layout.3
  let component_type = layout.4
  let component_count = layout.5
  guard buffer_index < buffer_bytes.length() else { return None }
  let bytes = buffer_bytes[buffer_index]
  guard component_count == 4 else { return None }
  let out : Array[@mesh.MeshJointIndices] = []
  for i in 0..<count {
    let offset = base_offset + i * stride
    match component_type {
      5121 => {
        guard bytes_read_u8(bytes, offset) is Some(x) else { return None }
        guard bytes_read_u8(bytes, offset + 1) is Some(y) else { return None }
        guard bytes_read_u8(bytes, offset + 2) is Some(z) else { return None }
        guard bytes_read_u8(bytes, offset + 3) is Some(w) else { return None }
        out.push(@mesh.MeshJointIndices::new(x, y, z, w))
      }
      5123 => {
        guard bytes_read_u16_le(bytes, offset) is Some(x) else { return None }
        guard bytes_read_u16_le(bytes, offset + 2) is Some(y) else {
          return None
        }
        guard bytes_read_u16_le(bytes, offset + 4) is Some(z) else {
          return None
        }
        guard bytes_read_u16_le(bytes, offset + 6) is Some(w) else {
          return None
        }
        out.push(@mesh.MeshJointIndices::new(x, y, z, w))
      }
      _ => return None
    }
  }
  Some(out)
}

///|
fn gltf_read_accessor_vec4(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> Array[@math.Vec4]? {
  guard gltf_read_accessor_f32_components(doc, buffer_bytes, accessor_index)
    is Some(decoded) else {
    return None
  }
  guard decoded.0 == 4 else { return None }
  guard decoded.1.length() % 4 == 0 else { return None }
  let out : Array[@math.Vec4] = []
  let vec_count = decoded.1.length() / 4
  for i in 0..<vec_count {
    out.push(
      @math.Vec4::new(
        decoded.1[i * 4],
        decoded.1[i * 4 + 1],
        decoded.1[i * 4 + 2],
        decoded.1[i * 4 + 3],
      ),
    )
  }
  Some(out)
}

///|
fn gltf_read_accessor_mat4(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> Array[@mesh.SkinningMat4]? {
  guard gltf_read_accessor_f32_components(doc, buffer_bytes, accessor_index)
    is Some(decoded) else {
    return None
  }
  guard decoded.0 == 16 else { return None }
  guard decoded.1.length() % 16 == 0 else { return None }
  let out : Array[@mesh.SkinningMat4] = []
  let matrix_count = decoded.1.length() / 16
  for i in 0..<matrix_count {
    let base = i * 16
    // glTF MAT4 data is column-major; SkinningMat4 fields are row-major.
    out.push(
      @mesh.SkinningMat4::from_values(
        decoded.1[base],
        decoded.1[base + 4],
        decoded.1[base + 8],
        decoded.1[base + 12],
        decoded.1[base + 1],
        decoded.1[base + 5],
        decoded.1[base + 9],
        decoded.1[base + 13],
        decoded.1[base + 2],
        decoded.1[base + 6],
        decoded.1[base + 10],
        decoded.1[base + 14],
        decoded.1[base + 3],
        decoded.1[base + 7],
        decoded.1[base + 11],
        decoded.1[base + 15],
      ),
    )
  }
  Some(out)
}

///|
fn gltf_read_accessor_indices(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> Array[Int]? {
  guard gltf_accessor_layout(doc, accessor_index) is Some(layout) else {
    return None
  }
  let buffer_index = layout.0
  let base_offset = layout.1
  let stride = layout.2
  let count = layout.3
  let component_type = layout.4
  let component_count = layout.5
  guard buffer_index < buffer_bytes.length() else { return None }
  let bytes = buffer_bytes[buffer_index]
  guard component_count == 1 else { return None }
  let out : Array[Int] = []
  for i in 0..<count {
    let offset = base_offset + i * stride
    match component_type {
      5121 => {
        guard bytes_read_u8(bytes, offset) is Some(value) else { return None }
        out.push(value)
      }
      5123 => {
        guard bytes_read_u16_le(bytes, offset) is Some(value) else {
          return None
        }
        out.push(value)
      }
      5125 => {
        guard bytes_read_u32_le(bytes, offset) is Some(value) else {
          return None
        }
        guard value <= 2_147_483_647U else { return None }
        out.push(value.reinterpret_as_int())
      }
      _ => return None
    }
  }
  Some(out)
}

///|
fn gltf_read_accessor_f32_components(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> (Int, Array[Float])? {
  guard gltf_accessor_layout(doc, accessor_index) is Some(layout) else {
    return None
  }
  let buffer_index = layout.0
  let base_offset = layout.1
  let stride = layout.2
  let count = layout.3
  let component_type = layout.4
  let component_count = layout.5
  guard buffer_index < buffer_bytes.length() else { return None }
  let bytes = buffer_bytes[buffer_index]
  guard component_type == 5126 else { return None }
  let out : Array[Float] = []
  for i in 0..<count {
    let offset = base_offset + i * stride
    for c in 0..<component_count {
      guard bytes_read_f32_le(bytes, offset + c * 4) is Some(value) else {
        return None
      }
      out.push(value)
    }
  }
  Some((component_count, out))
}

///|
fn gltf_read_accessor_timestamps(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  accessor_index : Int,
) -> Array[Float]? {
  guard gltf_read_accessor_f32_components(doc, buffer_bytes, accessor_index)
    is Some(decoded) else {
    return None
  }
  guard decoded.0 == 1 else { return None }
  Some(decoded.1)
}

///|
fn gltf_node_path_name(node : GltfNodeDef, node_index : Int) -> String {
  if node.name == "" {
    "GltfNode\{node_index.to_string()}"
  } else {
    node.name
  }
}

///|
fn gltf_collect_node_name_paths(
  doc : ParsedGltfDocument,
) -> Array[Array[String]?] {
  let paths : Array[Array[String]?] = []
  for _ in doc.nodes {
    paths.push(None)
  }

  fn walk_node_paths(
    node_index : Int,
    current_path : Array[String],
    visited : Array[Bool],
  ) -> Unit {
    guard node_index >= 0 && node_index < doc.nodes.length() else { return }
    if visited[node_index] {
      return
    }
    visited[node_index] = true
    let node = doc.nodes[node_index]

    let next_path : Array[String] = []
    for part in current_path {
      next_path.push(part)
    }
    next_path.push(gltf_node_path_name(node, node_index))

    for child in node.children {
      walk_node_paths(child, next_path, visited)
    }

    paths[node_index] = Some(next_path)
    visited[node_index] = false
  }

  for scene in doc.scenes {
    for root_node in scene.nodes {
      let visited : Array[Bool] = []
      for _ in doc.nodes {
        visited.push(false)
      }
      walk_node_paths(root_node, [], visited)
    }
  }

  for i in 0..<doc.nodes.length() {
    if paths[i] is None {
      paths[i] = Some([gltf_node_path_name(doc.nodes[i], i)])
    }
  }

  paths
}

///|
fn gltf_collect_node_parents(doc : ParsedGltfDocument) -> Array[Int?] {
  let parents : Array[Int?] = []
  for _ in doc.nodes {
    parents.push(None)
  }
  for parent_index, node in doc.nodes {
    for child in node.children {
      if child >= 0 && child < parents.length() {
        parents[child] = Some(parent_index)
      }
    }
  }
  parents
}

///|
fn gltf_collect_animation_root_indices(doc : ParsedGltfDocument) -> Array[Int] {
  let roots : Array[Int] = []
  let parents = gltf_collect_node_parents(doc)
  for animation in doc.animations {
    for channel in animation.channels {
      guard channel.target_node is Some(target_node) else { continue }
      let mut root = target_node
      while root >= 0 &&
            root < parents.length() &&
            parents[root] is Some(parent) {
        root = parent
      }
      let mut duplicate = false
      for existing in roots {
        if existing == root {
          duplicate = true
          break
        }
      }
      if !duplicate {
        roots.push(root)
      }
    }
  }
  roots
}

///|
fn path_dirname(path : String) -> String {
  if path.rev_find("/") is Some(split) {
    return path[0:split].to_string()
  }
  ""
}

///|
fn path_join(base_dir : String, relative : String) -> String {
  if relative.has_prefix("data:") ||
    relative.contains("://") ||
    relative.has_prefix("/") {
    return relative
  }
  let normalized = if relative.has_prefix("./") {
    relative[2:relative.length()].to_string()
  } else {
    relative
  }
  if base_dir == "" {
    normalized
  } else {
    "\{base_dir}/\{normalized}"
  }
}

///|
fn scene_try_resolve_request_buffers(
  asset_server : @asset.AssetServer,
  gltf_path : String,
  doc : ParsedGltfDocument,
  buffer_blobs : Array[@asset.Handle[@asset.Blob]?],
  buffer_bytes : Array[Bytes?],
) -> GltfResolveBuffersState {
  if buffer_bytes.length() != doc.buffers.length() {
    buffer_bytes.clear()
    for _ in doc.buffers {
      buffer_bytes.push(None)
    }
  }
  if buffer_blobs.length() != doc.buffers.length() {
    buffer_blobs.clear()
    for _ in doc.buffers {
      buffer_blobs.push(None)
    }
  }

  let base_dir = path_dirname(gltf_path)
  for i in 0..<doc.buffers.length() {
    if buffer_bytes[i] is Some(_) {
      continue
    }
    let buffer = doc.buffers[i]
    match buffer.uri {
      Some(uri) =>
        if uri.has_prefix("data:") {
          if data_uri_decode_bytes(uri) is Some(decoded) {
            buffer_bytes[i] = Some(decoded)
          } else {
            return GltfResolveBuffersState::Fatal
          }
        } else {
          let resolved_path = path_join(base_dir, uri)
          if buffer_blobs[i] is None {
            buffer_blobs[i] = Some(asset_server.load_bytes(resolved_path))
          }
          guard buffer_blobs[i] is Some(blob) else {
            return GltfResolveBuffersState::Pending
          }
          guard @asset.asset_blob_read_bytes(blob) is Some(bytes) else {
            return GltfResolveBuffersState::Pending
          }
          buffer_bytes[i] = Some(bytes)
        }
      None =>
        if buffer.byte_length == 0 {
          buffer_bytes[i] = Some(Bytes::new(0))
        } else {
          return GltfResolveBuffersState::Fatal
        }
    }
  }

  let resolved_buffers : Array[Bytes] = []
  for maybe_bytes in buffer_bytes {
    guard maybe_bytes is Some(bytes) else {
      return GltfResolveBuffersState::Pending
    }
    resolved_buffers.push(bytes)
  }
  GltfResolveBuffersState::Ready(resolved_buffers)
}

///|
fn gltf_texture_image_sampler(
  doc : ParsedGltfDocument,
  texture_index : Int,
) -> @image.ImageSampler {
  guard texture_index >= 0 && texture_index < doc.textures.length() else {
    return @image.ImageSampler::linear()
  }

  let mut nearest = false
  let mut repeat = true
  if doc.textures[texture_index].sampler is Some(sampler_index) &&
    sampler_index >= 0 &&
    sampler_index < doc.samplers.length() {
    let sampler = doc.samplers[sampler_index]
    nearest = sampler.nearest
    repeat = sampler.repeat
  }

  let descriptor = if nearest {
    @image.ImageSamplerDescriptor::nearest()
  } else {
    @image.ImageSamplerDescriptor::linear()
  }
  descriptor.set_address_mode(
    if repeat {
      @image.ImageAddressMode::Repeat
    } else {
      @image.ImageAddressMode::ClampToEdge
    },
  )
  |> ignore
  @image.ImageSampler::Descriptor(descriptor)
}

///|
fn gltf_buffer_view_bytes(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  buffer_view_index : Int,
) -> Bytes? {
  guard buffer_view_index >= 0 && buffer_view_index < doc.buffer_views.length() else {
    return None
  }
  let buffer_view = doc.buffer_views[buffer_view_index]
  guard buffer_view.buffer >= 0 && buffer_view.buffer < buffer_bytes.length() else {
    return None
  }
  guard buffer_view.byte_offset >= 0 && buffer_view.byte_length >= 0 else {
    return None
  }
  let start = buffer_view.byte_offset
  let end_ = start + buffer_view.byte_length
  guard end_ >= start else { return None }
  bytes_slice(buffer_bytes[buffer_view.buffer], start, end_)
}

///|
fn scene_cached_load_texture(
  asset_server : @asset.AssetServer,
  gltf_path : String,
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  texture_index : Int,
  cache : Array[@asset.Handle[@asset.Image]?],
) -> @asset.Handle[@asset.Image]? {
  guard texture_index >= 0 && texture_index < doc.textures.length() else {
    return None
  }
  let texture_def = doc.textures[texture_index]
  guard texture_def.source is Some(image_index) else { return None }
  guard image_index >= 0 && image_index < doc.images.length() else {
    return None
  }
  if cache[image_index] is Some(handle) {
    return Some(handle)
  }
  let image_def = doc.images[image_index]
  if image_def.mime_type is Some(_) {
    ()
  }
  let handle = match image_def.uri {
    Some(uri) =>
      if uri.has_prefix("data:") {
        guard data_uri_decode_bytes(uri) is Some(image_blob) else {
          return None
        }
        asset_server.load_texture_bytes(image_blob, false)
      } else {
        let resolved_path = path_join(path_dirname(gltf_path), uri)
        asset_server.load(resolved_path)
      }
    None => {
      guard image_def.buffer_view is Some(buffer_view_index) else {
        return None
      }
      guard gltf_buffer_view_bytes(doc, buffer_bytes, buffer_view_index)
        is Some(image_blob) else {
        return None
      }
      asset_server.load_texture_bytes(image_blob, false)
    }
  }
  @asset.asset_set_texture_sampler(
    handle,
    gltf_texture_image_sampler(doc, texture_index),
  )
  cache[image_index] = Some(handle)
  Some(handle)
}

///|
fn scene_build_material_component(
  asset_server : @asset.AssetServer,
  gltf_path : String,
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  material_index : Int,
  material_cache : Array[@pbr.MeshMaterial3d?],
  image_cache : Array[@asset.Handle[@asset.Image]?],
) -> @pbr.MeshMaterial3d? {
  guard material_index >= 0 && material_index < doc.materials.length() else {
    return None
  }
  if !@gltf.gltf_pbr_material_handler_enabled() {
    return None
  }

  if material_cache[material_index] is Some(component) {
    return Some(component)
  }

  let def = doc.materials[material_index]
  let mut material = @pbr.StandardMaterial::default()
  material = material.with_base_color(def.base_color)
  material = material.with_alpha_mode(def.alpha_mode)
  material = material.with_uv_transform(
    @transform.Affine2::from_translation(def.base_color_uv_offset).mul(
      @transform.Affine2::from_scale(def.base_color_uv_scale),
    ),
  )
  material = material.with_clearcoat(def.clearcoat)
  material = material.with_clearcoat_perceptual_roughness(
    def.clearcoat_roughness,
  )
  material = material.with_anisotropy_strength(def.anisotropy_strength)
  material = material.with_anisotropy_rotation(def.anisotropy_rotation)
  material = material.with_metallic(def.metallic)
  material = material.with_perceptual_roughness(def.roughness)
  material = material.with_emissive(def.emissive)
  material = material.with_unlit(def.unlit)

  if def.base_color_texture is Some(texture_index) {
    material = material.with_base_color_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.normal_texture is Some(texture_index) {
    material = material.with_normal_map_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.clearcoat_texture is Some(texture_index) {
    material = material.with_clearcoat_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.clearcoat_roughness_texture is Some(texture_index) {
    material = material.with_clearcoat_roughness_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.clearcoat_normal_texture is Some(texture_index) {
    material = material.with_clearcoat_normal_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.anisotropy_texture is Some(texture_index) {
    material = material.with_anisotropy_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.emissive_texture is Some(texture_index) {
    material = material.with_emissive_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.metallic_roughness_texture is Some(texture_index) {
    material = material.with_metallic_roughness_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }
  if def.occlusion_texture is Some(texture_index) {
    material = material.with_occlusion_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, buffer_bytes, texture_index, image_cache,
      ),
    )
  }

  let component = @pbr.MeshMaterial3d::new(@pbr.standard_material_add(material))
  material_cache[material_index] = Some(component)
  Some(component)
}

///|
fn gltf_lod_visibility_range_with_policy(
  policy : GltfLodVisibilityPolicy,
  lod_level : Int,
) -> @visibility.VisibilityRange? {
  if !policy.enabled {
    return None
  }
  let level = if lod_level < 0 { 0 } else { lod_level }
  let level_float = Float::from_double(level.to_double())
  let start_min = if level <= 0 {
    policy.first_start_margin_min
  } else {
    policy.first_end_margin_min + (level_float - 1.0F) * policy.step
  }
  let start_max = if level <= 0 {
    policy.first_start_margin_max
  } else {
    policy.first_end_margin_max + (level_float - 1.0F) * policy.step
  }
  let end_min = policy.first_end_margin_min + level_float * policy.step
  let end_max = policy.first_end_margin_max + level_float * policy.step
  Some(
    @visibility.VisibilityRange::new(
      start_min, start_max, end_min, end_max, false,
    ),
  )
}

///|
fn gltf_lod_visibility_range(lod_level : Int) -> @visibility.VisibilityRange? {
  gltf_lod_visibility_range_with_policy(
    scene_get_gltf_lod_visibility_policy(),
    lod_level,
  )
}

///|
fn gltf_select_scene_index(
  doc : ParsedGltfDocument,
  requested_scene_index : Int,
) -> Int {
  if doc.scenes.length() == 0 {
    return -1
  }
  if requested_scene_index >= 0 && requested_scene_index < doc.scenes.length() {
    return requested_scene_index
  }
  if doc.default_scene >= 0 && doc.default_scene < doc.scenes.length() {
    return doc.default_scene
  }
  0
}

///|
fn gltf_select_animation_index(
  doc : ParsedGltfDocument,
  requested_animation_index : Int,
) -> Int {
  if doc.animations.length() == 0 {
    return -1
  }
  if requested_animation_index >= 0 &&
    requested_animation_index < doc.animations.length() {
    return requested_animation_index
  }
  0
}

///|
fn scene_build_animation_clip_from_gltf(
  animation_index : Int,
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
) -> @animation.AnimationClip {
  let selected_animation_index = gltf_select_animation_index(
    doc, animation_index,
  )
  if selected_animation_index < 0 {
    return @animation.AnimationClip::new()
  }

  let animation = doc.animations[selected_animation_index]
  let node_paths = gltf_collect_node_name_paths(doc)
  let clip = @animation.AnimationClip::new()
  let mut duration = 0.0F

  for channel in animation.channels {
    guard channel.sampler is Some(sampler_index) else { continue }
    guard sampler_index >= 0 && sampler_index < animation.samplers.length() else {
      continue
    }
    let sampler = animation.samplers[sampler_index]
    guard sampler.input is Some(input_accessor) else { continue }
    guard sampler.output is Some(output_accessor) else { continue }
    guard gltf_read_accessor_timestamps(doc, buffer_bytes, input_accessor)
      is Some(timestamps) else {
      continue
    }
    if timestamps.length() == 0 {
      continue
    }

    let end_time = timestamps[timestamps.length() - 1]
    if end_time > duration {
      duration = end_time
    }

    guard channel.target_node is Some(target_node) else { continue }
    guard target_node >= 0 && target_node < doc.nodes.length() else { continue }
    guard node_paths[target_node] is Some(target_path) else { continue }
    let target_id = @animation.AnimationTargetId::from_names(target_path)

    match channel.target_path {
      "translation" => {
        guard gltf_read_accessor_vec3(doc, buffer_bytes, output_accessor)
          is Some(samples) else {
          continue
        }
        guard @animation.gltf_translation_keyframes_from_samples(
            timestamps,
            samples,
            sampler.interpolation,
          )
          is Some(keyframes) else {
          continue
        }
        clip.add_translation_curve(target_id, keyframes) |> ignore
      }
      "rotation" => {
        guard gltf_read_accessor_vec4(doc, buffer_bytes, output_accessor)
          is Some(samples) else {
          continue
        }
        guard @animation.gltf_rotation_keyframes_from_samples(
            timestamps,
            samples,
            sampler.interpolation,
          )
          is Some(keyframes) else {
          continue
        }
        clip.add_rotation_curve(target_id, keyframes) |> ignore
      }
      "scale" => {
        guard gltf_read_accessor_vec3(doc, buffer_bytes, output_accessor)
          is Some(samples) else {
          continue
        }
        guard @animation.gltf_translation_keyframes_from_samples(
            timestamps,
            samples,
            sampler.interpolation,
          )
          is Some(keyframes) else {
          continue
        }
        clip.add_scale_curve(target_id, keyframes) |> ignore
      }
      "weights" => {
        guard gltf_read_accessor_f32_components(
            doc, buffer_bytes, output_accessor,
          )
          is Some(decoded) else {
          continue
        }
        guard decoded.0 == 1 else { continue }
        guard @animation.gltf_weight_keyframes_from_flat_samples(
            timestamps,
            decoded.1,
            sampler.interpolation,
          )
          is Some(keyframes) else {
          continue
        }
        clip.add_weights_curve(target_id, keyframes) |> ignore
      }
      _ => continue
    }
  }

  clip.set_duration(duration) |> ignore
  clip
}

///|
fn scene_build_mesh_primitive_from_gltf(
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
  mesh_index : Int,
  primitive_index : Int,
) -> @mesh.Mesh? {
  guard mesh_index >= 0 && mesh_index < doc.meshes.length() else { return None }
  let mesh = doc.meshes[mesh_index]
  guard primitive_index >= 0 && primitive_index < mesh.primitives.length() else {
    return None
  }
  let primitive = mesh.primitives[primitive_index]
  guard primitive.position is Some(position_accessor) else { return None }
  guard gltf_read_accessor_vec3(doc, buffer_bytes, position_accessor)
    is Some(positions) else {
    return None
  }
  if positions.length() == 0 {
    return None
  }

  let mut uvs : Array[@math.Vec2] = []
  if primitive.uv0 is Some(uv_accessor) {
    if gltf_read_accessor_vec2(doc, buffer_bytes, uv_accessor) is Some(decoded) {
      uvs = decoded
    }
  }
  if uvs.length() != positions.length() {
    uvs.clear()
    for _ in positions {
      uvs.push(@math.Vec2::new(0.0F, 0.0F))
    }
  }

  let indices = match primitive.indices {
    Some(index_accessor) =>
      gltf_read_accessor_indices(doc, buffer_bytes, index_accessor)
    None => None
  }
  let mut geometry = @mesh.Mesh3dGeometry::new(positions, uvs, indices)
  if primitive.joint_indices is Some(joint_indices_accessor) &&
    primitive.joint_weights is Some(joint_weights_accessor) &&
    gltf_read_accessor_joint_indices(doc, buffer_bytes, joint_indices_accessor)
    is Some(joint_indices) &&
    gltf_read_accessor_vec4(doc, buffer_bytes, joint_weights_accessor)
    is Some(joint_weights) {
    geometry = geometry.with_joint_data(
      Some(joint_indices),
      Some(joint_weights),
    )
  }
  if primitive.morph_targets.length() > 0 {
    let morph_targets : Array[Array[@math.Vec3]] = []
    for morph_target_position in primitive.morph_targets {
      match morph_target_position {
        Some(accessor_index) =>
          if gltf_read_accessor_vec3(doc, buffer_bytes, accessor_index)
            is Some(values) {
            morph_targets.push(values)
          }
        None => ()
      }
    }
    if morph_targets.length() > 0 {
      let morph_target_names = if mesh.morph_target_names.length() ==
        morph_targets.length() {
        Some(mesh.morph_target_names)
      } else {
        None
      }
      geometry = geometry.with_morph_targets(
        Some(morph_targets),
        morph_target_names~,
      )
    }
  }
  for custom_attribute in primitive.custom_attributes {
    let (attribute_name, accessor_index) = custom_attribute
    if gltf_read_accessor_vec3(doc, buffer_bytes, accessor_index)
      is Some(values) {
      let mapped_name = match
        @gltf.gltf_resolve_custom_vertex_attribute_name(attribute_name) {
        Some(name) => name
        None => attribute_name
      }
      geometry = geometry.with_custom_attribute_vec3(mapped_name, values)
    }
  }
  guard geometry.validate() is None else { return None }
  Some(@mesh.Mesh::from_3d_geometry(geometry))
}

///|
fn scene_build_from_gltf(
  asset_server : @asset.AssetServer,
  request : PendingGltfSceneRequest,
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
) -> Scene {
  let selected_scene_index = gltf_select_scene_index(doc, request.scene_index)
  let nodes : Array[SceneNode3d] = []
  let node_paths = gltf_collect_node_name_paths(doc)
  let image_cache : Array[@asset.Handle[@asset.Image]?] = []
  for _ in doc.images {
    image_cache.push(None)
  }
  let material_cache : Array[@pbr.MeshMaterial3d?] = []
  for _ in doc.materials {
    material_cache.push(None)
  }
  let visited_nodes : Array[Bool] = []
  for _ in doc.nodes {
    visited_nodes.push(false)
  }

  let default_material_component = @pbr.MeshMaterial3d::new(
    @pbr.standard_material_add(@pbr.StandardMaterial::default()),
  )

  fn walk_node(
    node_index : Int,
    parent_scene_node_index : Int?,
    lod_level : Int,
  ) -> Unit {
    guard node_index >= 0 && node_index < doc.nodes.length() else { return }
    if visited_nodes[node_index] {
      return
    }
    visited_nodes[node_index] = true
    let node = doc.nodes[node_index]
    let effective_lod_level = if lod_level >= 0 {
      lod_level
    } else if node.lod_nodes.length() > 0 {
      0
    } else {
      -1
    }
    let visibility_range = if effective_lod_level >= 0 {
      gltf_lod_visibility_range(effective_lod_level)
    } else {
      None
    }
    let animation_target = match node_paths[node_index] {
      Some(path) => Some(@animation.AnimationTargetId::from_names(path))
      None => None
    }
    let scene_node_index = nodes.length()
    nodes.push(
      SceneNode3d::new_empty(
        node.transform,
        visibility_range,
        animation_target,
        parent_node_index=parent_scene_node_index,
        name=if node.name == "" {
          None
        } else {
          Some(@ecs.Name::new(node.name))
        },
        gltf_scene_index=Some(@gltf.GltfSceneIndex::new(selected_scene_index)),
        gltf_node_index=Some(@gltf.GltfNodeIndex::new(node_index)),
        gltf_skin_index=node.skin.map(@gltf.GltfSkinIndex::new),
      ),
    )

    if node.mesh is Some(mesh_index) &&
      mesh_index >= 0 &&
      mesh_index < doc.meshes.length() {
      let mesh = doc.meshes[mesh_index]
      let skin = match node.skin {
        Some(skin_index) =>
          if skin_index >= 0 && skin_index < doc.skins.length() {
            Some(doc.skins[skin_index])
          } else {
            None
          }
        None => None
      }
      let inverse_bindposes = match skin {
        Some(skin_def) =>
          match skin_def.inverse_bind_matrices {
            Some(accessor_index) =>
              gltf_read_accessor_mat4(doc, buffer_bytes, accessor_index)
            None => {
              let defaults : Array[@mesh.SkinningMat4] = []
              for _ in skin_def.joints {
                defaults.push(@mesh.SkinningMat4::identity())
              }
              Some(defaults)
            }
          }
        None => None
      }

      for primitive in mesh.primitives {
        guard scene_build_mesh_primitive_from_gltf(
            doc,
            buffer_bytes,
            mesh_index,
            primitive.primitive_index,
          )
          is Some(mesh_asset) else {
          continue
        }
        let material_component = match primitive.material {
          Some(material_index) =>
            match
              scene_build_material_component(
                asset_server,
                request.gltf_path,
                doc,
                buffer_bytes,
                material_index,
                material_cache,
                image_cache,
              ) {
              Some(component) => component
              None => default_material_component
            }
          None => default_material_component
        }
        let material_name = match primitive.material {
          Some(material_index) =>
            if material_index >= 0 &&
              material_index < doc.materials.length() &&
              doc.materials[material_index].name != "" {
              Some(
                @gltf.GltfMaterialName::new(doc.materials[material_index].name),
              )
            } else {
              None
            }
          None => None
        }
        let primitive_name = gltf_primitive_display_name(
          mesh,
          material_name.map(fn(name) { name.as_str() }),
        )
        let primitive_extras = primitive.extras.map(@gltf.GltfExtras::new)
        let mesh_extras = mesh.extras.map(@gltf.GltfMeshExtras::new)
        let material_extras = match primitive.material {
          Some(material_index) =>
            if material_index >= 0 && material_index < doc.materials.length() {
              doc.materials[material_index].extras.map(
                @gltf.GltfMaterialExtras::new,
              )
            } else {
              None
            }
          None => None
        }

        nodes.push(
          SceneNode3d::new(
            @pbr.Mesh3d::new(
              @pbr.mesh_assets_mut_or_abort().val.add(mesh_asset),
            ),
            material_component,
            @transform.Transform::identity(),
            visibility_range,
            None,
            parent_node_index=Some(scene_node_index),
            name=primitive_name,
            gltf_scene_index=Some(
              @gltf.GltfSceneIndex::new(selected_scene_index),
            ),
            gltf_node_index=Some(@gltf.GltfNodeIndex::new(node_index)),
            gltf_mesh_index=Some(@gltf.GltfMeshIndex::new(mesh_index)),
            gltf_primitive_index=Some(
              @gltf.GltfPrimitiveIndex::new(
                mesh_index,
                primitive.primitive_index,
              ),
            ),
            gltf_skin_index=node.skin.map(@gltf.GltfSkinIndex::new),
            gltf_material_name=material_name,
            gltf_extras=primitive_extras,
            gltf_mesh_extras=mesh_extras,
            gltf_material_extras=material_extras,
            skinned_joint_node_indices=skin.map(fn(value) { value.joints }),
            skinned_inverse_bindposes=inverse_bindposes,
            default_morph_weights=if mesh.weights.length() > 0 {
              Some(mesh.weights)
            } else {
              None
            },
          ),
        )
      }
    }

    let lod_base_level = if effective_lod_level >= 0 {
      effective_lod_level
    } else {
      0
    }
    for lod_index, lod_node_index in node.lod_nodes {
      walk_node(
        lod_node_index,
        parent_scene_node_index,
        lod_base_level + lod_index + 1,
      )
    }

    for child_index in node.children {
      walk_node(child_index, Some(scene_node_index), effective_lod_level)
    }
  }

  if selected_scene_index >= 0 {
    for root_node in doc.scenes[selected_scene_index].nodes {
      walk_node(root_node, None, -1)
    }
  }

  Scene::{
    nodes3d: nodes,
    gltf_scene_extras: doc.scenes[selected_scene_index].extras.map(
      @gltf.GltfSceneExtras::new,
    ),
    ready: true,
  }
}

///|
fn scene_try_resolve_scene_request(
  asset_server : @asset.AssetServer,
  request : PendingGltfSceneRequest,
) -> (PendingGltfSceneRequest, Scene?) {
  let updated = request

  if updated.doc is None {
    guard @asset.asset_blob_read_bytes(updated.gltf_blob)
      is Some(gltf_blob_bytes) else {
      return (updated, None)
    }
    guard gltf_parse_source(updated.gltf_path, gltf_blob_bytes) is Some(parsed) else {
      return (updated, Some(Scene::new([])))
    }
    updated.doc = Some(parsed.0)
    updated.buffer_bytes = parsed.1
    updated.buffer_blobs.clear()
    for _ in parsed.0.buffers {
      updated.buffer_blobs.push(None)
    }
  }

  guard updated.doc is Some(doc) else { return (updated, Some(Scene::new([]))) }
  match
    scene_try_resolve_request_buffers(
      asset_server,
      updated.gltf_path,
      doc,
      updated.buffer_blobs,
      updated.buffer_bytes,
    ) {
    GltfResolveBuffersState::Pending => (updated, None)
    GltfResolveBuffersState::Fatal => (updated, Some(Scene::new([])))
    GltfResolveBuffersState::Ready(resolved_buffers) =>
      (
        updated,
        Some(
          scene_build_from_gltf(asset_server, updated, doc, resolved_buffers),
        ),
      )
  }
}

///|
fn scene_try_resolve_animation_request(
  asset_server : @asset.AssetServer,
  request : PendingGltfAnimationRequest,
) -> (PendingGltfAnimationRequest, @animation.AnimationClip?) {
  let updated = request

  if updated.doc is None {
    guard @asset.asset_blob_read_bytes(updated.gltf_blob)
      is Some(gltf_blob_bytes) else {
      return (updated, None)
    }
    guard gltf_parse_source(updated.gltf_path, gltf_blob_bytes) is Some(parsed) else {
      return (updated, Some(@animation.AnimationClip::new()))
    }
    updated.doc = Some(parsed.0)
    updated.buffer_bytes = parsed.1
    updated.buffer_blobs.clear()
    for _ in parsed.0.buffers {
      updated.buffer_blobs.push(None)
    }
  }

  guard updated.doc is Some(doc) else {
    return (updated, Some(@animation.AnimationClip::new()))
  }

  match
    scene_try_resolve_request_buffers(
      asset_server,
      updated.gltf_path,
      doc,
      updated.buffer_blobs,
      updated.buffer_bytes,
    ) {
    GltfResolveBuffersState::Pending => (updated, None)
    GltfResolveBuffersState::Fatal =>
      (updated, Some(@animation.AnimationClip::new()))
    GltfResolveBuffersState::Ready(resolved_buffers) =>
      (
        updated,
        Some(
          scene_build_animation_clip_from_gltf(
            updated.animation_index,
            doc,
            resolved_buffers,
          ),
        ),
      )
  }
}

///|
fn scene_try_resolve_mesh_request(
  asset_server : @asset.AssetServer,
  request : PendingGltfMeshRequest,
) -> (PendingGltfMeshRequest, @mesh.Mesh?) {
  let updated = request

  if updated.doc is None {
    guard @asset.asset_blob_read_bytes(updated.gltf_blob)
      is Some(gltf_blob_bytes) else {
      return (updated, None)
    }
    guard gltf_parse_source(updated.gltf_path, gltf_blob_bytes) is Some(parsed) else {
      return (updated, None)
    }
    updated.doc = Some(parsed.0)
    updated.buffer_bytes = parsed.1
    updated.buffer_blobs.clear()
    for _ in parsed.0.buffers {
      updated.buffer_blobs.push(None)
    }
  }

  guard updated.doc is Some(doc) else { return (updated, None) }
  match
    scene_try_resolve_request_buffers(
      asset_server,
      updated.gltf_path,
      doc,
      updated.buffer_blobs,
      updated.buffer_bytes,
    ) {
    GltfResolveBuffersState::Pending => (updated, None)
    GltfResolveBuffersState::Fatal => (updated, None)
    GltfResolveBuffersState::Ready(resolved_buffers) =>
      (
        updated,
        scene_build_mesh_primitive_from_gltf(
          doc,
          resolved_buffers,
          updated.mesh_index,
          updated.primitive_index,
        ),
      )
  }
}

///|
fn scene_process_pending_scene_requests(
  asset_server : @asset.AssetServer,
) -> Unit {
  let remaining : Array[PendingGltfSceneRequest] = []
  let scene_assets = scene_assets_from_world_mut_or_abort(
    scene_current_world_or_abort(),
  )

  for request in pending_gltf_scene_requests.val {
    let (updated_request, resolved_scene) = scene_try_resolve_scene_request(
      asset_server, request,
    )

    if resolved_scene is Some(scene) {
      scene_assets.val.set(updated_request.scene_handle, scene) |> ignore
    } else {
      remaining.push(updated_request)
    }
  }

  pending_gltf_scene_requests.val = remaining
}

///|
fn scene_process_pending_animation_requests(
  asset_server : @asset.AssetServer,
) -> Unit {
  let remaining : Array[PendingGltfAnimationRequest] = []

  for request in pending_gltf_animation_requests.val {
    let (updated_request, resolved_clip) = scene_try_resolve_animation_request(
      asset_server, request,
    )

    if resolved_clip is Some(clip) {
      @animation.animation_clip_set(updated_request.clip_handle, clip) |> ignore
    } else {
      remaining.push(updated_request)
    }
  }

  pending_gltf_animation_requests.val = remaining
}

///|
fn scene_process_pending_mesh_requests(
  asset_server : @asset.AssetServer,
) -> Unit {
  let remaining : Array[PendingGltfMeshRequest] = []
  let mesh_assets = scene_mesh_assets_from_world_mut_or_abort(
    scene_current_world_or_abort(),
  )

  for request in pending_gltf_mesh_requests.val {
    let (updated_request, resolved_mesh) = scene_try_resolve_mesh_request(
      asset_server, request,
    )

    if resolved_mesh is Some(mesh) {
      mesh_assets.val.set(updated_request.mesh_handle, mesh) |> ignore
    } else {
      remaining.push(updated_request)
    }
  }

  pending_gltf_mesh_requests.val = remaining
}

///|
fn scene_process_pending_requests(asset_server : @asset.AssetServer) -> Unit {
  scene_process_pending_scene_requests(asset_server)
  scene_process_pending_animation_requests(asset_server)
  scene_process_pending_mesh_requests(asset_server)
}
