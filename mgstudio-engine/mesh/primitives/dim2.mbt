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
  let positions : Array[@math.Vec3] = []
  let indices : Array[Int] = []
  for vertex in polygon.vertices {
    positions.push(@math.Vec3::new(vertex.x, vertex.y, 0.0F))
  }
  for i in 2..<polygon.vertices.length() {
    indices.push(0)
    indices.push(i - 1)
    indices.push(i)
  }
  @mesh.Mesh3dGeometry::new_with_positions(positions, Some(indices))
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
// Bevy source: `bevy/crates/bevy_mesh/src/primitives/dim2.rs`.
// 2D primitive mesh geometry constructors used by sprite and mesh2d render paths.

///|
pub fn rectangle_to_mesh2d_geometry(
  rectangle : Rectangle,
) -> @mesh.Mesh2dGeometry {
  let hx = shape_safe_positive(shape_abs_float(rectangle.half_size.x), 0.5F)
  let hy = shape_safe_positive(shape_abs_float(rectangle.half_size.y), 0.5F)
  let positions = shape_perimeter_rectangle(@math.Vec2::new(hx, hy))
  let uvs = [
    // Positions are ordered bottom-left -> bottom-right -> top-right -> top-left.
    // Use top-origin V (same visual orientation as Bevy's Rectangle mesh UVs).
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  ]
  let indices = [0, 1, 2, 0, 2, 3]
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
pub fn rectangle_ring_to_mesh2d_geometry(
  ring : Ring[Rectangle],
) -> @mesh.Mesh2dGeometry {
  let outer_hx = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.x),
    0.5F,
  )
  let outer_hy = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.y),
    0.5F,
  )
  let mut inner_hx = shape_abs_float(ring.inner_shape.half_size.x)
  let mut inner_hy = shape_abs_float(ring.inner_shape.half_size.y)
  if inner_hx >= outer_hx {
    inner_hx = outer_hx * 0.5F
  }
  if inner_hy >= outer_hy {
    inner_hy = outer_hy * 0.5F
  }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_rectangle(@math.Vec2::new(outer_hx, outer_hy)),
    shape_perimeter_rectangle(
      @math.Vec2::new(
        shape_safe_positive(inner_hx, outer_hx * 0.5F),
        shape_safe_positive(inner_hy, outer_hy * 0.5F),
      ),
    ),
  )
}

///|
pub fn generic_circle_ring_to_mesh2d_geometry(
  ring : Ring[Circle],
) -> @mesh.Mesh2dGeometry {
  let vertices = if ring.outer_shape.vertices > ring.inner_shape.vertices {
    ring.outer_shape.vertices
  } else {
    ring.inner_shape.vertices
  }
  annulus_to_mesh2d_geometry(
    Annulus::new(ring.inner_shape.radius, ring.outer_shape.radius).with_vertices(
      vertices,
    ),
  )
}

///|
pub fn generic_circular_sector_ring_to_mesh2d_geometry(
  ring : Ring[CircularSector],
) -> @mesh.Mesh2dGeometry {
  circular_sector_ring_to_mesh2d_geometry(ring)
}

///|
pub fn generic_circular_segment_ring_to_mesh2d_geometry(
  ring : Ring[CircularSegment],
) -> @mesh.Mesh2dGeometry {
  circular_segment_ring_to_mesh2d_geometry(ring)
}

///|
pub fn generic_ellipse_ring_to_mesh2d_geometry(
  ring : Ring[Ellipse],
) -> @mesh.Mesh2dGeometry {
  ellipse_ring_to_mesh2d_geometry(ring)
}

///|
pub fn generic_capsule_ring_to_mesh2d_geometry(
  ring : Ring[Capsule2d],
) -> @mesh.Mesh2dGeometry {
  capsule_ring_to_mesh2d_geometry(ring)
}

///|
pub fn generic_rhombus_ring_to_mesh2d_geometry(
  ring : Ring[Rhombus],
) -> @mesh.Mesh2dGeometry {
  rhombus_ring_to_mesh2d_geometry(ring)
}

