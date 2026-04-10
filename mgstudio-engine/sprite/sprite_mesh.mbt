// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_sprite/src/sprite_mesh.rs`.
// Mesh asset and shape conversion surface split out of `render2d.mbt`.
pub fn render_mesh_asset_add(mesh : @mesh.Mesh) -> @asset.Handle[@mesh.Mesh] {
  mesh_asset_add(mesh)
}

///|
pub fn render_mesh_asset_get(handle : @asset.Handle[@mesh.Mesh]) -> @mesh.Mesh? {
  mesh_asset_get(handle)
}

///|
pub fn render_mesh_asset_set(
  handle : @asset.Handle[@mesh.Mesh],
  mesh : @mesh.Mesh,
) -> Bool {
  mesh_asset_set(handle, mesh)
}

///|
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  mesh_upload_cache_sync_with_asset_events()
  let mesh_handle_id = mesh.id()
  if mesh_upload_cache.val.get(mesh_handle_id) is Some(mesh_id) {
    return mesh_id
  }
  let mut uploaded_mesh_radius = 1.0F
  let uploaded_mesh_id = match mesh_asset_get(mesh) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry2d(geometry2d) => {
          uploaded_mesh_radius = mesh2d_geometry_base_radius(geometry2d)
          match geometry2d.encode_triangle_interleaved_xy_uv_rgba_csv() {
            Some(vertices_csv) =>
              @render.host_gpu_create_mesh_triangles_xyuvrgba(
                vertices_xyuvrgba_csv=vertices_csv,
              )
            None => {
              let message = match geometry2d.validate() {
                Some(err) =>
                  "Mesh2dGeometry validation failed: \{to_repr(err).to_string()}"
                None => "Mesh2dGeometry flatten failed"
              }
              @window.host_debug_string(value=message)
              0
            }
          }
        }
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          uploaded_mesh_radius = 64.0F
          match mesh3d_geometry_flatten_vertices_f32(geometry3d) {
            Some(vertices_f32) =>
              @render.host_gpu_create_mesh3d_xyznuvrgba(
                vertices_xyznuvrgba=vertices_f32,
                primitive_topology=geometry3d.primitive_topology().to_int(),
              )
            None => {
              let message = match geometry3d.validate() {
                Some(err) =>
                  "Mesh3dGeometry validation failed: \{to_repr(err).to_string()}"
                None => "Mesh3dGeometry flatten failed"
              }
              @window.host_debug_string(value=message)
              0
            }
          }
        }
      }
    None => {
      @window.host_debug_string(
        value="Mesh2d upload failed: mesh handle not found",
      )
      0
    }
  }
  if uploaded_mesh_id > 0 {
    mesh_upload_cache.val.set(mesh_handle_id, uploaded_mesh_id)
    mesh_upload_radius_cache.val.set(uploaded_mesh_id, uploaded_mesh_radius)
  }
  uploaded_mesh_id
}

///|
pub(open) trait IntoSpriteRingMeshGeometry {
  into_sprite_ring_mesh_geometry(self : Self, inner_shape : Self) -> Mesh2dGeometry
}

///|
pub fn mesh2d_geometry_capsule(capsule : Capsule2d) -> Mesh2dGeometry {
  capsule_to_mesh2d_geometry(capsule)
}

///|
pub fn mesh2d_geometry_circular_sector(
  sector : CircularSector,
) -> Mesh2dGeometry {
  circular_sector_to_mesh2d_geometry(sector)
}

///|
pub fn mesh2d_geometry_circular_segment(
  segment : CircularSegment,
) -> Mesh2dGeometry {
  circular_segment_to_mesh2d_geometry(segment)
}

///|
pub fn mesh2d_geometry_circle(circle : Circle) -> Mesh2dGeometry {
  circle_to_mesh2d_geometry(circle)
}

///|
pub fn mesh2d_geometry_ellipse(ellipse : Ellipse) -> Mesh2dGeometry {
  ellipse_to_mesh2d_geometry(ellipse)
}

///|
pub fn mesh2d_geometry_annulus(annulus : Annulus) -> Mesh2dGeometry {
  annulus_to_mesh2d_geometry(annulus)
}

