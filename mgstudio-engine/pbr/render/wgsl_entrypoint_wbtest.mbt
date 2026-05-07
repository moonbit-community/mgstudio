///|
test "pbr render: item-imported entrypoints are tree-shaken when unused" {
  let composer = @wgsl_compose.Composer::default()
  let mesh_source =
    #|#define_import_path demo::mesh
    #|struct Vertex {
    #|  position: vec3<f32>,
    #|}
    #|struct VertexOutput {
    #|  @builtin(position) clip_position: vec4<f32>,
    #|}
    #|@vertex
    #|fn vertex(vertex_no_morph: Vertex) -> VertexOutput {
    #|  var out: VertexOutput;
    #|  out.clip_position = vec4<f32>(vertex_no_morph.position, 1.0);
    #|  return out;
    #|}
    #|
  composer.register_source("mesh.wgsl", mesh_source)
  let pbr_source =
    #|#define_import_path demo::pbr
    #|@fragment
    #|fn fragment(vertex_output: demo::mesh::VertexOutput) -> @location(0) vec4<f32> {
    #|  return vec4<f32>(vertex_output.clip_position.xyz, 1.0);
    #|}
    #|
  composer.register_source("pbr.wgsl", pbr_source)
  composer.register_source(
    "entry.wgsl", "#import demo::{ mesh::vertex, pbr::fragment }\n",
  )
  let source = composer.compose_wgsl("entry.wgsl", @wgsl_common.WgslComposeOptions::{
    defines: @hashmap.HashMap([]),
    value_defines: @wgsl_common.default_wgsl_value_defines(),
    redirects: [],
    additional_imports: [],
  }) catch {
    err =>
      abort(
        "expected item-imported entrypoint compose success: \{err.message()}",
      )
  }
  debug_inspect(source.trim().length(), content="0")
}

///|
test "pbr render: module alias global binding access composes" {
  let composer = @wgsl_compose.Composer::default()
  let mesh_view_bindings_source =
    #|#define_import_path demo::mesh_view_bindings
    #|struct View {
    #|  world_from_view: mat4x4<f32>,
    #|}
    #|@group(0) @binding(0) var<uniform> view: View;
    #|
  composer.register_source("mesh_view_bindings.wgsl", mesh_view_bindings_source)
  let view_transformations_source =
    #|#define_import_path demo::view_transformations
    #|#import demo::mesh_view_bindings as view_bindings
    #|
    #|fn view_to_world(view_pos: vec3<f32>) -> vec3<f32> {
    #|  let world_pos = view_bindings::view.world_from_view * vec4<f32>(view_pos, 1.0);
    #|  return world_pos.xyz;
    #|}
    #|
  composer.register_source(
    "view_transformations.wgsl", view_transformations_source,
  )
  let source = composer.compose_wgsl("view_transformations.wgsl", @wgsl_common.WgslComposeOptions::{
    defines: @hashmap.HashMap([]),
    value_defines: @wgsl_common.default_wgsl_value_defines(),
    redirects: [],
    additional_imports: [],
  }) catch {
    err =>
      abort(
        "expected alias-qualified global binding compose success: \{err.message()}",
      )
  }
  debug_inspect(source.contains("var<uniform> view"), content="true")
  debug_inspect(source.contains("fn view_to_world"), content="true")
}
