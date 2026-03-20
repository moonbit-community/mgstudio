#import bevy_sprite::mesh2d_vertex_output::VertexOutput

struct Wireframe2dMaterial {
    color: vec4<f32>
}

@group(#{MATERIAL_BIND_GROUP}) @binding(0) var<uniform> material: Wireframe2dMaterial;

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    return material.color;
}