///|
pub fn mesh2d_geometry_ring(ring : Ring2d) -> Mesh2dGeometry {
  ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_circular_sector_ring(
  ring : CircularSectorRing,
) -> Mesh2dGeometry {
  circular_sector_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_circular_segment_ring(
  ring : CircularSegmentRing,
) -> Mesh2dGeometry {
  circular_segment_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_ellipse_ring(ring : EllipseRing) -> Mesh2dGeometry {
  ellipse_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_capsule_ring(ring : Capsule2dRing) -> Mesh2dGeometry {
  capsule_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_rhombus_ring(ring : RhombusRing) -> Mesh2dGeometry {
  rhombus_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_rectangle_ring(ring : RectangleRing) -> Mesh2dGeometry {
  rectangle_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_regular_polygon_ring(
  ring : RegularPolygonRing,
) -> Mesh2dGeometry {
  regular_polygon_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_triangle_ring(ring : Triangle2dRing) -> Mesh2dGeometry {
  triangle_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_rhombus(rhombus : Rhombus) -> Mesh2dGeometry {
  rhombus_to_mesh2d_geometry(rhombus)
}

///|
pub fn mesh2d_geometry_regular_polygon(
  polygon : RegularPolygon,
) -> Mesh2dGeometry {
  regular_polygon_to_mesh2d_geometry(polygon)
}

///|
pub fn mesh2d_geometry_triangle(triangle : Triangle2d) -> Mesh2dGeometry {
  triangle_to_mesh2d_geometry(triangle)
}

///|
pub fn mesh2d_geometry_segment(segment : Segment2d) -> Mesh2dGeometry {
  segment_to_mesh2d_geometry(segment)
}

///|
pub fn mesh2d_geometry_polyline(polyline : Polyline2d) -> Mesh2dGeometry {
  polyline_to_mesh2d_geometry(polyline)
}

///|
pub fn mesh2d_geometry_rectangle(rectangle : Rectangle) -> Mesh2dGeometry {
  rectangle_to_mesh2d_geometry(rectangle)
}

///|
pub(open) trait IntoSpriteMeshAsset {
  into_sprite_mesh_asset(Self) -> @mesh.Mesh
}

///|
pub impl IntoSpriteRingMeshGeometry for Circle with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_circle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for CircularSector with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_circular_sector_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for CircularSegment with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_circular_segment_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Ellipse with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_ellipse_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Capsule2d with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_capsule_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Rhombus with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_rhombus_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Rectangle with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_rectangle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for RegularPolygon with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_regular_polygon_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Triangle2d with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_triangle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub fn[S : IntoSpriteMeshAsset] add_mesh(
  assets : @asset.Assets[@mesh.Mesh],
  value : S,
) -> @asset.Handle[@mesh.Mesh] {
  assets.add(value.into_sprite_mesh_asset())
}

///|
pub impl IntoSpriteMeshAsset for Mesh2dGeometry with into_sprite_mesh_asset(
  self,
) {
  self.to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Capsule2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_capsule(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSector with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_sector(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSegment with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_segment(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Circle with into_sprite_mesh_asset(self) {
  mesh2d_geometry_circle(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Ellipse with into_sprite_mesh_asset(self) {
  mesh2d_geometry_ellipse(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Annulus with into_sprite_mesh_asset(self) {
  mesh2d_geometry_annulus(self).to_mesh()
}

///|
pub impl[P : IntoSpriteRingMeshGeometry] IntoSpriteMeshAsset for Ring[P] with into_sprite_mesh_asset(
  self,
) {
  self.outer_shape.into_sprite_ring_mesh_geometry(self.inner_shape).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Ring2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSectorRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_sector_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSegmentRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_segment_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for EllipseRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_ellipse_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Capsule2dRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_capsule_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RhombusRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rhombus_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RectangleRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rectangle_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RegularPolygonRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_regular_polygon_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Triangle2dRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_triangle_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Rhombus with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rhombus(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RegularPolygon with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_regular_polygon(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Triangle2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_triangle(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Segment2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_segment(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Polyline2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_polyline(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Rectangle with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rectangle(self).to_mesh()
}
