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
  position : Int?
  uv0 : Int?
  indices : Int?
  material : Int?
}

///|
priv struct GltfMeshDef {
  primitives : Array[GltfPrimitiveDef]
}

///|
priv struct GltfNodeDef {
  mesh : Int?
  children : Array[Int]
  transform : @math.Transform
}

///|
priv struct GltfSceneDef {
  nodes : Array[Int]
}

///|
priv struct GltfMaterialDef {
  base_color : @render2d.Color
  base_color_texture : Int?
  normal_texture : Int?
  emissive_texture : Int?
  metallic_roughness_texture : Int?
  occlusion_texture : Int?
  metallic : Float
  roughness : Float
  emissive : @render2d.Color
  alpha_mode : @render3d.AlphaMode3d
  unlit : Bool
}

///|
priv struct GltfTextureDef {
  source : Int?
}

///|
priv struct GltfImageDef {
  uri : String?
}

///|
priv struct ParsedGltfDocument {
  default_scene : Int
  buffers : Array[GltfBufferDef]
  buffer_views : Array[GltfBufferViewDef]
  accessors : Array[GltfAccessorDef]
  meshes : Array[GltfMeshDef]
  nodes : Array[GltfNodeDef]
  scenes : Array[GltfSceneDef]
  materials : Array[GltfMaterialDef]
  textures : Array[GltfTextureDef]
  images : Array[GltfImageDef]
}

///|
fn scene_split_gltf_asset_path(asset_path : String) -> (String, Int) {
  let marker = "#Scene"
  if asset_path.rev_find(marker) is Some(index) {
    let start = index + marker.length()
    if start <= asset_path.length() {
      let gltf_path = (try! asset_path[0:index]).to_string()
      let index_string = (try! asset_path[start:asset_path.length()]).to_string()
      let parsed_index = @strconv.parse_int(index_string[:], base=10) catch {
        _ => 0
      }
      return (gltf_path, if parsed_index < 0 { 0 } else { parsed_index })
    }
  }
  (asset_path, 0)
}

///|
fn scene_pending_remove_handle(handle : @asset.Handle[Scene]) -> Unit {
  let filtered : Array[PendingGltfSceneRequest] = []
  for req in pending_gltf_scene_requests.val {
    if req.scene_handle.id() != handle.id() {
      filtered.push(req)
    }
  }
  pending_gltf_scene_requests.val = filtered
}

