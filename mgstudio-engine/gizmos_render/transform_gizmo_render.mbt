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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/transform_gizmo_render.rs`.
//
// Mesh-based rendering for the transform gizmo. Requires
// `@gizmos.TransformGizmoPlugin` for the interaction logic.

///|
const GIZMO_RENDER_LAYER : Int = 15

///|
const FRAC_PI_2 : Float = 1.5707964

///|
/// Marker for the internal overlay camera that renders gizmo meshes.
pub struct GizmoOverlayCamera {}

///|
#warnings("-unnecessary_annotation")
pub fn GizmoOverlayCamera::GizmoOverlayCamera() -> GizmoOverlayCamera {
  GizmoOverlayCamera::{  }
}

///|
pub let ecs_key_gizmo_overlay_camera : @ecs.ComponentKey[GizmoOverlayCamera] = @ecs.register_component(
  debug_name="mgstudio_gizmos_render::GizmoOverlayCamera",
)

///|
pub impl @ecs.Component for GizmoOverlayCamera with fn component() {
  ecs_key_gizmo_overlay_camera
}

///|
/// Per-axis handle colours in their normal, highlighted and inactive states.
pub(all) struct TransformGizmoMaterials {
  normal_colors : Array[@color.Color]
  highlight_colors : Array[@color.Color]
  inactive_colors : Array[@color.Color]
}

///|
pub fn transform_gizmo_axis_index(axis : @gizmos.TransformGizmoAxis) -> Int {
  match axis {
    X => 0
    Y => 1
    Z => 2
    View => 3
  }
}

///|
pub fn TransformGizmoMaterials::color(
  self : TransformGizmoMaterials,
  axis : @gizmos.TransformGizmoAxis,
  highlight : Bool,
  inactive : Bool,
) -> @color.Color {
  let i = transform_gizmo_axis_index(axis)
  if highlight {
    self.highlight_colors[i]
  } else if inactive {
    self.inactive_colors[i]
  } else {
    self.normal_colors[i]
  }
}

///|
pub let ecs_res_key_transform_gizmo_materials : @ecs.ResourceKey[
  TransformGizmoMaterials,
] = @ecs.register_resource(
  debug_name="mgstudio_gizmos_render::TransformGizmoMaterials",
)

///|
pub impl @app.Resource for TransformGizmoMaterials with fn resource() {
  ecs_res_key_transform_gizmo_materials
}

///|
fn axis_vec(axis : @gizmos.TransformGizmoAxis) -> @math.Vec3 {
  match axis {
    X => @math.Vec3::new(1.0F, 0.0F, 0.0F)
    Y => @math.Vec3::new(0.0F, 1.0F, 0.0F)
    Z => @math.Vec3::new(0.0F, 0.0F, 1.0F)
    View => @math.Vec3::zero()
  }
}

///|
fn make_unlit_material(color : @color.Color) -> @pbr.StandardMaterial {
  @pbr.StandardMaterial::from_color(color).with_unlit(true)
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn highlight_color(color : @color.Color) -> @color.Color {
  let (red, green, blue, alpha) = color.to_srgba_tuple()
  @color.Color::srgba(
    min_float(red * 1.4F, 1.0F),
    min_float(green * 1.4F, 1.0F),
    min_float(blue * 1.4F, 1.0F),
    alpha,
  )
}

///|
fn inactive_color(color : @color.Color) -> @color.Color {
  let (red, green, blue, _) = color.to_srgba_tuple()
  @color.Color::srgba(
    red * @gizmos.INACTIVE_ALPHA,
    green * @gizmos.INACTIVE_ALPHA,
    blue * @gizmos.INACTIVE_ALPHA,
    1.0F,
  )
}

///|
/// Cylinder and cone meshes are Y-up by default, so each axis handle is rotated
/// onto its own axis.
fn axis_rotation(axis : @gizmos.TransformGizmoAxis) -> @math.Quat {
  match axis {
    X => @math.Quat::from_rotation_z(-FRAC_PI_2)
    Y | View => @math.Quat::identity()
    Z => @math.Quat::from_rotation_x(FRAC_PI_2)
  }
}

///|
/// The rotation tori use a different orientation from the translate handles.
fn torus_rotation(axis : @gizmos.TransformGizmoAxis) -> @math.Quat {
  match axis {
    X => @math.Quat::from_rotation_z(FRAC_PI_2)
    Y | View => @math.Quat::identity()
    Z => @math.Quat::from_rotation_x(FRAC_PI_2)
  }
}

///|
fn gizmo_render_global_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global) => global.to_transform_approx()
    None =>
      match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
        Some(value) => value
        None => @transform.Transform::identity()
      }
  }
}

///|
fn spawn_gizmo_child(
  world : @ecs.World,
  root : @core.Entity,
  mesh : @mesh.Mesh3d,
  material : @pbr.StandardMaterial,
  transform : @transform.Transform,
  axis : @gizmos.TransformGizmoAxis,
  mode : @gizmos.TransformGizmoMode,
  layer : @camera_render_layers.RenderLayers,
) -> Unit {
  let child = @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3dTyped::new(@pbr.standard_material_add(material)),
    transform,
  ).spawn(world)
  try! world.set_by_key(
    child,
    @gizmos.ecs_key_transform_gizmo_mesh_marker,
    @gizmos.TransformGizmoMeshMarker::new(axis, mode),
  )
  try! world.set_by_key(child, @visibility.ecs_key_visibility, Hidden)
  try! world.set_by_key(
    child, @camera_render_layers.ecs_key_render_layers, layer,
  )
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
}

///|
/// Spawn the gizmo mesh hierarchy and the overlay camera. Runs at `Startup`,
/// but only once `TransformGizmoSettings` exists.
///
/// Bevy gates this with
/// `run_if(resource_exists::<TransformGizmoSettings>)`. The resource is
/// inserted by `TransformGizmoPlugin`, which an app opts into, so an app that
/// never adds that plugin gets no gizmo meshes and, crucially, no overlay
/// camera. Without the guard every app built on `DefaultPlugins` gains a second
/// order-1 camera on the primary window.
pub fn spawn_gizmo_meshes(world : @ecs.World) -> Unit {
  guard world.get_resource(@gizmos.ecs_res_key_transform_gizmo_settings)
    is Some(_) else {
    return
  }
  if world.get_resource(ecs_res_key_transform_gizmo_materials) is Some(_) {
    return
  }
  let layer = @camera_render_layers.RenderLayers::layer(GIZMO_RENDER_LAYER)
  let colors = [
    @gizmos.transform_gizmo_color_x(),
    @gizmos.transform_gizmo_color_y(),
    @gizmos.transform_gizmo_color_z(),
    @gizmos.transform_gizmo_color_view(),
  ]
  let materials : TransformGizmoMaterials = {
    normal_colors: colors,
    highlight_colors: colors.map(highlight_color),
    inactive_colors: colors.map(inactive_color),
  }
  let shaft_mesh = @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.cylinder_mesh(
            @math.Cylinder::new(@gizmos.SHAFT_RADIUS, @gizmos.SHAFT_LENGTH),
          ),
        ),
      )
    }),
  )
  let cone_mesh = @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.cone_mesh(
            @math.Cone::new(@gizmos.CONE_RADIUS, @gizmos.CONE_HEIGHT),
          ),
        ),
      )
    }),
  )
  let scale_cube_mesh = @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.cuboid_mesh(
            @math.Cuboid::new(
              @gizmos.SCALE_CUBE_SIZE,
              @gizmos.SCALE_CUBE_SIZE,
              @gizmos.SCALE_CUBE_SIZE,
            ),
          ),
        ),
      )
    }),
  )
  let rotate_torus_mesh = @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.torus_mesh(
            @math.Torus::new(0.015F, @gizmos.ROTATE_RING_RADIUS),
          ),
        ),
      )
    }),
  )
  let view_circle_mesh = @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.torus_mesh(
            @math.Torus::new(
              @gizmos.VIEW_CIRCLE_MINOR,
              @gizmos.VIEW_CIRCLE_MAJOR,
            ),
          ),
        ),
      )
    }),
  )
  let view_ring_mesh = @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.torus_mesh(
            @math.Torus::new(@gizmos.VIEW_RING_MINOR, @gizmos.VIEW_RING_MAJOR),
          ),
        ),
      )
    }),
  )

  // Root of the gizmo hierarchy.
  let root = world.spawn_empty()
  try! world.set_by_key(
    root,
    @gizmos.ecs_key_transform_gizmo_root,
    @gizmos.TransformGizmoRoot::TransformGizmoRoot(),
  )
  try! world.set_by_key(
    root,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  try! world.set_by_key(root, @visibility.ecs_key_visibility, Hidden)
  let shaft_offset = @gizmos.AXIS_START_OFFSET + @gizmos.SHAFT_LENGTH / 2.0F
  let tip_offset = @gizmos.AXIS_START_OFFSET +
    @gizmos.SHAFT_LENGTH +
    @gizmos.CONE_HEIGHT / 2.0F
  let axes : Array[@gizmos.TransformGizmoAxis] = [X, Y, Z]

  // Translate mode: shaft plus arrow tip per axis.
  for axis in axes {
    let color = colors[transform_gizmo_axis_index(axis)]
    let shaft_position = axis_vec(axis).mul_scalar(shaft_offset)
    spawn_gizmo_child(
      world,
      root,
      shaft_mesh,
      make_unlit_material(color),
      @transform.Transform::from_xyz(
        shaft_position.x,
        shaft_position.y,
        shaft_position.z,
      ).with_rotation(axis_rotation(axis)),
      axis,
      Translate,
      layer,
    )
    let tip_position = axis_vec(axis).mul_scalar(tip_offset)
    spawn_gizmo_child(
      world,
      root,
      cone_mesh,
      make_unlit_material(color),
      @transform.Transform::from_xyz(
        tip_position.x,
        tip_position.y,
        tip_position.z,
      ).with_rotation(axis_rotation(axis)),
      axis,
      Translate,
      layer,
    )
  }

  // View-plane circle (translate).
  spawn_gizmo_child(
    world,
    root,
    view_circle_mesh,
    make_unlit_material(colors[3]),
    @transform.Transform::identity(),
    View,
    Translate,
    layer,
  )

  // Rotate mode: one torus per axis.
  for axis in axes {
    spawn_gizmo_child(
      world,
      root,
      rotate_torus_mesh,
      make_unlit_material(colors[transform_gizmo_axis_index(axis)]),
      @transform.Transform::identity().with_rotation(torus_rotation(axis)),
      axis,
      Rotate,
      layer,
    )
  }

  // View-axis ring (rotate).
  spawn_gizmo_child(
    world,
    root,
    view_ring_mesh,
    make_unlit_material(colors[3]),
    @transform.Transform::identity(),
    View,
    Rotate,
    layer,
  )

  // Scale mode: shaft plus cube per axis.
  for axis in axes {
    let color = colors[transform_gizmo_axis_index(axis)]
    let shaft_position = axis_vec(axis).mul_scalar(shaft_offset)
    spawn_gizmo_child(
      world,
      root,
      shaft_mesh,
      make_unlit_material(color),
      @transform.Transform::from_xyz(
        shaft_position.x,
        shaft_position.y,
        shaft_position.z,
      ).with_rotation(axis_rotation(axis)),
      axis,
      Scale,
      layer,
    )
    let cube_position = axis_vec(axis).mul_scalar(tip_offset)
    spawn_gizmo_child(
      world,
      root,
      scale_cube_mesh,
      make_unlit_material(color),
      @transform.Transform::from_xyz(
        cube_position.x,
        cube_position.y,
        cube_position.z,
      ),
      axis,
      Scale,
      layer,
    )
  }

  // Overlay camera: renders only the gizmo layer, after the main camera
  // (order 1), so gizmo meshes appear on top of everything.
  //
  // Bevy leaves `clear_color` at its default here: its `ColorAttachment` clears
  // a target only on the first write of a frame, so a second camera on the same
  // target implicitly loads. mgstudio does not yet compose cameras that way --
  // post-process targets are keyed by camera entity rather than by render
  // target, so this camera's composite currently erases the main camera's
  // output. `ClearColorConfig::None` does not help, because the composite
  // rewrites the whole surface regardless of the load op. Tracked as ISS-479;
  // this spawn stays faithful to the Bevy source.
  let overlay = @camera.Camera3dBundle::new(
    @camera_camera.Camera::Camera().with_order(1),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(
    overlay,
    ecs_key_gizmo_overlay_camera,
    GizmoOverlayCamera::GizmoOverlayCamera(),
  )
  try! world.set_by_key(
    overlay, @camera_render_layers.ecs_key_render_layers, layer,
  )
  world.insert_resource(ecs_res_key_transform_gizmo_materials, materials)
}

///|
fn overlay_camera_entity(world : @ecs.World) -> @core.Entity? {
  let mut found : @core.Entity? = None
  world.for_each_component(ecs_key_gizmo_overlay_camera, fn(entity, _marker) {
    if found is None {
      found = Some(entity)
    }
  })
  found
}

///|
fn gizmo_root_entity(world : @ecs.World) -> @core.Entity? {
  let mut found : @core.Entity? = None
  world.for_each_component(@gizmos.ecs_key_transform_gizmo_root, fn(
    entity,
    _marker,
  ) {
    if found is None {
      found = Some(entity)
    }
  })
  found
}

///|
/// Follow the focused entity with the gizmo root, keep the overlay camera in
/// step with the gizmo camera, and recolour the handles. Runs at `PostUpdate`.
pub fn update_gizmo_meshes(world : @ecs.World) -> Unit {
  guard world.get_resource(ecs_res_key_transform_gizmo_materials)
    is Some(materials) else {
    return
  }
  guard world.get_resource(@gizmos.ecs_res_key_transform_gizmo_settings)
    is Some(settings) else {
    return
  }
  guard world.get_resource(@gizmos.ecs_res_key_transform_gizmo_state)
    is Some(state) else {
    return
  }
  guard gizmo_root_entity(world) is Some(root) else { return }
  let mut focus : @transform.Transform? = None
  world.for_each_component(@gizmos.ecs_key_transform_gizmo_focus, fn(
    entity,
    _marker,
  ) {
    if focus is None {
      focus = Some(gizmo_render_global_transform(world, entity))
    }
  })
  guard focus is Some(focus_transform) else {
    try! world.set_by_key(root, @visibility.ecs_key_visibility, Hidden)
    return
  }
  guard @gizmos.resolve_gizmo_camera(world) is Some(gizmo_camera) else {
    try! world.set_by_key(root, @visibility.ecs_key_visibility, Hidden)
    return
  }

  // Keep the overlay camera on the gizmo camera's transform.
  if overlay_camera_entity(world) is Some(overlay) {
    try! (world.replace(
      overlay,
      @transform.ecs_key_transform,
      gizmo_camera.transform,
    )
    |> ignore)
  }
  try! world.set_by_key(root, @visibility.ecs_key_visibility, Inherited)
  let position = focus_transform.translation
  let space = @gizmos.effective_space(settings)
  let rotation = @gizmos.gizmo_rotation(focus_transform.rotation, space)
  let scale = if settings.screen_scale_factor > 0.0F {
    gizmo_camera.transform.translation.sub(position).length() *
    settings.screen_scale_factor
  } else {
    1.0F
  }
  try! (world.replace(
    root,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(position.x, position.y, position.z)
    .with_rotation(rotation)
    .with_scale(@math.Vec3::splat(scale)),
  )
  |> ignore)
  let active_axis = if state.active { state.axis } else { state.hovered_axis }
  let dragging = state.active
  world.for_each_component(@gizmos.ecs_key_transform_gizmo_mesh_marker, fn(
    entity,
    marker,
  ) {
    if marker.mode != settings.mode {
      try! world.set_by_key(entity, @visibility.ecs_key_visibility, Hidden)
      return
    }
    try! world.set_by_key(entity, @visibility.ecs_key_visibility, Inherited)
    let is_active = active_axis is Some(axis) && axis == marker.axis
    let desired = materials.color(
      marker.axis,
      is_active,
      dragging && !is_active,
    )
    guard (try! world.get_by_key(entity, @pbr.ecs_key_mesh_material3d))
      is Some(material_component) else {
      return
    }
    let handle = @asset.Handle::from_asset_id(
      @asset.AssetId::new(material_component.material_asset_id()),
    )
    guard @pbr.standard_material_get(handle) is Some(material) else { return }
    // Bevy compares `Color` directly; mgstudio's `Color` has no `Eq`, so the
    // srgba tuples are compared instead.
    if material.base_color.to_srgba_tuple() != desired.to_srgba_tuple() {
      @pbr.standard_material_set(handle, material.with_base_color(desired))
      |> ignore
    }
  })
}

///|
/// Plugin that adds mesh-based rendering for the transform gizmo.
///
/// Requires `@gizmos.TransformGizmoPlugin` for the interaction logic.
pub struct TransformGizmoRenderPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn TransformGizmoRenderPlugin::TransformGizmoRenderPlugin() -> TransformGizmoRenderPlugin {
  TransformGizmoRenderPlugin::{  }
}

///|
pub impl @app.Plugin for TransformGizmoRenderPlugin with fn name(_self) {
  "mgstudio.gizmos_render.TransformGizmoRenderPlugin"
}

///|
pub impl @app.Plugin for TransformGizmoRenderPlugin with fn build(_self, app) {
  transform_gizmo_render_plugin(app)
}

///|
pub fn transform_gizmo_render_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .add_systems_world(Startup, spawn_gizmo_meshes)
  .add_post_update_system_config(
    @app.system(update_gizmo_meshes).after(@transform.transform_set_propagate),
  )
}