///|
pub fn generic_rectangle_ring_to_mesh2d_geometry(
  ring : Ring[Rectangle],
) -> @mesh.Mesh2dGeometry {
  rectangle_ring_to_mesh2d_geometry(ring)
}

///|
pub fn generic_regular_polygon_ring_to_mesh2d_geometry(
  ring : Ring[RegularPolygon],
) -> @mesh.Mesh2dGeometry {
  regular_polygon_ring_to_mesh2d_geometry(ring)
}

///|
pub fn generic_triangle_ring_to_mesh2d_geometry(
  ring : Ring[Triangle2d],
) -> @mesh.Mesh2dGeometry {
  triangle_ring_to_mesh2d_geometry(ring)
}

///|
fn shape_abs_float(v : Float) -> Float {
  if v < 0.0F {
    -v
  } else {
    v
  }
}

///|
fn shape_swap_float_pair(a : Float, b : Float) -> (Float, Float) {
  (b, a)
}

///|
fn shape_safe_positive(v : Float, fallback : Float) -> Float {
  if v <= 0.0F {
    fallback
  } else {
    v
  }
}

///|
fn shape_safe_segments(v : Int, minimum : Int) -> Int {
  if v < minimum {
    minimum
  } else {
    v
  }
}

///|
fn shape_tau() -> Float {
  @math.pi_half() * 4.0F
}

