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
pub struct MeshVertexAttributeId {
  value : UInt64
} derive(Eq, Debug)

///|
pub fn MeshVertexAttributeId::new(value : UInt64) -> MeshVertexAttributeId {
  { value, }
}

///|
pub fn MeshVertexAttributeId::value(self : MeshVertexAttributeId) -> UInt64 {
  self.value
}

///|
pub(all) enum MeshVertexFormat {
  Float32
  Sint32
  Uint32
  Float32x2
  Sint32x2
  Uint32x2
  Float32x3
  Sint32x3
  Uint32x3
  Float32x4
  Sint32x4
  Uint32x4
  Uint16x4
} derive(Eq, Debug)

///|
pub struct MeshVertexAttribute {
  name : String
  id : MeshVertexAttributeId
  format : MeshVertexFormat
} derive(Debug)

///|
pub fn MeshVertexAttribute::new(
  name : String,
  id : UInt64,
  format : MeshVertexFormat,
) -> MeshVertexAttribute {
  { name, id: MeshVertexAttributeId::new(id), format }
}

///|
pub fn MeshVertexAttribute::name(self : MeshVertexAttribute) -> String {
  self.name
}

///|
pub fn MeshVertexAttribute::id(
  self : MeshVertexAttribute,
) -> MeshVertexAttributeId {
  self.id
}

///|
pub fn MeshVertexAttribute::format(
  self : MeshVertexAttribute,
) -> MeshVertexFormat {
  self.format
}

///|
pub fn MeshVertexAttribute::position() -> MeshVertexAttribute {
  MeshVertexAttribute::new("Vertex_Position", 0UL, MeshVertexFormat::Float32x3)
}

///|
pub fn MeshVertexAttribute::normal() -> MeshVertexAttribute {
  MeshVertexAttribute::new("Vertex_Normal", 1UL, MeshVertexFormat::Float32x3)
}

///|
pub fn MeshVertexAttribute::uv_0() -> MeshVertexAttribute {
  MeshVertexAttribute::new("Vertex_Uv", 2UL, MeshVertexFormat::Float32x2)
}

///|
pub fn MeshVertexAttribute::uv_1() -> MeshVertexAttribute {
  MeshVertexAttribute::new("Vertex_Uv_1", 3UL, MeshVertexFormat::Float32x2)
}

///|
pub fn MeshVertexAttribute::tangent() -> MeshVertexAttribute {
  MeshVertexAttribute::new("Vertex_Tangent", 4UL, MeshVertexFormat::Float32x4)
}

///|
pub fn MeshVertexAttribute::color() -> MeshVertexAttribute {
  MeshVertexAttribute::new("Vertex_Color", 5UL, MeshVertexFormat::Float32x4)
}

///|
pub fn MeshVertexAttribute::joint_weight() -> MeshVertexAttribute {
  MeshVertexAttribute::new(
    "Vertex_JointWeight",
    6UL,
    MeshVertexFormat::Float32x4,
  )
}

///|
pub fn MeshVertexAttribute::joint_index() -> MeshVertexAttribute {
  MeshVertexAttribute::new("Vertex_JointIndex", 7UL, MeshVertexFormat::Uint16x4)
}

///|
pub fn first_available_custom_mesh_attribute() -> UInt64 {
  8UL
}

///|
pub(all) enum VertexAttributeValues {
  Float32(Array[Float])
  Sint32(Array[Int])
  Uint32(Array[UInt])
  Float32x2(Array[@math.Vec2])
  Sint32x2(Array[@math.IVec2])
  Uint32x2(Array[@math.UVec2])
  Float32x3(Array[@math.Vec3])
  Sint32x3(Array[(Int, Int, Int)])
  Uint32x3(Array[(UInt, UInt, UInt)])
  Float32x4(Array[@math.Vec4])
  Sint32x4(Array[(Int, Int, Int, Int)])
  Uint32x4(Array[(UInt, UInt, UInt, UInt)])
  Uint16x4(Array[MeshJointIndices])
}