///|
fn scene_queue_gltf_request(
  asset_server : @asset.AssetServer,
  scene_handle : @asset.Handle[Scene],
  scene_asset_path : String,
) -> Unit {
  scene_pending_remove_handle(scene_handle)
  let (gltf_path, scene_index) = scene_split_gltf_asset_path(scene_asset_path)
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
fn gltf_parse_quat(value : Json, default_value : @math.Quat) -> @math.Quat {
  guard json_array(value) is Some(values) else { return default_value }
  guard json_array_float(values, 0) is Some(x) else { return default_value }
  guard json_array_float(values, 1) is Some(y) else { return default_value }
  guard json_array_float(values, 2) is Some(z) else { return default_value }
  guard json_array_float(values, 3) is Some(w) else { return default_value }
  @math.Quat::new(x, y, z, w).normalize()
}

///|
fn gltf_parse_color(
  value : Json,
  default_value : @render2d.Color,
) -> @render2d.Color {
  guard json_array(value) is Some(values) else { return default_value }
  guard json_array_float(values, 0) is Some(r) else { return default_value }
  guard json_array_float(values, 1) is Some(g) else { return default_value }
  guard json_array_float(values, 2) is Some(b) else { return default_value }
  let a = match json_array_float(values, 3) {
    Some(alpha) => alpha
    None => default_value.a
  }
  @render2d.Color::new(r, g, b, a)
}

///|
fn gltf_parse_emissive(
  value : Json,
  default_value : @render2d.Color,
) -> @render2d.Color {
  guard json_array(value) is Some(values) else { return default_value }
  guard json_array_float(values, 0) is Some(r) else { return default_value }
  guard json_array_float(values, 1) is Some(g) else { return default_value }
  guard json_array_float(values, 2) is Some(b) else { return default_value }
  @render2d.Color::new(r, g, b, 1.0F)
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
fn gltf_parse_transform_from_matrix(values : Array[Json]) -> @math.Transform? {
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
    @math.Transform::new(
      translation,
      quat_from_basis(safe_x, safe_y, safe_z),
      @math.Vec3::new(sx, sy, sz),
    ),
  )
}

///|
fn gltf_parse_node_transform(obj : Map[String, Json]) -> @math.Transform {
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
  @math.Transform::new(translation, rotation, scale)
}

///|
fn gltf_parse_texture_index(obj : Map[String, Json], key : String) -> Int? {
  guard json_get_object(obj, key) is Some(texture_info) else { return None }
  json_get_int(texture_info, "index")
}

///|
fn gltf_parse_material_alpha_mode(
  obj : Map[String, Json],
) -> @render3d.AlphaMode3d {
  guard json_get_string(obj, "alphaMode") is Some(alpha_mode) else {
    return @render3d.AlphaMode3d::Opaque
  }
  match alpha_mode {
    "BLEND" => @render3d.AlphaMode3d::Blend
    "MASK" => {
      let cutoff = match json_get_float(obj, "alphaCutoff") {
        Some(value) => value
        None => 0.5F
      }
      @render3d.AlphaMode3d::Mask(cutoff)
    }
    _ => @render3d.AlphaMode3d::Opaque
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
        if json_get_array(obj, "primitives") is Some(primitive_entries) {
          for primitive_entry in primitive_entries {
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
              primitives.push({
                position,
                uv0,
                indices: json_get_int(primitive_obj, "indices"),
                material: json_get_int(primitive_obj, "material"),
              })
            } else {
              primitives.push({
                position: None,
                uv0: None,
                indices: None,
                material: None,
              })
            }
          }
        }
        meshes.push({ primitives, })
      } else {
        meshes.push({ primitives: [] })
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
          mesh: json_get_int(obj, "mesh"),
          children,
          transform: gltf_parse_node_transform(obj),
        })
      } else {
        nodes.push({
          mesh: None,
          children: [],
          transform: @math.Transform::identity(),
        })
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
        scenes.push({ nodes: node_indices })
      } else {
        scenes.push({ nodes: [] })
      }
    }
  }

  let materials : Array[GltfMaterialDef] = []
  if json_get_array(root, "materials") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        let mut base_color = @render2d.Color::white()
        let mut metallic = 1.0F
        let mut roughness = 1.0F
        let mut base_color_texture : Int? = None
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
          base_color_texture = gltf_parse_texture_index(pbr, "baseColorTexture")
          metallic_roughness_texture = gltf_parse_texture_index(
            pbr, "metallicRoughnessTexture",
          )
        }

        let emissive = if obj.get("emissiveFactor") is Some(value) {
          gltf_parse_emissive(
            value,
            @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
          )
        } else {
          @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F)
        }

        materials.push({
          base_color,
          base_color_texture,
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
          base_color: @render2d.Color::white(),
          base_color_texture: None,
          normal_texture: None,
          emissive_texture: None,
          metallic_roughness_texture: None,
          occlusion_texture: None,
          metallic: 1.0F,
          roughness: 1.0F,
          emissive: @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
          alpha_mode: @render3d.AlphaMode3d::Opaque,
          unlit: false,
        })
      }
    }
  }

  let textures : Array[GltfTextureDef] = []
  if json_get_array(root, "textures") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        textures.push({ source: json_get_int(obj, "source") })
      } else {
        textures.push({ source: None })
      }
    }
  }

  let images : Array[GltfImageDef] = []
  if json_get_array(root, "images") is Some(entries) {
    for entry in entries {
      if json_object(entry) is Some(obj) {
        images.push({ uri: json_get_string(obj, "uri") })
      } else {
        images.push({ uri: None })
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
    scenes,
    materials,
    textures,
    images,
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
  let head = (try! uri[0:split]).to_string()
  let payload = (try! uri[split + 1:uri.length()]).to_string()
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
fn path_dirname(path : String) -> String {
  if path.rev_find("/") is Some(split) {
    return (try! path[0:split]).to_string()
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
    (try! relative[2:relative.length()]).to_string()
  } else {
    relative
  }
  if base_dir == "" {
    normalized
  } else {
    base_dir + "/" + normalized
  }
}

///|
fn scene_cached_load_texture(
  asset_server : @asset.AssetServer,
  gltf_path : String,
  doc : ParsedGltfDocument,
  texture_index : Int,
  cache : Array[(String, @asset.Handle[@asset.Image])],
) -> @asset.Handle[@asset.Image]? {
  guard texture_index >= 0 && texture_index < doc.textures.length() else {
    return None
  }
  let texture_def = doc.textures[texture_index]
  guard texture_def.source is Some(image_index) else { return None }
  guard image_index >= 0 && image_index < doc.images.length() else {
    return None
  }
  let image_def = doc.images[image_index]
  guard image_def.uri is Some(uri) else { return None }
  if uri.has_prefix("data:") {
    return None
  }

  let resolved_path = path_join(path_dirname(gltf_path), uri)
  for entry in cache {
    if entry.0 == resolved_path {
      return Some(entry.1)
    }
  }

  let handle = asset_server.load(resolved_path)
  cache.push((resolved_path, handle))
  Some(handle)
}

///|
fn scene_build_material_component(
  asset_server : @asset.AssetServer,
  gltf_path : String,
  doc : ParsedGltfDocument,
  material_index : Int,
  material_cache : Array[@render3d.MeshMaterial3d?],
  image_cache : Array[(String, @asset.Handle[@asset.Image])],
) -> @render3d.MeshMaterial3d? {
  guard material_index >= 0 && material_index < doc.materials.length() else {
    return None
  }

  if material_cache[material_index] is Some(component) {
    return Some(component)
  }

  let def = doc.materials[material_index]
  let mut material = @render3d.StandardMaterial::default()
  material = material.with_base_color(def.base_color)
  material = material.with_alpha_mode(def.alpha_mode)
  material = material.with_metallic(def.metallic)
  material = material.with_perceptual_roughness(def.roughness)
  material = material.with_emissive(def.emissive)
  material = material.with_unlit(def.unlit)

  if def.base_color_texture is Some(texture_index) {
    material = material.with_base_color_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, texture_index, image_cache,
      ),
    )
  }
  if def.normal_texture is Some(texture_index) {
    material = material.with_normal_map_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, texture_index, image_cache,
      ),
    )
  }
  if def.emissive_texture is Some(texture_index) {
    material = material.with_emissive_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, texture_index, image_cache,
      ),
    )
  }
  if def.metallic_roughness_texture is Some(texture_index) {
    material = material.with_metallic_roughness_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, texture_index, image_cache,
      ),
    )
  }
  if def.occlusion_texture is Some(texture_index) {
    material = material.with_occlusion_texture(
      scene_cached_load_texture(
        asset_server, gltf_path, doc, texture_index, image_cache,
      ),
    )
  }

  let component = @render3d.MeshMaterial3d::new(
    @render3d.standard_material_add(material),
  )
  material_cache[material_index] = Some(component)
  Some(component)
}