///|
fn shape_positions_to_uvs(positions : Array[@math.Vec2]) -> Array[@math.Vec2] {
  if positions.length() == 0 {
    return []
  }
  let mut min_x = positions[0].x
  let mut max_x = positions[0].x
  let mut min_y = positions[0].y
  let mut max_y = positions[0].y
  for p in positions {
    if p.x < min_x {
      min_x = p.x
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.y > max_y {
      max_y = p.y
    }
  }
  let dx = if max_x - min_x == 0.0F { 1.0F } else { max_x - min_x }
  let dy = if max_y - min_y == 0.0F { 1.0F } else { max_y - min_y }
  let uvs : Array[@math.Vec2] = []
  for p in positions {
    let u = (p.x - min_x) / dx
    let v = (p.y - min_y) / dy
    uvs.push(@math.Vec2::new(u, v))
  }
  uvs
}

///|
fn shape_geometry_from_nonindexed_positions(
  positions : Array[@math.Vec2],
) -> @mesh.Mesh2dGeometry {
  let safe_positions : Array[@math.Vec2] = []
  if positions.length() >= 3 {
    for p in positions {
      safe_positions.push(p)
    }
  } else {
    safe_positions.push(@math.Vec2::new(-0.5F, -0.5F))
    safe_positions.push(@math.Vec2::new(0.5F, -0.5F))
    safe_positions.push(@math.Vec2::new(0.0F, 0.5F))
  }
  let uvs = shape_positions_to_uvs(safe_positions)
  @mesh.Mesh2dGeometry::new(safe_positions, uvs, None)
}

///|
fn shape_triangulate_fan(perimeter : Array[@math.Vec2]) -> Array[@math.Vec2] {
  let out : Array[@math.Vec2] = []
  let n = perimeter.length()
  if n < 3 {
    return out
  }
  let pivot = perimeter[0]
  for i in 1..<(n - 1) {
    out.push(pivot)
    out.push(perimeter[i])
    out.push(perimeter[i + 1])
  }
  out
}

///|
fn shape_perimeter_circle(radius : Float, segments : Int) -> Array[@math.Vec2] {
  let perimeter : Array[@math.Vec2] = []
  let tau = shape_tau()
  for i in 0..<segments {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let theta = t * tau
    perimeter.push(
      @math.Vec2::new(@math.cos(theta) * radius, @math.sin(theta) * radius),
    )
  }
  perimeter
}

///|
fn shape_perimeter_ellipse(
  half_size : @math.Vec2,
  segments : Int,
) -> Array[@math.Vec2] {
  let perimeter : Array[@math.Vec2] = []
  let tau = shape_tau()
  for i in 0..<segments {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let theta = t * tau
    perimeter.push(
      @math.Vec2::new(
        @math.cos(theta) * half_size.x,
        @math.sin(theta) * half_size.y,
      ),
    )
  }
  perimeter
}

///|
fn shape_perimeter_rectangle(half_size : @math.Vec2) -> Array[@math.Vec2] {
  [
    @math.Vec2::new(-half_size.x, -half_size.y),
    @math.Vec2::new(half_size.x, -half_size.y),
    @math.Vec2::new(half_size.x, half_size.y),
    @math.Vec2::new(-half_size.x, half_size.y),
  ]
}

///|
fn shape_perimeter_rhombus(half_diagonal : @math.Vec2) -> Array[@math.Vec2] {
  [
    @math.Vec2::new(0.0F, half_diagonal.y),
    @math.Vec2::new(half_diagonal.x, 0.0F),
    @math.Vec2::new(0.0F, -half_diagonal.y),
    @math.Vec2::new(-half_diagonal.x, 0.0F),
  ]
}

///|
fn shape_perimeter_triangle(triangle : Triangle2d) -> Array[@math.Vec2] {
  [triangle.a, triangle.b, triangle.c]
}

///|
fn shape_perimeter_capsule(
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Array[@math.Vec2] {
  let mut safe_segments = segments
  if safe_segments < 4 {
    safe_segments = 4
  }
  let pi = @math.pi_half() * 2.0F
  let perimeter : Array[@math.Vec2] = []
  // Top arc: right -> left.
  for i in 0..<(safe_segments + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(safe_segments.to_double())
    let theta = t * pi
    perimeter.push(
      @math.Vec2::new(
        @math.cos(theta) * radius,
        @math.sin(theta) * radius + half_length,
      ),
    )
  }
  // Left side down to bottom-left.
  perimeter.push(@math.Vec2::new(-radius, -half_length))
  // Bottom arc: left -> right, skipping duplicated first point.
  for i in 1..<(safe_segments + 1) {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(safe_segments.to_double())
    let theta = pi + t * pi
    perimeter.push(
      @math.Vec2::new(
        @math.cos(theta) * radius,
        @math.sin(theta) * radius - half_length,
      ),
    )
  }
  perimeter
}

///|
fn shape_arc_points(
  radius : Float,
  half_angle : Float,
  count : Int,
) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  let first_angle = @math.pi_half() - half_angle
  let last_angle = @math.pi_half() + half_angle
  for i in 0..<count {
    let angle = arc_angle_from_index(first_angle, last_angle, i, count)
    points.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
  }
  points
}

///|
fn shape_ring_geometry_from_closed_loops(
  outer_loop : Array[@math.Vec2],
  inner_loop : Array[@math.Vec2],
) -> @mesh.Mesh2dGeometry {
  let n = outer_loop.length()
  if n < 3 || inner_loop.length() != n {
    return shape_geometry_from_nonindexed_positions([])
  }
  let triangles : Array[@math.Vec2] = []
  for i in 0..<n {
    let j = (i + 1) % n
    let o0 = outer_loop[i]
    let o1 = outer_loop[j]
    let i0 = inner_loop[i]
    let i1 = inner_loop[j]
    triangles.push(o0)
    triangles.push(o1)
    triangles.push(i1)
    triangles.push(o0)
    triangles.push(i1)
    triangles.push(i0)
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
fn shape_ring_geometry_from_open_loops(
  outer_loop : Array[@math.Vec2],
  inner_loop : Array[@math.Vec2],
) -> @mesh.Mesh2dGeometry {
  let n = outer_loop.length()
  if n < 2 || inner_loop.length() != n {
    return shape_geometry_from_nonindexed_positions([])
  }
  let triangles : Array[@math.Vec2] = []
  for i in 0..<(n - 1) {
    let o0 = outer_loop[i]
    let o1 = outer_loop[i + 1]
    let i0 = inner_loop[i]
    let i1 = inner_loop[i + 1]
    triangles.push(o0)
    triangles.push(o1)
    triangles.push(i1)
    triangles.push(o0)
    triangles.push(i1)
    triangles.push(i0)
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
pub fn circle_to_mesh2d_geometry(circle : Circle) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(circle.radius), 0.5F)
  let segments = shape_safe_segments(circle.vertices, 3)
  shape_geometry_from_nonindexed_positions(
    shape_triangulate_fan(shape_perimeter_circle(radius, segments)),
  )
}

///|
pub fn ellipse_to_mesh2d_geometry(ellipse : Ellipse) -> @mesh.Mesh2dGeometry {
  let hx = shape_safe_positive(shape_abs_float(ellipse.half_size.x), 0.5F)
  let hy = shape_safe_positive(shape_abs_float(ellipse.half_size.y), 0.5F)
  let segments = shape_safe_segments(ellipse.vertices, 3)
  shape_geometry_from_nonindexed_positions(
    shape_triangulate_fan(
      shape_perimeter_ellipse(@math.Vec2::new(hx, hy), segments),
    ),
  )
}

///|
pub fn annulus_to_mesh2d_geometry(annulus : Annulus) -> @mesh.Mesh2dGeometry {
  let mut inner = shape_abs_float(annulus.inner_radius)
  let mut outer = shape_abs_float(annulus.outer_radius)
  if outer < inner {
    let pair = shape_swap_float_pair(inner, outer)
    inner = pair.0
    outer = pair.1
  }
  outer = shape_safe_positive(outer, 0.5F)
  if inner >= outer {
    inner = outer * 0.5F
  }
  let segments = shape_safe_segments(annulus.vertices, 3)
  let tau = shape_tau()
  let triangles : Array[@math.Vec2] = []
  for i in 0..<segments {
    let t0 = Float::from_double(i.to_double()) /
      Float::from_double(segments.to_double())
    let t1 = Float::from_double((i + 1).to_double()) /
      Float::from_double(segments.to_double())
    let theta0 = t0 * tau
    let theta1 = t1 * tau
    let o0 = @math.Vec2::new(
      @math.cos(theta0) * outer,
      @math.sin(theta0) * outer,
    )
    let o1 = @math.Vec2::new(
      @math.cos(theta1) * outer,
      @math.sin(theta1) * outer,
    )
    let i0 = @math.Vec2::new(
      @math.cos(theta0) * inner,
      @math.sin(theta0) * inner,
    )
    let i1 = @math.Vec2::new(
      @math.cos(theta1) * inner,
      @math.sin(theta1) * inner,
    )
    triangles.push(o0)
    triangles.push(o1)
    triangles.push(i1)
    triangles.push(o0)
    triangles.push(i1)
    triangles.push(i0)
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
pub fn circular_sector_ring_to_mesh2d_geometry(
  ring : Ring[CircularSector],
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_half_angle = arc_safe_half_angle(ring.outer_shape.half_angle)
  let inner_half_angle = arc_safe_half_angle(ring.inner_shape.half_angle)
  let outer_count = shape_safe_segments(ring.outer_shape.vertices, 2)
  let inner_count = shape_safe_segments(ring.inner_shape.vertices, 2)
  let count = if outer_count < inner_count { outer_count } else { inner_count }
  shape_ring_geometry_from_open_loops(
    shape_arc_points(outer_radius, outer_half_angle, count),
    shape_arc_points(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      inner_half_angle,
      count,
    ),
  )
}

///|
pub fn circular_segment_ring_to_mesh2d_geometry(
  ring : Ring[CircularSegment],
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_half_angle = arc_safe_half_angle(ring.outer_shape.half_angle)
  let inner_half_angle = arc_safe_half_angle(ring.inner_shape.half_angle)
  let outer_count = shape_safe_segments(ring.outer_shape.vertices, 2)
  let inner_count = shape_safe_segments(ring.inner_shape.vertices, 2)
  let count = if outer_count < inner_count { outer_count } else { inner_count }
  shape_ring_geometry_from_closed_loops(
    shape_arc_points(outer_radius, outer_half_angle, count),
    shape_arc_points(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      inner_half_angle,
      count,
    ),
  )
}

///|
pub fn ellipse_ring_to_mesh2d_geometry(
  ring : Ring[Ellipse],
) -> @mesh.Mesh2dGeometry {
  let outer_hx = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.x),
    0.5F,
  )
  let outer_hy = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_size.y),
    0.5F,
  )
  let mut inner_hx = shape_abs_float(ring.inner_shape.half_size.x)
  let mut inner_hy = shape_abs_float(ring.inner_shape.half_size.y)
  if inner_hx >= outer_hx {
    inner_hx = outer_hx * 0.5F
  }
  if inner_hy >= outer_hy {
    inner_hy = outer_hy * 0.5F
  }
  let outer_count = shape_safe_segments(ring.outer_shape.vertices, 3)
  let inner_count = shape_safe_segments(ring.inner_shape.vertices, 3)
  let count = if outer_count < inner_count { outer_count } else { inner_count }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_ellipse(@math.Vec2::new(outer_hx, outer_hy), count),
    shape_perimeter_ellipse(
      @math.Vec2::new(
        shape_safe_positive(inner_hx, outer_hx * 0.5F),
        shape_safe_positive(inner_hy, outer_hy * 0.5F),
      ),
      count,
    ),
  )
}

