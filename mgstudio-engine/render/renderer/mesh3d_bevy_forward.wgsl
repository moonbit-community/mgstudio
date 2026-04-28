// Thin local entrypoint that keeps the default mesh3d runtime on Bevy's
// original PBR shader modules.
#import bevy_pbr::{ mesh::vertex, pbr::fragment }

fn _mgstudio_keep_bevy_mesh_vertex(vertex_no_morph: Vertex) -> VertexOutput {
    return vertex(vertex_no_morph);
}

fn _mgstudio_keep_bevy_pbr_fragment(vertex_output: VertexOutput, is_front: bool) -> FragmentOutput {
    return fragment(vertex_output, is_front);
}