///|
pub fn VertexAttributeValues::format(
  self : VertexAttributeValues,
) -> MeshVertexFormat {
  match self {
    Float32(_) => MeshVertexFormat::Float32
    Sint32(_) => MeshVertexFormat::Sint32
    Uint32(_) => MeshVertexFormat::Uint32
    Float32x2(_) => MeshVertexFormat::Float32x2
    Sint32x2(_) => MeshVertexFormat::Sint32x2
    Uint32x2(_) => MeshVertexFormat::Uint32x2
    Float32x3(_) => MeshVertexFormat::Float32x3
    Sint32x3(_) => MeshVertexFormat::Sint32x3
    Uint32x3(_) => MeshVertexFormat::Uint32x3
    Float32x4(_) => MeshVertexFormat::Float32x4
    Sint32x4(_) => MeshVertexFormat::Sint32x4
    Uint32x4(_) => MeshVertexFormat::Uint32x4
    Uint16x4(_) => MeshVertexFormat::Uint16x4
  }
}

///|
pub fn VertexAttributeValues::len(self : VertexAttributeValues) -> Int {
  match self {
    Float32(values) => values.length()
    Sint32(values) => values.length()
    Uint32(values) => values.length()
    Float32x2(values) => values.length()
    Sint32x2(values) => values.length()
    Uint32x2(values) => values.length()
    Float32x3(values) => values.length()
    Sint32x3(values) => values.length()
    Uint32x3(values) => values.length()
    Float32x4(values) => values.length()
    Sint32x4(values) => values.length()
    Uint32x4(values) => values.length()
    Uint16x4(values) => values.length()
  }
}

///|
pub fn VertexAttributeValues::is_empty(self : VertexAttributeValues) -> Bool {
  self.len() == 0
}

///|
pub fn VertexAttributeValues::as_float32x2(
  self : VertexAttributeValues,
) -> Array[@math.Vec2]? {
  match self {
    Float32x2(values) => Some(values)
    _ => None
  }
}

///|
pub fn VertexAttributeValues::as_float32x3(
  self : VertexAttributeValues,
) -> Array[@math.Vec3]? {
  match self {
    Float32x3(values) => Some(values)
    _ => None
  }
}

///|
pub fn VertexAttributeValues::as_float32x4(
  self : VertexAttributeValues,
) -> Array[@math.Vec4]? {
  match self {
    Float32x4(values) => Some(values)
    _ => None
  }
}

///|
pub fn VertexAttributeValues::as_uint16x4(
  self : VertexAttributeValues,
) -> Array[MeshJointIndices]? {
  match self {
    Uint16x4(values) => Some(values)
    _ => None
  }
}

///|
pub struct MeshAttributeData {
  attribute : MeshVertexAttribute
  values : VertexAttributeValues
}

///|
pub fn MeshAttributeData::new(
  attribute : MeshVertexAttribute,
  values : VertexAttributeValues,
) -> MeshAttributeData {
  { attribute, values }
}

///|
pub fn MeshAttributeData::attribute(
  self : MeshAttributeData,
) -> MeshVertexAttribute {
  self.attribute
}

///|
pub fn MeshAttributeData::values(
  self : MeshAttributeData,
) -> VertexAttributeValues {
  self.values
}

///|
pub(all) enum MeshVertexStepMode {
  Vertex
  Instance
} derive(Eq, Debug)

///|
pub struct VertexAttribute {
  offset : Int
  format : MeshVertexFormat
  shader_location : Int
} derive(Debug)

///|
pub fn VertexAttribute::new(
  offset~ : Int,
  format~ : MeshVertexFormat,
  shader_location~ : Int,
) -> VertexAttribute {
  VertexAttribute::{ offset, format, shader_location }
}

///|
pub struct VertexBufferLayout {
  array_stride : Int
  step_mode : MeshVertexStepMode
  attributes : Array[VertexAttribute]
} derive(Debug)

///|
pub fn VertexBufferLayout::new(
  array_stride~ : Int,
  step_mode~ : MeshVertexStepMode,
  attributes~ : Array[VertexAttribute],
) -> VertexBufferLayout {
  VertexBufferLayout::{ array_stride, step_mode, attributes }
}

