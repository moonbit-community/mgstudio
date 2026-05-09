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
pub(open) trait IntoPbrMeshAsset {
  into_pbr_mesh_asset(Self) -> @mesh.Mesh
}

///|
pub fn[S : IntoPbrMeshAsset] add_mesh(
  assets : @asset.Assets[@mesh.Mesh],
  value : S,
) -> @asset.Handle[@mesh.Mesh] {
  assets.add(value.into_pbr_mesh_asset())
}

///|
pub impl IntoPbrMeshAsset for @mesh.Mesh3dGeometry with into_pbr_mesh_asset(
  self,
) {
  self.to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Cuboid with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Plane3d with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Sphere with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Cylinder with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Capsule3d with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Triangle3d with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Tetrahedron with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Cone with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.ConicalFrustum with into_pbr_mesh_asset(
  self,
) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Torus with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Segment3d with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}

///|
pub impl IntoPbrMeshAsset for @math.Polyline3d with into_pbr_mesh_asset(self) {
  @mesh_primitives_dim3.Meshable::mesh(self).to_mesh()
}
