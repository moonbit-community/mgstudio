#define_import_path bevy_pbr::view_transformations

#import bevy_pbr::mesh_view_bindings as view_bindings
#import bevy_pbr::prepass_bindings

fn position_world_to_view(world_pos: vec3<f32>) -> vec3<f32> {
    let view_pos = view_bindings::view.view_from_world * vec4(world_pos, 1.0);
    return view_pos.xyz;
}

fn position_world_to_prev_view(world_pos: vec3<f32>) -> vec3<f32> {
    let view_pos = prepass_bindings::previous_view_uniforms.view_from_world * vec4(world_pos, 1.0);
    return view_pos.xyz;
}

fn position_world_to_prev_ndc(world_pos: vec3<f32>) -> vec3<f32> {
    let ndc_pos = prepass_bindings::previous_view_uniforms.clip_from_world * vec4(world_pos, 1.0);
    return ndc_pos.xyz / ndc_pos.w;
}

fn position_world_to_ndc(world_pos: vec3<f32>) -> vec3<f32> {
    let ndc_pos = view_bindings::view.clip_from_world * vec4(world_pos, 1.0);
    return ndc_pos.xyz / ndc_pos.w;
}

fn perspective_camera_near() -> f32 {
    return view_bindings::view.clip_from_view[3][2];
}

fn view_z_to_depth_ndc(view_z: f32) -> f32 {
#ifdef VIEW_PROJECTION_PERSPECTIVE
    return -perspective_camera_near() / view_z;
#else ifdef VIEW_PROJECTION_ORTHOGRAPHIC
    return view_bindings::view.clip_from_view[3][2] + view_z * view_bindings::view.clip_from_view[2][2];
#else
    let ndc_pos = view_bindings::view.clip_from_view * vec4(0.0, 0.0, view_z, 1.0);
    return ndc_pos.z / ndc_pos.w;
#endif
}

fn prev_view_z_to_depth_ndc(view_z: f32) -> f32 {
#ifdef VIEW_PROJECTION_PERSPECTIVE
    return -perspective_camera_near() / view_z;
#else ifdef VIEW_PROJECTION_ORTHOGRAPHIC
    return prepass_bindings::previous_view_uniforms.clip_from_view[3][2] +
        view_z * prepass_bindings::previous_view_uniforms.clip_from_view[2][2];
#else
    let ndc_pos = prepass_bindings::previous_view_uniforms.clip_from_view * vec4(0.0, 0.0, view_z, 1.0);
    return ndc_pos.z / ndc_pos.w;
#endif
}

fn ndc_to_uv(ndc: vec2<f32>) -> vec2<f32> {
    return ndc * vec2(0.5, -0.5) + vec2(0.5);
}