///|
pub fn VertexBufferLayout::from_vertex_formats(
  step_mode : MeshVertexStepMode,
  formats : Array[MeshVertexFormat],
) -> VertexBufferLayout {
  let attributes : Array[VertexAttribute] = []
  let mut offset = 0
  for index in 0..<formats.length() {
    let format = formats[index]
    attributes.push(
      VertexAttribute::new(offset~, format~, shader_location=index),
    )
    offset = offset + format.size()
  }
  VertexBufferLayout::new(array_stride=offset, step_mode~, attributes~)
}

///|
pub fn VertexBufferLayout::offset_locations_by(
  self : VertexBufferLayout,
  location : Int,
) -> VertexBufferLayout {
  let attributes : Array[VertexAttribute] = []
  for attribute in self.attributes {
    attributes.push(VertexAttribute::{
      ..attribute,
      shader_location: attribute.shader_location + location,
    })
  }
  VertexBufferLayout::{ ..self, attributes, }
}

///|
pub struct VertexAttributeDescriptor {
  shader_location : Int
  id : MeshVertexAttributeId
  name : String
}

///|
pub fn VertexAttributeDescriptor::new(
  shader_location~ : Int,
  id~ : MeshVertexAttributeId,
  name~ : String,
) -> VertexAttributeDescriptor {
  VertexAttributeDescriptor::{ shader_location, id, name }
}

///|
pub struct MissingVertexAttributeError {
  id : MeshVertexAttributeId
  name : String
  pipeline_type : String?
}

///|
pub fn MissingVertexAttributeError::new(
  id~ : MeshVertexAttributeId,
  name~ : String,
  pipeline_type? : String? = None,
) -> MissingVertexAttributeError {
  MissingVertexAttributeError::{ id, name, pipeline_type }
}

///|
pub fn MissingVertexAttributeError::id(
  self : MissingVertexAttributeError,
) -> MeshVertexAttributeId {
  self.id
}

///|
pub fn MissingVertexAttributeError::name(
  self : MissingVertexAttributeError,
) -> String {
  self.name
}

///|
pub fn MissingVertexAttributeError::pipeline_type(
  self : MissingVertexAttributeError,
) -> String? {
  self.pipeline_type
}

///|
pub fn MissingVertexAttributeError::with_pipeline_type(
  self : MissingVertexAttributeError,
  pipeline_type : String?,
) -> MissingVertexAttributeError {
  MissingVertexAttributeError::{ ..self, pipeline_type, }
}

///|
pub struct MeshVertexBufferLayout {
  attribute_ids : Array[MeshVertexAttributeId]
  layout : VertexBufferLayout
} derive(Debug)

///|
pub fn MeshVertexBufferLayout::new(
  attribute_ids~ : Array[MeshVertexAttributeId],
  layout~ : VertexBufferLayout,
) -> MeshVertexBufferLayout {
  MeshVertexBufferLayout::{ attribute_ids, layout }
}

///|
pub fn MeshVertexBufferLayout::contains(
  self : MeshVertexBufferLayout,
  attribute_id : MeshVertexAttributeId,
) -> Bool {
  for id in self.attribute_ids {
    if mesh_vertex_attribute_id_eq(id, attribute_id) {
      return true
    }
  }
  false
}

///|
pub fn MeshVertexBufferLayout::attribute_ids(
  self : MeshVertexBufferLayout,
) -> Array[MeshVertexAttributeId] {
  self.attribute_ids
}

///|
pub fn MeshVertexBufferLayout::layout(
  self : MeshVertexBufferLayout,
) -> VertexBufferLayout {
  self.layout
}

///|
fn mesh_vertex_buffer_attribute_index(
  ids : Array[MeshVertexAttributeId],
  id : MeshVertexAttributeId,
) -> Int? {
  for index in 0..<ids.length() {
    if mesh_vertex_attribute_id_eq(ids[index], id) {
      return Some(index)
    }
  }
  None
}

