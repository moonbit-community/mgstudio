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
fn primitive2d_f32(value : Int) -> Float {
  Float::from_int(value)
}

///|
fn primitive2d_resolution(vertices : Int, default_resolution : Int) -> Int {
  if vertices < 3 {
    default_resolution
  } else {
    vertices
  }
}

///|
fn primitive2d_lerp(a : Float, b : Float, t : Float) -> Float {
  a + (b - a) * t
}

///|
fn primitive2d_vec2_from_angle(angle : Float) -> @math.Vec2 {
  @math.Vec2::new(@math.cos(angle), @math.sin(angle))
}

///|
fn primitive2d_circular_uv(
  angle : Float,
  uv_mode : @math.CircularMeshUvMode,
) -> @math.Vec2 {
  match uv_mode {
    Mask(uv_angle) => {
      let uv = primitive2d_vec2_from_angle(-(angle + uv_angle))
      uv.mul_scalar(0.5F).add(@math.Vec2::new(0.5F, 0.5F))
    }
  }
}

///|
fn primitive2d_geometry_with_normals(
  positions : Array[@math.Vec3],
  normals : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::new_empty(@mesh.Mesh3dPrimitiveTopology::TriangleList)
  .with_inserted_attribute(
    @mesh.MeshVertexAttribute::position(),
    @mesh.VertexAttributeValues::Float32x3(positions),
  )
  .with_inserted_attribute(
    @mesh.MeshVertexAttribute::normal(),
    @mesh.VertexAttributeValues::Float32x3(normals),
  )
  .with_inserted_attribute(
    @mesh.MeshVertexAttribute::uv_0(),
    @mesh.VertexAttributeValues::Float32x2(uvs),
  )
  .with_inserted_indices(indices)
}

///|
fn primitive2d_normal_z(count : Int, z : Float) -> Array[@math.Vec3] {
  let normals : Array[@math.Vec3] = []
  for _ in 0..<count {
    normals.push(@math.Vec3::new(0.0F, 0.0F, z))
  }
  normals
}

///|
pub(all) struct CircleMeshBuilder {
  circle : @math.Circle
  resolution : Int
}

///|
pub fn CircleMeshBuilder::CircleMeshBuilder() -> CircleMeshBuilder {
  { circle: @math.Circle::Circle(), resolution: 32 }
}

///|
pub fn CircleMeshBuilder::new(
  radius : Float,
  resolution : Int,
) -> CircleMeshBuilder {
  { circle: @math.Circle::new(radius), resolution }
}

///|
pub fn CircleMeshBuilder::from_circle(
  circle : @math.Circle,
) -> CircleMeshBuilder {
  { circle, resolution: 32 }
}

///|
pub fn CircleMeshBuilder::resolution(
  self : CircleMeshBuilder,
  resolution : Int,
) -> CircleMeshBuilder {
  { circle: self.circle, resolution }
}

///|
pub fn CircleMeshBuilder::build(
  self : CircleMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  circle_mesh(self.circle.radius, self.resolution)
}

///|
pub impl MeshBuilder for CircleMeshBuilder with fn build(self) {
  circle_mesh(self.circle.radius, self.resolution)
}

///|
pub impl Extrudable for CircleMeshBuilder with fn perimeter(self) {
  [
    Smooth(
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(0.0F, 1.0F),
      closed_range_indices(0, self.resolution, 0),
    ),
  ]
}

///|
pub impl Meshable for @math.Circle with fn mesh(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  circle_mesh(self.radius, resolution)
}

///|
pub impl ExtrudablePrimitive for @math.Circle with fn mesh_perimeter(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  [
    Smooth(
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(0.0F, 1.0F),
      closed_range_indices(0, resolution, 0),
    ),
  ]
}

///|
pub fn circle(radius : Float) -> @math.Circle {
  @math.Circle::new(radius)
}

///|
pub fn circle_mesh(radius : Float, segments : Int) -> @mesh.Mesh3dGeometry {
  let resolution = if segments < 3 { 3 } else { segments }
  ellipse_mesh_with_resolution(@math.Ellipse::new(radius, radius), resolution)
}

///|
pub fn circle_line_strip_mesh(
  radius : Float,
  segments : Int,
) -> @mesh.Mesh3dGeometry {
  let resolution = if segments < 3 { 3 } else { segments }
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let start_angle = @math.pi() / 2.0F
  let step = 2.0F * @math.pi() / primitive2d_f32(resolution)
  for i in 0..<resolution {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(@math.Vec3::new(cos * radius, sin * radius, 0.0F))
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
    indices.push(i)
    indices.push((i + 1) % resolution)
  }
  @mesh.Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    Some(indices),
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}

///|
pub fn rectangle(width : Float, height : Float) -> @math.Rectangle {
  @math.Rectangle::new(width, height)
}

///|
pub fn rectangle_mesh(width : Float, height : Float) -> @mesh.Mesh3dGeometry {
  rectangle_shape_mesh(@math.Rectangle::new(width, height))
}

