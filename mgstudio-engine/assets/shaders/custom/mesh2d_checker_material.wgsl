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

#import bevy_sprite::{
    mesh2d_vertex_output::VertexOutput,
    mesh2d_view_bindings::view,
}

#ifdef TONEMAP_IN_SHADER
#import bevy_core_pipeline::tonemapping
#endif

struct CheckerMaterial {
    color: vec4<f32>,
};

struct CheckerSettings {
    frequency: f32,
    low_value: f32,
    _padding: vec2<f32>,
};

@group(#{MATERIAL_BIND_GROUP}) @binding(0) var<uniform> material: CheckerMaterial;
@group(#{MATERIAL_BIND_GROUP}) @binding(3) var<uniform> settings: CheckerSettings;

fn checker_value(uv: vec2<f32>) -> f32 {
    let cell_x = i32(floor(uv.x * settings.frequency));
    let cell_y = i32(floor(uv.y * settings.frequency));
    let parity = (cell_x + cell_y) & 1;
    if parity == 0 {
        return 1.0;
    } else {
        return settings.low_value;
    }
}

@fragment
fn fragment(
    mesh: VertexOutput,
) -> @location(0) vec4<f32> {
    var output_color: vec4<f32> = material.color;

#ifdef VERTEX_COLORS
    output_color = output_color * mesh.color;
#endif

    let checker = checker_value(mesh.uv);
    output_color = vec4<f32>(output_color.rgb * checker, output_color.a);

#ifdef TONEMAP_IN_SHADER
    output_color = tonemapping::tone_mapping(output_color, view.color_grading);
#endif
    return output_color;
}