///|
pub fn MeshVertexBufferLayout::get_layout(
  self : MeshVertexBufferLayout,
  attribute_descriptors : Array[VertexAttributeDescriptor],
) -> Result[VertexBufferLayout, MissingVertexAttributeError] {
  let attributes : Array[VertexAttribute] = []
  for descriptor in attribute_descriptors {
    match
      mesh_vertex_buffer_attribute_index(self.attribute_ids, descriptor.id) {
      Some(index) => {
        let source = self.layout.attributes[index]
        attributes.push(VertexAttribute::{
          format: source.format,
          offset: source.offset,
          shader_location: descriptor.shader_location,
        })
      }
      None =>
        return Err(MissingVertexAttributeError::{
          id: descriptor.id,
          name: descriptor.name,
          pipeline_type: None,
        })
    }
  }
  Ok(VertexBufferLayout::{
    array_stride: self.layout.array_stride,
    step_mode: self.layout.step_mode,
    attributes,
  })
}

///|
pub struct MeshVertexBufferLayoutRef {
  index : Int
  layout : MeshVertexBufferLayout
}

///|
pub fn MeshVertexBufferLayoutRef::layout(
  self : MeshVertexBufferLayoutRef,
) -> MeshVertexBufferLayout {
  self.layout
}

///|
pub fn MeshVertexBufferLayoutRef::index(
  self : MeshVertexBufferLayoutRef,
) -> Int {
  self.index
}

///|
pub fn MeshVertexBufferLayoutRef::equal(
  self : MeshVertexBufferLayoutRef,
  other : MeshVertexBufferLayoutRef,
) -> Bool {
  self.index == other.index && self.layout.equal(other.layout)
}

///|
pub struct MeshVertexBufferLayouts {
  layouts : Array[MeshVertexBufferLayout]
}

///|
pub fn MeshVertexBufferLayouts::default() -> MeshVertexBufferLayouts {
  MeshVertexBufferLayouts::{ layouts: [] }
}

///|
pub fn MeshVertexBufferLayouts::len(self : MeshVertexBufferLayouts) -> Int {
  self.layouts.length()
}

///|
fn mesh_vertex_attribute_id_array_eq(
  left : Array[MeshVertexAttributeId],
  right : Array[MeshVertexAttributeId],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for index in 0..<left.length() {
    if !mesh_vertex_attribute_id_eq(left[index], right[index]) {
      return false
    }
  }
  true
}

///|
pub fn VertexAttribute::equal(
  self : VertexAttribute,
  other : VertexAttribute,
) -> Bool {
  self.offset == other.offset &&
  self.format == other.format &&
  self.shader_location == other.shader_location
}

///|
pub fn VertexBufferLayout::equal(
  self : VertexBufferLayout,
  other : VertexBufferLayout,
) -> Bool {
  if self.array_stride != other.array_stride ||
    self.step_mode != other.step_mode ||
    self.attributes.length() != other.attributes.length() {
    return false
  }
  for index in 0..<self.attributes.length() {
    if !self.attributes[index].equal(other.attributes[index]) {
      return false
    }
  }
  true
}

///|
pub fn MeshVertexBufferLayout::equal(
  self : MeshVertexBufferLayout,
  other : MeshVertexBufferLayout,
) -> Bool {
  mesh_vertex_attribute_id_array_eq(self.attribute_ids, other.attribute_ids) &&
  self.layout.equal(other.layout)
}

///|
pub fn MeshVertexBufferLayouts::insert(
  self : MeshVertexBufferLayouts,
  layout : MeshVertexBufferLayout,
) -> MeshVertexBufferLayoutRef {
  for index in 0..<self.layouts.length() {
    if self.layouts[index].equal(layout) {
      return MeshVertexBufferLayoutRef::{ index, layout: self.layouts[index] }
    }
  }
  self.layouts.push(layout)
  MeshVertexBufferLayoutRef::{ index: self.layouts.length() - 1, layout }
}

///|
fn mesh_vertex_attribute_id_eq(
  left : MeshVertexAttributeId,
  right : MeshVertexAttributeId,
) -> Bool {
  left.value() == right.value()
}