///|
pub fn rhombus_to_mesh2d_geometry(rhombus : Rhombus) -> @mesh.Mesh2dGeometry {
  let hx = shape_safe_positive(shape_abs_float(rhombus.half_diagonal.x), 0.5F)
  let hy = shape_safe_positive(shape_abs_float(rhombus.half_diagonal.y), 0.5F)
  let perimeter = shape_perimeter_rhombus(@math.Vec2::new(hx, hy))
  shape_geometry_from_nonindexed_positions(shape_triangulate_fan(perimeter))
}

///|
pub fn rhombus_ring_to_mesh2d_geometry(
  ring : Ring[Rhombus],
) -> @mesh.Mesh2dGeometry {
  let outer_hx = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_diagonal.x),
    0.5F,
  )
  let outer_hy = shape_safe_positive(
    shape_abs_float(ring.outer_shape.half_diagonal.y),
    0.5F,
  )
  let mut inner_hx = shape_abs_float(ring.inner_shape.half_diagonal.x)
  let mut inner_hy = shape_abs_float(ring.inner_shape.half_diagonal.y)
  if inner_hx >= outer_hx {
    inner_hx = outer_hx * 0.5F
  }
  if inner_hy >= outer_hy {
    inner_hy = outer_hy * 0.5F
  }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_rhombus(@math.Vec2::new(outer_hx, outer_hy)),
    shape_perimeter_rhombus(
      @math.Vec2::new(
        shape_safe_positive(inner_hx, outer_hx * 0.5F),
        shape_safe_positive(inner_hy, outer_hy * 0.5F),
      ),
    ),
  )
}

