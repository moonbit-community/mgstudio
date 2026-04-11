#define_import_path bevy_pbr::mesh_view_bindings

#import bevy_render::view::View

@group(0) @binding(0) var<uniform> view: View;
