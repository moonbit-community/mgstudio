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
extend LineMaterial with @asset.Asset::{asset_debug_name}

///|
const SHADER_ASSET_PATH : String = "shaders/line_material.wgsl"

///|
priv struct LineMaterial {
  color : @color.LinearRgba
}

///|
fn LineMaterial::LineMaterial() -> LineMaterial {
  { color: @color.Color::white() }
}

///|
impl @asset.Asset for LineMaterial with fn asset_debug_name() {
  "mgstudio_examples::lines::LineMaterial"
}

///|
impl @asset.Asset for LineMaterial with fn asset_as_image(_self) {
  None
}

///|
let line_material_asset_resource_keys : @asset.AssetResourceKeys[LineMaterial] = @asset.register_asset_resource_keys(
  LineMaterial::asset_debug_name(),
)

///|
impl @asset.Asset for LineMaterial with fn asset_resource_keys() {
  line_material_asset_resource_keys
}

///|
let line_material_keys : @pbr.MaterialKeys[LineMaterial] = @pbr.register_material_keys(
  LineMaterial::asset_debug_name(),
)

///|
fn line_material_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, fn(index) {
    let word = words[index / 4]
    let shift = index % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn line_material_uniform_bytes(color : @color.LinearRgba) -> Bytes {
  let (r, g, b, a) = color.to_linear_rgba_tuple()
  line_material_u32le_pack([
    r.reinterpret_as_uint(),
    g.reinterpret_as_uint(),
    b.reinterpret_as_uint(),
    a.reinterpret_as_uint(),
  ])
}

///|
impl @pbr.Material for LineMaterial with fn material_debug_name() {
  LineMaterial::asset_debug_name()
}

///|
impl @pbr.Material for LineMaterial with fn material_keys() {
  line_material_keys
}

///|
impl @pbr.Material for LineMaterial with fn vertex_shader() {
  @pbr.material_default_vertex_shader()
}

///|
impl @pbr.Material for LineMaterial with fn fragment_shader() {
  Some(SHADER_ASSET_PATH)
}

///|
impl @pbr.Material for LineMaterial with fn prepass_vertex_shader() {
  @pbr.material_default_vertex_shader()
}

///|
impl @pbr.Material for LineMaterial with fn prepass_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for LineMaterial with fn deferred_vertex_shader() {
  @pbr.material_default_vertex_shader()
}

///|
impl @pbr.Material for LineMaterial with fn deferred_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for LineMaterial with fn meshlet_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for LineMaterial with fn meshlet_prepass_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for LineMaterial with fn meshlet_deferred_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for LineMaterial with fn register_shader_sources() {
  @pbr.material_default_register_shader_sources()
}

///|
impl @pbr.Material for LineMaterial with fn alpha_mode(self) {
  self |> ignore
  @pbr.material_default_alpha_mode()
}

///|
impl @pbr.Material for LineMaterial with fn opaque_render_method(self) {
  self |> ignore
  @pbr.material_default_opaque_render_method()
}

///|
impl @pbr.Material for LineMaterial with fn depth_bias(self) {
  self |> ignore
  @pbr.material_default_depth_bias()
}

///|
impl @pbr.Material for LineMaterial with fn reads_view_transmission_texture(
  self,
) {
  self |> ignore
  @pbr.material_default_reads_view_transmission_texture()
}

///|
impl @pbr.Material for LineMaterial with fn draw_data(self) {
  self |> ignore
  @pbr.material_default_draw_data()
}

///|
impl @pbr.Material for LineMaterial with fn material_extension_metadata(self) {
  self |> ignore
  None
}

///|
impl @pbr.Material for LineMaterial with fn enable_prepass() {
  @pbr.material_default_enable_prepass()
}

///|
impl @pbr.Material for LineMaterial with fn enable_shadows() {
  @pbr.material_default_enable_shadows()
}

///|
impl @pbr.Material for LineMaterial with fn bindless_supported(render_device) {
  @pbr.material_default_bindless_supported(render_device)
}

///|
impl @pbr.Material for LineMaterial with fn bindless_slot_count() {
  @pbr.material_default_bindless_slot_count()
}

///|
impl @pbr.Material for LineMaterial with fn bind_group(self, context) {
  ignore(context)
  @pbr.MaterialBindGroup::new([
    @pbr.MaterialBinding::uniform(0, line_material_uniform_bytes(self.color)),
  ])
}

///|
impl @pbr.Material for LineMaterial with fn bind_group_layout_descriptor(
  self,
  context,
) {
  @pbr.material_default_bind_group_layout_descriptor(self, context~)
}

///|
impl @pbr.Material for LineMaterial with fn bind_group_data(self, context) {
  @pbr.material_default_bind_group_data(self, context~)
}

///|
impl @pbr.Material for LineMaterial with fn renderer_extra_bind_group_data(
  self,
  context,
) {
  @pbr.material_default_renderer_extra_bind_group_data(self, context)
}

///|
impl @pbr.Material for LineMaterial with fn material_key(self, context) {
  @pbr.material_default_material_key(self, context)
}

///|
impl @pbr.Material for LineMaterial with fn specialize(descriptor, layout, key) {
  @pbr.material_default_specialize(descriptor, layout, key)
}

///|
fn color_green() -> @color.Color {
  @color.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_blue() -> @color.Color {
  @color.Color::new(0.0F, 0.0F, 1.0F, 1.0F)
}

///|
priv struct LineList {
  lines : Array[(@math.Vec3, @math.Vec3)]
}

///|
priv struct LineStrip {
  points : Array[@math.Vec3]
  indices : Array[Int]
}

///|
fn line_mesh_from_line_list(line_list : LineList) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  for i in 0..<line_list.lines.length() {
    let (start, end_) = line_list.lines[i]
    positions.push(start)
    positions.push(end_)
  }
  @mesh.Mesh3dGeometry::new_with_positions_and_topology(
    positions,
    None,
    LineList,
  )
}

///|
fn line_mesh_from_line_strip(line_strip : LineStrip) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  for point in line_strip.points {
    positions.push(point)
  }
  @mesh.Mesh3dGeometry::new_with_positions_and_topology(
    positions,
    None,
    LineStrip,
  ).with_inserted_indices_u16(Some(line_strip.indices))
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[LineMaterial]],
) -> Unit {
  let line_list_material = materials.modify(fn(material_assets) {
    material_assets.add({ color: color_green() })
  })
  let line_strip_material = materials.modify(fn(material_assets) {
    material_assets.add({ color: color_blue() })
  })

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.modify(fn(mesh_assets) {
            mesh_assets
            |> @pbr.add_mesh(
              line_mesh_from_line_list({
                lines: [
                  (@math.Vec3::zero(), @math.Vec3::new(1.0F, 1.0F, 0.0F)),
                  (
                    @math.Vec3::new(1.0F, 1.0F, 0.0F),
                    @math.Vec3::new(1.0F, 0.0F, 0.0F),
                  ),
                ],
              }),
            )
          }),
        ),
        @pbr.MeshMaterial3dTyped::new(line_list_material),
        @transform.Transform::from_xyz(-1.5F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.modify(fn(mesh_assets) {
            mesh_assets
            |> @pbr.add_mesh(
              line_mesh_from_line_strip({
                points: [
                  @math.Vec3::zero(),
                  @math.Vec3::new(1.0F, 1.0F, 0.0F),
                  @math.Vec3::new(2.0F, 0.0F, 0.0F),
                  @math.Vec3::new(2.0F, 1.0F, 0.0F),
                  @math.Vec3::new(3.0F, 1.0F, 0.0F),
                ],
                indices: [0, 1, 0xffff, 2, 3, 4],
              }),
            )
          }),
        ),
        @pbr.MeshMaterial3dTyped::new(line_strip_material),
        @transform.Transform::from_xyz(0.5F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn main {
  let line_material_plugin : @pbr.MaterialPlugin[LineMaterial] = @pbr.MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      LineMaterial()
    },
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(line_material_plugin)
  .add_systems_param3(Startup, setup)
  .run()
}