///|
fn shape_perimeter_regular_polygon(
  radius : Float,
  sides : Int,
) -> Array[@math.Vec2] {
  let perimeter : Array[@math.Vec2] = []
  let tau = shape_tau()
  for i in 0..<sides {
    let t = Float::from_double(i.to_double()) /
      Float::from_double(sides.to_double())
    let theta = t * tau + @math.pi_half()
    perimeter.push(
      @math.Vec2::new(@math.cos(theta) * radius, @math.sin(theta) * radius),
    )
  }
  perimeter
}

///|
pub fn regular_polygon_to_mesh2d_geometry(
  polygon : RegularPolygon,
) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(polygon.radius), 0.5F)
  let sides = shape_safe_segments(polygon.sides, 3)
  shape_geometry_from_nonindexed_positions(
    shape_triangulate_fan(shape_perimeter_regular_polygon(radius, sides)),
  )
}

///|
pub fn regular_polygon_ring_to_mesh2d_geometry(
  ring : Ring[RegularPolygon],
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_sides = shape_safe_segments(ring.outer_shape.sides, 3)
  let inner_sides = shape_safe_segments(ring.inner_shape.sides, 3)
  let sides = if outer_sides < inner_sides { outer_sides } else { inner_sides }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_regular_polygon(outer_radius, sides),
    shape_perimeter_regular_polygon(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      sides,
    ),
  )
}

