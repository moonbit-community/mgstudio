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
const NUM_SLICES : Int = 8

///|
const SPACING_X : Float = 100.0F

///|
const SECTOR_Y : Float = 50.0F

///|
const SEGMENT_Y : Float = -50.0F

///|
const ARC_RADIUS : Float = 40.0F

///|
struct SectorBounds {
  shape : @sprite.CircularSector
}

///|
struct SegmentBounds {
  shape : @sprite.CircularSegment
}

///|
let sector_bounds_component_key : @ecs.ComponentKey[SectorBounds] = @ecs.register_component(
  debug_name="examples.2d.mesh2d_arcs.SectorBounds",
)

///|
let segment_bounds_component_key : @ecs.ComponentKey[SegmentBounds] = @ecs.register_component(
  debug_name="examples.2d.mesh2d_arcs.SegmentBounds",
)

///|
impl @ecs.Component for SectorBounds with fn component() {
  sector_bounds_component_key
}

///|
impl @ecs.Component for SegmentBounds with fn component() {
  segment_bounds_component_key
}

///|
fn main {
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system_config_param4(
    setup,
  )
  let draw_sector_bounds_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    draw_sector_bounds,
  )
  let draw_segment_bounds_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    draw_segment_bounds,
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems(@app.Startup, setup_system)
  .add_systems(
    @app.Update,
    (draw_sector_bounds_system, draw_segment_bounds_system) |> @app.chain(),
  )
  .run()
}

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
) -> Unit {
  let material = @sprite_render_mesh2d_material.MeshMaterial2d::new(
    materials
    .peek()
    .add(
      @sprite_render_mesh2d_color_material.ColorMaterial::from_image(
        asset_server.get().load("branding/icon.png"),
      ),
    ),
  )
  let offset_x = SPACING_X * int_to_float(NUM_SLICES - 1) / 2.0F

  ignore(
    commands.spawn(
      (
        @camera_components2d.Camera2d::Camera2d(),
        @camera_camera.Camera::new(
          @sprite.Color::srgba(0.5019608F, 0.5019608F, 0.5019608F, 1.0F),
        ),
      ),
    ),
  )

  for i in 0..<NUM_SLICES {
    let fraction = int_to_float(i + 1) / int_to_float(NUM_SLICES)
    let x = SPACING_X * int_to_float(i) - offset_x

    let sector = @sprite.CircularSector::from_turns(ARC_RADIUS, fraction)
    let sector_angle = -sector.half_angle()
    ignore(
      commands.spawn(
        (
          @mesh.Mesh2d::new(
            meshes
            .peek()
            .add(
              @sprite.mesh2d_geometry_circular_sector(
                sector.with_uv_mask_angle(sector_angle),
              ).to_mesh(),
            ),
          ),
          material,
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(x, SECTOR_Y),
            sector_angle,
            @math.Vec2::new(1.0F, 1.0F),
          ),
          SectorBounds::{ shape: sector },
        ),
      ),
    )

    let segment = @sprite.CircularSegment::from_turns(ARC_RADIUS, fraction)
    let segment_angle = -@math.pi_half()
    ignore(
      commands.spawn(
        (
          @mesh.Mesh2d::new(
            meshes
            .peek()
            .add(
              @sprite.mesh2d_geometry_circular_segment(
                segment.with_uv_mask_angle(-segment_angle),
              ).to_mesh(),
            ),
          ),
          material,
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(x, SEGMENT_Y),
            segment_angle,
            @math.Vec2::new(1.0F, 1.0F),
          ),
          SegmentBounds::{ shape: segment },
        ),
      ),
    )
  }
}

///|
fn[T : @math.Bounded2d] draw_bounds_for_shape(
  shape : T,
  transform : @transform.GlobalTransform,
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  let red = @sprite.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F)
  let blue = @sprite.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F)
  let world_transform = transform.to_transform_approx()
  let translation = @math.Vec2::new(
    world_transform.translation.x,
    world_transform.translation.y,
  )
  let rotation = @math.Rot2::radians(world_transform.rotation_z())
  let isometry = @math.Isometry2d::new(translation, rotation)
  let aabb = shape.aabb_2d(isometry)
  gizmos.rect_2d(
    @sprite.Isometry2d::new(aabb.center(), 0.0F),
    aabb.half_size().mul_scalar(2.0F),
    red,
  )
  let bounding_circle = shape.bounding_circle(isometry)
  ignore(
    gizmos.circle_2d(
      @sprite.Isometry2d::new(bounding_circle.center, 0.0F),
      bounding_circle.radius(),
      blue,
    ),
  )
}

///|
fn draw_sector_bounds(
  query : @ecs.Query[
    (@ecs.Comp[SectorBounds], @ecs.Comp[@transform.GlobalTransform]),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (shape, transform) = data
    draw_bounds_for_shape(shape.value().shape, transform.value(), gizmos)
  })
}

///|
fn draw_segment_bounds(
  query : @ecs.Query[
    (@ecs.Comp[SegmentBounds], @ecs.Comp[@transform.GlobalTransform]),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (shape, transform) = data
    draw_bounds_for_shape(shape.value().shape, transform.value(), gizmos)
  })
}