///|
pub struct RectangleMeshBuilder {
  half_size : @math.Vec2
}

///|
pub fn RectangleMeshBuilder::RectangleMeshBuilder() -> RectangleMeshBuilder {
  { half_size: @math.Vec2::new(0.5F, 0.5F) }
}

///|
pub fn RectangleMeshBuilder::new(
  width : Float,
  height : Float,
) -> RectangleMeshBuilder {
  { half_size: @math.Vec2::new(width * 0.5F, height * 0.5F) }
}

///|
pub fn RectangleMeshBuilder::from_rectangle(
  rectangle : @math.Rectangle,
) -> RectangleMeshBuilder {
  { half_size: rectangle.half_size }
}

///|
pub fn RectangleMeshBuilder::build(
  self : RectangleMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  rectangle_shape_mesh(
    @math.Rectangle::from_size(self.half_size.mul_scalar(2.0F)),
  )
}

///|
pub impl MeshBuilder for RectangleMeshBuilder with fn build(self) {
  rectangle_shape_mesh(
    @math.Rectangle::from_size(self.half_size.mul_scalar(2.0F)),
  )
}

///|
pub impl Extrudable for RectangleMeshBuilder with fn perimeter(_self) {
  [Flat([0, 1, 2, 3, 0])]
}

///|
pub impl Meshable for @math.Rectangle with fn mesh(self) {
  rectangle_shape_mesh(self)
}

///|
pub impl ExtrudablePrimitive for @math.Rectangle with fn mesh_perimeter(_self) {
  [Flat([0, 1, 2, 3, 0])]
}

///|
fn rectangle_shape_mesh(shape : @math.Rectangle) -> @mesh.Mesh3dGeometry {
  let hw = shape.half_size.x
  let hh = shape.half_size.y
  primitive2d_geometry_with_normals(
    [
      @math.Vec3::new(hw, hh, 0.0F),
      @math.Vec3::new(-hw, hh, 0.0F),
      @math.Vec3::new(-hw, -hh, 0.0F),
      @math.Vec3::new(hw, -hh, 0.0F),
    ],
    primitive2d_normal_z(4, 1.0F),
    [
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ],
    Some([0, 1, 2, 0, 2, 3]),
  )
}

///|
pub(all) struct CircularSectorMeshBuilder {
  sector : @math.CircularSector
  resolution : Int
  uv_mode : @math.CircularMeshUvMode
}

///|
pub fn CircularSectorMeshBuilder::CircularSectorMeshBuilder() -> CircularSectorMeshBuilder {
  {
    sector: @math.CircularSector::CircularSector(),
    resolution: 32,
    uv_mode: Mask(0.0F),
  }
}

///|
pub fn CircularSectorMeshBuilder::new(
  sector : @math.CircularSector,
) -> CircularSectorMeshBuilder {
  { sector, resolution: 32, uv_mode: Mask(0.0F) }
}

///|
pub fn CircularSectorMeshBuilder::resolution(
  self : CircularSectorMeshBuilder,
  resolution : Int,
) -> CircularSectorMeshBuilder {
  { sector: self.sector, resolution, uv_mode: self.uv_mode }
}

///|
pub fn CircularSectorMeshBuilder::uv_mode(
  self : CircularSectorMeshBuilder,
  uv_mode : @math.CircularMeshUvMode,
) -> CircularSectorMeshBuilder {
  { sector: self.sector, resolution: self.resolution, uv_mode }
}

///|
pub fn CircularSectorMeshBuilder::build(
  self : CircularSectorMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  circular_sector_mesh(
    self.sector.with_vertices(self.resolution).with_uv_mode(self.uv_mode),
  )
}

///|
pub impl MeshBuilder for CircularSectorMeshBuilder with fn build(self) {
  circular_sector_mesh(
    self.sector.with_vertices(self.resolution).with_uv_mode(self.uv_mode),
  )
}

///|
pub impl Extrudable for CircularSectorMeshBuilder with fn perimeter(self) {
  circular_arc_perimeter(self.resolution, self.sector.half_angle)
}

///|
pub impl Meshable for @math.CircularSector with fn mesh(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  circular_sector_mesh(self.with_vertices(resolution))
}

///|
pub impl ExtrudablePrimitive for @math.CircularSector with fn mesh_perimeter(
  self,
) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  circular_arc_perimeter(resolution, self.half_angle)
}