///|
pub fn triangle_to_mesh2d_geometry(
  triangle : Triangle2d,
) -> @mesh.Mesh2dGeometry {
  shape_geometry_from_nonindexed_positions(shape_perimeter_triangle(triangle))
}

///|
pub fn triangle_ring_to_mesh2d_geometry(
  ring : Ring[Triangle2d],
) -> @mesh.Mesh2dGeometry {
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_triangle(ring.outer_shape),
    shape_perimeter_triangle(ring.inner_shape),
  )
}

///|
fn shape_segment_triangles(
  start : @math.Vec2,
  end : @math.Vec2,
  half_thickness : Float,
) -> Array[@math.Vec2] {
  let triangles : Array[@math.Vec2] = []
  let thickness = shape_safe_positive(shape_abs_float(half_thickness), 0.5F)
  let dx = end.x - start.x
  let dy = end.y - start.y
  let len = @math.sqrt(dx * dx + dy * dy)
  if len <= 0.0001F {
    let p0 = @math.Vec2::new(start.x - thickness, start.y - thickness)
    let p1 = @math.Vec2::new(start.x + thickness, start.y - thickness)
    let p2 = @math.Vec2::new(start.x + thickness, start.y + thickness)
    let p3 = @math.Vec2::new(start.x - thickness, start.y + thickness)
    triangles.push(p0)
    triangles.push(p1)
    triangles.push(p2)
    triangles.push(p0)
    triangles.push(p2)
    triangles.push(p3)
    return triangles
  }
  let nx = -dy / len * thickness
  let ny = dx / len * thickness
  let p0 = @math.Vec2::new(start.x + nx, start.y + ny)
  let p1 = @math.Vec2::new(end.x + nx, end.y + ny)
  let p2 = @math.Vec2::new(end.x - nx, end.y - ny)
  let p3 = @math.Vec2::new(start.x - nx, start.y - ny)
  triangles.push(p0)
  triangles.push(p1)
  triangles.push(p2)
  triangles.push(p0)
  triangles.push(p2)
  triangles.push(p3)
  triangles
}

///|
pub fn segment_to_mesh2d_geometry(segment : Segment2d) -> @mesh.Mesh2dGeometry {
  shape_geometry_from_nonindexed_positions(
    shape_segment_triangles(segment.start, segment.end, segment.half_thickness),
  )
}

///|
pub fn polyline_to_mesh2d_geometry(
  polyline : Polyline2d,
) -> @mesh.Mesh2dGeometry {
  let points = polyline.points
  if points.length() < 2 {
    return shape_geometry_from_nonindexed_positions([])
  }
  let triangles : Array[@math.Vec2] = []
  for i in 0..<(points.length() - 1) {
    let part = shape_segment_triangles(
      points[i],
      points[i + 1],
      polyline.half_thickness,
    )
    for p in part {
      triangles.push(p)
    }
  }
  shape_geometry_from_nonindexed_positions(triangles)
}

