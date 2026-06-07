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
const PI : Float = 3.141592653589793F

///|
const COLORED_MESH2D_SHADER_PATH : String = "examples/2d/mesh2d_manual/colored_mesh2d.wgsl"

///|
const COLORED_MESH2D_SHADER : String =
  #|#import bevy_sprite::mesh2d_functions
  #|
  #|struct Vertex {
  #|    @builtin(instance_index) instance_index: u32,
  #|    @location(0) position: vec3<f32>,
  #|    @location(1) color: u32,
  #|};
  #|
  #|struct VertexOutput {
  #|    @builtin(position) clip_position: vec4<f32>,
  #|    @location(0) color: vec4<f32>,
  #|};
  #|
  #|@vertex
  #|fn vertex(vertex: Vertex) -> VertexOutput {
  #|    var out: VertexOutput;
  #|    let model = mesh2d_functions::get_world_from_local(vertex.instance_index);
  #|    out.clip_position = mesh2d_functions::mesh2d_position_local_to_clip(model, vec4<f32>(vertex.position, 1.0));
  #|    out.color = vec4<f32>((vec4<u32>(vertex.color) >> vec4<u32>(0u, 8u, 16u, 24u)) & vec4<u32>(255u)) / 255.0;
  #|    return out;
  #|}
  #|
  #|struct FragmentInput {
  #|    @location(0) color: vec4<f32>,
  #|};
  #|
  #|@fragment
  #|fn fragment(in: FragmentInput) -> @location(0) vec4<f32> {
  #|    return in.color;
  #|}

///|
const BLACK_U32 : UInt = 0xFF000000U

///|
const YELLOW_U32 : UInt = 0xFF00FFFFU

///|
struct ColoredMesh2d {}

///|
fn ColoredMesh2d::ColoredMesh2d() -> ColoredMesh2d {
  ColoredMesh2d::{  }
}

///|
let colored_mesh2d_key : @ecs.ComponentKey[ColoredMesh2d] = @ecs.register_component(
  debug_name="mgstudio.examples.mesh2d_manual.ColoredMesh2d",
)

///|
pub impl @ecs.Component for ColoredMesh2d with fn component() {
  colored_mesh2d_key
}

///|
struct ColoredMesh2dPlugin {}

///|
fn ColoredMesh2dPlugin::ColoredMesh2dPlugin() -> ColoredMesh2dPlugin {
  ColoredMesh2dPlugin::{  }
}

///|
pub impl @app.Plugin for ColoredMesh2dPlugin with fn name(_self) {
  "mgstudio.examples.mesh2d_manual.ColoredMesh2dPlugin"
}

///|
pub impl @app.Plugin for ColoredMesh2dPlugin with fn build(_self, app) {
  let descriptor = @sprite_render.CustomMesh2dPipelineDescriptor::new(
    COLORED_MESH2D_SHADER_PATH,
  )
  let configured = @render.with_render_app(app, fn(render_app) {
    @sprite_render.register_custom_mesh2d_pipeline_world(
      render_app.world(),
      type_name="mgstudio.examples.mesh2d_manual.ColoredMesh2d",
      component_key=colored_mesh2d_key,
      descriptor~,
    )
    render_app
  })
  configured.add_startup_system(fn(_world : @ecs.World) {
    @render.register_wgsl_source(
      COLORED_MESH2D_SHADER_PATH,
      COLORED_MESH2D_SHADER,
    )
  })
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  let star = meshes.modify(fn(meshes) { meshes.add(build_star_mesh()) })

  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))
  ignore(
    commands.spawn((@mesh.Mesh2d::new(star), ColoredMesh2d::ColoredMesh2d())),
  )
}

///|
fn build_star_mesh() -> @mesh.Mesh {
  let positions : Array[@math.Vec3] = []
  let colors : Array[UInt] = []
  let indices : Array[Int] = []

  positions.push(@math.Vec3::new(0.0F, 0.0F, 0.0F))
  colors.push(BLACK_U32)

  for i in 0..<10 {
    let angle = Float::from_double(i.to_double()) * PI / 5.0F
    let radius = Float::from_int(1 - i % 2) * 100.0F + 100.0F
    positions.push(
      @math.Vec3::new(
        radius * @math.sin(angle),
        radius * @math.cos(angle),
        0.0F,
      ),
    )
    colors.push(YELLOW_U32)
  }

  indices.push(0)
  indices.push(1)
  indices.push(10)
  for i in 2..<11 {
    indices.push(0)
    indices.push(i)
    indices.push(i - 1)
  }

  let geometry = @mesh.Mesh2dGeometry::new_empty()
  ignore(
    geometry.insert_attribute(
      @mesh.MeshVertexAttribute::position(),
      @mesh.VertexAttributeValues::Float32x3(positions),
    ),
  )
  ignore(
    geometry.insert_attribute(
      @mesh.MeshVertexAttribute::new(
        "Vertex_Color",
        1UL,
        @mesh.MeshVertexFormat::Uint32,
      ),
      @mesh.VertexAttributeValues::Uint32(colors),
    ),
  )
  geometry.insert_indices(Some(indices))
  @mesh.Mesh::from_2d_geometry(geometry)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(ColoredMesh2dPlugin::ColoredMesh2dPlugin())
  .add_systems_param2(@app.Startup, setup)
  .run()
}