///|
fn quat_rotate_vec3(q : @math.Quat, value : @math.Vec3) -> @math.Vec3 {
  let axis = @math.Vec3::new(q.x, q.y, q.z)
  let uv = axis.cross(value)
  let uuv = axis.cross(uv)
  value.add(uv.mul_scalar(2.0F * q.w)).add(uuv.mul_scalar(2.0F))
}

///|
fn transform_compose(
  parent : @math.Transform,
  local_transform : @math.Transform,
) -> @math.Transform {
  let scaled_translation = local_transform.translation.mul(parent.scale)
  let world_translation = parent.translation.add(
    quat_rotate_vec3(parent.rotation, scaled_translation),
  )
  @math.Transform::new(
    world_translation,
    parent.rotation.mul(local_transform.rotation).normalize(),
    parent.scale.mul(local_transform.scale),
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
fn scene_build_from_gltf(
  asset_server : @asset.AssetServer,
  request : PendingGltfSceneRequest,
  doc : ParsedGltfDocument,
  buffer_bytes : Array[Bytes],
) -> Scene {
  let nodes : Array[SceneNode3d] = []
  let image_cache : Array[(String, @asset.Handle[@asset.Image])] = []
  let material_cache : Array[@render3d.MeshMaterial3d?] = []
  for _ in doc.materials {
    material_cache.push(None)
  }

  let default_material_component = @render3d.MeshMaterial3d::new(
    @render3d.standard_material_add(@render3d.StandardMaterial::default()),
  )

  fn walk_node(node_index : Int, parent_transform : @math.Transform) -> Unit {
    guard node_index >= 0 && node_index < doc.nodes.length() else { return }
    let node = doc.nodes[node_index]
    let world_transform = transform_compose(parent_transform, node.transform)

    if node.mesh is Some(mesh_index) {
      if mesh_index >= 0 && mesh_index < doc.meshes.length() {
        let mesh = doc.meshes[mesh_index]
        for primitive in mesh.primitives {
          guard primitive.position is Some(position_accessor) else { continue }
          guard gltf_read_accessor_vec3(doc, buffer_bytes, position_accessor)
            is Some(positions) else {
            continue
          }
          if positions.length() == 0 {
            continue
          }

          let mut uvs : Array[@math.Vec2] = []
          if primitive.uv0 is Some(uv_accessor) {
            if gltf_read_accessor_vec2(doc, buffer_bytes, uv_accessor)
              is Some(decoded) {
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

          let geometry = @mesh.Mesh3dGeometry::new(positions, uvs, indices)
          if geometry.validate() is Some(_) {
            continue
          }

          let material_component = match primitive.material {
            Some(material_index) =>
              match
                scene_build_material_component(
                  asset_server,
                  request.gltf_path,
                  doc,
                  material_index,
                  material_cache,
                  image_cache,
                ) {
                Some(component) => component
                None => default_material_component
              }
            None => default_material_component
          }

          nodes.push(
            SceneNode3d::new(
              @render3d.Mesh3d::from_geometry(geometry),
              material_component,
              world_transform,
              None,
            ),
          )
        }
      }
    }

    for child_index in node.children {
      walk_node(child_index, world_transform)
    }
  }

  let selected_scene_index = gltf_select_scene_index(doc, request.scene_index)
  if selected_scene_index >= 0 {
    for root_node in doc.scenes[selected_scene_index].nodes {
      walk_node(root_node, @math.Transform::identity())
    }
  }

  Scene::new(nodes)
}

///|
fn scene_try_resolve_request(
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

  if updated.buffer_bytes.length() != doc.buffers.length() {
    updated.buffer_bytes.clear()
    for _ in doc.buffers {
      updated.buffer_bytes.push(None)
    }
  }
  if updated.buffer_blobs.length() != doc.buffers.length() {
    updated.buffer_blobs.clear()
    for _ in doc.buffers {
      updated.buffer_blobs.push(None)
    }
  }

  let base_dir = path_dirname(updated.gltf_path)
  for i in 0..<doc.buffers.length() {
    if updated.buffer_bytes[i] is Some(_) {
      continue
    }

    let buffer = doc.buffers[i]
    match buffer.uri {
      Some(uri) =>
        if uri.has_prefix("data:") {
          if data_uri_decode_bytes(uri) is Some(decoded) {
            updated.buffer_bytes[i] = Some(decoded)
          } else {
            return (updated, Some(Scene::new([])))
          }
        } else {
          let resolved_path = path_join(base_dir, uri)
          if updated.buffer_blobs[i] is None {
            updated.buffer_blobs[i] = Some(
              asset_server.load_bytes(resolved_path),
            )
          }
          guard updated.buffer_blobs[i] is Some(blob) else {
            return (updated, None)
          }
          guard @asset.asset_blob_read_bytes(blob) is Some(bytes) else {
            return (updated, None)
          }
          updated.buffer_bytes[i] = Some(bytes)
        }
      None =>
        if buffer.byte_length == 0 {
          updated.buffer_bytes[i] = Some(Bytes::new(0))
        } else {
          return (updated, Some(Scene::new([])))
        }
    }
  }

  let resolved_buffers : Array[Bytes] = []
  for maybe_bytes in updated.buffer_bytes {
    guard maybe_bytes is Some(bytes) else { return (updated, None) }
    resolved_buffers.push(bytes)
  }

  (
    updated,
    Some(scene_build_from_gltf(asset_server, updated, doc, resolved_buffers)),
  )
}

///|
fn scene_process_pending_requests(asset_server : @asset.AssetServer) -> Unit {
  let remaining : Array[PendingGltfSceneRequest] = []

  for request in pending_gltf_scene_requests.val {
    let maybe_current = scene_assets.val.get(request.scene_handle)
    if maybe_current is Some(current_scene) && current_scene.ready {
      continue
    }

    let (updated_request, resolved_scene) = scene_try_resolve_request(
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