///|
fn shape_clamp_float(
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
fn arc_safe_half_angle(raw_half_angle : Float) -> Float {
  shape_clamp_float(
    shape_abs_float(raw_half_angle),
    0.0F,
    @math.pi_half() * 2.0F,
  )
}

///|
fn arc_angle_from_index(
  first_angle : Float,
  last_angle : Float,
  index : Int,
  count : Int,
) -> Float {
  if count <= 1 {
    first_angle
  } else {
    let t = Float::from_double(index.to_double()) /
      Float::from_double((count - 1).to_double())
    first_angle + (last_angle - first_angle) * t
  }
}

///|
pub fn circular_sector_to_mesh2d_geometry(
  sector : CircularSector,
) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(sector.radius), 0.5F)
  let half_angle = arc_safe_half_angle(sector.half_angle)
  let uv_angle = match sector.uv_mode {
    Mask(angle) => angle
  }
  let resolution = shape_safe_segments(sector.vertices, 2)
  let first_angle = @math.pi_half() - half_angle
  let last_angle = @math.pi_half() + half_angle
  let positions : Array[@math.Vec2] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  positions.push(@math.Vec2::new(0.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  for i in 0..<resolution {
    let angle = arc_angle_from_index(first_angle, last_angle, i, resolution)
    positions.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
    uvs.push(
      @math.Vec2::new(
        @math.cos(-(angle + uv_angle)) * 0.5F + 0.5F,
        @math.sin(-(angle + uv_angle)) * 0.5F + 0.5F,
      ),
    )
  }
  for i in 1..<resolution {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
fn circular_segment_apothem(radius : Float, half_angle : Float) -> Float {
  let half_chord = radius * @math.sin(half_angle)
  let leg = radius * radius - half_chord * half_chord
  let positive_leg = if leg < 0.0F { 0.0F } else { leg }
  let sign = if half_angle <= @math.pi_half() { 1.0F } else { -1.0F }
  sign * @math.sqrt(positive_leg)
}

///|
pub fn circular_segment_to_mesh2d_geometry(
  segment : CircularSegment,
) -> @mesh.Mesh2dGeometry {
  let radius = shape_safe_positive(shape_abs_float(segment.radius), 0.5F)
  let half_angle = arc_safe_half_angle(segment.half_angle)
  let uv_angle = match segment.uv_mode {
    Mask(angle) => angle
  }
  let resolution = shape_safe_segments(segment.vertices, 2)
  let first_angle = @math.pi_half() - half_angle
  let last_angle = @math.pi_half() + half_angle
  let midpoint_y = circular_segment_apothem(radius, half_angle)
  let positions : Array[@math.Vec2] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  let midpoint_uv_scale = 0.5F * midpoint_y / radius
  positions.push(@math.Vec2::new(0.0F, midpoint_y))
  uvs.push(
    @math.Vec2::new(
      @math.cos(-uv_angle - @math.pi_half()) * midpoint_uv_scale + 0.5F,
      @math.sin(-uv_angle - @math.pi_half()) * midpoint_uv_scale + 0.5F,
    ),
  )
  for i in 0..<resolution {
    let angle = arc_angle_from_index(first_angle, last_angle, i, resolution)
    positions.push(
      @math.Vec2::new(@math.cos(angle) * radius, @math.sin(angle) * radius),
    )
    uvs.push(
      @math.Vec2::new(
        @math.cos(-(angle + uv_angle)) * 0.5F + 0.5F,
        @math.sin(-(angle + uv_angle)) * 0.5F + 0.5F,
      ),
    )
  }
  for i in 1..<resolution {
    indices.push(0)
    indices.push(i)
    indices.push(i + 1)
  }
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
pub fn capsule_to_mesh2d_geometry(capsule : Capsule2d) -> @mesh.Mesh2dGeometry {
  let r = shape_safe_positive(shape_abs_float(capsule.radius), 0.5F)
  let half = shape_abs_float(capsule.half_length)
  let segments = shape_safe_segments(capsule.segments, 4)
  let perimeter = shape_perimeter_capsule(r, half, segments)
  // Right side back to start is implicit.
  let positions : Array[@math.Vec2] = []
  positions.push(@math.Vec2::new(0.0F, 0.0F)) // center
  for p in perimeter {
    positions.push(p)
  }
  // Simple UVs based on bounds.
  let denom_x = if r == 0.0F { 1.0F } else { 2.0F * r }
  let denom_y = if half + r == 0.0F { 1.0F } else { 2.0F * (half + r) }
  let uvs : Array[@math.Vec2] = []
  for p in positions {
    let u = p.x / denom_x + 0.5F
    let v = p.y / denom_y + 0.5F
    uvs.push(@math.Vec2::new(u, v))
  }
  let indices : Array[Int] = []
  let n = perimeter.length()
  for i in 0..<n {
    let a = 0
    let b = 1 + i
    let c = 1 + (i + 1) % n
    indices.push(a)
    indices.push(b)
    indices.push(c)
  }
  @mesh.Mesh2dGeometry::new(positions, uvs, Some(indices))
}

///|
pub fn capsule_ring_to_mesh2d_geometry(
  ring : Ring[Capsule2d],
) -> @mesh.Mesh2dGeometry {
  let outer_radius = shape_safe_positive(
    shape_abs_float(ring.outer_shape.radius),
    0.5F,
  )
  let inner_radius = shape_abs_float(ring.inner_shape.radius)
  let safe_inner_radius = if inner_radius >= outer_radius {
    outer_radius * 0.5F
  } else {
    inner_radius
  }
  let outer_half = shape_abs_float(ring.outer_shape.half_length)
  let inner_half = shape_abs_float(ring.inner_shape.half_length)
  let outer_segments = shape_safe_segments(ring.outer_shape.segments, 4)
  let inner_segments = shape_safe_segments(ring.inner_shape.segments, 4)
  let segments = if outer_segments < inner_segments {
    outer_segments
  } else {
    inner_segments
  }
  shape_ring_geometry_from_closed_loops(
    shape_perimeter_capsule(outer_radius, outer_half, segments),
    shape_perimeter_capsule(
      shape_safe_positive(safe_inner_radius, outer_radius * 0.5F),
      inner_half,
      segments,
    ),
  )
}

///|
pub(open) trait IntoMeshPrimitiveAsset {
  fn into_mesh_primitive_asset(Self) -> @mesh.Mesh
}

///|
pub(open) trait IntoMeshPrimitiveRingGeometry {
  fn into_mesh_primitive_ring_geometry(self : Self, inner_shape : Self) -> @mesh.Mesh2dGeometry
}

///|
pub fn[S : IntoMeshPrimitiveAsset] add_mesh(
  assets : @asset.Assets[@mesh.Mesh],
  value : S,
) -> @asset.Handle[@mesh.Mesh] {
  assets.add(value.into_mesh_primitive_asset())
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
  capsule_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for CircularSector with fn into_mesh_primitive_asset(
  self,
) {
  circular_sector_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for CircularSegment with fn into_mesh_primitive_asset(
  self,
) {
  circular_segment_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Circle with fn into_mesh_primitive_asset(
  self,
) {
  circle_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Ellipse with fn into_mesh_primitive_asset(
  self,
) {
  ellipse_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Annulus with fn into_mesh_primitive_asset(
  self,
) {
  annulus_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl[P : IntoMeshPrimitiveRingGeometry] IntoMeshPrimitiveAsset for Ring[P] with fn into_mesh_primitive_asset(
  self,
) {
  self.outer_shape.into_mesh_primitive_ring_geometry(self.inner_shape).to_mesh()
}

///|
pub impl IntoMeshPrimitiveRingGeometry for Circle with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_circle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for CircularSector with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_circular_sector_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for CircularSegment with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_circular_segment_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for Ellipse with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_ellipse_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for Capsule2d with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_capsule_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for Rhombus with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_rhombus_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for Rectangle with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_rectangle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for RegularPolygon with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_regular_polygon_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveRingGeometry for Triangle2d with fn into_mesh_primitive_ring_geometry(
  self,
  inner_shape,
) {
  generic_triangle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoMeshPrimitiveAsset for Rhombus with fn into_mesh_primitive_asset(
  self,
) {
  rhombus_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for RegularPolygon with fn into_mesh_primitive_asset(
  self,
) {
  regular_polygon_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Triangle2d with fn into_mesh_primitive_asset(
  self,
) {
  triangle_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Segment2d with fn into_mesh_primitive_asset(
  self,
) {
  segment_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Polyline2d with fn into_mesh_primitive_asset(
  self,
) {
  polyline_to_mesh2d_geometry(self).to_mesh()
}

///|
pub impl IntoMeshPrimitiveAsset for Rectangle with fn into_mesh_primitive_asset(
  self,
) {
  rectangle_to_mesh2d_geometry(self).to_mesh()
}