///|
fn mesh3d_attribute_values_for_standard_id(
  geometry : Mesh3dGeometry,
  id : MeshVertexAttributeId,
) -> VertexAttributeValues? {
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::position().id()) {
    return Some(VertexAttributeValues::Float32x3(geometry.positions))
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::normal().id()) {
    return match geometry.normals {
      Some(values) => Some(VertexAttributeValues::Float32x3(values))
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::uv_0().id()) {
    return match geometry.uvs {
      Some(values) => Some(VertexAttributeValues::Float32x2(values))
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::tangent().id()) {
    return match geometry.tangents {
      Some(values) => Some(VertexAttributeValues::Float32x4(values))
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::color().id()) {
    return match geometry.colors {
      Some(values) => Some(VertexAttributeValues::Float32x4(values))
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_weight().id()) {
    return match geometry.joint_weights {
      Some(values) => Some(VertexAttributeValues::Float32x4(values))
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_index().id()) {
    return match geometry.joint_indices {
      Some(values) => Some(VertexAttributeValues::Uint16x4(values))
      None => None
    }
  }
  None
}

///|
fn mesh3d_attribute_descriptor_for_standard_id(
  id : MeshVertexAttributeId,
) -> MeshVertexAttribute? {
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::position().id()) {
    return Some(MeshVertexAttribute::position())
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::normal().id()) {
    return Some(MeshVertexAttribute::normal())
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::uv_0().id()) {
    return Some(MeshVertexAttribute::uv_0())
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::uv_1().id()) {
    return Some(MeshVertexAttribute::uv_1())
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::tangent().id()) {
    return Some(MeshVertexAttribute::tangent())
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::color().id()) {
    return Some(MeshVertexAttribute::color())
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_weight().id()) {
    return Some(MeshVertexAttribute::joint_weight())
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_index().id()) {
    return Some(MeshVertexAttribute::joint_index())
  }
  None
}

///|
pub fn Mesh3dGeometry::attribute(
  self : Mesh3dGeometry,
  id : MeshVertexAttributeId,
) -> VertexAttributeValues? {
  if mesh3d_attribute_values_for_standard_id(self, id) is Some(values) {
    return Some(values)
  }
  for custom_attribute in self.custom_attributes_vec3 {
    if mesh_vertex_attribute_id_eq(custom_attribute.id(), id) {
      return Some(VertexAttributeValues::Float32x3(custom_attribute.values()))
    }
  }
  None
}

///|
pub fn Mesh3dGeometry::attribute_data(
  self : Mesh3dGeometry,
  id : MeshVertexAttributeId,
) -> MeshAttributeData? {
  if mesh3d_attribute_values_for_standard_id(self, id) is Some(values) {
    guard mesh3d_attribute_descriptor_for_standard_id(id) is Some(attribute) else {
      return None
    }
    return Some(MeshAttributeData::new(attribute, values))
  }
  for custom_attribute in self.custom_attributes_vec3 {
    if mesh_vertex_attribute_id_eq(custom_attribute.id(), id) {
      return Some(
        MeshAttributeData::new(
          custom_attribute.attribute(),
          VertexAttributeValues::Float32x3(custom_attribute.values()),
        ),
      )
    }
  }
  None
}

///|
pub fn Mesh3dGeometry::contains_attribute(
  self : Mesh3dGeometry,
  id : MeshVertexAttributeId,
) -> Bool {
  self.attribute(id) is Some(_)
}

///|
fn mesh3d_assign_positions(
  positions : Array[@math.Vec3],
  values : Array[@math.Vec3],
) -> Unit {
  positions.clear()
  for value in values {
    positions.push(value)
  }
}

///|
pub fn Mesh3dGeometry::insert_attribute(
  self : Mesh3dGeometry,
  attribute : MeshVertexAttribute,
  values : VertexAttributeValues,
) -> Bool {
  if values.format() != attribute.format() {
    return false
  }
  let id = attribute.id()
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::position().id()) {
    guard values is VertexAttributeValues::Float32x3(positions) else {
      return false
    }
    mesh3d_assign_positions(self.positions, positions)
    self.tangents = None
    return true
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::normal().id()) {
    guard values is VertexAttributeValues::Float32x3(normals) else {
      return false
    }
    self.normals = Some(normals)
    self.tangents = None
    return true
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::uv_0().id()) {
    guard values is VertexAttributeValues::Float32x2(uvs) else { return false }
    self.uvs = Some(uvs)
    self.tangents = None
    return true
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::tangent().id()) {
    guard values is VertexAttributeValues::Float32x4(tangents) else {
      return false
    }
    self.tangents = Some(tangents)
    return true
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::color().id()) {
    guard values is VertexAttributeValues::Float32x4(colors) else {
      return false
    }
    self.colors = Some(colors)
    return true
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_weight().id()) {
    guard values is VertexAttributeValues::Float32x4(weights) else {
      return false
    }
    self.joint_weights = Some(weights)
    return true
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_index().id()) {
    guard values is VertexAttributeValues::Uint16x4(indices) else {
      return false
    }
    self.joint_indices = Some(indices)
    return true
  }
  guard values is VertexAttributeValues::Float32x3(custom_values) else {
    return false
  }
  let next : Array[MeshCustomAttributeVec3] = []
  let mut replaced = false
  for custom_attribute in self.custom_attributes_vec3 {
    if mesh_vertex_attribute_id_eq(custom_attribute.id(), id) {
      next.push(
        MeshCustomAttributeVec3::new_with_attribute(attribute, custom_values),
      )
      replaced = true
    } else {
      next.push(custom_attribute)
    }
  }
  if !replaced {
    next.push(
      MeshCustomAttributeVec3::new_with_attribute(attribute, custom_values),
    )
  }
  self.custom_attributes_vec3 = next
  true
}

///|
pub fn Mesh3dGeometry::with_inserted_attribute(
  self : Mesh3dGeometry,
  attribute : MeshVertexAttribute,
  values : VertexAttributeValues,
) -> Mesh3dGeometry {
  ignore(self.insert_attribute(attribute, values))
  self
}

///|
pub fn Mesh3dGeometry::remove_attribute(
  self : Mesh3dGeometry,
  id : MeshVertexAttributeId,
) -> VertexAttributeValues? {
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::position().id()) {
    let removed = self.positions.copy()
    self.positions.clear()
    self.tangents = None
    return Some(VertexAttributeValues::Float32x3(removed))
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::normal().id()) {
    return match self.normals {
      Some(values) => {
        self.normals = None
        self.tangents = None
        Some(VertexAttributeValues::Float32x3(values))
      }
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::uv_0().id()) {
    return match self.uvs {
      Some(values) => {
        self.uvs = None
        self.tangents = None
        Some(VertexAttributeValues::Float32x2(values))
      }
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::tangent().id()) {
    return match self.tangents {
      Some(values) => {
        self.tangents = None
        Some(VertexAttributeValues::Float32x4(values))
      }
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::color().id()) {
    return match self.colors {
      Some(values) => {
        self.colors = None
        Some(VertexAttributeValues::Float32x4(values))
      }
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_weight().id()) {
    return match self.joint_weights {
      Some(values) => {
        self.joint_weights = None
        Some(VertexAttributeValues::Float32x4(values))
      }
      None => None
    }
  }
  if mesh_vertex_attribute_id_eq(id, MeshVertexAttribute::joint_index().id()) {
    return match self.joint_indices {
      Some(values) => {
        self.joint_indices = None
        Some(VertexAttributeValues::Uint16x4(values))
      }
      None => None
    }
  }
  let next : Array[MeshCustomAttributeVec3] = []
  let mut removed : VertexAttributeValues? = None
  for custom_attribute in self.custom_attributes_vec3 {
    if mesh_vertex_attribute_id_eq(custom_attribute.id(), id) {
      removed = Some(
        VertexAttributeValues::Float32x3(custom_attribute.values()),
      )
    } else {
      next.push(custom_attribute)
    }
  }
  self.custom_attributes_vec3 = next
  removed
}

///|
pub fn Mesh3dGeometry::with_removed_attribute(
  self : Mesh3dGeometry,
  id : MeshVertexAttributeId,
) -> Mesh3dGeometry {
  ignore(self.remove_attribute(id))
  self
}