///|
pub fn circular_sector_mesh(
  sector : @math.CircularSector,
) -> @mesh.Mesh3dGeometry {
  let resolution = primitive2d_resolution(sector.vertices, 32)
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  positions.push(@math.Vec3::zero())
  uvs.push(@math.Vec2::new(0.5F, 0.5F))

  let first_angle = @math.pi() / 2.0F - sector.half_angle
  let last_angle = @math.pi() / 2.0F + sector.half_angle
  let last_i = primitive2d_f32(resolution - 1)
  for i in 0..<resolution {
    let angle = primitive2d_lerp(
      first_angle,
      last_angle,
      primitive2d_f32(i) / last_i,
    )
    let vertex = primitive2d_vec2_from_angle(angle).mul_scalar(sector.radius)
    let uv = primitive2d_circular_uv(angle, sector.uv_mode)
    positions.push(@math.Vec3::new(vertex.x, vertex.y, 0.0F))
    uvs.push(uv)
  }

  for i in 1..<resolution {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }

  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(resolution + 1, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
pub(all) struct CircularSegmentMeshBuilder {
  segment : @math.CircularSegment
  resolution : Int
  uv_mode : @math.CircularMeshUvMode
}

///|
pub fn CircularSegmentMeshBuilder::CircularSegmentMeshBuilder() -> CircularSegmentMeshBuilder {
  {
    segment: @math.CircularSegment::CircularSegment(),
    resolution: 32,
    uv_mode: Mask(0.0F),
  }
}

///|
pub fn CircularSegmentMeshBuilder::new(
  segment : @math.CircularSegment,
) -> CircularSegmentMeshBuilder {
  { segment, resolution: 32, uv_mode: Mask(0.0F) }
}

///|
pub fn CircularSegmentMeshBuilder::resolution(
  self : CircularSegmentMeshBuilder,
  resolution : Int,
) -> CircularSegmentMeshBuilder {
  { segment: self.segment, resolution, uv_mode: self.uv_mode }
}

///|
pub fn CircularSegmentMeshBuilder::uv_mode(
  self : CircularSegmentMeshBuilder,
  uv_mode : @math.CircularMeshUvMode,
) -> CircularSegmentMeshBuilder {
  { segment: self.segment, resolution: self.resolution, uv_mode }
}

///|
pub fn CircularSegmentMeshBuilder::build(
  self : CircularSegmentMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  circular_segment_mesh(
    self.segment.with_vertices(self.resolution).with_uv_mode(self.uv_mode),
  )
}

///|
pub impl MeshBuilder for CircularSegmentMeshBuilder with fn build(self) {
  circular_segment_mesh(
    self.segment.with_vertices(self.resolution).with_uv_mode(self.uv_mode),
  )
}

///|
pub impl Extrudable for CircularSegmentMeshBuilder with fn perimeter(self) {
  circular_arc_perimeter(self.resolution, self.segment.half_angle)
}

///|
pub impl Meshable for @math.CircularSegment with fn mesh(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  circular_segment_mesh(self.with_vertices(resolution))
}

///|
pub impl ExtrudablePrimitive for @math.CircularSegment with fn mesh_perimeter(
  self,
) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  circular_arc_perimeter(resolution, self.half_angle)
}

///|
pub fn circular_segment_mesh(
  segment : @math.CircularSegment,
) -> @mesh.Mesh3dGeometry {
  let resolution = primitive2d_resolution(segment.vertices, 32)
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let apothem = segment.radius * @math.cos(segment.half_angle)

  positions.push(@math.Vec3::new(0.0F, apothem, 0.0F))
  let midpoint_scale = 0.5F * apothem / segment.radius
  let midpoint_uv = match segment.uv_mode {
    Mask(uv_angle) =>
      primitive2d_vec2_from_angle(-uv_angle - @math.pi() / 2.0F)
      .mul_scalar(midpoint_scale)
      .add(@math.Vec2::new(0.5F, 0.5F))
  }
  uvs.push(midpoint_uv)

  let first_angle = @math.pi() / 2.0F - segment.half_angle
  let last_angle = @math.pi() / 2.0F + segment.half_angle
  let last_i = primitive2d_f32(resolution - 1)
  for i in 0..<resolution {
    let angle = primitive2d_lerp(
      first_angle,
      last_angle,
      primitive2d_f32(i) / last_i,
    )
    let vertex = primitive2d_vec2_from_angle(angle).mul_scalar(segment.radius)
    let uv = primitive2d_circular_uv(angle, segment.uv_mode)
    positions.push(@math.Vec3::new(vertex.x, vertex.y, 0.0F))
    uvs.push(uv)
  }

  for i in 1..<resolution {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }

  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(resolution + 1, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
pub fn convex_polygon_mesh(
  polygon : @math.ConvexPolygon,
) -> @mesh.Mesh3dGeometry {
  let len = polygon.vertices.length()
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  if len == 0 {
    return primitive2d_geometry_with_normals([], [], [], Some([]))
  }
  let first = polygon.vertices[0]
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x
  let mut max_y = first.y
  for vertex in polygon.vertices {
    if vertex.x < min_x {
      min_x = vertex.x
    }
    if vertex.y < min_y {
      min_y = vertex.y
    }
    if vertex.x > max_x {
      max_x = vertex.x
    }
    if vertex.y > max_y {
      max_y = vertex.y
    }
  }
  let size_x = if max_x - min_x < 0.000001F { 0.000001F } else { max_x - min_x }
  let size_y = if max_y - min_y < 0.000001F { 0.000001F } else { max_y - min_y }
  for vertex in polygon.vertices {
    positions.push(@math.Vec3::new(vertex.x, vertex.y, 0.0F))
    uvs.push(
      @math.Vec2::new((vertex.x - min_x) / size_x, (vertex.y - min_y) / size_y),
    )
  }
  for i in 2..<len {
    indices.push(0)
    indices.push(i - 1)
    indices.push(i)
  }
  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(len, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
pub(all) struct ConvexPolygonMeshBuilder {
  vertices : Array[@math.Vec2]
}

///|
pub fn ConvexPolygonMeshBuilder::new(
  vertices : Array[@math.Vec2],
) -> ConvexPolygonMeshBuilder {
  { vertices, }
}

///|
pub fn ConvexPolygonMeshBuilder::from_polygon(
  polygon : @math.ConvexPolygon,
) -> ConvexPolygonMeshBuilder {
  { vertices: polygon.vertices }
}

///|
pub fn ConvexPolygonMeshBuilder::build(
  self : ConvexPolygonMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  convex_polygon_mesh(@math.ConvexPolygon::new(self.vertices))
}

///|
pub impl MeshBuilder for ConvexPolygonMeshBuilder with fn build(self) {
  convex_polygon_mesh(@math.ConvexPolygon::new(self.vertices))
}

///|
pub impl Extrudable for ConvexPolygonMeshBuilder with fn perimeter(self) {
  [Flat(closed_range_indices(0, self.vertices.length(), 0))]
}

///|
pub impl Meshable for @math.ConvexPolygon with fn mesh(self) {
  convex_polygon_mesh(self)
}

///|
pub impl ExtrudablePrimitive for @math.ConvexPolygon with fn mesh_perimeter(
  self,
) {
  [Flat(closed_range_indices(0, self.vertices.length(), 0))]
}

///|
pub(all) struct EllipseMeshBuilder {
  ellipse : @math.Ellipse
  resolution : Int
}

///|
pub fn EllipseMeshBuilder::EllipseMeshBuilder() -> EllipseMeshBuilder {
  { ellipse: @math.Ellipse::Ellipse(), resolution: 32 }
}

///|
pub fn EllipseMeshBuilder::new(
  half_width : Float,
  half_height : Float,
  resolution : Int,
) -> EllipseMeshBuilder {
  { ellipse: @math.Ellipse::new(half_width, half_height), resolution }
}

///|
pub fn EllipseMeshBuilder::from_ellipse(
  ellipse : @math.Ellipse,
) -> EllipseMeshBuilder {
  { ellipse, resolution: 32 }
}

///|
pub fn EllipseMeshBuilder::resolution(
  self : EllipseMeshBuilder,
  resolution : Int,
) -> EllipseMeshBuilder {
  { ellipse: self.ellipse, resolution }
}

///|
pub fn EllipseMeshBuilder::build(
  self : EllipseMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  ellipse_mesh_with_resolution(self.ellipse, self.resolution)
}

///|
pub impl MeshBuilder for EllipseMeshBuilder with fn build(self) {
  ellipse_mesh_with_resolution(self.ellipse, self.resolution)
}

///|
pub impl Extrudable for EllipseMeshBuilder with fn perimeter(self) {
  [
    Smooth(
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(0.0F, 1.0F),
      closed_range_indices(0, self.resolution, 0),
    ),
  ]
}

///|
pub impl Meshable for @math.Ellipse with fn mesh(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  ellipse_mesh(self.with_vertices(resolution))
}

///|
pub impl ExtrudablePrimitive for @math.Ellipse with fn mesh_perimeter(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  [
    Smooth(
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(0.0F, 1.0F),
      closed_range_indices(0, resolution, 0),
    ),
  ]
}

///|
pub fn ellipse_mesh(shape : @math.Ellipse) -> @mesh.Mesh3dGeometry {
  let resolution = primitive2d_resolution(shape.vertices, 32)
  ellipse_mesh_with_resolution(shape, resolution)
}

///|
fn ellipse_mesh_with_resolution(
  shape : @math.Ellipse,
  resolution : Int,
) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let start_angle = @math.pi() / 2.0F
  let step = 2.0F * @math.pi() / primitive2d_f32(resolution)
  for i in 0..<resolution {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * shape.half_size.x, sin * shape.half_size.y, 0.0F),
    )
    uvs.push(@math.Vec2::new(0.5F * (cos + 1.0F), 1.0F - 0.5F * (sin + 1.0F)))
  }
  for i in 1..<(resolution - 1) {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(resolution, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
pub fn segment2d_mesh(segment : @math.Segment2d) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::new_with_positions_and_topology(
    [
      @math.Vec3::new(segment.start.x, segment.start.y, 0.0F),
      @math.Vec3::new(segment.end.x, segment.end.y, 0.0F),
    ],
    Some([0, 1]),
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}

///|
pub(all) struct Segment2dMeshBuilder {
  segment : @math.Segment2d
}

///|
pub fn Segment2dMeshBuilder::new(
  segment : @math.Segment2d,
) -> Segment2dMeshBuilder {
  { segment, }
}

///|
pub fn Segment2dMeshBuilder::build(
  self : Segment2dMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  segment2d_mesh(self.segment)
}

///|
pub impl MeshBuilder for Segment2dMeshBuilder with fn build(self) {
  segment2d_mesh(self.segment)
}

///|
pub impl Meshable for @math.Segment2d with fn mesh(self) {
  segment2d_mesh(self)
}

///|
pub struct Polyline2dMeshBuilder {
  polyline : @math.Polyline2d
}

///|
pub fn Polyline2dMeshBuilder::Polyline2dMeshBuilder() -> Polyline2dMeshBuilder {
  { polyline: @math.Polyline2d::new([]) }
}

///|
pub fn Polyline2dMeshBuilder::new(
  polyline : @math.Polyline2d,
) -> Polyline2dMeshBuilder {
  { polyline, }
}

///|
pub fn Polyline2dMeshBuilder::build(
  self : Polyline2dMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  polyline2d_mesh(self.polyline)
}

///|
pub impl MeshBuilder for Polyline2dMeshBuilder with fn build(self) {
  polyline2d_mesh(self.polyline)
}

///|
pub impl Meshable for @math.Polyline2d with fn mesh(self) {
  polyline2d_mesh(self)
}

///|
pub fn polyline2d_mesh(polyline : @math.Polyline2d) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  let indices : Array[Int] = []
  for vertex in polyline.points {
    positions.push(@math.Vec3::new(vertex.x, vertex.y, 0.0F))
  }
  if polyline.points.length() >= 2 {
    for i in 0..<(polyline.points.length() - 1) {
      indices.push(i)
      indices.push(i + 1)
    }
  }
  @mesh.Mesh3dGeometry::new_with_positions_and_topology(
    positions,
    Some(indices),
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}

///|
pub fn annulus_mesh(shape : @math.Annulus) -> @mesh.Mesh3dGeometry {
  let resolution = primitive2d_resolution(shape.vertices, 32)
  let vertex_count = (resolution + 1) * 2
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let start_angle = @math.pi() / 2.0F
  let step = 2.0F * @math.pi() / primitive2d_f32(resolution)
  for i in 0..<=resolution {
    let theta = start_angle + primitive2d_f32(i % resolution) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * shape.inner_radius, sin * shape.inner_radius, 0.0F),
    )
    positions.push(
      @math.Vec3::new(cos * shape.outer_radius, sin * shape.outer_radius, 0.0F),
    )
    uvs.push(
      @math.Vec2::new(0.0F, primitive2d_f32(i) / primitive2d_f32(resolution)),
    )
    uvs.push(
      @math.Vec2::new(1.0F, primitive2d_f32(i) / primitive2d_f32(resolution)),
    )
  }
  for i in 0..<resolution {
    let inner_vertex = 2 * i
    let outer_vertex = 2 * i + 1
    let next_inner = inner_vertex + 2
    let next_outer = outer_vertex + 2
    indices.push(inner_vertex)
    indices.push(outer_vertex)
    indices.push(next_outer)
    indices.push(next_outer)
    indices.push(next_inner)
    indices.push(inner_vertex)
  }
  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(vertex_count, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
pub(all) struct AnnulusMeshBuilder {
  annulus : @math.Annulus
  resolution : Int
}

///|
pub fn AnnulusMeshBuilder::AnnulusMeshBuilder() -> AnnulusMeshBuilder {
  { annulus: @math.Annulus::Annulus(), resolution: 32 }
}

///|
pub fn AnnulusMeshBuilder::new(
  inner_radius : Float,
  outer_radius : Float,
  resolution : Int,
) -> AnnulusMeshBuilder {
  { annulus: @math.Annulus::new(inner_radius, outer_radius), resolution }
}

///|
pub fn AnnulusMeshBuilder::from_annulus(
  annulus : @math.Annulus,
) -> AnnulusMeshBuilder {
  { annulus, resolution: 32 }
}

///|
pub fn AnnulusMeshBuilder::resolution(
  self : AnnulusMeshBuilder,
  resolution : Int,
) -> AnnulusMeshBuilder {
  { annulus: self.annulus, resolution }
}

///|
pub fn AnnulusMeshBuilder::build(
  self : AnnulusMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  annulus_mesh(self.annulus.with_vertices(self.resolution))
}

///|
pub impl MeshBuilder for AnnulusMeshBuilder with fn build(self) {
  annulus_mesh(self.annulus.with_vertices(self.resolution))
}

///|
pub impl Extrudable for AnnulusMeshBuilder with fn perimeter(self) {
  annulus_perimeter(self.resolution)
}

///|
pub impl Meshable for @math.Annulus with fn mesh(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  annulus_mesh(self.with_vertices(resolution))
}

///|
pub impl ExtrudablePrimitive for @math.Annulus with fn mesh_perimeter(self) {
  let resolution = primitive2d_resolution(self.vertices, 32)
  annulus_perimeter(resolution)
}

///|
pub fn rhombus_mesh(shape : @math.Rhombus) -> @mesh.Mesh3dGeometry {
  let hhd = shape.half_diagonal.x
  let vhd = shape.half_diagonal.y
  primitive2d_geometry_with_normals(
    [
      @math.Vec3::new(hhd, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, vhd, 0.0F),
      @math.Vec3::new(-hhd, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, -vhd, 0.0F),
    ],
    primitive2d_normal_z(4, 1.0F),
    [
      @math.Vec2::new(1.0F, 0.5F),
      @math.Vec2::new(0.5F, 0.0F),
      @math.Vec2::new(0.0F, 0.5F),
      @math.Vec2::new(0.5F, 1.0F),
    ],
    Some([2, 0, 1, 2, 3, 0]),
  )
}

///|
pub struct RhombusMeshBuilder {
  half_diagonals : @math.Vec2
}

///|
pub fn RhombusMeshBuilder::RhombusMeshBuilder() -> RhombusMeshBuilder {
  { half_diagonals: @math.Vec2::new(0.5F, 0.5F) }
}

///|
pub fn RhombusMeshBuilder::new(
  horizontal_diagonal : Float,
  vertical_diagonal : Float,
) -> RhombusMeshBuilder {
  {
    half_diagonals: @math.Vec2::new(
      horizontal_diagonal * 0.5F,
      vertical_diagonal * 0.5F,
    ),
  }
}

///|
pub fn RhombusMeshBuilder::from_rhombus(
  rhombus : @math.Rhombus,
) -> RhombusMeshBuilder {
  { half_diagonals: rhombus.half_diagonal }
}

///|
pub fn RhombusMeshBuilder::build(
  self : RhombusMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  rhombus_mesh(
    @math.Rhombus::new(
      self.half_diagonals.x * 2.0F,
      self.half_diagonals.y * 2.0F,
    ),
  )
}

///|
pub impl MeshBuilder for RhombusMeshBuilder with fn build(self) {
  rhombus_mesh(
    @math.Rhombus::new(
      self.half_diagonals.x * 2.0F,
      self.half_diagonals.y * 2.0F,
    ),
  )
}

///|
pub impl Extrudable for RhombusMeshBuilder with fn perimeter(_self) {
  [Flat([0, 1, 2, 3, 0])]
}

///|
pub impl Meshable for @math.Rhombus with fn mesh(self) {
  rhombus_mesh(self)
}

///|
pub impl ExtrudablePrimitive for @math.Rhombus with fn mesh_perimeter(_self) {
  [Flat([0, 1, 2, 3, 0])]
}

///|
pub fn regular_polygon_mesh(
  shape : @math.RegularPolygon,
) -> @mesh.Mesh3dGeometry {
  ellipse_mesh(
    @math.Ellipse::new(shape.radius, shape.radius).with_vertices(shape.sides),
  )
}

///|
pub struct RegularPolygonMeshBuilder {
  circumradius : Float
  sides : Int
}

///|
pub fn RegularPolygonMeshBuilder::RegularPolygonMeshBuilder() -> RegularPolygonMeshBuilder {
  { circumradius: 0.5F, sides: 6 }
}

///|
pub fn RegularPolygonMeshBuilder::new(
  circumradius : Float,
  sides : Int,
) -> RegularPolygonMeshBuilder {
  { circumradius, sides }
}

///|
pub fn RegularPolygonMeshBuilder::from_regular_polygon(
  polygon : @math.RegularPolygon,
) -> RegularPolygonMeshBuilder {
  { circumradius: polygon.radius, sides: polygon.sides }
}

///|
pub fn RegularPolygonMeshBuilder::build(
  self : RegularPolygonMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  regular_polygon_mesh(@math.RegularPolygon::new(self.circumradius, self.sides))
}

///|
pub impl MeshBuilder for RegularPolygonMeshBuilder with fn build(self) {
  regular_polygon_mesh(@math.RegularPolygon::new(self.circumradius, self.sides))
}

///|
pub impl Extrudable for RegularPolygonMeshBuilder with fn perimeter(self) {
  [Flat(closed_range_indices(0, self.sides, 0))]
}

///|
pub impl Meshable for @math.RegularPolygon with fn mesh(self) {
  regular_polygon_mesh(self)
}

///|
pub impl ExtrudablePrimitive for @math.RegularPolygon with fn mesh_perimeter(
  self,
) {
  [Flat(closed_range_indices(0, self.sides, 0))]
}

///|
fn triangle2d_signed_area(shape : @math.Triangle2d) -> Float {
  let ab = shape.b.sub(shape.a)
  let ac = shape.c.sub(shape.a)
  ab.perp_dot(ac) * 0.5F
}

///|
pub fn triangle2d_mesh(shape : @math.Triangle2d) -> @mesh.Mesh3dGeometry {
  let vertices_3d = [
    @math.Vec3::new(shape.a.x, shape.a.y, 0.0F),
    @math.Vec3::new(shape.b.x, shape.b.y, 0.0F),
    @math.Vec3::new(shape.c.x, shape.c.y, 0.0F),
  ]
  let uvs = triangle2d_uvs(shape)
  let indices = if triangle2d_signed_area(shape) >= 0.0F {
    [0, 1, 2]
  } else {
    [2, 1, 0]
  }
  primitive2d_geometry_with_normals(
    vertices_3d,
    primitive2d_normal_z(3, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
pub struct Triangle2dMeshBuilder {
  triangle : @math.Triangle2d
}

///|
pub fn Triangle2dMeshBuilder::Triangle2dMeshBuilder() -> Triangle2dMeshBuilder {
  { triangle: @math.Triangle2d::Triangle2d() }
}

///|
pub fn Triangle2dMeshBuilder::new(
  a : @math.Vec2,
  b : @math.Vec2,
  c : @math.Vec2,
) -> Triangle2dMeshBuilder {
  { triangle: @math.Triangle2d::new(a, b, c) }
}

///|
pub fn Triangle2dMeshBuilder::from_triangle(
  triangle : @math.Triangle2d,
) -> Triangle2dMeshBuilder {
  { triangle, }
}

///|
pub fn Triangle2dMeshBuilder::build(
  self : Triangle2dMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  triangle2d_mesh(self.triangle)
}

///|
pub impl MeshBuilder for Triangle2dMeshBuilder with fn build(self) {
  triangle2d_mesh(self.triangle)
}

///|
pub impl Extrudable for Triangle2dMeshBuilder with fn perimeter(self) {
  triangle2d_perimeter(self.triangle)
}

///|
pub impl Meshable for @math.Triangle2d with fn mesh(self) {
  triangle2d_mesh(self)
}

///|
pub impl ExtrudablePrimitive for @math.Triangle2d with fn mesh_perimeter(self) {
  triangle2d_perimeter(self)
}

///|
fn triangle2d_perimeter(triangle : @math.Triangle2d) -> Array[PerimeterSegment] {
  if triangle2d_signed_area(triangle) >= 0.0F {
    [Flat([0, 1, 2, 0])]
  } else {
    [Flat([2, 1, 0, 2])]
  }
}

///|
fn triangle2d_uvs(shape : @math.Triangle2d) -> Array[@math.Vec2] {
  let a = @math.Vec3::new(shape.a.x, shape.a.y, 0.0F)
  let b = @math.Vec3::new(shape.b.x, shape.b.y, 0.0F)
  let c = @math.Vec3::new(shape.c.x, shape.c.y, 0.0F)
  let main_length = a.distance(b)
  if main_length <= 0.000001F {
    return [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ]
  }
  let x = b.sub(a).normalize_or_zero()
  let y = c.sub(a)
  let y_proj = x.mul_scalar(y.dot(x))
  let offset = y_proj.dot(x) / main_length
  if offset < 0.0F {
    let total_length = 1.0F - offset
    [
      @math.Vec2::new(offset.abs() / total_length, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ]
  } else if offset > 1.0F {
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F / offset, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ]
  } else {
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(offset, 1.0F),
    ]
  }
}

///|
fn capsule2d_mesh_with_resolution(
  shape : @math.Capsule2d,
  resolution : Int,
) -> @mesh.Mesh3dGeometry {
  let resolution = if resolution < 2 { 2 } else { resolution }
  let vertex_count = 2 * resolution
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let radius = shape.radius
  let step = 2.0F * @math.pi() / primitive2d_f32(vertex_count)
  let start_angle = if vertex_count % 2 == 0 { step / 2.0F } else { 0.0F }
  let radius_frac = shape.radius / (shape.half_length + shape.radius)

  for i in 0..<resolution {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * radius, sin * radius + shape.half_length, 0.0F),
    )
    uvs.push(
      @math.Vec2::new(
        0.5F * (cos + 1.0F),
        radius_frac * (1.0F - 0.5F * (sin + 1.0F)),
      ),
    )
  }
  for i in 1..<(resolution - 1) {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  indices.push(0)
  indices.push(resolution - 1)
  indices.push(resolution)

  for i in resolution..<vertex_count {
    let theta = start_angle + primitive2d_f32(i) * step
    let sin = @math.sin(theta)
    let cos = @math.cos(theta)
    positions.push(
      @math.Vec3::new(cos * radius, sin * radius - shape.half_length, 0.0F),
    )
    uvs.push(
      @math.Vec2::new(
        0.5F * (cos + 1.0F),
        1.0F - radius_frac * 0.5F * (sin + 1.0F),
      ),
    )
  }
  for i in 1..<(resolution - 1) {
    indices.push(resolution)
    indices.push(resolution + i)
    indices.push(resolution + i + 1)
  }
  indices.push(resolution)
  indices.push(vertex_count - 1)
  indices.push(0)

  primitive2d_geometry_with_normals(
    positions,
    primitive2d_normal_z(vertex_count, 1.0F),
    uvs,
    Some(indices),
  )
}

///|
pub(all) struct Capsule2dMeshBuilder {
  capsule : @math.Capsule2d
  resolution : Int
}

///|
pub fn Capsule2dMeshBuilder::Capsule2dMeshBuilder() -> Capsule2dMeshBuilder {
  { capsule: @math.Capsule2d::Capsule2d(), resolution: 16 }
}

///|
pub fn Capsule2dMeshBuilder::new(
  radius : Float,
  length : Float,
  resolution : Int,
) -> Capsule2dMeshBuilder {
  { capsule: @math.Capsule2d::new(radius, length), resolution }
}

///|
pub fn Capsule2dMeshBuilder::from_capsule(
  capsule : @math.Capsule2d,
) -> Capsule2dMeshBuilder {
  { capsule, resolution: 16 }
}

///|
pub fn Capsule2dMeshBuilder::resolution(
  self : Capsule2dMeshBuilder,
  resolution : Int,
) -> Capsule2dMeshBuilder {
  { capsule: self.capsule, resolution }
}

///|
pub fn Capsule2dMeshBuilder::build(
  self : Capsule2dMeshBuilder,
) -> @mesh.Mesh3dGeometry {
  capsule2d_mesh_with_resolution(self.capsule, self.resolution)
}

///|
pub impl MeshBuilder for Capsule2dMeshBuilder with fn build(self) {
  capsule2d_mesh_with_resolution(self.capsule, self.resolution)
}

///|
pub impl Extrudable for Capsule2dMeshBuilder with fn perimeter(self) {
  capsule2d_perimeter(self.resolution)
}

///|
pub impl Meshable for @math.Capsule2d with fn mesh(self) {
  let resolution = if self.segments < 2 { 16 } else { self.segments / 2 }
  capsule2d_mesh_with_resolution(self, resolution)
}

///|
pub impl ExtrudablePrimitive for @math.Capsule2d with fn mesh_perimeter(self) {
  let resolution = if self.segments < 2 { 16 } else { self.segments / 2 }
  capsule2d_perimeter(resolution)
}

///|
pub(all) struct RingMeshBuilder {
  outer_shape_builder : @mesh.Mesh3dGeometry
  inner_shape_builder : @mesh.Mesh3dGeometry
  outer_perimeter : Array[PerimeterSegment]
  inner_perimeter : Array[PerimeterSegment]
}

///|
pub fn RingMeshBuilder::new(
  outer_shape_builder : @mesh.Mesh3dGeometry,
  inner_shape_builder : @mesh.Mesh3dGeometry,
  outer_perimeter : Array[PerimeterSegment],
  inner_perimeter : Array[PerimeterSegment],
) -> RingMeshBuilder {
  { outer_shape_builder, inner_shape_builder, outer_perimeter, inner_perimeter }
}

///|
pub fn RingMeshBuilder::build(self : RingMeshBuilder) -> @mesh.Mesh3dGeometry {
  ring_mesh(self.outer_shape_builder, self.inner_shape_builder)
}

///|
pub impl MeshBuilder for RingMeshBuilder with fn build(self) {
  ring_mesh(self.outer_shape_builder, self.inner_shape_builder)
}

///|
pub impl Extrudable for RingMeshBuilder with fn perimeter(self) {
  ring_perimeter(
    self.outer_perimeter,
    self.inner_perimeter,
    self.outer_shape_builder.vertex_count(),
  )
}

///|
pub impl[P : ExtrudablePrimitive] Meshable for @math.Ring[P] with fn mesh(self) {
  ring_mesh(self.outer_shape.mesh(), self.inner_shape.mesh())
}

///|
pub impl[P : ExtrudablePrimitive] ExtrudablePrimitive for @math.Ring[P] with fn mesh_perimeter(
  self,
) {
  ring_perimeter(
    self.outer_shape.mesh_perimeter(),
    self.inner_shape.mesh_perimeter(),
    self.outer_shape.mesh().vertex_count(),
  )
}

///|
pub(open) trait IntoMeshPrimitiveAsset {
  fn into_mesh_primitive_asset(self : Self) -> @mesh.Mesh
}

///|
pub fn[S : IntoMeshPrimitiveAsset] add_mesh(
  assets : @asset.Assets[@mesh.Mesh],
  value : S,
) -> @asset.Handle[@mesh.Mesh] {
  assets.add(value.into_mesh_primitive_asset())
}

///|
fn[S : Meshable] meshable_into_mesh_asset(value : S) -> @mesh.Mesh {
  value.mesh().to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for @mesh.Mesh2dGeometry with fn into_mesh_primitive_asset(
  self,
) {
  self.to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Capsule2d with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for CircularSector with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for CircularSegment with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Circle with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Ellipse with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Annulus with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl[P : ExtrudablePrimitive] IntoMeshPrimitiveAsset for Ring[P] with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Rhombus with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for RegularPolygon with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Triangle2d with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Segment2d with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Polyline2d with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}

///|
pub impl IntoMeshPrimitiveAsset for Rectangle with fn into_mesh_primitive_asset(
  self,
) {
  meshable_into_mesh_asset(self)
}
